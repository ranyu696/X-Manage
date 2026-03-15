//
//  Game.swift
//  X-Manage
//
//  游戏模型

import Foundation

// MARK: - 游戏
struct Game: Codable, Identifiable {
    let id: Int
    let title: String
    let name: String?
    let slug: String
    let author: String
    let status: String
    let covers: [String]
    let categoryId: Int

    // 可选字段
    let original: String?
    let region: String?
    let language: String?
    let quality: String?
    let description: String?
    let content: String?
    let types: [String]?

    // 统计信息
    let viewCount: Int?
    let likeCount: Int?
    let commentCount: Int?
    let favoriteCount: Int?
    let saleCount: Int?

    // 状态
    let isTop: Bool?
    let isTranslated: Bool?

    // 时间
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?

    // 额外信息
    let update: String?
    let updateTime: String?
    let contentImages: [String]?
    let updateImages: [String]?
    let uploaderId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, name, slug, original, author, region, language, quality
        case description, content, covers, types, status, update
        case categoryId = "category_id"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case favoriteCount = "favorite_count"
        case saleCount = "sale_count"
        case isTop = "is_top"
        case isTranslated = "is_translated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case publishedAt = "published_at"
        case updateTime = "update_time"
        case contentImages = "content_images"
        case updateImages = "update_images"
        case uploaderId = "uploader_id"
    }
}

// MARK: - 游戏列表响应
struct GameListResponse: Codable {
    let schema: String?
    let games: [Game]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case games, pagination
    }
}

// MARK: - 游戏详情响应
struct GameDetailResponse: Codable {
    let game: Game
}

// MARK: - 游戏版本状态
enum GameVersionStatus: String, Codable {
    case active = "ACTIVE"
    case outdated = "OUTDATED"
    case disabled = "DISABLED"

    var displayName: String {
        switch self {
        case .active: return "活跃"
        case .outdated: return "旧版"
        case .disabled: return "禁用"
        }
    }
}

// MARK: - 作弊码
struct CheatCode: Codable {
    let code: String
    let description: String
}

// MARK: - 游戏版本
struct GameVersion: Codable, Identifiable {
    let id: Int
    let gameId: Int
    let version: String
    let description: String?
    let size: Double?
    let pricingId: Int?
    let isLatest: Bool?
    let status: GameVersionStatus?
    let baiduUrl: String?
    let baiduPassword: String?
    let cloudUrl: String?
    let cloudPassword: String?
    let storagePath: String?
    let unzipCodes: String?
    let cheatCodes: [CheatCode]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, version, description, size, status
        case gameId = "game_id"
        case pricingId = "pricing_id"
        case isLatest = "is_latest"
        case baiduUrl = "baidu_url"
        case baiduPassword = "baidu_password"
        case cloudUrl = "cloud_url"
        case cloudPassword = "cloud_password"
        case storagePath = "storage_path"
        case unzipCodes = "unzip_codes"
        case cheatCodes = "cheat_codes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 游戏版本列表响应
struct GameVersionListResponse: Codable {
    let versions: [GameVersion]
    let pagination: PaginationMeta?
}

// MARK: - 游戏定价
struct GamePricing: Codable, Identifiable {
    let id: Int
    let gameId: Int?
    let name: String
    let price: String
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
        case gameId = "game_id"
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

// MARK: - 游戏定价列表响应
struct GamePricingListResponse: Codable {
    let pricings: [GamePricing]
    let pagination: PaginationMeta
}

// MARK: - 游戏订单
struct GameOrder: Codable, Identifiable {
    let id: Int
    let orderNo: String
    let userId: Int
    let gameId: Int
    let versionId: Int
    let versionName: String?
    let amount: String
    let originalPrice: String
    let discount: String
    let ip: String?
    let userAgent: String?
    let remarks: String?
    let userRole: String?
    let gameTitle: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, amount, discount, ip, remarks
        case orderNo = "order_no"
        case userId = "user_id"
        case gameId = "game_id"
        case versionId = "version_id"
        case versionName = "version_name"
        case originalPrice = "original_price"
        case userAgent = "user_agent"
        case userRole = "user_role"
        case gameTitle = "game_title"
        case createdAt = "created_at"
    }
}

// MARK: - 游戏订单列表响应
struct GameOrderListResponse: Codable {
    let orders: [GameOrder]
    let pagination: PaginationMeta
}

// MARK: - 游戏状态
enum GameStatus: String, CaseIterable {
    case published = "PUBLISHED"
    case pending = "PENDING"
    case unlisted = "UNLISTED"

    var displayName: String {
        switch self {
        case .published: return "已发布"
        case .pending: return "待审核"
        case .unlisted: return "已下架"
        }
    }
}

// MARK: - 游戏区域
enum GameRegion: String, CaseIterable {
    case asia = "ASIA"
    case china = "CHINA"
    case europe = "EUROPE"
    case korea = "KOREA"
    case japan = "JAPAN"

