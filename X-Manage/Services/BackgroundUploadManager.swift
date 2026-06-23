//
//  BackgroundUploadManager.swift
//  X-Manage
//
//  统一管理客户端在进行中的分块上传任务，使 sheet/详情页关闭后上传仍能继续。
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.xyouacg.X-Manage", category: "BackgroundUpload")

// MARK: - 上传任务模型

struct UploadJob: Identifiable, Equatable {
    enum Kind: String {
        case anime
        case comic
    }

    enum Status: String {
        case running
        case completed
        case failed
        case cancelled
    }

    let id: UUID
    let kind: Kind
    let title: String
    let subtitle: String?
    let startedAt: Date

    var percentage: Double
    var uploadedChunks: Int
    var totalChunks: Int
    var uploadedBytes: Int
    var totalBytes: Int
    var status: Status
    var error: String?
    var resultTaskId: String?

    static func == (lhs: UploadJob, rhs: UploadJob) -> Bool { lhs.id == rhs.id }
}

// MARK: - 后台上传管理器

@MainActor
final class BackgroundUploadManager: ObservableObject {
    static let shared = BackgroundUploadManager()

    @Published private(set) var jobs: [UploadJob] = []

    // 进行中任务的底层引用，仅 manager 自己维护
    private final class Handle {
        let animeUploader: AnimeVideoUploader?
        let comicUploader: ComicZipUploader?
        let task: Task<Void, Never>

        init(animeUploader: AnimeVideoUploader? = nil, comicUploader: ComicZipUploader? = nil, task: Task<Void, Never>) {
            self.animeUploader = animeUploader
            self.comicUploader = comicUploader
            self.task = task
        }
    }
    private var handles: [UUID: Handle] = [:]

    private init() {}

    // MARK: - 状态查询

    var activeCount: Int {
        jobs.lazy.filter { $0.status == .running }.count
    }

    var hasActiveJobs: Bool {
        activeCount > 0
    }

    func job(_ id: UUID) -> UploadJob? {
        jobs.first { $0.id == id }
    }

    // MARK: - 启动动漫视频上传

    @discardableResult
    func startAnimeUpload(
        animeId: Int,
        animeSlug: String,
        animeTitle: String? = nil,
        episodeNo: Int,
        fileUrl: URL,
        subtitlePath: String? = nil,
        onProgress: (@MainActor (VideoUploadProgress) -> Void)? = nil,
        onCompleted: (@MainActor (CompleteVideoUploadResponse) -> Void)? = nil,
        onFailed: (@MainActor (Error) -> Void)? = nil
    ) -> UUID {
        let id = UUID()
        let display = animeTitle?.isEmpty == false ? animeTitle! : animeSlug
        let job = UploadJob(
            id: id,
            kind: .anime,
            title: "《\(display)》第 \(episodeNo) 集",
            subtitle: fileUrl.lastPathComponent,
            startedAt: Date(),
            percentage: 0,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0,
            status: .running,
            error: nil,
            resultTaskId: nil
        )
        jobs.append(job)

        let uploader = AnimeVideoUploader(
            animeId: animeId,
            animeSlug: animeSlug,
            episodeNo: episodeNo,
            fileUrl: fileUrl,
            subtitlePath: subtitlePath,
            concurrency: 2,
            maxRetries: 3
        ) { [weak self] progress in
            Task { @MainActor in
                self?.updateAnimeProgress(id: id, progress: progress)
                onProgress?(progress)
            }
        }

        let task = Task { @MainActor [weak self] in
            do {
                let result = try await uploader.upload()
                self?.markCompleted(id: id, taskId: result.taskId)
                onCompleted?(result)
            } catch {
                self?.handleUploadError(id: id, error: error)
                if !Self.isAbort(error) { onFailed?(error) }
            }
        }

        handles[id] = Handle(animeUploader: uploader, task: task)
        logger.info("Started anime upload job=\(id.uuidString) episode=\(episodeNo)")
        return id
    }

    private static func isAbort(_ error: Error) -> Bool {
        if let videoErr = error as? VideoUploadError, case .aborted = videoErr { return true }
        if let comicErr = error as? ComicZipUploadError, case .aborted = comicErr { return true }
        return false
    }

    // MARK: - 启动漫画 ZIP 上传

