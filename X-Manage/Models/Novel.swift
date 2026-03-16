//
//  Novel.swift
//  X-Manage
//
//  小说模型

import Foundation

// MARK: - 小说状态
enum NovelStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case published = "PUBLISHED"
    case unlisted = "UNLISTED"

    var displayName: String {
        switch self {
        case .pending: return "审核中"
        case .published: return "已发布"
        case .unlisted: return "已下架"
        }
    }
}

// MARK: - 小说
struct Novel: Codable, Identifiable {
    let id: Int
    let title: String
    let slug: String
    let author: String
    let series: String?
    let cover: String
    let categoryId: Int
    let pricingId: Int?
    let tags: [String]?

    // 章节信息
    let chapterCount: Int?
    let wordCount: Int?
    let lastChapterTitle: String?
    let lastChapterUpdatedAt: String?

    // 统计信息
    let viewCount: Int?
    let likeCount: Int?
    let commentCount: Int?
    let favoriteCount: Int?

    // 状态
    let status: String
    let isCompleted: Bool?
    let isTop: Bool?

    // 时间
    let createdAt: String?
    let updatedAt: String?

    // 详情
    let description: String?
    let content: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, author, series, cover, tags, status, description, content
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case chapterCount = "chapter_count"
        case wordCount = "word_count"
        case lastChapterTitle = "last_chapter_title"
        case lastChapterUpdatedAt = "last_chapter_updated_at"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case favoriteCount = "favorite_count"
        case isCompleted = "is_completed"
        case isTop = "is_top"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 状态显示名称
    var statusDisplayName: String {
        switch status {
        case "PENDING": return "审核中"
        case "PUBLISHED": return "已发布"
        case "UNLISTED": return "已下架"
        default: return status
        }
    }
}

// MARK: - 小说列表响应
struct NovelListResponse: Codable {
    let schema: String?
    let novels: [Novel]
    let pagination: NovelPagination

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case novels, pagination
    }
}

struct NovelPagination: Codable {
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

// MARK: - 小说章节
struct NovelChapter: Codable, Identifiable, Hashable {
    let id: Int
    let novelId: Int
    let title: String
    let sort: Int
    let wordCount: Int
    let contentPath: String?
    let content: String?  // 仅在获取详情时返回
    let viewCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, sort, content
        case novelId = "novel_id"
        case wordCount = "word_count"
        case contentPath = "content_path"
        case viewCount = "view_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 小说章节列表响应
struct NovelChapterListResponse: Codable {
    let chapters: [NovelChapter]
    let pagination: NovelPagination
}

// MARK: - 小说定价
struct NovelPricing: Codable, Identifiable {
    let id: Int
    let novelId: Int?
    let name: String
    let price: String
    let previewCount: Int?
    let memberDiscount: String?
    let vipDiscount: String?
    let svipDiscount: String?
    let svipFree: Bool
    let memberFree: Bool
    let vipFree: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, price
        case novelId = "novel_id"
        case previewCount = "preview_count"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case svipFree = "svip_free"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 小说定价列表响应
struct NovelPricingListResponse: Codable {
    let pricings: [NovelPricing]
    let pagination: NovelPagination
}

// MARK: - 小说定价请求
struct CreateNovelPricingRequest: Encodable {
    let name: String
    let price: String
    let previewCount: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let memberFree: Bool
    let vipFree: Bool
    let svipFree: Bool

    enum CodingKeys: String, CodingKey {
        case name, price
        case previewCount = "preview_count"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case svipFree = "svip_free"
    }
}

struct UpdateNovelPricingRequest: Encodable {
    let name: String
    let price: String
    let previewCount: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let memberFree: Bool
    let vipFree: Bool
    let svipFree: Bool

    enum CodingKeys: String, CodingKey {
        case name, price
        case previewCount = "preview_count"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case svipFree = "svip_free"
    }
}

struct NovelPricingResponse: Codable {
    let pricing: NovelPricing
}

// MARK: - 小说订单
struct NovelOrder: Codable, Identifiable {
    let id: Int
    let orderNo: String
    let userId: Int
    let novelId: Int
    let novelTitle: String
    let amount: String
    let originalPrice: String?
    let discount: String?
    let paymentMethod: String?
    let paymentStatus: String?
    let userRole: String?
    let ip: String?
    let userAgent: String?
    let remarks: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, discount, ip, remarks
        case orderNo = "order_no"
        case userId = "user_id"
        case novelId = "novel_id"
        case novelTitle = "novel_title"
        case originalPrice = "original_price"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case userRole = "user_role"
        case userAgent = "user_agent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 小说订单列表响应
struct NovelOrderListResponse: Codable {
    let orders: [NovelOrder]
    let pagination: PaginationMeta
}

// MARK: - 创建小说请求
struct CreateNovelRequest: Codable {
    let title: String
    let description: String
    let author: String
    let series: String?
    let tags: String?
    let categoryId: Int
    let pricingId: Int

    enum CodingKeys: String, CodingKey {
        case title, description, author, series, tags
        case categoryId = "category_id"
        case pricingId = "pricing_id"
    }
}

// MARK: - 更新小说请求
struct UpdateNovelRequest: Codable {
    var title: String?
    var description: String?
    var author: String?
    var series: String?
    var tags: String?
    var categoryId: Int?
    var pricingId: Int?
    var isCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case title, description, author, series, tags
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case isCompleted = "is_completed"
    }
}
