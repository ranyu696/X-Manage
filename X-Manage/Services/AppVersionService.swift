//
//  AppVersionService.swift
//  X-Manage
//
//  应用版本服务

import Foundation

struct AppVersionListParams {
    var page: Int = 1
    var pageSize: Int = 20
    var platform: AppPlatform?
    var status: AppVersionStatus?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let platform = platform {
            items.append(URLQueryItem(name: "platform", value: platform.rawValue))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        return items
    }
}

struct AppDeviceListParams {
    var page: Int = 1
    var pageSize: Int = 20
    var platform: AppPlatform?
    var userId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let platform = platform {
            items.append(URLQueryItem(name: "platform", value: platform.rawValue))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        return items
    }
}

struct AppUpdateLogListParams {
    var page: Int = 1
    var pageSize: Int = 20
    var versionId: Int?
    var userId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let versionId = versionId {
            items.append(URLQueryItem(name: "version_id", value: "\(versionId)"))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        return items
    }
}

@MainActor
class AppVersionService {
    static let shared = AppVersionService()
    private let api = APIClient.shared

    private init() {}

    // MARK: - 获取版本列表
    func getList(params: AppVersionListParams) async throws -> AppVersionListResponse {
        try await api.request(
            endpoint: APIEndpoints.AppVersions.list,
            queryItems: params.queryItems
        )
    }

    // MARK: - 获取版本详情
    func getDetail(id: Int) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.detail(id)
        )
        return response.version
    }

    // MARK: - 创建版本
    func create(request: CreateAppVersionRequest) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.list,
            method: .post,
            body: request
        )
        return response.version
    }

    // MARK: - 更新版本
    func update(id: Int, request: UpdateAppVersionRequest) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.detail(id),
            method: .put,
            body: request
        )
        return response.version
    }

    // MARK: - 删除版本
    func delete(id: Int) async throws {
        let _: AppVersionDeleteResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.detail(id),
            method: .delete
        )
    }

    // MARK: - 发布版本
    func publish(id: Int) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.publish(id),
            method: .post
        )
        return response.version
    }

    // MARK: - 废弃版本
    func deprecate(id: Int) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.deprecate(id),
            method: .post
        )
        return response.version
    }

    // MARK: - 获取设备列表
    func getDevices(params: AppDeviceListParams) async throws -> AppDeviceListResponse {
        try await api.request(
            endpoint: APIEndpoints.AppVersions.devices,
            queryItems: params.queryItems
        )
    }

    // MARK: - 获取更新日志
    func getUpdateLogs(params: AppUpdateLogListParams) async throws -> AppUpdateLogListResponse {
        try await api.request(
            endpoint: APIEndpoints.AppVersions.updateLogs,
            queryItems: params.queryItems
        )
    }

    // MARK: - 获取上传URL
    func getUploadUrl(versionId: Int, fileName: String, contentType: String, fileSize: Int) async throws -> AppVersionUploadUrlResponse {
        let queryItems = [
            URLQueryItem(name: "file_name", value: fileName),
            URLQueryItem(name: "content_type", value: contentType),
            URLQueryItem(name: "file_size", value: "\(fileSize)")
        ]
        return try await api.request(
            endpoint: APIEndpoints.AppVersions.uploadUrl(versionId),
            queryItems: queryItems
        )
    }

    // MARK: - 确认上传
    func confirmUpload(versionId: Int, request: ConfirmUploadRequest) async throws -> AppVersion {
        let response: AppVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.AppVersions.confirmUpload(versionId),
            method: .post,
            body: request
        )
        return response.version
    }
}
