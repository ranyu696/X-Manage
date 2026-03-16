//
//  AnimeVideoUploader.swift
//  X-Manage
//
//  动漫视频分块上传器（S3 Multipart Upload）

import Foundation

// MARK: - 上传请求/响应模型

struct InitVideoUploadRequest: Codable {
    let animeId: Int
    let animeSlug: String
    let episodeNo: Int
    let filename: String
    let contentType: String
    let fileSize: Int

    enum CodingKeys: String, CodingKey {
        case animeId = "anime_id"
        case animeSlug = "anime_slug"
        case episodeNo = "episode_no"
        case filename
        case contentType = "content_type"
        case fileSize = "file_size"
    }
}

struct VideoPartInfo: Codable {
    let partNumber: Int
    let uploadUrl: String
    let startByte: Int
    let endByte: Int

    enum CodingKeys: String, CodingKey {
        case partNumber = "part_number"
        case uploadUrl = "upload_url"
        case startByte = "start_byte"
        case endByte = "end_byte"
    }

    var size: Int { endByte - startByte }
}

struct InitVideoUploadResponse: Codable {
    let uploadId: String
    let parts: [VideoPartInfo]

    enum CodingKeys: String, CodingKey {
        case uploadId = "upload_id"
        case parts
    }
}

struct CompletedPart: Codable {
    let partNumber: Int
    let etag: String

    enum CodingKeys: String, CodingKey {
        case partNumber = "part_number"
        case etag
    }
}

struct CompleteVideoUploadRequest: Codable {
    let parts: [CompletedPart]
    let subtitlePath: String?

    enum CodingKeys: String, CodingKey {
        case parts
        case subtitlePath = "subtitle_path"
    }
}

struct CompleteVideoUploadResponse: Codable {
    let taskId: String
    let taskStatus: String
    let storageKey: String?
    let sourcePath: String?
    let fileSize: Int?
    let etag: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case taskStatus = "task_status"
        case storageKey = "storage_key"
        case sourcePath = "source_path"
        case fileSize = "file_size"
        case etag
    }
}

// MARK: - 上传进度

struct VideoUploadProgress {
    enum Status {
        case pending
        case uploading
        case completing
        case completed
        case failed
        case aborted
    }

    var status: Status
    var uploadedChunks: Int
    var totalChunks: Int
    var uploadedBytes: Int
    var totalBytes: Int

    var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(uploadedBytes) / Double(totalBytes) * 100
    }

    var error: String?
}

// MARK: - 动漫视频上传器

