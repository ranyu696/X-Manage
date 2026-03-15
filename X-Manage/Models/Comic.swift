//
//  Comic.swift
//  X-Manage
//
//  漫画模型

import Foundation

// MARK: - 漫画类型
enum ComicType: String, Codable, CaseIterable {
    case bg = "BG"
    case gl = "GL"
    case bl = "BL"
    case tl = "TL"

    var displayName: String {
        return rawValue
    }
}

// MARK: - 漫画状态
enum ComicStatus: String, Codable, CaseIterable {
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
}

// MARK: - 漫画
struct Comic: Codable, Identifiable {
    let id: Int
    let title: String
    let slug: String
    let cover: String
    let authors: [String]
    let status: String
    let categoryId: Int
    let comicType: String?

    // 可选字段
    let description: String?
    let isTop: Bool?
    let is3d: Bool?
    let isColor: Bool?
    let isCompleted: Bool?

    // 统计信息
    let viewCount: Int?
    let likeCount: Int?
    let favoriteCount: Int?
    let commentCount: Int?
    let saleCount: Int?

    // 章节信息
    let chapterCount: Int?
    let lastChapterSort: Int?
    let lastChapterName: String?

    // 时间信息
    let lastUpdateAt: String?
    let publishedAt: String?
    let createdAt: String?
    let updatedAt: String?

    // 关联ID
    let uploaderId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, cover, description, authors, status
        case isTop = "is_top"
        case is3d = "is_3d"
        case isColor = "is_color"
        case comicType = "comic_type"
        case isCompleted = "is_completed"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case favoriteCount = "favorite_count"
        case commentCount = "comment_count"
        case saleCount = "sale_count"
        case chapterCount = "chapter_count"
        case lastChapterSort = "last_chapter_sort"
        case lastChapterName = "last_chapter_name"
        case lastUpdateAt = "last_update_at"
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case uploaderId = "uploader_id"
        case categoryId = "category_id"
    }
}

// MARK: - 漫画列表响应
struct ComicListResponse: Codable {
    let schema: String?
    let comics: [Comic]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case comics, pagination
    }
}

// MARK: - 漫画详情响应
struct ComicDetailResponse: Codable {
    let comic: Comic
}

// MARK: - 章节
struct Chapter: Codable, Identifiable {
    let id: Int
    let comicId: Int
    let title: String
    let sort: Int
    let pageCount: Int
    let viewCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, sort
        case comicId = "comic_id"
        case pageCount = "page_count"
        case viewCount = "view_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 章节列表响应
struct ChapterListResponse: Codable {
    let chapters: [Chapter]
    let pagination: PaginationMeta
}

// MARK: - 章节详情响应
struct ChapterDetailResponse: Codable {
    let chapter: Chapter
}

// MARK: - 更新章节请求
struct UpdateChapterRequest: Codable {
    var title: String?
    var sort: Int?
}

// MARK: - 章节页面列表响应
struct ChapterPagesResponse: Codable {
    let pages: [Page]
    let pagination: PaginationMeta?
}

// MARK: - 页面
struct Page: Codable, Identifiable {
    let id: Int
    let chapterId: Int
    let imagePath: String
    let imageUrl: String?
    let sort: Int
    let width: Int
    let height: Int
    let fileSize: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, sort, width, height
        case chapterId = "chapter_id"
        case imagePath = "image_path"
        case imageUrl = "image_url"
        case fileSize = "file_size"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// 获取显示用的图片URL
    var displayUrl: String {
        imageUrl ?? imagePath
    }
}

// MARK: - 漫画定价
struct ComicPricing: Codable, Identifiable {
    let id: Int
    let name: String
    let price: String
    let previewCount: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let svipFree: Bool
    let memberFree: Bool
    let vipFree: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, price
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

// MARK: - 漫画定价列表响应
struct ComicPricingListResponse: Codable {
    let pricings: [ComicPricing]
    let pagination: PaginationMeta
}

// MARK: - 漫画订单
struct ComicOrder: Codable, Identifiable {
    let id: Int
    let orderNo: String
    let userId: Int
    let comicId: Int
    let comicTitle: String
    let amount: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, amount
        case orderNo = "order_no"
        case userId = "user_id"
        case comicId = "comic_id"
        case comicTitle = "comic_title"
        case createdAt = "created_at"
    }
}

// MARK: - 漫画订单列表响应
struct ComicOrderListResponse: Codable {
    let orders: [ComicOrder]
    let pagination: PaginationMeta
}

// MARK: - 创建漫画请求
struct CreateComicRequest: Codable {
    let title: String
    let description: String
    let is3d: Bool
    let isColor: Bool
    let comicType: ComicType
    let authors: [String]
    let categoryId: Int
    let pricingId: Int
    let isCompleted: Bool
    let tags: String

    enum CodingKeys: String, CodingKey {
        case title, description, authors, tags
        case is3d = "is_3d"
        case isColor = "is_color"
        case comicType = "comic_type"
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case isCompleted = "is_completed"
    }
}

// MARK: - 更新漫画请求
struct UpdateComicRequest: Codable {
    var title: String?
    var description: String?
    var is3d: Bool?
    var isColor: Bool?
    var comicType: ComicType?
    var authors: [String]?
    var categoryId: Int?
    var pricingId: Int?
    var isCompleted: Bool?
    var tags: String?

    enum CodingKeys: String, CodingKey {
        case title, description, authors, tags
        case is3d = "is_3d"
        case isColor = "is_color"
        case comicType = "comic_type"
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case isCompleted = "is_completed"
    }
}
