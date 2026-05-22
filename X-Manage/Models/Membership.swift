//
//  Membership.swift
//  X-Manage
//
//  会员（订阅权益）模型 —— 对应后端 memberships / membership_events 两表

import Foundation
import SwiftUI

// MARK: - 会员等级
enum MembershipTier: String, Codable, CaseIterable {
    case vip
    case svip

    var displayName: String {
        switch self {
        case .vip: return "VIP"
        case .svip: return "SVIP"
        }
    }

    var color: Color {
        switch self {
        case .vip: return .orange
        case .svip: return .purple
        }
    }
}

// MARK: - 会员状态
enum MembershipStatus: String, Codable, CaseIterable {
    case active
    case grace
    case expired
    case canceled

    var displayName: String {
        switch self {
        case .active: return "有效"
        case .grace: return "宽限期"
        case .expired: return "已过期"
        case .canceled: return "已取消"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .grace: return .orange
        case .expired: return .secondary
        case .canceled: return .red
        }
    }
}

// MARK: - 会员来源
enum MembershipSource: String, Codable, CaseIterable {
    case purchase
    case admin
    case gift
    case compensation
    case backfill

    var displayName: String {
        switch self {
        case .purchase: return "付费购买"
        case .admin: return "管理员发放"
        case .gift: return "赠送"
        case .compensation: return "补偿"
        case .backfill: return "历史回填"
        }
    }
}

// MARK: - 会员事件类型
enum MembershipEventType: String, Codable {
    case grant
    case renew
    case upgrade
    case reactivate
    case enterGrace = "enter_grace"
    case expire
    case cancel
    case backfill

    var displayName: String {
        switch self {
        case .grant: return "首次开通"
        case .renew: return "续费"
        case .upgrade: return "升级"
        case .reactivate: return "重新开通"
        case .enterGrace: return "进入宽限期"
        case .expire: return "彻底过期"
        case .cancel: return "取消/退款"
        case .backfill: return "历史回填"
        }
    }

    var color: Color {
        switch self {
        case .grant, .renew, .reactivate: return .green
        case .upgrade: return .blue
        case .enterGrace: return .orange
        case .expire, .cancel: return .red
        case .backfill: return .secondary
        }
    }
}

// MARK: - 会员实体
struct Membership: Codable, Identifiable {
    let id: Int
    let userId: Int
    let tier: String
    let status: String
    let startedAt: String
    let currentPeriodEnd: String
    let graceUntil: String?
    let source: String
    let lastOrderId: String?
    let autoRenew: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier, status, source
        case startedAt = "started_at"
        case currentPeriodEnd = "current_period_end"
        case graceUntil = "grace_until"
        case lastOrderId = "last_order_id"
        case autoRenew = "auto_renew"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var tierEnum: MembershipTier? { MembershipTier(rawValue: tier) }
    var statusEnum: MembershipStatus? { MembershipStatus(rawValue: status) }
    var sourceEnum: MembershipSource? { MembershipSource(rawValue: source) }

    var tierDisplay: String { tierEnum?.displayName ?? tier.uppercased() }
    var statusDisplay: String { statusEnum?.displayName ?? status }
    var sourceDisplay: String { sourceEnum?.displayName ?? source }
}

// MARK: - 会员事件
struct MembershipEvent: Codable, Identifiable {
    let id: Int
    let userId: Int
    let membershipId: Int
    let eventType: String
    let tierBefore: String?
    let tierAfter: String?
    let periodEndBefore: String?
    let periodEndAfter: String?
    let source: String?
    let operatorName: String?
    let orderId: String?
    let reason: String?
    let metadata: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case membershipId = "membership_id"
        case eventType = "event_type"
        case tierBefore = "tier_before"
        case tierAfter = "tier_after"
        case periodEndBefore = "period_end_before"
        case periodEndAfter = "period_end_after"
        case source
        case operatorName = "operator"
        case orderId = "order_id"
        case reason, metadata
        case createdAt = "created_at"
    }

    var eventTypeEnum: MembershipEventType? { MembershipEventType(rawValue: eventType) }
    var eventTypeDisplay: String { eventTypeEnum?.displayName ?? eventType }
}

// MARK: - 响应
struct MembershipListResponse: Codable {
    let memberships: [Membership]
    let pagination: PaginationMeta
}

struct MembershipDetailResponse: Codable {
    let found: Bool
    let membership: Membership?
}

struct MembershipEventListResponse: Codable {
    let events: [MembershipEvent]
    let pagination: PaginationMeta
}
