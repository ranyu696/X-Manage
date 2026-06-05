//
//  PaymentAppeal.swift
//  X-Manage
//
//  支付申诉模型

import Foundation

// MARK: - 申诉类型
enum AppealType: String, Codable, CaseIterable {
    case paidNotReceived = "paid_not_received"
    case amountError = "amount_error"
    case other = "other"

    var displayName: String {
        switch self {
        case .paidNotReceived: return "已支付未到账"
        case .amountError: return "金额错误"
        case .other: return "其他支付问题"
        }
    }
}

// MARK: - 申诉状态
enum AppealStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case needMoreInfo = "need_more_info"

    var displayName: String {
        switch self {
        case .pending: return "待处理"
        case .approved: return "已批准"
        case .rejected: return "已驳回"
        case .needMoreInfo: return "需补充材料"
        }
    }
}

// MARK: - 支付申诉
struct PaymentAppeal: Codable, Identifiable {
    let id: Int
    let publicId: String
    let userId: Int
    let paymentId: Int
    let outTradeNo: String
    let type: String
    let status: String
    let description: String
    let images: [String]
    // OCR 预审结果
    let ocrPassed: Bool
    let ocrPlatform: String
    let ocrAmount: String
    let ocrTradeNo: String
    let ocrPaidAt: String
    // 管理员处理
    let adminNote: String
    let resolvedAt: String
    let createdAt: String
    let updatedAt: String
    // 关联订单
    let orderAmount: String
    let orderStatus: String
    let orderPayType: String

    enum CodingKeys: String, CodingKey {
        case id, type, status, description, images
        case publicId = "public_id"
        case userId = "user_id"
        case paymentId = "payment_id"
        case outTradeNo = "out_trade_no"
        case ocrPassed = "ocr_passed"
        case ocrPlatform = "ocr_platform"
        case ocrAmount = "ocr_amount"
        case ocrTradeNo = "ocr_trade_no"
        case ocrPaidAt = "ocr_paid_at"
        case adminNote = "admin_note"
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case orderAmount = "order_amount"
        case orderStatus = "order_status"
        case orderPayType = "order_pay_type"
    }

    // 容错解码：后端某些字段可能缺省
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        publicId = try c.decode(String.self, forKey: .publicId)
        userId = (try? c.decode(Int.self, forKey: .userId)) ?? 0
        paymentId = (try? c.decode(Int.self, forKey: .paymentId)) ?? 0
        outTradeNo = (try? c.decode(String.self, forKey: .outTradeNo)) ?? ""
        type = (try? c.decode(String.self, forKey: .type)) ?? "other"
        status = (try? c.decode(String.self, forKey: .status)) ?? "pending"
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        images = (try? c.decode([String].self, forKey: .images)) ?? []
        ocrPassed = (try? c.decode(Bool.self, forKey: .ocrPassed)) ?? false
        ocrPlatform = (try? c.decode(String.self, forKey: .ocrPlatform)) ?? ""
        ocrAmount = (try? c.decode(String.self, forKey: .ocrAmount)) ?? ""
        ocrTradeNo = (try? c.decode(String.self, forKey: .ocrTradeNo)) ?? ""
        ocrPaidAt = (try? c.decode(String.self, forKey: .ocrPaidAt)) ?? ""
        adminNote = (try? c.decode(String.self, forKey: .adminNote)) ?? ""
        resolvedAt = (try? c.decode(String.self, forKey: .resolvedAt)) ?? ""
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
        orderAmount = (try? c.decode(String.self, forKey: .orderAmount)) ?? ""
        orderStatus = (try? c.decode(String.self, forKey: .orderStatus)) ?? ""
        orderPayType = (try? c.decode(String.self, forKey: .orderPayType)) ?? ""
    }

    // 申诉类型显示名
    var typeDisplayName: String {
        AppealType(rawValue: type)?.displayName ?? type
    }

    // 申诉状态显示名
    var statusDisplayName: String {
        AppealStatus(rawValue: status)?.displayName ?? status
    }

    // 识别平台显示名
    var ocrPlatformDisplayName: String {
        switch ocrPlatform {
        case "wechat": return "微信支付"
        case "alipay": return "支付宝"
        default: return "未识别"
        }
    }

    // 是否进行中（可处理）
    var isActionable: Bool {
        status == AppealStatus.pending.rawValue || status == AppealStatus.needMoreInfo.rawValue
    }
}

// MARK: - 申诉列表响应
struct PaymentAppealListResponse: Codable {
    let schema: String?
    let appeals: [PaymentAppeal]
    let pagination: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case appeals, pagination
    }
}

// MARK: - 申诉详情/处理响应
struct PaymentAppealDetailResponse: Codable {
    let appeal: PaymentAppeal
}

// MARK: - 处理申诉请求
struct ResolvePaymentAppealRequest: Codable {
    let decision: String
    let adminNote: String

    enum CodingKeys: String, CodingKey {
        case decision
        case adminNote = "admin_note"
    }
}
