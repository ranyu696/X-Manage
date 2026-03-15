//
//  Payment.swift
//  X-Manage
//
//  支付模型

import Foundation

// MARK: - 支付状态
enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case paid = "PAID"
    case timeout = "TIMEOUT"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case refunded = "REFUNDED"

    var displayName: String {
        switch self {
        case .pending: return "待支付"
        case .paid: return "已支付"
        case .timeout: return "超时"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        case .refunded: return "已退款"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .paid: return "green"
        case .timeout, .failed: return "red"
        case .cancelled: return "gray"
        case .refunded: return "blue"
        }
    }
}

// MARK: - 支付方式
enum PaymentMethod: String, Codable, CaseIterable {
    case alipay = "ALIPAY"
    case wxpay = "WXPAY"
    case card = "CARD"
    case balance = "BALANCE"

    var displayName: String {
        switch self {
        case .alipay: return "支付宝"
        case .wxpay: return "微信支付"
        case .card: return "银行卡"
        case .balance: return "余额"
        }
    }
}

// MARK: - 支付类型
enum PaymentType: String, Codable, CaseIterable {
    case recharge = "RECHARGE"
    case paymentVip = "PAYMENT_VIP"
    case paymentSvip = "PAYMENT_SVIP"
    case vipUpgrade = "VIP_UPGRADE"
    case vipRenewal = "VIP_RENEWAL"
    case svipRenewal = "SVIP_RENEWAL"

    var displayName: String {
        switch self {
        case .recharge: return "余额充值"
        case .paymentVip: return "VIP购买"
        case .paymentSvip: return "SVIP购买"
        case .vipUpgrade: return "VIP升级"
        case .vipRenewal: return "VIP续费"
        case .svipRenewal: return "SVIP续费"
        }
    }
}

// MARK: - 客户端类型
enum ClientType: String, Codable, CaseIterable {
    case unspecified = "UNSPECIFIED"
    case web = "WEB"
    case ios = "IOS"
    case android = "ANDROID"

    var displayName: String {
        switch self {
        case .unspecified: return "未知"
        case .web: return "Web"
        case .ios: return "iOS"
        case .android: return "Android"
        }
    }
}

// MARK: - 支付
struct Payment: Codable, Identifiable {
    let id: Int
    let userId: Int
    let amount: String
    let method: String
    let status: String
    let payType: String
    let param: String?
    let tradeNo: String?
    let outTradeNo: String?
    let errorMessage: String?
    let failReason: String?
    let payUrl: String?
    let clientType: String?
    let ip: String?
    let userAgent: String?
    let paidAt: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, method, status, param, ip
        case userId = "user_id"
        case payType = "pay_type"
        case tradeNo = "trade_no"
        case outTradeNo = "out_trade_no"
        case errorMessage = "error_message"
        case failReason = "fail_reason"
        case payUrl = "pay_url"
        case clientType = "client_type"
        case userAgent = "user_agent"
        case paidAt = "paid_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 状态显示名称
    var statusDisplayName: String {
        switch status {
        case "PENDING": return "待支付"
        case "PAID": return "已支付"
        case "TIMEOUT": return "超时"
        case "FAILED": return "失败"
        case "CANCELLED": return "已取消"
        case "REFUNDED": return "已退款"
        default: return status
        }
    }

    // 支付方式显示名称
    var methodDisplayName: String {
        switch method {
        case "ALIPAY": return "支付宝"
        case "WXPAY": return "微信支付"
        case "CARD": return "银行卡"
        case "BALANCE": return "余额"
        default: return method
        }
    }

    // 支付类型显示名称
    var payTypeDisplayName: String {
        switch payType {
        case "RECHARGE": return "余额充值"
        case "PAYMENT_VIP": return "VIP购买"
        case "PAYMENT_SVIP": return "SVIP购买"
        case "VIP_UPGRADE": return "VIP升级"
        case "VIP_RENEWAL": return "VIP续费"
        case "SVIP_RENEWAL": return "SVIP续费"
        default: return payType
        }
    }

    // 客户端类型显示名称
    var clientTypeDisplayName: String {
        switch clientType {
        case "WEB": return "Web"
        case "IOS": return "iOS"
        case "ANDROID": return "Android"
        case "UNSPECIFIED": return "未知"
        default: return clientType ?? "未知"
        }
    }
}

// MARK: - 支付统计
struct PaymentStats: Codable {
    let totalCount: Int
    let successCount: Int
    let failedCount: Int
    let successRate: Double
    let totalAmount: String
    let todayCount: Int
    let todayAmount: String
    let periodCount: Int
    let periodAmount: String

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case successCount = "success_count"
        case failedCount = "failed_count"
        case successRate = "success_rate"
        case totalAmount = "total_amount"
        case todayCount = "today_count"
        case todayAmount = "today_amount"
        case periodCount = "period_count"
        case periodAmount = "period_amount"
    }
}

// MARK: - 支付仪表板
struct PaymentDashboard: Codable {
    let todayRevenue: String
    let monthRevenue: String
    let todayOrders: Int
    let monthOrders: Int
    let successRate: Double
    let popularMethods: [PopularPaymentMethod]

    enum CodingKeys: String, CodingKey {
        case todayRevenue = "today_revenue"
        case monthRevenue = "month_revenue"
        case todayOrders = "today_orders"
        case monthOrders = "month_orders"
        case successRate = "success_rate"
        case popularMethods = "popular_methods"
    }
}

// MARK: - 热门支付方式
struct PopularPaymentMethod: Codable {
    let method: String
    let count: Int
    let percentage: Double
}

// MARK: - 支付分页
struct PaymentPagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPage: Int
    let hasNext: Bool
    let hasPrev: Bool

    enum CodingKeys: String, CodingKey {
        case page, total
        case pageSize = "page_size"
        case totalPage = "total_page"
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
}

// MARK: - 支付列表响应
struct PaymentListResponse: Codable {
    let schema: String?
    let payments: [Payment]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case payments, pagination
    }
}

// MARK: - 支付详情响应
struct PaymentDetailResponse: Codable {
    let payment: Payment
}

// MARK: - 支付统计响应
struct PaymentStatsResponse: Codable {
    let stats: PaymentStats
}

// MARK: - 支付仪表板响应
struct PaymentDashboardResponse: Codable {
    let dashboard: PaymentDashboard
}

// MARK: - 支付趋势数据点
struct PaymentChartDataPoint: Codable {
    let date: String
    let createdAmount: String
    let successAmount: String

    enum CodingKeys: String, CodingKey {
        case date
        case createdAmount = "created_amount"
        case successAmount = "success_amount"
    }

    // 转换为Double用于图表
    var createdValue: Double {
        Double(createdAmount) ?? 0
    }

    var successValue: Double {
        Double(successAmount) ?? 0
    }
}

// MARK: - 支付趋势统计响应
struct PaymentTrendStatsResponse: Codable {
    let chartData: [PaymentChartDataPoint]

    enum CodingKeys: String, CodingKey {
        case chartData = "chart_data"
    }
}
