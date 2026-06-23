//
//  ComicZipUploader.swift
//  X-Manage
//
//  漫画ZIP分块上传器

import Foundation
import os.log

private let uploaderLogger = Logger(subsystem: "com.xyouacg.X-Manage", category: "ComicZipUploader")

// MARK: - 上传请求/响应模型

struct InitComicZipUploadRequest: Codable {
    let comicId: Int
    let comicSlug: String
    let fileName: String
    let fileSize: Int
    let startChapterSort: Int?

    enum CodingKeys: String, CodingKey {
        case comicId = "comic_id"
        case comicSlug = "comic_slug"
        case fileName = "file_name"
        case fileSize = "file_size"
        case startChapterSort = "start_chapter_sort"
    }
}

struct ChunkInfo: Codable {
    let chunkNumber: Int
    let startByte: Int
    let endByte: Int
    let size: Int

    enum CodingKeys: String, CodingKey {
        case chunkNumber = "chunk_number"
        case startByte = "start_byte"
        case endByte = "end_byte"
        case size
    }
}

struct InitComicZipUploadResponse: Codable {
    let sessionId: String
    let chunks: [ChunkInfo]
    let totalChunks: Int
    let chunkSize: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case chunks
        case totalChunks = "total_chunks"
        case chunkSize = "chunk_size"
    }
}

struct CompleteComicZipUploadRequest: Codable {
    let comicId: Int
    let comicSlug: String

    enum CodingKeys: String, CodingKey {
        case comicId = "comic_id"
        case comicSlug = "comic_slug"
    }
}

struct CompleteComicZipUploadResponse: Codable {
    let taskId: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case message
    }
}

// MARK: - 上传进度

