//
//  Comment.swift
//  X-Manage
//
//  评论模型

import Foundation

// MARK: - 评论状态
enum CommentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending: return "待审核"
        case .approved: return "已通过"
        case .rejected: return "已拒绝"
        }
    }
}

// MARK: - 漫画评论
struct ComicComment: Codable, Identifiable {
    let id: Int
    let comicId: Int
    let comicTitle: String?
    let userId: Int
    let username: String?
    let avatar: String?
    let userRole: String?
    let content: String
    let status: String
    let isTop: Bool?
    let likeCount: Int?
    let replyCount: Int?
    let parentId: Int?
    let replyToId: Int?
    let replyToUsername: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, content, status, avatar, username
        case comicId = "comic_id"
        case comicTitle = "comic_title"
        case userId = "user_id"
        case userRole = "user_role"
        case isTop = "is_top"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case parentId = "parent_id"
        case replyToId = "reply_to_id"
        case replyToUsername = "reply_to_username"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 漫画评论列表响应
struct ComicCommentListResponse: Codable {
    let comments: [ComicComment]
    let pagination: PaginationMeta
}

// MARK: - 游戏评论用户
struct GameCommentUser: Codable {
    let id: Int
    let username: String
    let avatar: String?
    let role: String?
}

// MARK: - 游戏评论关联游戏
struct GameCommentGame: Codable {
    let id: Int
    let name: String
    let slug: String
    let covers: [String]?
}

// MARK: - 游戏评论回复目标
struct GameCommentReplyTo: Codable {
    let id: Int
    let content: String
    let createdAt: String
    let user: GameCommentUser?

    enum CodingKeys: String, CodingKey {
        case id, content, user
        case createdAt = "created_at"
    }
}

// MARK: - 游戏评论
struct GameComment: Codable, Identifiable {
    let id: Int
    let gameId: Int
    let userId: Int
    let content: String
    let status: String
    let isTop: Bool?
    let likeCount: Int?
    let replyCount: Int?
    let parentId: Int?
    let createdAt: String
    let updatedAt: String?
    let user: GameCommentUser?
    let game: GameCommentGame?
    let replyTo: GameCommentReplyTo?

    enum CodingKeys: String, CodingKey {
        case id, content, status, user, game
        case gameId = "game_id"
        case userId = "user_id"
        case isTop = "is_top"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case parentId = "parent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case replyTo = "reply_to"
    }

    // 便捷属性，兼容旧代码
    var username: String? { user?.username }
    var avatar: String? { user?.avatar }
    var userRole: String? { user?.role }
    var gameTitle: String? { game?.name }
}

// MARK: - 游戏评论列表响应
struct GameCommentListResponse: Codable {
    let comments: [GameComment]
    let pagination: PaginationMeta
}

// MARK: - 小说评论
struct NovelComment: Codable, Identifiable {
    let id: Int
    let novelId: Int
    let novelTitle: String?
    let chapterId: Int?
    let userId: Int
    let username: String?
    let avatar: String?
    let userRole: String?
    let content: String
    let status: String
    let isTop: Bool?
    let likeCount: Int?
    let replyCount: Int?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, content, status, avatar, username
        case novelId = "novel_id"
        case novelTitle = "novel_title"
        case chapterId = "chapter_id"
        case userId = "user_id"
        case userRole = "user_role"
        case isTop = "is_top"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 小说评论列表响应
struct NovelCommentListResponse: Codable {
    let comments: [NovelComment]
    let pagination: PaginationMeta
}

// MARK: - 动漫评论
struct AnimeComment: Codable, Identifiable {
    let id: Int
    let animeId: Int
    let animeTitle: String?
    let episodeId: Int?
    let userId: Int
    let username: String?
    let avatar: String?
    let userRole: String?
    let content: String
    let status: String
    let isTop: Bool?
    let likeCount: Int?
    let replyCount: Int?
    let parentId: Int?
    let replyToId: Int?
    let replyToUsername: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, content, status, avatar, username
        case animeId = "anime_id"
        case animeTitle = "anime_title"
        case episodeId = "episode_id"
        case userId = "user_id"
        case userRole = "user_role"
        case isTop = "is_top"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case parentId = "parent_id"
        case replyToId = "reply_to_id"
        case replyToUsername = "reply_to_username"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 动漫评论列表响应
struct AnimeCommentListResponse: Codable {
    let comments: [AnimeComment]
    let pagination: PaginationMeta
}

// MARK: - 单个动漫评论响应
struct AnimeCommentResponse: Codable {
    let comment: AnimeComment
}

// MARK: - 批量操作评论请求
struct BatchCommentIdsRequest: Codable {
    let commentIds: [Int]

    enum CodingKeys: String, CodingKey {
        case commentIds = "comment_ids"
    }
}

// MARK: - 批量拒绝评论请求（带拒绝原因）
struct BatchRejectCommentRequest: Codable {
    let commentIds: [Int]
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case commentIds = "comment_ids"
        case reason
    }
}

// MARK: - 批量操作响应
struct BatchCommentResponse: Codable {
    let successCount: Int
    let failedCount: Int
    let failedIds: [Int]?
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
        case successCount = "success_count"
        case failedCount = "failed_count"
        case failedIds = "failed_ids"
    }
}

// MARK: - 编辑评论请求
struct EditCommentRequest: Codable {
    let content: String
}

// MARK: - 设置评论置顶请求
struct SetCommentTopRequest: Codable {
    let isTop: Bool

    enum CodingKeys: String, CodingKey {
        case isTop = "is_top"
    }
}

// MARK: - 回复评论请求
struct ReplyCommentRequest: Codable {
    let content: String
}

// MARK: - 拒绝评论请求（带原因）
struct RejectCommentRequest: Codable {
    let reason: String?
}

// MARK: - 单个游戏评论响应
struct GameCommentResponse: Codable {
    let comment: GameComment
}
