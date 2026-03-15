//
//  Ticket.swift
//  X-Manage
//
//  工单模型

import Foundation

// MARK: - 工单
struct Ticket: Codable, Identifiable {
    let id: Int
    let publicId: String
    let userId: Int
    let title: String
    let content: String
    let status: String
    let category: String
    let source: String?
    let replyCount: Int?
    let images: [String]?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, content, status, category, source, images
        case publicId = "public_id"
        case userId = "user_id"
        case replyCount = "reply_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 状态显示名称
    var statusDisplayName: String {
        switch status {
        case "OPEN", "TICKET_OPEN": return "待处理"
        case "PENDING", "TICKET_PENDING": return "处理中"
        case "RESOLVED", "TICKET_RESOLVED": return "已解决"
        case "CLOSED", "TICKET_CLOSED": return "已关闭"
        default: return status
        }
    }

    // 来源显示名称
    var sourceDisplayName: String {
        switch source {
        case "WEB": return "Web"
        case "MOBILE": return "移动应用"
        case "TELEGRAM": return "Telegram"
        default: return source ?? "未知"
        }
    }

    // 分类显示名称
    var categoryDisplayName: String {
        switch category {
        case "GAME": return "游戏"
        case "COMIC": return "漫画"
        case "NOVEL": return "小说"
        case "ANIME": return "动漫"
        case "ACCOUNT": return "账号"
        case "PAYMENT": return "支付"
        case "OTHER": return "其他"
        default: return category
        }
    }
}

// MARK: - 工单详情响应
struct TicketDetailResponse: Codable {
    let ticket: Ticket
}

// MARK: - 工单回复
struct TicketReply: Codable, Identifiable {
    let id: Int
    let ticketId: Int
    let userId: Int
    let content: String
    let isAdmin: Bool
    let images: [String]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, content, images
        case ticketId = "ticket_id"
        case userId = "user_id"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 工单分页
struct TicketPagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPage: Int
    let hasNext: Bool
    let hasPrev: Bool

    enum CodingKeys: String, CodingKey {
        case page, total
        case pageSize = "page_size"
        case totalPage = "total_page"
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
}

// MARK: - 工单列表响应
struct TicketListResponse: Codable {
    let schema: String?
    let tickets: [Ticket]
    let pagination: TicketPagination

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case tickets, pagination
    }
}

// MARK: - 工单回复列表响应
struct TicketReplyListResponse: Codable {
    let replies: [TicketReply]
    let total: Int
}

// MARK: - 分配工单请求
struct AssignTicketRequest: Codable {
    let assignedTo: Int

    enum CodingKeys: String, CodingKey {
        case assignedTo = "assigned_to"
    }
}

// MARK: - 创建工单回复请求
struct CreateTicketReplyRequest: Codable {
    let content: String
    let isAdmin: Bool?

    enum CodingKeys: String, CodingKey {
        case content
        case isAdmin = "is_admin"
    }
}

// MARK: - 更新工单类别请求
struct UpdateTicketCategoryRequest: Codable {
    let category: String
}

// MARK: - 更新工单状态请求
struct UpdateTicketStatusRequest: Codable {
    let status: String
}
