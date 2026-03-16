//
//  Anime.swift
//  X-Manage
//
//  动漫模型

import Foundation

// MARK: - 动漫状态
enum AnimeStatus: String, Codable, CaseIterable {
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

// MARK: - 剧集状态
enum EpisodeStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending: return "等待上传"
        case .processing: return "转码中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }
}

// MARK: - 动漫分类
struct AnimeCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - 动漫标签
struct AnimeTag: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - 动漫列表项
struct Anime: Codable, Identifiable {
    let id: Int
    let title: String
    let slug: String
    let cover: String
    let fanart: String?
    let studio: String?
    let status: String
    let isTop: Bool?
    let isCompleted: Bool?
    let episodeCount: Int?
    let currentEpisode: Int?
    let categoryId: Int

    // 统计信息
    let viewCount: Int?
    let likeCount: Int?
    let favoriteCount: Int?
    let commentCount: Int?

    // 时间
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, cover, fanart, studio, status
        case isTop = "is_top"
        case isCompleted = "is_completed"
        case episodeCount = "episode_count"
        case currentEpisode = "current_episode"
        case categoryId = "category_id"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case favoriteCount = "favorite_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 动漫详情
struct AnimeDetail: Codable, Identifiable {
    let id: Int
    let title: String
    let titleOriginal: String?
    let slug: String
    let cover: String
    let description: String?
    let codes: [String]?
    let studio: String?
    let status: String
    let isTop: Bool?
    let isCompleted: Bool?
    let episodeCount: Int?
    let currentEpisode: Int?
    let episodeDuration: Int?
    let totalEpisodes: Int?
    let season: Int?
    let airDate: String?
    let endDate: String?
    let region: String?
    let quality: String?
    let productionStatus: String?
    let categoryId: Int
    let pricingId: Int?
    let fanart: String?

    // 统计信息
    let viewCount: Int?
    let likeCount: Int?
    let favoriteCount: Int?
    let commentCount: Int?

    // 关联
    let category: AnimeCategory?
    let tags: [AnimeTag]?

    // 时间
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, cover, description, codes, studio, status
        case category, tags, region, quality, fanart
        case titleOriginal = "title_original"
        case isTop = "is_top"
        case isCompleted = "is_completed"
        case episodeCount = "episode_count"
        case currentEpisode = "current_episode"
        case episodeDuration = "episode_duration"
        case totalEpisodes = "total_episodes"
        case season
        case airDate = "air_date"
        case endDate = "end_date"
        case productionStatus = "production_status"
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case favoriteCount = "favorite_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 动漫列表响应
struct AnimeListResponse: Codable {
    let schema: String?
    let animes: [Anime]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case animes, pagination
    }
}

// MARK: - 动漫详情响应
struct AnimeDetailResponse: Codable {
    let anime: AnimeDetail
}

// MARK: - 剧集
struct Episode: Codable, Identifiable, Hashable {
    let id: Int
    let animeId: Int
    let episodeNo: Int?
    let title: String
    let cover: String?
    let fanart: String?
    let previewVideo: String?
    let screenshots: [String]?
    let duration: Int?
    let status: String?
    let isActive: Bool?
    let viewCount: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, cover, fanart, screenshots, duration, status
        case animeId = "anime_id"
        case episodeNo = "episode_no"
        case previewVideo = "preview_video"
        case isActive = "is_active"
        case viewCount = "view_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 剧集列表响应
struct EpisodeListResponse: Codable {
    let schema: String?
    let episodes: [Episode]
    let pagination: PaginationMeta?

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case episodes, pagination
    }
}

// MARK: - 视频加密信息
struct EpisodeEncryption: Codable {
    let keyId: String
    let key: String

