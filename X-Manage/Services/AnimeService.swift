//
//  AnimeService.swift
//  X-Manage
//
//  动漫服务

import Foundation

struct AnimeOrderListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var userId: Int?
    var animeId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let animeId = animeId {
            items.append(URLQueryItem(name: "anime_id", value: "\(animeId)"))
        }
        return items
    }
}

struct AnimeListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var categoryId: Int?
    var status: AnimeStatus?
    var year: Int?

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
        if let year = year {
            items.append(URLQueryItem(name: "year", value: "\(year)"))
        }
        return items
    }
}

@MainActor
class AnimeService {
    static let shared = AnimeService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: AnimeListParams) async throws -> AnimeListResponse {
        try await api.request(
            endpoint: APIEndpoints.Anime.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> AnimeDetail {
        let response: AnimeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.detail(id)
        )
        return response.anime
    }

    func create(request: CreateAnimeRequest) async throws -> AnimeDetail {
        let response: AnimeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.list,
            method: .post,
            body: request
        )
        return response.anime
    }

    func update(id: Int, request: UpdateAnimeRequest) async throws -> AnimeDetail {
        let response: AnimeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.detail(id),
            method: .put,
            body: request
        )
        return response.anime
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Anime.detail(id),
            method: .delete
        )
    }

    func publish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.detail(id))/publish",
            method: .post
        )
    }

    func unpublish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.detail(id))/unpublish",
            method: .post
        )
    }

    func setTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.detail(id))/top",
            method: .patch,
            body: ["is_top": isTop]
        )
    }

    func setComplete(id: Int, isCompleted: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.detail(id))/complete",
            method: .put,
            body: ["is_completed": isCompleted]
        )
    }

    // MARK: - 剧集
    func getEpisodes(animeId: Int, page: Int = 1, pageSize: Int = 50) async throws -> EpisodeListResponse {
        try await api.request(
            endpoint: APIEndpoints.Anime.episodes(animeId),
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func getEpisodeDetail(episodeId: Int) async throws -> EpisodeDetail {
        let response: EpisodeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.episodeDetail(episodeId)
        )
        return response.episode
    }

    func createEpisode(animeId: Int, request: CreateEpisodeRequest) async throws -> EpisodeDetail {
        let response: EpisodeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.episodes(animeId),
            method: .post,
            body: request
        )
        return response.episode
    }

    func updateEpisode(episodeId: Int, request: UpdateEpisodeRequest) async throws -> EpisodeDetail {
        let response: EpisodeDetailResponse = try await api.request(
            endpoint: APIEndpoints.Anime.episodeDetail(episodeId),
            method: .put,
            body: request
        )
        return response.episode
    }

    func deleteEpisode(episodeId: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Anime.episodeDetail(episodeId),
            method: .delete
        )
    }

    func updateEpisodeCover(episodeId: Int, cover: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.episodeDetail(episodeId))/cover",
            method: .put,
            body: ["cover": cover]
        )
    }

    func updateEpisodeFanart(episodeId: Int, fanart: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.episodeDetail(episodeId))/fanart",
            method: .put,
            body: ["fanart": fanart]
        )
    }

    // MARK: - 定价
    func getPricings(page: Int = 1, pageSize: Int = 50) async throws -> AnimePricingListResponse {
        try await api.request(
            endpoint: APIEndpoints.Anime.pricings,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    // MARK: - 订单
    func getOrders(params: AnimeOrderListParams) async throws -> AnimeOrderListResponse {
        try await api.request(
            endpoint: APIEndpoints.Anime.orders,
            queryItems: params.queryItems
        )
    }
}
