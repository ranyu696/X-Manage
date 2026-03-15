//
//  User.swift
//  X-Manage
//
//  用户模型

import Foundation

// MARK: - 用户角色
enum UserRole: String, Codable, CaseIterable {
    case member = "MEMBER"
    case vip = "VIP"
    case svip = "SVIP"
    case admin = "ADMIN"
    case superAdmin = "SUPER_ADMIN"

    var displayName: String {
        switch self {
        case .member: return "普通会员"
        case .vip: return "VIP"
        case .svip: return "SVIP"
        case .admin: return "管理员"
        case .superAdmin: return "超级管理员"
        }
    }
}

// MARK: - 用户状态
enum UserStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case banned = "BANNED"
    case deleted = "DELETED"
    case pendingVerification = "PENDING_VERIFICATION"

    var displayName: String {
        switch self {
        case .active: return "正常"
        case .banned: return "已封禁"
        case .deleted: return "已删除"
        case .pendingVerification: return "待验证"
        }
    }
}

// MARK: - 用户
struct User: Codable, Identifiable {
    let id: Int
    let publicId: String
    let username: String
    let email: String?
    let role: String
    let status: String
    let balance: String?
    let avatar: String?

    // VIP 相关字段
    let isVip: Bool?
    let vipExpireAt: String?
    let vipStartAt: String?

    // 可选字段
    let emailVerified: Bool?
    let lastLoginAt: String?
    let lastLoginIp: String?
    let lastLoginUserAgent: String?
    let registerIp: String?
    let registerUserAgent: String?
    let telegramId: String?
    let expoPushToken: String?
    let gamePush: Bool?
    let comicPush: Bool?
    let novelPush: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email, role, status, balance, avatar
        case publicId = "public_id"
        case isVip = "is_vip"
        case vipExpireAt = "vip_expire_at"
        case vipStartAt = "vip_start_at"
        case emailVerified = "email_verified"
        case lastLoginAt = "last_login_at"
        case lastLoginIp = "last_login_ip"
        case lastLoginUserAgent = "last_login_user_agent"
        case registerIp = "register_ip"
        case registerUserAgent = "register_user_agent"
        case telegramId = "telegram_id"
        case expoPushToken = "expo_push_token"
        case gamePush = "game_push"
        case comicPush = "comic_push"
        case novelPush = "novel_push"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 角色显示名称
    var roleDisplayName: String {
        switch role {
        case "MEMBER": return "普通会员"
        case "VIP": return "VIP"
        case "SVIP": return "SVIP"
        case "ADMIN": return "管理员"
        case "SUPER_ADMIN": return "超级管理员"
        default: return role
        }
    }

    // 状态显示名称
    var statusDisplayName: String {
        switch status {
        case "ACTIVE": return "正常"
        case "BANNED": return "已封禁"
        case "DELETED": return "已删除"
        case "PENDING_VERIFICATION": return "待验证"
        default: return status
        }
    }

    // 是否已封禁
    var isBanned: Bool {
        status == "BANNED"
    }

    // 是否为 VIP 角色
    var isVipRole: Bool {
        role == "VIP" || role == "SVIP"
    }
}

// MARK: - 用户详情响应
struct UserDetailResponse: Codable {
    let user: User
}

// MARK: - 用户列表响应
struct UserListResponse: Codable {
    let schema: String?
    let users: [User]
    let pagination: PaginationMeta
    let filters: UserFilters?

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case users, pagination, filters
    }
}

struct UserFilters: Codable {
    let keyword: String?
    let status: [String]?
    let role: [String]?
    let totalFound: Int?

    enum CodingKeys: String, CodingKey {
        case keyword, status, role
        case totalFound = "total_found"
    }
}

// MARK: - 用户统计
struct UserStatistics: Codable {
    let totalUsers: Int
    let activeUsers: Int
    let vipUsers: Int
    let svipUsers: Int
    let todayRegistrations: Int
    let todayLogins: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case activeUsers = "active_users"
        case vipUsers = "vip_users"
        case svipUsers = "svip_users"
        case todayRegistrations = "today_registrations"
        case todayLogins = "today_logins"
    }
}

// MARK: - 单个用户统计
struct UserStats: Codable {
    let totalComics: Int
    let totalComments: Int
    let totalFavorites: Int
    let totalGames: Int
    let totalNovels: Int
    let totalOrders: Int
    let totalSpent: Double

    enum CodingKeys: String, CodingKey {
        case totalComics = "total_comics"
        case totalComments = "total_comments"
        case totalFavorites = "total_favorites"
        case totalGames = "total_games"
        case totalNovels = "total_novels"
        case totalOrders = "total_orders"
        case totalSpent = "total_spent"
    }
}

struct UserStatsResponse: Codable {
    let stats: UserStats
}

// MARK: - 余额操作请求
struct BalanceOperationRequest: Codable {
    let amount: String
    let reason: String
}

// MARK: - VIP 操作请求
struct UpgradeVIPRequest: Codable {
    let role: String
    let expireAt: String

    enum CodingKeys: String, CodingKey {
        case role
        case expireAt = "expire_at"
    }
}

struct RenewVIPRequest: Codable {
    let durationDays: Int

    enum CodingKeys: String, CodingKey {
        case durationDays = "duration_days"
    }
}

// MARK: - 用户状态更新请求
struct UpdateUserStatusRequest: Codable {
    let status: String
}

// MARK: - 用户排序
enum UserSortBy: String, Codable, CaseIterable {
    case createdAt = "CREATED_AT"
    case updatedAt = "UPDATED_AT"
    case id = "ID"
    case username = "USERNAME"
    case lastLoginAt = "LAST_LOGIN_AT"
    case balance = "BALANCE"
}

enum UserSortOrder: String, Codable {
    case asc = "ASC"
    case desc = "DESC"
}
