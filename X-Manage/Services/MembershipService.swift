//
//  MembershipService.swift
//  X-Manage
//
//  会员（订阅权益）服务

import Foundation

// MARK: - 会员列表查询参数
struct MembershipListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var sortBy: String = "current_period_end"
    var sortOrder: String = "desc"
    var userId: Int?
    var tier: MembershipTier?
    var status: MembershipStatus?
    var source: MembershipSource?
    var expireAfter: String?
    var expireBefore: String?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "sort_order", value: sortOrder)
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let tier = tier {
            items.append(URLQueryItem(name: "tier", value: tier.rawValue))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let source = source {
            items.append(URLQueryItem(name: "source", value: source.rawValue))
        }
        if let expireAfter = expireAfter, !expireAfter.isEmpty {
            items.append(URLQueryItem(name: "expire_after", value: expireAfter))
        }
        if let expireBefore = expireBefore, !expireBefore.isEmpty {
            items.append(URLQueryItem(name: "expire_before", value: expireBefore))
        }
        return items
    }
}

@MainActor
class MembershipService {
    static let shared = MembershipService()
    private let api = APIClient.shared

    private init() {}

    /// 分页查询会员列表
    func getList(params: MembershipListParams) async throws -> MembershipListResponse {
        try await api.request(
            endpoint: APIEndpoints.Memberships.list,
            queryItems: params.queryItems
        )
    }

    /// 查询单个用户的当前会员（不存在时 found=false）
    func getMembership(userId: Int) async throws -> MembershipDetailResponse {
        try await api.request(
            endpoint: APIEndpoints.Users.membership(userId)
        )
    }

    /// 分页查询某用户的会员审计事件
    func getEvents(userId: Int, page: Int = 1, pageSize: Int = 25) async throws -> MembershipEventListResponse {
        try await api.request(
            endpoint: APIEndpoints.Users.membershipEvents(userId),
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }
}
