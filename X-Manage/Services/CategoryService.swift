//
//  CategoryService.swift
//  X-Manage
//
//  分类服务

import Foundation

struct CategoryListParams {
    var page: Int = 1
    var pageSize: Int = 50
    var keyword: String?
    var parentId: Int?
    var status: String?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let keyword = keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let parentId = parentId {
            items.append(URLQueryItem(name: "parent_id", value: "\(parentId)"))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        return items
    }
}

@MainActor
class CategoryService {
    static let shared = CategoryService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: CategoryListParams) async throws -> CategoryListResponse {
        try await api.request(
            endpoint: APIEndpoints.Categories.list,
            queryItems: params.queryItems
        )
    }

    // MARK: - 树形结构
    func getTree() async throws -> CategoryTreeResponse {
        try await api.request(
            endpoint: APIEndpoints.Categories.tree
        )
    }

    func getChildren(id: Int) async throws -> CategoryChildrenResponse {
        try await api.request(
            endpoint: APIEndpoints.Categories.children(id)
        )
    }

    func getChildrenBySlug(_ slug: String) async throws -> CategoryChildrenResponse {
        try await api.request(
            endpoint: APIEndpoints.Categories.childrenBySlug(slug)
        )
    }

    func getDetail(id: Int) async throws -> Category {
        let response: CategoryDetailResponse = try await api.request(
            endpoint: APIEndpoints.Categories.detail(id)
        )
        return response.category
    }

    func create(request: CreateCategoryRequest) async throws -> Category {
        let response: CategoryDetailResponse = try await api.request(
            endpoint: APIEndpoints.Categories.list,
            method: .post,
            body: request
        )
        return response.category
    }

    func update(id: Int, request: UpdateCategoryRequest) async throws -> Category {
        let response: CategoryDetailResponse = try await api.request(
            endpoint: APIEndpoints.Categories.detail(id),
            method: .put,
            body: request
        )
        return response.category
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Categories.detail(id),
            method: .delete
        )
    }
}

// MARK: - 分类详情响应
struct CategoryDetailResponse: Codable {
    let category: Category
}
