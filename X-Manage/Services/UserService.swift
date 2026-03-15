//
//  UserService.swift
//  X-Manage
//
//  用户服务

import Foundation

struct UserListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var userId: Int?
    var publicId: String?
    var role: UserRole?
    var status: UserStatus?
    var sortBy: UserSortBy?
    var sortOrder: UserSortOrder?
    var hasVip: Bool?
    var registerAfter: String?
    var registerBefore: String?
    var loginAfter: String?
    var loginBefore: String?
    var minBalance: String?
    var maxBalance: String?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let keyword = keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let publicId = publicId, !publicId.isEmpty {
            items.append(URLQueryItem(name: "public_id", value: publicId))
        }
        if let role = role {
            items.append(URLQueryItem(name: "role", value: role.rawValue))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy.rawValue))
        }
        if let sortOrder = sortOrder {
            items.append(URLQueryItem(name: "sort_order", value: sortOrder.rawValue))
        }
        if let hasVip = hasVip {
            items.append(URLQueryItem(name: "has_vip", value: "\(hasVip)"))
        }
        if let registerAfter = registerAfter {
            items.append(URLQueryItem(name: "register_after", value: registerAfter))
        }
        if let registerBefore = registerBefore {
            items.append(URLQueryItem(name: "register_before", value: registerBefore))
        }
        if let loginAfter = loginAfter {
            items.append(URLQueryItem(name: "login_after", value: loginAfter))
        }
        if let loginBefore = loginBefore {
            items.append(URLQueryItem(name: "login_before", value: loginBefore))
        }
        if let minBalance = minBalance {
            items.append(URLQueryItem(name: "min_balance", value: minBalance))
        }
        if let maxBalance = maxBalance {
            items.append(URLQueryItem(name: "max_balance", value: maxBalance))
        }
        return items
    }
}

@MainActor
class UserService {
    static let shared = UserService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: UserListParams) async throws -> UserListResponse {
        try await api.request(
            endpoint: APIEndpoints.Users.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> User {
        let response: UserDetailResponse = try await api.request(
            endpoint: APIEndpoints.Users.detail(id)
        )
        return response.user
    }

    func getStats(id: Int) async throws -> UserStats {
        let response: UserStatsResponse = try await api.request(
            endpoint: APIEndpoints.Users.stats(id)
        )
        return response.stats
    }

    func updateStatus(id: Int, status: String) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Users.detail(id),
            method: .patch,
            body: UpdateUserStatusRequest(status: status)
        )
    }

    func addBalance(id: Int, amount: String, reason: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Users.balance(id))/add",
            method: .post,
            body: BalanceOperationRequest(amount: amount, reason: reason)
        )
    }

    func deductBalance(id: Int, amount: String, reason: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Users.balance(id))/deduct",
            method: .post,
            body: BalanceOperationRequest(amount: amount, reason: reason)
        )
    }

    func upgradeVip(id: Int, role: String, expireAt: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Users.vip(id))/upgrade",
            method: .post,
            body: UpgradeVIPRequest(role: role, expireAt: expireAt)
        )
    }

    func renewVip(id: Int, durationDays: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Users.vip(id))/renew",
            method: .post,
            body: RenewVIPRequest(durationDays: durationDays)
        )
    }

    func cancelVip(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Users.vip(id),
            method: .delete
        )
    }

    func banUser(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Users.ban(id),
            method: .post
        )
    }

    func unbanUser(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Users.unban(id),
            method: .post
        )
    }
}
