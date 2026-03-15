//
//  Tag.swift
//  X-Manage
//
//  标签模型

import Foundation

// MARK: - 标签
struct Tag: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let description: String
    let count: Int
    let comicCount: Int
    let novelCount: Int
    let gameCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, count
        case comicCount = "comic_count"
        case novelCount = "novel_count"
        case gameCount = "game_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 标签分页
struct TagPagination: Codable {
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

// MARK: - 标签列表响应
struct TagListResponse: Codable {
    let tags: [Tag]
    let pagination: TagPagination
}

// MARK: - 创建标签请求
struct CreateTagRequest: Codable {
    let name: String
    let slug: String
    let description: String
}

// MARK: - 更新标签请求
struct UpdateTagRequest: Codable {
    var name: String?
    var slug: String?
    var description: String?
}