struct ComicZipUploadProgress {
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

// MARK: - 漫画ZIP上传器

actor ComicZipUploader {
    private let comicId: Int
    private let comicSlug: String
    private let fileUrl: URL
    private let startChapterSort: Int?
    private let onProgress: ((ComicZipUploadProgress) -> Void)?

    private var sessionId: String?
    private var aborted = false
    private let concurrency: Int
    private let maxRetries: Int

    init(
        comicId: Int,
        comicSlug: String,
        fileUrl: URL,
        startChapterSort: Int? = nil,
        concurrency: Int = 3,
        maxRetries: Int = 3,
        onProgress: ((ComicZipUploadProgress) -> Void)? = nil
    ) {
        self.comicId = comicId
        self.comicSlug = comicSlug
        self.fileUrl = fileUrl
        self.startChapterSort = startChapterSort
        self.concurrency = concurrency
        self.maxRetries = maxRetries
        self.onProgress = onProgress
    }

    func upload() async throws -> CompleteComicZipUploadResponse {
        guard !aborted else {
            throw ComicZipUploadError.aborted
        }

        // 只读取文件大小，分块内容由 FileHandle 按需读取，避免把整个大文件载入内存
        let attributes = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
        guard let fileSize = (attributes[.size] as? NSNumber)?.intValue, fileSize > 0 else {
            throw ComicZipUploadError.fileReadFailed
        }
        let fileName = fileUrl.lastPathComponent

        // 1. 初始化上传
        let initResponse = try await initUpload(fileName: fileName, fileSize: fileSize)
        sessionId = initResponse.sessionId

        updateProgress(ComicZipUploadProgress(
            status: .uploading,
            uploadedChunks: 0,
            totalChunks: initResponse.totalChunks,
            uploadedBytes: 0,
            totalBytes: fileSize
        ))

        // 2. 上传分块
        var uploadedChunks = 0
        var uploadedBytes = 0

        // 按批次并发上传
        for batchStart in stride(from: 0, to: initResponse.chunks.count, by: concurrency) {
            guard !aborted else {
                throw ComicZipUploadError.aborted
            }

            let batchEnd = min(batchStart + concurrency, initResponse.chunks.count)
            let batch = Array(initResponse.chunks[batchStart..<batchEnd])

            try await withThrowingTaskGroup(of: Int.self) { group in
                for chunk in batch {
                    group.addTask {
                        try await self.uploadChunk(
                            sessionId: initResponse.sessionId,
                            chunk: chunk
                        )
                        return chunk.size
                    }
                }

                for try await chunkSize in group {
                    uploadedChunks += 1
                    uploadedBytes += chunkSize
                    self.updateProgress(ComicZipUploadProgress(
                        status: .uploading,
                        uploadedChunks: uploadedChunks,
                        totalChunks: initResponse.totalChunks,
                        uploadedBytes: uploadedBytes,
                        totalBytes: fileSize
                    ))
                }
            }
        }

        // 3. 完成上传
        updateProgress(ComicZipUploadProgress(
            status: .completing,
            uploadedChunks: initResponse.totalChunks,
            totalChunks: initResponse.totalChunks,
            uploadedBytes: fileSize,
            totalBytes: fileSize
        ))

        let completeResponse = try await completeUpload(sessionId: initResponse.sessionId)

        updateProgress(ComicZipUploadProgress(
            status: .completed,
            uploadedChunks: initResponse.totalChunks,
            totalChunks: initResponse.totalChunks,
            uploadedBytes: fileSize,
            totalBytes: fileSize
        ))

        return completeResponse
    }

    func abort() async {
        aborted = true
        if let sessionId = sessionId {
            do {
                try await abortUpload(sessionId: sessionId)
            } catch {
                // 客户端取消后服务端清理失败，记录 sessionId 便于人工清理
                uploaderLogger.error("Failed to abort comic upload session (sessionId=\(sessionId)): \(error.localizedDescription)")
            }
        }
        updateProgress(ComicZipUploadProgress(
            status: .aborted,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0
        ))
    }

    // MARK: - Private Methods

    private func initUpload(fileName: String, fileSize: Int) async throws -> InitComicZipUploadResponse {
        let request = InitComicZipUploadRequest(
            comicId: comicId,
            comicSlug: comicSlug,
            fileName: fileName,
            fileSize: fileSize,
            startChapterSort: startChapterSort
        )

        return try await APIClient.shared.request(
            endpoint: APIEndpoints.ComicUpload.initSession,
            method: .post,
            body: request
        )
    }

    private func uploadChunk(sessionId: String, chunk: ChunkInfo) async throws {
        let chunkData = try readChunk(chunk)

        var lastError: Error?

        for retry in 0...maxRetries {
            // 每次重试前重新读取 baseURL 与 token，避免中途刷新后仍用陈旧 token 导致 401
            let baseURL = await APIClient.shared.baseURL
            let token = await AuthManager.shared.accessToken

            do {
                guard let url = URL(string: baseURL + APIEndpoints.ComicUpload.chunk(sessionId, chunk.chunkNumber)) else {
                    throw ComicZipUploadError.invalidUrl
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.httpBody = Data(chunkData)
                request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

                // 添加认证头
                if let token = token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw ComicZipUploadError.chunkUploadFailed(chunk: chunk.chunkNumber)
                }

                return
            } catch {
                lastError = error
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (retry + 1)))
                }
            }
        }

        throw lastError ?? ComicZipUploadError.chunkUploadFailed(chunk: chunk.chunkNumber)
    }

    // readChunk 用 FileHandle 按需读取单个分块，避免把整个大文件载入内存
    private func readChunk(_ chunk: ChunkInfo) throws -> Data {
        let handle = try FileHandle(forReadingFrom: fileUrl)
        defer { try? handle.close() }

        try handle.seek(toOffset: UInt64(chunk.startByte))
        guard let data = try handle.read(upToCount: chunk.size), data.count == chunk.size else {
            throw ComicZipUploadError.fileReadFailed
        }
        return data
    }

    private func completeUpload(sessionId: String) async throws -> CompleteComicZipUploadResponse {
        let request = CompleteComicZipUploadRequest(
            comicId: comicId,
            comicSlug: comicSlug
        )

        return try await APIClient.shared.request(
            endpoint: APIEndpoints.ComicUpload.complete(sessionId),
            method: .post,
            body: request
        )
    }

    private func abortUpload(sessionId: String) async throws {
        try await APIClient.shared.requestVoid(
            endpoint: APIEndpoints.ComicUpload.abort(sessionId),
            method: .delete
        )
    }

    private func updateProgress(_ progress: ComicZipUploadProgress) {
        onProgress?(progress)
    }
}

// MARK: - 错误类型

enum ComicZipUploadError: LocalizedError {
    case aborted
    case invalidUrl
    case fileReadFailed
    case chunkUploadFailed(chunk: Int)
    case completeFailed

    var errorDescription: String? {
        switch self {
        case .aborted:
            return "上传已取消"
        case .invalidUrl:
            return "无效的上传URL"
        case .fileReadFailed:
            return "读取文件失败"
        case .chunkUploadFailed(let chunk):
            return "分块 \(chunk) 上传失败"
        case .completeFailed:
            return "完成上传失败"
        }
    }
}
