//
//  PaymentAppealService.swift
//  X-Manage
//
//  支付申诉服务

import Foundation

struct PaymentAppealListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var status: String?
    var type: String?
    var outTradeNo: String?
    var userId: Int?
    var sortField: String?
    var sortOrder: String?

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        if let type = type {
            items.append(URLQueryItem(name: "type", value: type))
        }
        if let outTradeNo = outTradeNo, !outTradeNo.isEmpty {
            items.append(URLQueryItem(name: "out_trade_no", value: outTradeNo))
        }
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let sortField = sortField {
            items.append(URLQueryItem(name: "sort_field", value: sortField))
        }
        if let sortOrder = sortOrder {
            items.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        return items
    }
}

@MainActor
class PaymentAppealService {
    static let shared = PaymentAppealService()
    private let api = APIClient.shared

    private init() {}

    /// 申诉列表
    func getList(params: PaymentAppealListParams) async throws -> PaymentAppealListResponse {
        try await api.request(
            endpoint: APIEndpoints.PaymentAppeals.list,
            queryItems: params.queryItems
        )
    }

    /// 申诉详情
    func getDetail(publicId: String) async throws -> PaymentAppeal {
        let response: PaymentAppealDetailResponse = try await api.request(
            endpoint: APIEndpoints.PaymentAppeals.detail(publicId)
        )
        return response.appeal
    }

    /// 处理申诉（批准/驳回/需补充材料）
    /// - Parameters:
    ///   - publicId: 申诉公开ID
    ///   - decision: approved | rejected | need_more_info
    ///   - adminNote: 管理员备注（驳回原因/需补充说明）
    /// - Returns: 更新后的申诉
    @discardableResult
    func resolve(publicId: String, decision: String, adminNote: String) async throws -> PaymentAppeal {
        let response: PaymentAppealDetailResponse = try await api.request(
            endpoint: APIEndpoints.PaymentAppeals.resolve(publicId),
            method: .post,
            body: ResolvePaymentAppealRequest(decision: decision, adminNote: adminNote)
        )
        return response.appeal
    }
}