    enum CodingKeys: String, CodingKey {
        case keyId = "key_id"
        case key
    }
}

// MARK: - 剧集详情（包含视频播放信息）
struct EpisodeDetail: Codable, Identifiable {
    let id: Int
    let animeId: Int
    let episodeNo: Int?
    let title: String
    let description: String?
    // 图片
    let cover: String?
    let fanart: String?
    let screenshots: [String]?
    // 视频
    let previewVideo: String?
    let manifestUrl: String?
    let duration: Int?
    let status: String?
    let isActive: Bool?
    let viewCount: Int?
    // 视频技术信息
    let storagePath: String?
    let disguiseKey: String?
    let qualities: String?
    let width: Int?
    let height: Int?
    let bitrate: Int?
    let frameRate: Double?
    let spriteSheet: String?
    let spriteCount: Int?
    let spriteInterval: Int?
    // 加密信息
    let encryption: EpisodeEncryption?
    // 时间
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, cover, fanart, screenshots, duration, status, qualities
        case animeId = "anime_id"
        case episodeNo = "episode_no"
        case previewVideo = "preview_video"
        case manifestUrl = "manifest_url"
        case isActive = "is_active"
        case viewCount = "view_count"
        case storagePath = "storage_path"
        case disguiseKey = "disguise_key"
        case width, height, bitrate
        case frameRate = "frame_rate"
        case spriteSheet = "sprite_sheet"
        case spriteCount = "sprite_count"
        case spriteInterval = "sprite_interval"
        case encryption
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 剧集详情响应
struct EpisodeDetailResponse: Codable {
    let episode: EpisodeDetail
}

// MARK: - 动漫定价
struct AnimePricing: Codable, Identifiable {
    let id: Int
    let name: String
    let price: String
    let previewSeconds: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let memberFree: Bool
    let vipFree: Bool
    let svipFree: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, price
        case previewSeconds = "preview_seconds"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case svipFree = "svip_free"
        case createdAt = "created_at"
    }
}

// MARK: - 动漫定价列表响应
struct AnimePricingListResponse: Codable {
    let pricings: [AnimePricing]
    let pagination: PaginationMeta
}

// MARK: - 动漫定价请求
struct CreateAnimePricingRequest: Encodable {
    let name: String
    let price: String
    let previewSeconds: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let memberFree: Bool
    let vipFree: Bool
    let svipFree: Bool

    enum CodingKeys: String, CodingKey {
        case name, price
        case previewSeconds = "preview_seconds"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case svipFree = "svip_free"
    }
}

struct UpdateAnimePricingRequest: Encodable {
    let name: String
    let price: String
    let previewSeconds: Int
    let memberDiscount: String
    let vipDiscount: String
    let svipDiscount: String
    let memberFree: Bool
    let vipFree: Bool
    let svipFree: Bool

    enum CodingKeys: String, CodingKey {
        case name, price
        case previewSeconds = "preview_seconds"
        case memberDiscount = "member_discount"
        case vipDiscount = "vip_discount"
        case svipDiscount = "svip_discount"
        case memberFree = "member_free"
        case vipFree = "vip_free"
        case svipFree = "svip_free"
    }
}

struct AnimePricingResponse: Codable {
    let pricing: AnimePricing
}

// MARK: - 动漫订单
struct AnimeOrder: Codable, Identifiable {
    let id: Int
    let orderNo: String
    let userId: Int
    let animeId: Int
    let animeTitle: String
    let amount: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, amount
        case orderNo = "order_no"
        case userId = "user_id"
        case animeId = "anime_id"
        case animeTitle = "anime_title"
        case createdAt = "created_at"
    }
}

// MARK: - 动漫订单列表响应
struct AnimeOrderListResponse: Codable {
    let orders: [AnimeOrder]
    let pagination: PaginationMeta
}

// MARK: - 创建动漫请求
struct CreateAnimeRequest: Codable {
    let title: String
    let titleOriginal: String?
    let cover: String?
    let description: String
    let codes: [String]?
    let studio: String
    let categoryId: Int
    let pricingId: Int
    let totalEpisodes: Int
    let season: Int?
    let airDate: String?
    let endDate: String?
    let region: String?
    let quality: String?
    let productionStatus: String?
    let tags: String?

    enum CodingKeys: String, CodingKey {
        case title, cover, description, codes, studio, season, region, quality, tags
        case titleOriginal = "title_original"
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case totalEpisodes = "total_episodes"
        case airDate = "air_date"
        case endDate = "end_date"
        case productionStatus = "production_status"
    }
}

// MARK: - 更新动漫请求
struct UpdateAnimeRequest: Codable {
    var title: String?
    var titleOriginal: String?
    var description: String?
    var codes: [String]?
    var studio: String?
    var categoryId: Int?
    var pricingId: Int?
    var totalEpisodes: Int?
    var season: Int?
    var airDate: String?
    var endDate: String?
    var region: String?
    var quality: String?
    var productionStatus: String?
    var tags: String?

    enum CodingKeys: String, CodingKey {
        case title, description, codes, studio, season, region, quality, tags
        case titleOriginal = "title_original"
        case categoryId = "category_id"
        case pricingId = "pricing_id"
        case totalEpisodes = "total_episodes"
        case airDate = "air_date"
        case endDate = "end_date"
        case productionStatus = "production_status"
    }
}

// MARK: - 创建剧集请求
struct CreateEpisodeRequest: Codable {
    let title: String
    let episodeNo: Int

    enum CodingKeys: String, CodingKey {
        case title
        case episodeNo = "episode_no"
    }
}

// MARK: - 更新剧集请求
struct UpdateEpisodeRequest: Codable {
    var title: String?
    var episodeNo: Int?
    var cover: String?
    var fanart: String?

    enum CodingKeys: String, CodingKey {
        case title
        case episodeNo = "episode_no"
        case cover
        case fanart
    }
}
