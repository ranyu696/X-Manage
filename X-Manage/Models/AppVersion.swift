//
//  AppVersion.swift
//  X-Manage
//
//  应用版本模型

import Foundation

// MARK: - 平台
enum AppPlatform: String, Codable, CaseIterable {
    case ios = "IOS"
    case android = "ANDROID"
    case windows = "WINDOWS"
    case macos = "MACOS"
    case linux = "LINUX"
    case harmony = "HARMONY"

    var displayName: String {
        switch self {
        case .ios: return "iOS"
        case .android: return "Android"
        case .windows: return "Windows"
        case .macos: return "macOS"
        case .linux: return "Linux"
        case .harmony: return "HarmonyOS"
        }
    }

    var iconName: String {
        switch self {
        case .ios: return "iphone"
        case .android: return "smartphone"
        case .windows: return "desktopcomputer"
        case .macos: return "laptopcomputer"
        case .linux: return "terminal"
        case .harmony: return "apps.iphone"
        }
    }
}

// MARK: - 版本状态
enum AppVersionStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case testing = "TESTING"
    case published = "PUBLISHED"
    case deprecated = "DEPRECATED"

    var displayName: String {
        switch self {
        case .draft: return "草稿"
        case .testing: return "测试中"
        case .published: return "已发布"
        case .deprecated: return "已废弃"
        }
    }

    var color: String {
        switch self {
        case .draft: return "gray"
        case .testing: return "orange"
        case .published: return "green"
        case .deprecated: return "red"
        }
    }
}

// MARK: - 更新类型
enum AppUpdateType: String, Codable, CaseIterable {
    case optional = "OPTIONAL"
    case required = "REQUIRED"

    var displayName: String {
        switch self {
        case .optional: return "可选更新"
        case .required: return "强制更新"
        }
    }
}

// MARK: - 应用版本
struct AppVersion: Codable, Identifiable {
    let id: Int
    let version: String
    let buildNumber: Int
    let platform: String
    let status: String
    let title: String
    let updateType: String

    // 可选字段
    let description: String?
    let downloadUrl: String?
    let fileSize: Int?
    let md5: String?
    let signature: String?
    let minVersion: String?
    let minOsVersion: String?

    // 时间信息
    let releaseTime: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, version, platform, status, title, description, md5, signature
        case buildNumber = "build_number"
        case downloadUrl = "download_url"
        case fileSize = "file_size"
        case minVersion = "min_version"
        case minOsVersion = "min_os_version"
        case updateType = "update_type"
        case releaseTime = "release_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 便捷属性
    var platformEnum: AppPlatform? {
        AppPlatform(rawValue: platform)
    }

    var statusEnum: AppVersionStatus? {
        AppVersionStatus(rawValue: status)
    }

    var updateTypeEnum: AppUpdateType? {
        AppUpdateType(rawValue: updateType)
    }

    var formattedFileSize: String {
        guard let size = fileSize else { return "-" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

// MARK: - 版本列表响应
struct AppVersionListResponse: Codable {
    let schema: String?
    let versions: [AppVersion]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case versions, pagination
    }
}

// MARK: - 版本详情响应
struct AppVersionDetailResponse: Codable {
    let schema: String?
    let version: AppVersion

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case version
    }
}

// MARK: - 删除响应
struct AppVersionDeleteResponse: Codable {
    let schema: String?
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case success
    }
}

// MARK: - 创建版本请求
struct CreateAppVersionRequest: Codable {
    let version: String
    let buildNumber: Int
    let platform: AppPlatform
    let title: String
    let updateType: AppUpdateType
    let description: String?
    let downloadUrl: String?
    let fileSize: Int?
    let md5: String?
    let signature: String?
    let minVersion: String?
    let minOsVersion: String?

