//
//  NovelService.swift
//  X-Manage
//
//  小说服务

import Foundation

struct NovelListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var categoryId: Int?
    var status: String?
    var isCompleted: Bool?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let keyword = keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let categoryId = categoryId {
            items.append(URLQueryItem(name: "category_id", value: "\(categoryId)"))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        if let isCompleted = isCompleted {
            items.append(URLQueryItem(name: "is_completed", value: "\(isCompleted)"))
        }
        return items
    }
}

struct NovelOrderListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var userId: Int?
    var novelId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let novelId = novelId {
            items.append(URLQueryItem(name: "novel_id", value: "\(novelId)"))
        }
        return items
    }
}

@MainActor
class NovelService {
    static let shared = NovelService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: NovelListParams) async throws -> NovelListResponse {
        try await api.request(
            endpoint: APIEndpoints.Novels.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Novel {
        let response: NovelDetailResponse = try await api.request(
            endpoint: APIEndpoints.Novels.detail(id)
        )
        return response.novel
    }

    func create(request: CreateNovelRequest) async throws -> Novel {
        let response: NovelDetailResponse = try await api.request(
            endpoint: APIEndpoints.Novels.list,
            method: .post,
            body: request
        )
        return response.novel
    }

    func update(id: Int, request: UpdateNovelRequest) async throws -> Novel {
        let response: NovelDetailResponse = try await api.request(
            endpoint: APIEndpoints.Novels.detail(id),
            method: .put,
            body: request
        )
        return response.novel
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Novels.detail(id),
            method: .delete
        )
    }

    // MARK: - 状态操作
    func publish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.detail(id))/publish",
            method: .post
        )
    }

    func unpublish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.detail(id))/unlist",
            method: .post
        )
    }

    func setTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.detail(id))/top",
            method: .patch,
            body: ["is_top": isTop]
        )
    }

    func setComplete(id: Int, isCompleted: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.detail(id))/complete",
            method: .put,
            body: ["is_completed": isCompleted]
        )
    }

    // MARK: - 封面
    func updateCover(id: Int, cover: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.detail(id))/cover",
            method: .put,
            body: ["cover": cover]
        )
    }

    // MARK: - 章节
    func getChapters(novelId: Int, page: Int = 1, pageSize: Int = 50) async throws -> NovelChapterListResponse {
        try await api.request(
            endpoint: APIEndpoints.Novels.chapters,
            queryItems: [
                URLQueryItem(name: "novel_id", value: "\(novelId)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func getChapterDetail(chapterId: Int) async throws -> NovelChapter {
        let response: NovelChapterDetailResponse = try await api.request(
            endpoint: "\(APIEndpoints.Novels.chapters)/\(chapterId)"
        )
        return response.chapter
    }

    func createChapter(request: CreateNovelChapterRequest) async throws -> NovelChapter {
        let response: NovelChapterDetailResponse = try await api.request(
            endpoint: APIEndpoints.Novels.chapters,
            method: .post,
            body: request
        )
        return response.chapter
    }

    func updateChapter(chapterId: Int, request: UpdateNovelChapterRequest) async throws -> NovelChapter {
        let response: NovelChapterDetailResponse = try await api.request(
            endpoint: "\(APIEndpoints.Novels.chapters)/\(chapterId)",
            method: .put,
            body: request
        )
        return response.chapter
    }

    func deleteChapter(chapterId: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.chapters)/\(chapterId)",
            method: .delete
        )
    }

    // MARK: - 定价
    func getPricings(page: Int = 1, pageSize: Int = 50) async throws -> NovelPricingListResponse {
        try await api.request(
            endpoint: APIEndpoints.Novels.pricings,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    // MARK: - 订单
    func getOrders(params: NovelOrderListParams) async throws -> NovelOrderListResponse {
        try await api.request(
            endpoint: APIEndpoints.Novels.orders,
            queryItems: params.queryItems
        )
    }
}

// MARK: - 小说详情响应
struct NovelDetailResponse: Codable {
    let novel: Novel
}

// MARK: - 章节操作请求
struct CreateNovelChapterRequest: Codable {
    let novelId: Int
    let title: String?
    let content: String
    let sort: Int?

    enum CodingKeys: String, CodingKey {
        case title, content, sort
        case novelId = "novel_id"
    }
}

struct UpdateNovelChapterRequest: Codable {
    var title: String?
    var content: String?
    var sort: Int?
}

// MARK: - 章节详情响应
struct NovelChapterDetailResponse: Codable {
    let chapter: NovelChapter
}
