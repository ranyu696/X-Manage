//
//  CommentService.swift
//  X-Manage
//
//  评论服务

import Foundation

struct CommentListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var status: String?
    var userId: Int?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let keyword = keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        return items
    }
}

@MainActor
class CommentService {
    static let shared = CommentService()
    private let api = APIClient.shared

    private init() {}

    // MARK: - 漫画评论
    func getComicComments(params: CommentListParams) async throws -> ComicCommentListResponse {
        try await api.request(
            endpoint: APIEndpoints.Comics.comments,
            queryItems: params.queryItems
        )
    }

    func approveComicComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.comments)/\(id)/approve",
            method: .post
        )
    }

    func rejectComicComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.comments)/\(id)/reject",
            method: .post
        )
    }

    func deleteComicComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.comments)/\(id)",
            method: .delete
        )
    }

    func setComicCommentTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Comics.comments)/\(id)/top",
            method: .post,
            body: SetCommentTopRequest(isTop: isTop)
        )
    }

    func batchApproveComicComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Comics.comments)/batch-approve",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func batchRejectComicComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Comics.comments)/batch-reject",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func batchDeleteComicComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Comics.comments)/batch-delete",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    // MARK: - 游戏评论
    func getGameComments(params: CommentListParams) async throws -> GameCommentListResponse {
        try await api.request(
            endpoint: APIEndpoints.Games.comments,
            queryItems: params.queryItems
        )
    }

    func approveGameComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)/approve",
            method: .post
        )
    }

    func rejectGameComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)/reject",
            method: .post
        )
    }

    func deleteGameComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)",
            method: .delete
        )
    }

    func batchApproveGameComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/batch-approve",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func batchRejectGameComments(ids: [Int], reason: String? = nil) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/batch-reject",
            method: .post,
            body: BatchRejectCommentRequest(commentIds: ids, reason: reason)
        )
    }

    func batchDeleteGameComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/batch-delete",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func editGameComment(id: Int, content: String) async throws -> GameCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)",
            method: .put,
            body: EditCommentRequest(content: content)
        )
    }

    func replyGameComment(id: Int, content: String) async throws -> GameCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)/reply",
            method: .post,
            body: ReplyCommentRequest(content: content)
        )
    }

    func setGameCommentTop(id: Int, isTop: Bool) async throws -> GameCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Games.comments)/\(id)/top",
            method: .post,
            body: SetCommentTopRequest(isTop: isTop)
        )
    }

    func getGameCommentsByGame(gameId: Int, page: Int = 1, pageSize: Int = 20) async throws -> GameCommentListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        return try await api.request(
            endpoint: "\(APIEndpoints.basePrefix)/games/\(gameId)/comments",
            queryItems: queryItems
        )
    }

    func getGameCommentsByUser(userId: Int, page: Int = 1, pageSize: Int = 20, status: String? = nil) async throws -> GameCommentListResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await api.request(
            endpoint: "\(APIEndpoints.basePrefix)/users/\(userId)/comments",
            queryItems: queryItems
        )
    }

    func getComicCommentsByUser(userId: Int, page: Int = 1, pageSize: Int = 20, status: String? = nil) async throws -> ComicCommentListResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await api.request(
            endpoint: "\(APIEndpoints.basePrefix)/users/\(userId)/comic-comments",
            queryItems: queryItems
        )
    }

    func getNovelCommentsByUser(userId: Int, page: Int = 1, pageSize: Int = 20, status: String? = nil) async throws -> NovelCommentListResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await api.request(
            endpoint: "\(APIEndpoints.basePrefix)/users/\(userId)/novel-comments",
            queryItems: queryItems
        )
    }

    // MARK: - 小说评论
    func getNovelComments(params: CommentListParams) async throws -> NovelCommentListResponse {
        try await api.request(
            endpoint: APIEndpoints.Novels.comments,
            queryItems: params.queryItems
        )
    }

    func approveNovelComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.comments)/\(id)/approve",
            method: .post
        )
    }

    func rejectNovelComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.comments)/\(id)/reject",
            method: .post
        )
    }

    func deleteNovelComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Novels.comments)/\(id)",
            method: .delete
        )
    }

    // MARK: - 动漫评论
    func getAnimeComments(params: CommentListParams) async throws -> AnimeCommentListResponse {
        try await api.request(
            endpoint: APIEndpoints.Anime.comments,
            queryItems: params.queryItems
        )
    }

    func approveAnimeComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)/approve",
            method: .post
        )
    }

    func rejectAnimeComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)/reject",
            method: .post
        )
    }

    func deleteAnimeComment(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)",
            method: .delete
        )
    }

    func editAnimeComment(id: Int, content: String) async throws -> AnimeCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)",
            method: .put,
            body: EditCommentRequest(content: content)
        )
    }

    func replyAnimeComment(id: Int, content: String) async throws -> AnimeCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)/reply",
            method: .post,
            body: ReplyCommentRequest(content: content)
        )
    }

    func setAnimeCommentTop(id: Int, isTop: Bool) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Anime.comments)/\(id)/top",
            method: .post,
            body: SetCommentTopRequest(isTop: isTop)
        )
    }

    func batchApproveAnimeComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Anime.comments)/batch-approve",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func batchRejectAnimeComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Anime.comments)/batch-reject",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }

    func batchDeleteAnimeComments(ids: [Int]) async throws -> BatchCommentResponse {
        try await api.request(
            endpoint: "\(APIEndpoints.Anime.comments)/batch-delete",
            method: .post,
            body: BatchCommentIdsRequest(commentIds: ids)
        )
    }
}