    enum CodingKeys: String, CodingKey {
        case version, platform, title, description, md5, signature
        case buildNumber = "build_number"
        case downloadUrl = "download_url"
        case fileSize = "file_size"
        case minVersion = "min_version"
        case minOsVersion = "min_os_version"
        case updateType = "update_type"
    }
}

// MARK: - 更新版本请求
struct UpdateAppVersionRequest: Encodable {
    var title: String? = nil
    var description: String? = nil
    var downloadUrl: String? = nil
    var fileSize: Int? = nil
    var md5: String? = nil
    var signature: String? = nil
    var updateType: AppUpdateType? = nil

    enum CodingKeys: String, CodingKey {
        case title, description, md5, signature
        case downloadUrl = "download_url"
        case fileSize = "file_size"
        case updateType = "update_type"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let title = title { try container.encode(title, forKey: .title) }
        if let description = description { try container.encode(description, forKey: .description) }
        if let downloadUrl = downloadUrl { try container.encode(downloadUrl, forKey: .downloadUrl) }
        if let fileSize = fileSize { try container.encode(fileSize, forKey: .fileSize) }
        if let md5 = md5 { try container.encode(md5, forKey: .md5) }
        if let signature = signature { try container.encode(signature, forKey: .signature) }
        if let updateType = updateType { try container.encode(updateType, forKey: .updateType) }
    }
}

// MARK: - 上传URL响应
struct AppVersionUploadUrlResponse: Codable {
    let schema: String?
    let uploadUrl: String
    let downloadUrl: String
    let storagePath: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case uploadUrl = "upload_url"
        case downloadUrl = "download_url"
        case storagePath = "storage_path"
        case expiresIn = "expires_in"
    }
}

// MARK: - 确认上传请求
struct ConfirmUploadRequest: Codable {
    let downloadUrl: String
    let fileSize: Int
    let md5: String

    enum CodingKeys: String, CodingKey {
        case md5
        case downloadUrl = "download_url"
        case fileSize = "file_size"
    }
}

// MARK: - 设备
struct AppDevice: Codable, Identifiable {
    let id: Int
    let deviceId: String
    let platform: String
    let model: String?
    let osVersion: String?
    let appVersion: String?
    let buildNumber: Int?
    let channel: String?
    let pushToken: String?
    let userId: Int?
    let userName: String?
    let isOnline: Bool?
    let daysSinceCheck: Int?
    let lastCheckTime: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, platform, model, channel
        case deviceId = "device_id"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case buildNumber = "build_number"
        case pushToken = "push_token"
        case userId = "user_id"
        case userName = "user_name"
        case isOnline = "is_online"
        case daysSinceCheck = "days_since_check"
        case lastCheckTime = "last_check_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var platformEnum: AppPlatform? {
        AppPlatform(rawValue: platform)
    }
}

// MARK: - 设备列表响应
struct AppDeviceListResponse: Codable {
    let schema: String?
    let devices: [AppDevice]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case devices, pagination
    }
}

// MARK: - 更新日志
struct AppUpdateLog: Codable, Identifiable {
    let id: Int
    let versionId: Int?
    let userId: Int?
    let userName: String?
    let deviceId: String?
    let deviceModel: String?
    let platform: String?
    let fromVersion: String?
    let toVersion: String?
    let errorMessage: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, platform
        case versionId = "version_id"
        case userId = "user_id"
        case userName = "user_name"
        case deviceId = "device_id"
        case deviceModel = "device_model"
        case fromVersion = "from_version"
        case toVersion = "to_version"
        case errorMessage = "error_message"
        case createdAt = "created_at"
    }

    var platformEnum: AppPlatform? {
        guard let platform = platform else { return nil }
        return AppPlatform(rawValue: platform)
    }

    var isSuccess: Bool {
        errorMessage == nil || errorMessage?.isEmpty == true
    }
}

// MARK: - 更新日志列表响应
struct AppUpdateLogListResponse: Codable {
    let schema: String?
    let logs: [AppUpdateLog]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case logs, pagination
    }
}