    @discardableResult
    func startComicUpload(
        comicId: Int,
        comicSlug: String,
        comicTitle: String? = nil,
        fileUrl: URL,
        startChapterSort: Int? = nil,
        onProgress: (@MainActor (ComicZipUploadProgress) -> Void)? = nil,
        onCompleted: (@MainActor (CompleteComicZipUploadResponse) -> Void)? = nil,
        onFailed: (@MainActor (Error) -> Void)? = nil
    ) -> UUID {
        let id = UUID()
        let display = comicTitle?.isEmpty == false ? comicTitle! : comicSlug
        let job = UploadJob(
            id: id,
            kind: .comic,
            title: "《\(display)》",
            subtitle: fileUrl.lastPathComponent,
            startedAt: Date(),
            percentage: 0,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0,
            status: .running,
            error: nil,
            resultTaskId: nil
        )
        jobs.append(job)

        let uploader = ComicZipUploader(
            comicId: comicId,
            comicSlug: comicSlug,
            fileUrl: fileUrl,
            startChapterSort: startChapterSort,
            onProgress: { [weak self] progress in
                Task { @MainActor in
                    self?.updateComicProgress(id: id, progress: progress)
                    onProgress?(progress)
                }
            }
        )

        let task = Task { @MainActor [weak self] in
            do {
                let result = try await uploader.upload()
                self?.markCompleted(id: id, taskId: result.taskId)
                onCompleted?(result)
            } catch {
                self?.handleUploadError(id: id, error: error)
                if !Self.isAbort(error) { onFailed?(error) }
            }
        }

        handles[id] = Handle(comicUploader: uploader, task: task)
        logger.info("Started comic upload job=\(id.uuidString) comic=\(comicSlug)")
        return id
    }

    // MARK: - 取消

    func cancel(_ jobId: UUID) {
        guard let handle = handles[jobId] else { return }
        logger.info("Cancelling upload job=\(jobId.uuidString)")
        Task {
            await handle.animeUploader?.abort()
            await handle.comicUploader?.abort()
        }
    }

    // MARK: - 清理列表

    /// 从列表中移除已结束的任务；进行中任务不允许移除
    func dismiss(_ jobId: UUID) {
        guard let idx = jobs.firstIndex(where: { $0.id == jobId }) else { return }
        if jobs[idx].status == .running { return }
        jobs.remove(at: idx)
        handles[jobId] = nil
    }

    func clearFinished() {
        let finishedIds = jobs.filter { $0.status != .running }.map(\.id)
        jobs.removeAll { $0.status != .running }
        for id in finishedIds { handles[id] = nil }
    }

    // MARK: - 内部状态更新

    private func updateAnimeProgress(id: UUID, progress: VideoUploadProgress) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].percentage = progress.percentage
        jobs[idx].uploadedChunks = progress.uploadedChunks
        jobs[idx].totalChunks = progress.totalChunks
        jobs[idx].uploadedBytes = progress.uploadedBytes
        jobs[idx].totalBytes = progress.totalBytes
    }

    private func updateComicProgress(id: UUID, progress: ComicZipUploadProgress) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].percentage = progress.percentage
        jobs[idx].uploadedChunks = progress.uploadedChunks
        jobs[idx].totalChunks = progress.totalChunks
        jobs[idx].uploadedBytes = progress.uploadedBytes
        jobs[idx].totalBytes = progress.totalBytes
    }

    private func markCompleted(id: UUID, taskId: String?) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].status = .completed
        jobs[idx].percentage = 100
        jobs[idx].resultTaskId = taskId
    }

    private func handleUploadError(id: UUID, error: Error) {
        // 区分主动取消与真实错误
        if let videoErr = error as? VideoUploadError, case .aborted = videoErr {
            markCancelled(id: id)
            return
        }
        if let comicErr = error as? ComicZipUploadError, case .aborted = comicErr {
            markCancelled(id: id)
            return
        }
        markFailed(id: id, error: error.localizedDescription)
    }

    private func markCancelled(id: UUID) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].status = .cancelled
    }

    private func markFailed(id: UUID, error: String) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].status = .failed
        jobs[idx].error = error
        logger.error("Upload job=\(id.uuidString) failed: \(error)")
    }
}
