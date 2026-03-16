//
//  ComicService.swift
//  X-Manage
//
//  漫画服务

import Foundation

protocol ComicServiceProtocol {
    func getList(params: ComicListParams) async throws -> ComicListResponse
    func getDetail(id: Int) async throws -> Comic
    func create(request: CreateComicRequest) async throws -> Comic
    func update(id: Int, request: UpdateComicRequest) async throws -> Comic
    func delete(id: Int) async throws
    func publish(id: Int) async throws
    func unpublish(id: Int) async throws
}

struct ComicOrderListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var userId: Int?
    var comicId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let comicId = comicId {
            items.append(URLQueryItem(name: "comic_id", value: "\(comicId)"))
        }
        return items
    }
}

struct ComicListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var categoryId: Int?
    var status: ComicStatus?
    var comicType: ComicType?
    var isTop: Bool?
    var isCompleted: Bool?
    var orderBy: String?
    var orderDirection: String?

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
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let comicType = comicType {
            items.append(URLQueryItem(name: "comic_type", value: comicType.rawValue))
        }
        if let isTop = isTop {
            items.append(URLQueryItem(name: "is_top", value: "\(isTop)"))
        }
        if let isCompleted = isCompleted {
            items.append(URLQueryItem(name: "is_completed", value: "\(isCompleted)"))
        }
        if let orderBy = orderBy {
            items.append(URLQueryItem(name: "order_by", value: orderBy))
        }
        if let orderDirection = orderDirection {
            items.append(URLQueryItem(name: "order_direction", value: orderDirection))
        }
        return items
    }
}

@MainActor
class ComicService: ComicServiceProtocol {
    static let shared = ComicService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: ComicListParams) async throws -> ComicListResponse {
        try await api.request(
            endpoint: APIEndpoints.Comics.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Comic {
        let response: ComicDetailResponse = try await api.request(
            endpoint: APIEndpoints.Comics.detail(id)
        )
        return response.comic
    }

    func create(request: CreateComicRequest) async throws -> Comic {
        let response: ComicDetailResponse = try await api.request(
            endpoint: APIEndpoints.Comics.list,
            method: .post,
            body: request
        )
        return response.comic
    }

    func update(id: Int, request: UpdateComicRequest) async throws -> Comic {
        let response: ComicDetailResponse = try await api.request(
            endpoint: APIEndpoints.Comics.detail(id),
            method: .put,
            body: request
        )
        return response.comic
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Comics.detail(id),
            method: .delete
        )
    }

    func publish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.detail(id))/publish",
            method: .post
        )
    }

    func unpublish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.detail(id))/unpublish",
            method: .post
        )
    }

    func setTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.detail(id))/top",
            method: .patch,
            body: ["is_top": isTop]
        )
    }

    func setComplete(id: Int, isCompleted: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.detail(id))/complete",
            method: .put,
            body: ["is_completed": isCompleted]
        )
    }

    // MARK: - 章节
    func getChapters(comicId: Int, page: Int = 1, pageSize: Int = 50) async throws -> ChapterListResponse {
        try await api.request(
            endpoint: APIEndpoints.Comics.chapters,
            queryItems: [
                URLQueryItem(name: "comic_id", value: "\(comicId)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func getChapterDetail(id: Int) async throws -> Chapter {
        let response: ChapterDetailResponse = try await api.request(
            endpoint: APIEndpoints.Comics.chapterDetail(id)
        )
        return response.chapter
    }

    func updateChapter(id: Int, request: UpdateChapterRequest) async throws -> Chapter {
        let response: ChapterDetailResponse = try await api.request(
            endpoint: APIEndpoints.Comics.chapterDetail(id),
            method: .put,
            body: request
        )
        return response.chapter
    }

    func deleteChapter(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Comics.chapterDetail(id),
            method: .delete
        )
    }

    func getChapterPages(chapterId: Int, page: Int = 1, pageSize: Int = 100) async throws -> [Page] {
        let response: ChapterPagesResponse = try await api.request(
            endpoint: APIEndpoints.Comics.pages,
            queryItems: [
                URLQueryItem(name: "chapter_id", value: "\(chapterId)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
        return response.pages
    }

    // MARK: - 定价
    func getPricings(page: Int = 1, pageSize: Int = 50) async throws -> ComicPricingListResponse {
        try await api.request(
            endpoint: APIEndpoints.Comics.pricings,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func createPricing(_ request: CreateComicPricingRequest) async throws -> ComicPricingResponse {
        try await api.request(endpoint: APIEndpoints.Comics.pricings, method: .post, body: request)
    }

    func updatePricing(id: Int, _ request: UpdateComicPricingRequest) async throws -> ComicPricingResponse {
        try await api.request(endpoint: APIEndpoints.Comics.pricingDetail(id), method: .put, body: request)
    }

    func deletePricing(id: Int) async throws {
        try await api.requestVoid(endpoint: APIEndpoints.Comics.pricingDetail(id), method: .delete)
    }

    // MARK: - 订单
    func getOrders(params: ComicOrderListParams) async throws -> ComicOrderListResponse {
        try await api.request(
            endpoint: APIEndpoints.Comics.orders,
            queryItems: params.queryItems
        )
    }
}

