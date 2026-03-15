//
//  Common.swift
//  X-Manage
//
//  通用类型定义

import Foundation

// MARK: - 分页元数据
struct PaginationMeta: Codable {
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let hasNext: Bool?
    let hasPrevious: Bool?

    enum CodingKeys: String, CodingKey {
        case total
        case page
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case totalPage = "total_page"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
        case hasPrev = "has_prev"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        page = try container.decode(Int.self, forKey: .page)
        pageSize = try container.decode(Int.self, forKey: .pageSize)

        // Handle both total_pages and total_page
        if let pages = try? container.decode(Int.self, forKey: .totalPages) {
            totalPages = pages
        } else {
            totalPages = try container.decode(Int.self, forKey: .totalPage)
        }

        // Handle both has_next
        hasNext = try? container.decode(Bool.self, forKey: .hasNext)

        // Handle both has_previous and has_prev
        if let prev = try? container.decode(Bool.self, forKey: .hasPrevious) {
            hasPrevious = prev
        } else {
            hasPrevious = try? container.decode(Bool.self, forKey: .hasPrev)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(total, forKey: .total)
        try container.encode(page, forKey: .page)
        try container.encode(pageSize, forKey: .pageSize)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encodeIfPresent(hasNext, forKey: .hasNext)
        try container.encodeIfPresent(hasPrevious, forKey: .hasPrevious)
    }
}

// MARK: - 分页参数
struct PaginationParams {
    var page: Int = 1
    var pageSize: Int = 25

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
    }
}

// MARK: - 排序方向
enum SortOrder: String, Codable {
    case asc = "asc"
    case desc = "desc"
}

// MARK: - 通用状态
enum ContentStatus: String, Codable, CaseIterable {
    case published = "PUBLISHED"
    case unlisted = "UNLISTED"
    case pending = "PENDING"

    var displayName: String {
        switch self {
        case .published: return "已发布"
        case .unlisted: return "已下架"
        case .pending: return "审核中"
        }
    }

    var color: String {
        switch self {
        case .published: return "green"
        case .unlisted: return "red"
        case .pending: return "orange"
        }
    }
}

// MARK: - 成功响应
struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - 简单消息响应
struct MessageResponse: Codable {
    let message: String
}
