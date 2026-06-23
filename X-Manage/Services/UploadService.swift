//
//  UploadService.swift
//  X-Manage
//
//  文件上传服务 - 支持预签名URL上传

import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - 上传请求/响应模型

struct UploadFileInfo: Codable {
    let fileName: String
    let contentType: String
    let sortOrder: Int
    let fileSize: Int

    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case contentType = "content_type"
        case sortOrder = "sort_order"
        case fileSize = "file_size"
    }
}

struct UploadImagesRequest: Codable {
    let files: [UploadFileInfo]
}

struct UploadInfo: Codable {
    let fileName: String
    let fileUrl: String
    let sortOrder: Int
    let storagePath: String
    let uploadUrl: String

    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case fileUrl = "file_url"
        case sortOrder = "sort_order"
        case storagePath = "storage_path"
        case uploadUrl = "upload_url"
    }
}

struct UploadImagesResult: Codable {
    let uploadInfos: [UploadInfo]
    let failedUploads: [String]

    enum CodingKeys: String, CodingKey {
        case uploadInfos = "upload_infos"
        case failedUploads = "failed_uploads"
    }
}

struct SingleUploadResult: Codable {
    let uploadUrl: String
    let coverUrl: String
    let storagePath: String

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case coverUrl = "cover_url"
        case storagePath = "storage_path"
    }
}

// 剧集图片（封面/横图）上传URL响应
struct EpisodeImageUploadResult: Codable {
    let uploadUrl: String
    let storageKey: String
    let expiresIn: Int64

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case storageKey = "storage_key"
        case expiresIn = "expires_in"
    }
}

// 剧集图片上传URL请求
struct EpisodeImageUploadRequest: Codable {
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

struct SingleUploadRequest: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int

    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case contentType = "content_type"
        case fileSize = "file_size"
    }
}

// MARK: - 上传进度

struct UploadProgress {
    let current: Int
    let total: Int
    let fileName: String
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
}

// MARK: - 上传服务

@MainActor
class UploadService {
    static let shared = UploadService()
    private let api = APIClient.shared

    private init() {}

    // MARK: - 游戏图片上传

    /// 获取游戏封面上传URL
    func getGameCoversUploadUrls(gameSlug: String, files: [UploadFileInfo]) async throws -> UploadImagesResult {
        let request = UploadImagesRequest(files: files)
        return try await api.request(
            endpoint: APIEndpoints.Games.uploadCovers(gameSlug),
            method: .post,
            body: request
        )
    }

    /// 获取游戏内容图片上传URL
    func getGameContentsUploadUrls(gameSlug: String, files: [UploadFileInfo]) async throws -> UploadImagesResult {
        let request = UploadImagesRequest(files: files)
        return try await api.request(
            endpoint: APIEndpoints.Games.uploadContents(gameSlug),
            method: .post,
            body: request
        )
    }

    /// 获取游戏更新图片上传URL
    func getGameUpdatesUploadUrls(gameSlug: String, files: [UploadFileInfo]) async throws -> UploadImagesResult {
        let request = UploadImagesRequest(files: files)
        return try await api.request(
            endpoint: APIEndpoints.Games.uploadUpdates(gameSlug),
            method: .post,
            body: request
        )
    }

