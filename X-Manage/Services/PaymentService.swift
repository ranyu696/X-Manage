//
//  PaymentService.swift
//  X-Manage
//
//  支付服务

import Foundation

struct PaymentListParams {
    var page: Int = 1
    var pageSize: Int = 25
    var userId: Int?
    var status: String?
    var payType: String?
    var sortField: String?
    var sortOrder: String?
    var tradeNo: String?      // 系统订单号
    var outTradeNo: String?   // 商户订单号

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let userId = userId {
            items.append(URLQueryItem(name: "user_id", value: "\(userId)"))
        }
        if let status = status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        if let payType = payType {
            items.append(URLQueryItem(name: "pay_type", value: payType))
        }
        if let sortField = sortField {
            items.append(URLQueryItem(name: "sort_field", value: sortField))
        }
        if let sortOrder = sortOrder {
            items.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        if let tradeNo = tradeNo, !tradeNo.isEmpty {
            items.append(URLQueryItem(name: "trade_no", value: tradeNo))
        }
        if let outTradeNo = outTradeNo, !outTradeNo.isEmpty {
            items.append(URLQueryItem(name: "out_trade_no", value: outTradeNo))
        }
        return items
    }
}

@MainActor
class PaymentService {
    static let shared = PaymentService()
    private let api = APIClient.shared

    private init() {}

    func getList(params: PaymentListParams) async throws -> PaymentListResponse {
        try await api.request(
            endpoint: APIEndpoints.Payments.list,
            queryItems: params.queryItems
        )
    }

    func getDetail(id: Int) async throws -> Payment {
        let response: PaymentDetailResponse = try await api.request(
            endpoint: "\(APIEndpoints.Payments.list)/\(id)"
        )
        return response.payment
    }

    func getStats() async throws -> PaymentStats {
        let response: PaymentStatsResponse = try await api.request(
            endpoint: APIEndpoints.Payments.stats
        )
        return response.stats
    }

    func getDashboard() async throws -> PaymentDashboard {
        let response: PaymentDashboardResponse = try await api.request(
            endpoint: "\(APIEndpoints.Payments.list)/dashboard"
        )
        return response.dashboard
    }

    /// 获取支付趋势统计
    /// - Parameters:
    ///   - startDate: 开始日期 (格式: yyyy-MM-dd)
    ///   - endDate: 结束日期 (格式: yyyy-MM-dd)
    /// - Returns: 支付趋势数据
    func getTrendStats(startDate: String? = nil, endDate: String? = nil) async throws -> [PaymentChartDataPoint] {
        var queryItems: [URLQueryItem] = []
        if let start = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: start))
        }
        if let end = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: end))
        }

        let response: PaymentTrendStatsResponse = try await api.request(
            endpoint: APIEndpoints.Payments.stats,
            queryItems: queryItems
        )
        return response.chartData
    }
}
