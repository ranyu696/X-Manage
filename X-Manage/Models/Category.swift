//
//  Category.swift
//  X-Manage
//
//  分类模型

import Foundation

// MARK: - 分类
struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let description: String
    let picture: String
    let parentId: Int?
    let sort: Int
    let depth: Int
    let path: String
    let itemCount: Int
    let status: String
    let children: [Category]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, picture, sort, depth, path, status, children
        case parentId = "parent_id"
        case itemCount = "item_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 分类列表响应
struct CategoryListResponse: Codable {
    let categories: [Category]
}

// MARK: - 分类树响应
struct CategoryTreeResponse: Codable {
    let categories: [Category]
}

// MARK: - 分类子节点响应
struct CategoryChildrenResponse: Codable {
    let categories: [Category]
}

// MARK: - 创建分类请求
struct CreateCategoryRequest: Codable {
    let name: String
    let slug: String
    let description: String
    let picture: String
    let parentId: Int?
    let sort: Int

    enum CodingKeys: String, CodingKey {
        case name, slug, description, picture, sort
        case parentId = "parent_id"
    }
}

// MARK: - 更新分类请求
struct UpdateCategoryRequest: Codable {
    var name: String?
    var slug: String?
    var description: String?
    var picture: String?
    var parentId: Int?
    var sort: Int?

    enum CodingKeys: String, CodingKey {
        case name, slug, description, picture, sort
        case parentId = "parent_id"
    }
}