    var displayName: String {
        switch self {
        case .asia: return "亚洲"
        case .china: return "国产"
        case .europe: return "欧美"
        case .korea: return "韩国"
        case .japan: return "日系"
        }
    }
}

// MARK: - 游戏语言
enum GameLanguage: String, CaseIterable {
    case official = "OFFICIAL"
    case ai = "AI"
    case machine = "MACHINE"

    var displayName: String {
        switch self {
        case .official: return "官方翻译"
        case .ai: return "AI汉化"
        case .machine: return "机器翻译"
        }
    }
}

// MARK: - 游戏画质
enum GameQuality: String, CaseIterable {
    case anime = "ANIME"
    case pixel = "PIXEL"
    case dynamic = "DYNAMIC"
    case real = "REAL"
    case threeD = "3D"
    case twoD = "2D"

    var displayName: String {
        switch self {
        case .anime: return "动画"
        case .pixel: return "像素"
        case .dynamic: return "动态"
        case .real: return "真人"
        case .threeD: return "3D"
        case .twoD: return "2D"
        }
    }
}

// MARK: - 游戏类型
enum GameType: String, CaseIterable {
    case pc = "PC"
    case mobile = "MOBILE"
    case emulator = "EMULATOR"
    case dual = "DUAL"

    var displayName: String {
        switch self {
        case .pc: return "电脑游戏"
        case .mobile: return "手机游戏"
        case .emulator: return "模拟器游戏"
        case .dual: return "双端游戏"
        }
    }
}

// MARK: - 游戏分类
enum GameCategory: String, CaseIterable {
    case adv = "adv"
    case rpg = "rpg"
    case slg = "slg"
    case act = "act"

    var displayName: String {
        switch self {
        case .adv: return "ADV"
        case .rpg: return "RPG"
        case .slg: return "SLG"
        case .act: return "ACT"
        }
    }
}

// MARK: - YAML 创建游戏请求
struct CreateGameFromYamlRequest: Codable {
    let yaml: String
}

// MARK: - 创建游戏请求
struct CreateGameRequest: Codable {
    let title: String
    let name: String
    let original: String
    let author: String
    let region: String
    let language: String
    let quality: String
    let description: String
    let content: String
    let categoryId: Int
    let types: [String]
    let covers: [String]

    enum CodingKeys: String, CodingKey {
        case title, name, original, author, region, language
        case quality, description, content, types, covers
        case categoryId = "category_id"
    }
}

// MARK: - 更新游戏请求
struct UpdateGameRequest: Codable {
    var title: String?
    var name: String?
    var original: String?
    var author: String?
    var region: String?
    var language: String?
    var quality: String?
    var description: String?
    var content: String?
    var update: String?
    var updateTime: String?
    var categorySlug: String?
    var types: [String]?
    var isTranslated: Bool?
    var tags: String?

    enum CodingKeys: String, CodingKey {
        case title, name, original, author, region, language
        case quality, description, content, update, types, tags
        case updateTime = "update_time"
        case categorySlug = "category_slug"
        case isTranslated = "is_translated"
    }
}

// MARK: - 设置置顶请求
struct SetGameTopRequest: Codable {
    let isTop: Bool

    enum CodingKeys: String, CodingKey {
        case isTop = "is_top"
    }
}

// MARK: - 创建游戏版本请求
struct CreateGameVersionRequest: Codable {
    var version: String
    var description: String
    var size: Double
    var pricingId: Int
    var isLatest: Bool
    var baiduUrl: String
    var baiduPassword: String
    var cloudUrl: String?
    var cloudPassword: String?
    var storagePath: String?
    var unzipCodes: String
    var cheatCodes: [CheatCode]?

    enum CodingKeys: String, CodingKey {
        case version, description, size
        case pricingId = "pricing_id"
        case isLatest = "is_latest"
        case baiduUrl = "baidu_url"
        case baiduPassword = "baidu_password"
        case cloudUrl = "cloud_url"
        case cloudPassword = "cloud_password"
        case storagePath = "storage_path"
        case unzipCodes = "unzip_codes"
        case cheatCodes = "cheat_codes"
    }
}

// MARK: - 更新游戏版本请求
struct UpdateGameVersionRequest: Codable {
    var version: String?
    var description: String?
    var size: Double?
    var pricingId: Int?
    var isLatest: Bool?
    var status: String?
    var baiduUrl: String?
    var baiduPassword: String?
    var cloudUrl: String?
    var cloudPassword: String?
    var storagePath: String?
    var unzipCodes: String?
    var cheatCodes: [CheatCode]?

    enum CodingKeys: String, CodingKey {
        case version, description, size, status
        case pricingId = "pricing_id"
        case isLatest = "is_latest"
        case baiduUrl = "baidu_url"
        case baiduPassword = "baidu_password"
        case cloudUrl = "cloud_url"
        case cloudPassword = "cloud_password"
        case storagePath = "storage_path"
        case unzipCodes = "unzip_codes"
        case cheatCodes = "cheat_codes"
    }
}

// MARK: - 更新图片请求
struct UpdateImagesRequest: Codable {
    let images: [String]
}

// MARK: - 游戏版本详情响应
struct GameVersionDetailResponse: Codable {
    let version: GameVersion
}