actor AnimeVideoUploader {
    private let animeId: Int
    private let animeSlug: String
    private let episodeNo: Int
    private let fileUrl: URL
    private let subtitlePath: String?
    private let onProgress: ((VideoUploadProgress) -> Void)?

    private var uploadId: String?
    private var aborted = false
    private let concurrency: Int
    private let maxRetries: Int

    init(
        animeId: Int,
        animeSlug: String,
        episodeNo: Int,
        fileUrl: URL,
        subtitlePath: String? = nil,
        concurrency: Int = 2,
        maxRetries: Int = 3,
        onProgress: ((VideoUploadProgress) -> Void)? = nil
    ) {
        self.animeId = animeId
        self.animeSlug = animeSlug
        self.episodeNo = episodeNo
        self.fileUrl = fileUrl
        self.subtitlePath = subtitlePath
        self.concurrency = concurrency
        self.maxRetries = maxRetries
        self.onProgress = onProgress
    }

    private static func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        default: return "video/mp4"
        }
    }

    func upload() async throws -> CompleteVideoUploadResponse {
        guard !aborted else {
            throw VideoUploadError.aborted
        }

        // 读取文件信息
        let fileData = try Data(contentsOf: fileUrl)
        let fileSize = fileData.count
        let fileName = fileUrl.lastPathComponent

        // 1. 初始化上传，获取预签名URL列表
        let initResponse = try await initUpload(fileName: fileName, fileSize: fileSize)
        uploadId = initResponse.uploadId

        let totalParts = initResponse.parts.count

        updateProgress(VideoUploadProgress(
            status: .uploading,
            uploadedChunks: 0,
            totalChunks: totalParts,
            uploadedBytes: 0,
            totalBytes: fileSize
        ))

        // 2. 按批次并发上传到预签名URL，收集 ETag
        var completedParts: [CompletedPart] = []
        var uploadedPartsCount = 0
        var uploadedBytes = 0

        for batchStart in stride(from: 0, to: totalParts, by: concurrency) {
            guard !aborted else {
                throw VideoUploadError.aborted
            }

            let batchEnd = min(batchStart + concurrency, totalParts)
            let batch = Array(initResponse.parts[batchStart..<batchEnd])

            try await withThrowingTaskGroup(of: CompletedPart.self) { group in
                for part in batch {
                    group.addTask {
                        let etag = try await self.uploadPart(part: part, fileData: fileData)
                        return CompletedPart(partNumber: part.partNumber, etag: etag)
                    }
                }

                for try await completedPart in group {
                    let partInfo = initResponse.parts.first { $0.partNumber == completedPart.partNumber }
                    completedParts.append(completedPart)
                    uploadedPartsCount += 1
                    uploadedBytes += partInfo?.size ?? 0
                    self.updateProgress(VideoUploadProgress(
                        status: .uploading,
                        uploadedChunks: uploadedPartsCount,
                        totalChunks: totalParts,
                        uploadedBytes: uploadedBytes,
                        totalBytes: fileSize
                    ))
                }
            }
        }

        // 按 partNumber 排序
        completedParts.sort { $0.partNumber < $1.partNumber }

        // 3. 完成上传
        updateProgress(VideoUploadProgress(
            status: .completing,
            uploadedChunks: totalParts,
            totalChunks: totalParts,
            uploadedBytes: fileSize,
            totalBytes: fileSize
        ))

        let completeResponse = try await completeUpload(uploadId: initResponse.uploadId, parts: completedParts)

        updateProgress(VideoUploadProgress(
            status: .completed,
            uploadedChunks: totalParts,
            totalChunks: totalParts,
            uploadedBytes: fileSize,
            totalBytes: fileSize
        ))

        return completeResponse
    }

    func abort() async {
        aborted = true
        if let uploadId = uploadId {
            try? await abortUpload(uploadId: uploadId)
        }
        updateProgress(VideoUploadProgress(
            status: .aborted,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0
        ))
    }

    // MARK: - Private Methods

    private func initUpload(fileName: String, fileSize: Int) async throws -> InitVideoUploadResponse {
        let request = InitVideoUploadRequest(
            animeId: animeId,
            animeSlug: animeSlug,
            episodeNo: episodeNo,
            filename: fileName,
            contentType: Self.contentType(for: fileUrl),
            fileSize: fileSize
        )

        return try await APIClient.shared.request(
            endpoint: APIEndpoints.Anime.videoUploadInit,
            method: .post,
            body: request
        )
    }

    private func uploadPart(part: VideoPartInfo, fileData: Data) async throws -> String {
        let startIndex = fileData.index(fileData.startIndex, offsetBy: part.startByte)
        let endIndex = fileData.index(fileData.startIndex, offsetBy: part.endByte)
        let partData = fileData[startIndex..<endIndex]

        var lastError: Error?

        for retry in 0...maxRetries {
            do {
                guard let url = URL(string: part.uploadUrl) else {
                    throw VideoUploadError.invalidUrl
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.httpBody = Data(partData)

                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw VideoUploadError.chunkUploadFailed(chunk: part.partNumber)
                }

                guard let etag = httpResponse.value(forHTTPHeaderField: "ETag") else {
                    throw VideoUploadError.chunkUploadFailed(chunk: part.partNumber)
                }

                return etag
            } catch {
                lastError = error
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (retry + 1)))
                }
            }
        }

        throw lastError ?? VideoUploadError.chunkUploadFailed(chunk: part.partNumber)
    }

    private func completeUpload(uploadId: String, parts: [CompletedPart]) async throws -> CompleteVideoUploadResponse {
        let request = CompleteVideoUploadRequest(parts: parts, subtitlePath: subtitlePath)

        return try await APIClient.shared.request(
            endpoint: APIEndpoints.Anime.videoUploadComplete(uploadId),
            method: .post,
            body: request
        )
    }

    private func abortUpload(uploadId: String) async throws {
        try await APIClient.shared.requestVoid(
            endpoint: "\(APIEndpoints.basePrefix)/anime/upload/abort/\(uploadId)",
            method: .delete
        )
    }

    private func updateProgress(_ progress: VideoUploadProgress) {
        onProgress?(progress)
    }
}

// MARK: - 错误类型

enum VideoUploadError: LocalizedError {
    case aborted
    case invalidUrl
    case chunkUploadFailed(chunk: Int)
    case completeFailed

    var errorDescription: String? {
        switch self {
        case .aborted:
            return "上传已取消"
        case .invalidUrl:
            return "无效的上传URL"
        case .chunkUploadFailed(let chunk):
            return "分块 \(chunk) 上传失败"
        case .completeFailed:
            return "完成上传失败"
        }
    }
}