    /// 更新游戏封面
    func updateGameCovers(gameId: Int, covers: [String]) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Games.updateCovers(gameId),
            method: .put,
            body: ["covers": covers]
        )
    }

    /// 更新游戏内容图片
    func updateGameContentImages(gameId: Int, contentImages: [String]) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Games.updateContentImages(gameId),
            method: .put,
            body: ["content_images": contentImages]
        )
    }

    /// 更新游戏更新图片
    func updateGameUpdateImages(gameId: Int, updateImages: [String]) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Games.updateUpdateImages(gameId),
            method: .put,
            body: ["update_images": updateImages]
        )
    }

    // MARK: - 小说封面上传

    /// 获取小说封面上传URL
    func getNovelCoverUploadUrl(novelSlug: String, fileName: String, contentType: String, fileSize: Int) async throws -> SingleUploadResult {
        let request = SingleUploadRequest(fileName: fileName, contentType: contentType, fileSize: fileSize)
        return try await api.request(
            endpoint: APIEndpoints.Novels.uploadCover(novelSlug),
            method: .post,
            body: request
        )
    }

    /// 更新小说封面
    func updateNovelCover(novelId: Int, cover: String) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Novels.updateCover(novelId),
            method: .put,
            body: ["cover": cover]
        )
    }

    // MARK: - 漫画封面上传

    /// 获取漫画封面上传URL
    func getComicCoverUploadUrl(comicSlug: String, fileName: String, contentType: String, fileSize: Int) async throws -> SingleUploadResult {
        let request = SingleUploadRequest(fileName: fileName, contentType: contentType, fileSize: fileSize)
        return try await api.request(
            endpoint: APIEndpoints.Comics.uploadCover(comicSlug),
            method: .post,
            body: request
        )
    }

    /// 更新漫画封面
    func updateComicCover(comicId: Int, cover: String) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Comics.updateCover(comicId),
            method: .put,
            body: ["cover": cover]
        )
    }

    // MARK: - 动漫剧集图片上传

    /// 获取剧集封面上传URL
    func getEpisodeCoverUploadUrl(animeId: Int, animeSlug: String, episodeNo: Int, filename: String, contentType: String, fileSize: Int) async throws -> EpisodeImageUploadResult {
        let request = EpisodeImageUploadRequest(animeId: animeId, animeSlug: animeSlug, episodeNo: episodeNo, filename: filename, contentType: contentType, fileSize: fileSize)
        return try await api.request(
            endpoint: APIEndpoints.Anime.episodeCoverUpload,
            method: .post,
            body: request
        )
    }

    /// 获取剧集横图上传URL
    func getEpisodeFanartUploadUrl(animeId: Int, animeSlug: String, episodeNo: Int, filename: String, contentType: String, fileSize: Int) async throws -> EpisodeImageUploadResult {
        let request = EpisodeImageUploadRequest(animeId: animeId, animeSlug: animeSlug, episodeNo: episodeNo, filename: filename, contentType: contentType, fileSize: fileSize)
        return try await api.request(
            endpoint: APIEndpoints.Anime.episodeFanartUpload,
            method: .post,
            body: request
        )
    }

    // MARK: - 文件上传到预签名URL

    /// 上传文件到预签名URL
    func uploadToPresignedUrl(_ url: String, data: Data, contentType: String) async throws {
        guard let uploadUrl = URL(string: url) else {
            throw UploadError.invalidUrl
        }

        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.httpBody = data
        // 不设置 Content-Type 以避免某些存储服务的 CORS 问题

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw UploadError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }

    /// 从NSImage读取数据
    func imageData(from image: NSImage, as type: NSBitmapImageRep.FileType = .jpeg) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: type, properties: [.compressionFactor: 0.9])
    }

    /// 从文件URL读取图片数据
    func imageData(from url: URL) -> Data? {
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }
        return imageData(from: image)
    }
}

// MARK: - 上传错误

enum UploadError: LocalizedError {
    case invalidUrl
    case invalidResponse
    case uploadFailed(statusCode: Int)
    case fileReadError
    case noFilesSelected

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "无效的上传URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .uploadFailed(let statusCode):
            return "上传失败 (状态码: \(statusCode))"
        case .fileReadError:
            return "无法读取文件"
        case .noFilesSelected:
            return "未选择文件"
        }
    }
}

// MARK: - 文件选择器辅助

extension UploadService {
    /// 打开图片选择器
    func selectImages(allowMultiple: Bool = true, maxCount: Int = 10) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowMultiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .webP, .gif]
        panel.message = allowMultiple ? "选择图片 (最多\(maxCount)张)" : "选择图片"

        guard panel.runModal() == .OK else {
            return []
        }

        let urls = Array(panel.urls.prefix(maxCount))
        return urls
    }

    /// 打开视频选择器
    func selectVideo() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .avi, .movie]
        panel.message = "选择视频文件"

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    /// 打开ZIP文件选择器
    func selectZipFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.zip]
        panel.message = "选择ZIP文件"

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    /// 打开APK/IPA文件选择器
    func selectAppPackage(platform: AppPlatform) -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        switch platform {
        case .android:
            panel.allowedContentTypes = [UTType(filenameExtension: "apk") ?? .data]
            panel.message = "选择APK文件"
        case .ios:
            panel.allowedContentTypes = [UTType(filenameExtension: "ipa") ?? .data]
            panel.message = "选择IPA文件"
        default:
            panel.allowedContentTypes = [.data]
            panel.message = "选择安装包文件"
        }

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    /// 选择 Tauri 自动更新产物（Windows 为 .nsis.zip）
    func selectUpdaterArtifact() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        // .nsis.zip 实为 zip；放开 data 以兼容各平台更新产物
        panel.allowedContentTypes = [.zip, .data]
        panel.message = "选择自动更新产物（Windows 为 .nsis.zip）"

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// 选择签名文件（.sig，文本内容即签名字符串）
    func selectSignatureFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        var types: [UTType] = [.text, .data]
        if let sig = UTType(filenameExtension: "sig") { types.insert(sig, at: 0) }
        panel.allowedContentTypes = types
        panel.message = "选择签名文件（.sig）"

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
