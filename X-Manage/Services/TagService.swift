//
//  TagService.swift
//  X-Manage
//
//  标签服务

import Foundation

struct TagListParams {
    var page: Int = 1
    var pageSize: Int = 50
    var keyword: String?
    var sortBy: String?
    var sortOrder: String?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let keyword = keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        if let sortOrder = sortOrder {
            items.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        return items
    }
}

@MainActor
class TagService {
    static let shared = TagService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: TagListParams) async throws -> TagListResponse {
        try await api.request(
            endpoint: APIEndpoints.Tags.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Tag {
        let response: TagDetailResponse = try await api.request(
            endpoint: APIEndpoints.Tags.detail(id)
        )
        return response.tag
    }

    func create(request: CreateTagRequest) async throws -> Tag {
        let response: TagDetailResponse = try await api.request(
            endpoint: APIEndpoints.Tags.list,
            method: .post,
            body: request
        )
        return response.tag
    }

    func update(id: Int, request: UpdateTagRequest) async throws -> Tag {
        let response: TagDetailResponse = try await api.request(
            endpoint: APIEndpoints.Tags.detail(id),
            method: .put,
            body: request
        )
        return response.tag
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Tags.detail(id),
            method: .delete
        )
    }
}

// MARK: - 标签详情响应
struct TagDetailResponse: Codable {
    let tag: Tag
}
