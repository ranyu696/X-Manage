//
//  GameService.swift
//  X-Manage
//
//  游戏服务

import Foundation

struct GameListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var categoryId: Int?
    var status: String?
    var types: [String]?

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
        return items
    }
}

struct GameOrderListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var userId: Int?
    var gameId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let gameId = gameId {
            items.append(URLQueryItem(name: "game_id", value: "\(gameId)"))
        }
        return items
    }
}

@MainActor
class GameService {
    static let shared = GameService()
    private let api = APIClient.shared

    private init() {}

    // MARK: - 游戏 CRUD
    func getList(params: GameListParams) async throws -> GameListResponse {
        try await api.request(
            endpoint: APIEndpoints.Games.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Game {
        let response: GameDetailResponse = try await api.request(
            endpoint: APIEndpoints.Games.detail(id)
        )
        return response.game
    }

    func createFromYaml(yaml: String) async throws -> Game {
        let response: GameDetailResponse = try await api.request(
            endpoint: APIEndpoints.Games.list,
            method: .post,
            body: CreateGameFromYamlRequest(yaml: yaml)
        )
        return response.game
    }

    func update(id: Int, request: UpdateGameRequest) async throws -> Game {
        let response: GameDetailResponse = try await api.request(
            endpoint: APIEndpoints.Games.detail(id),
            method: .put,
            body: request
        )
        return response.game
    }

    func delete(id: Int) async throws {
        try await api.requestVoid(
            endpoint: APIEndpoints.Games.detail(id),
            method: .delete
        )
    }

    // MARK: - 游戏状态操作
    func publish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/publish",
            method: .post
        )
    }

    func unpublish(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/unlist",
            method: .post
        )
    }

    func setTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/top",
            method: .post,
            body: SetGameTopRequest(isTop: isTop)
        )
    }

    // MARK: - 版本管理
    func getVersions(gameId: Int, page: Int = 1, pageSize: Int = 50) async throws -> GameVersionListResponse {
        try await api.request(
            endpoint: APIEndpoints.Games.versions(gameId),
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func createVersion(gameId: Int, request: CreateGameVersionRequest) async throws -> GameVersion {
        let response: GameVersionDetailResponse = try await api.request(
            endpoint: APIEndpoints.Games.versions(gameId),
            method: .post,
            body: request
        )
        return response.version
    }

    func updateVersion(gameId: Int, versionId: Int, request: UpdateGameVersionRequest) async throws -> GameVersion {
        let response: GameVersionDetailResponse = try await api.request(
            endpoint: "\(APIEndpoints.Games.versions(gameId))/\(versionId)",
            method: .put,
            body: request
        )
        return response.version
    }

    func deleteVersion(gameId: Int, versionId: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.versions(gameId))/\(versionId)",
            method: .delete
        )
    }

    // MARK: - 图片管理
    func updateCovers(id: Int, images: [String]) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/covers",
            method: .put,
            body: UpdateImagesRequest(images: images)
        )
    }

    func updateContentImages(id: Int, images: [String]) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/content-images",
            method: .put,
            body: UpdateImagesRequest(images: images)
        )
    }

    func updateUpdateImages(id: Int, images: [String]) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.detail(id))/update-images",
            method: .put,
            body: UpdateImagesRequest(images: images)
        )
    }

    // MARK: - 定价
    func getPricings(page: Int = 1, pageSize: Int = 50) async throws -> GamePricingListResponse {
        try await api.request(
            endpoint: APIEndpoints.Games.pricings,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    // MARK: - 订单
    func getOrders(params: GameOrderListParams) async throws -> GameOrderListResponse {
        try await api.request(
            endpoint: APIEndpoints.Games.orders,
            queryItems: params.queryItems
        )
    }
}
