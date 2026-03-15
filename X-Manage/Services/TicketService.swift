//
//  TicketService.swift
//  X-Manage
//
//  工单服务

import Foundation

struct TicketListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var keyword: String?
    var status: String?
    var category: String?
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
        if let category = category {
            items.append(URLQueryItem(name: "category", value: category))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        return items
    }
}

@MainActor
class TicketService {
    static let shared = TicketService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: TicketListParams) async throws -> TicketListResponse {
        try await api.request(
            endpoint: APIEndpoints.Tickets.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Ticket {
        let response: TicketDetailResponse = try await api.request(
            endpoint: APIEndpoints.Tickets.detail(id)
        )
        return response.ticket
    }

    func getReplies(ticketId: Int, page: Int = 1, pageSize: Int = 50) async throws -> TicketReplyListResponse {
        try await api.request(
            endpoint: APIEndpoints.Tickets.replies(ticketId),
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
    }

    func createReply(ticketId: Int, request: CreateTicketReplyRequest) async throws -> TicketReply {
        let response: TicketReplyResponse = try await api.request(
            endpoint: APIEndpoints.Tickets.replies(ticketId),
            method: .post,
            body: request
        )
        return response.reply
    }

    func updateStatus(id: Int, status: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Tickets.detail(id))/status",
            method: .put,
            body: UpdateTicketStatusRequest(status: status)
        )
    }

    func updateCategory(id: Int, category: String) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Tickets.detail(id))/category",
            method: .put,
            body: UpdateTicketCategoryRequest(category: category)
        )
    }

    func assign(id: Int, assignedTo: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Tickets.detail(id))/assign",
            method: .post,
            body: AssignTicketRequest(assignedTo: assignedTo)
        )
    }

    func close(id: Int) async throws {
        try await api.requestVoid(
            endpoint: "\(APIEndpoints.Tickets.detail(id))/close",
            method: .post
        )
    }
}

// MARK: - 工单回复响应
struct TicketReplyResponse: Codable {
    let reply: TicketReply
}
