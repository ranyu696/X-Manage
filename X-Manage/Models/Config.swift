//
//  Config.swift
//  X-Manage
//
//  系统配置模型

import Foundation

// MARK: - 站点配置
struct SiteConfig: Codable {
    var title: String?
    var domain: String?
    var description: String?
    var keywords: String?
    var logo: String?
    var favicon: String?
    var footer: String?
    var email: String?
    var telegram: String?
    var tgGroup: String?
    var permanentPage: String?
    var websites: [String]?

    enum CodingKeys: String, CodingKey {
        case title, domain, description, keywords, logo, favicon, footer, email, telegram, websites
        case tgGroup = "tg_group"
        case permanentPage = "permanent_page"
    }
}

struct SiteConfigResponse: Codable {
    let config: SiteConfig
}

// MARK: - 公告配置
struct AnnouncementConfig: Codable {
    var enabled: Bool?
    var title: String?
    var content: String?
}

struct AnnouncementConfigResponse: Codable {
    let config: AnnouncementConfig
}

// MARK: - CDN 配置
struct CDNConfig: Codable {
    var comicDomain: String?
    var novelDomain: String?
    var gameDomain: String?
    var ticketDomain: String?
    var animeDomain: String?
    var globalDomain: String?

    enum CodingKeys: String, CodingKey {
        case comicDomain = "comic_domain"
        case novelDomain = "novel_domain"
        case gameDomain = "game_domain"
        case ticketDomain = "ticket_domain"
        case animeDomain = "anime_domain"
        case globalDomain = "global_domain"
    }
}

struct CDNConfigResponse: Codable {
    let config: CDNConfig
}

// MARK: - 邮箱配置
struct EmailConfig: Codable {
    var host: String?
    var port: Int?
    var user: String?
    var password: String?
    var from: String?
    var fromAddr: String?

    enum CodingKeys: String, CodingKey {
        case host, port, user, password, from
        case fromAddr = "from_addr"
    }
}

struct EmailConfigResponse: Codable {
    let config: EmailConfig
}

// MARK: - 支付配置
struct PaymentConfig: Codable {
    // 支付宝配置
    var alipayEnabled: Bool?
    var alipayGateway: String?
    var alipayPid: String?
    var alipaySecret: String?
    var alipayNotifyWeb: String?
    var alipayNotifyMobile: String?
    var alipayNotifyPc: String?

    // 支付宝2配置
    var alipay2Enabled: Bool?
    var alipay2Gateway: String?
    var alipay2Pid: String?
    var alipay2Secret: String?
    var alipay2Channel: String?
    var alipay2NotifyWeb: String?
    var alipay2NotifyMobile: String?
    var alipay2NotifyPc: String?

    // 微信支付配置
    var wxpayEnabled: Bool?
    var wxpayGateway: String?
    var wxpayPid: String?
    var wxpaySecret: String?
    var wxpayNotifyWeb: String?
    var wxpayNotifyMobile: String?
    var wxpayNotifyPc: String?

    // 微信支付2配置
    var wxpay2Enabled: Bool?
    var wxpay2Gateway: String?
    var wxpay2Pid: String?
    var wxpay2Secret: String?
    var wxpay2Channel: String?
    var wxpay2NotifyWeb: String?
    var wxpay2NotifyMobile: String?
    var wxpay2NotifyPc: String?

    // 通道3 - 支付宝配置（金额单位分，MD5小写签名）
    var ch3AlipayEnabled: Bool?
    var ch3AlipayGateway: String?
    var ch3AlipayPid: String?
    var ch3AlipaySecret: String?
    var ch3AlipayNotifyWeb: String?
    var ch3AlipayNotifyMobile: String?
    var ch3AlipayNotifyPc: String?
    var ch3AlipayPaytype: String?

    // 通道3 - 微信支付配置
    var ch3WxpayEnabled: Bool?
    var ch3WxpayGateway: String?
    var ch3WxpayPid: String?
    var ch3WxpaySecret: String?
    var ch3WxpayNotifyWeb: String?
    var ch3WxpayNotifyMobile: String?
    var ch3WxpayNotifyPc: String?
    var ch3WxpayPaytype: String?

    enum CodingKeys: String, CodingKey {
        case alipayEnabled = "alipay_enabled"
        case alipayGateway = "alipay_gateway"
        case alipayPid = "alipay_pid"
        case alipaySecret = "alipay_secret"
        case alipayNotifyWeb = "alipay_notify_web"
        case alipayNotifyMobile = "alipay_notify_mobile"
        case alipayNotifyPc = "alipay_notify_pc"

        case alipay2Enabled = "alipay2_enabled"
        case alipay2Gateway = "alipay2_gateway"
        case alipay2Pid = "alipay2_pid"
        case alipay2Secret = "alipay2_secret"
        case alipay2Channel = "alipay2_channel"
        case alipay2NotifyWeb = "alipay2_notify_web"
        case alipay2NotifyMobile = "alipay2_notify_mobile"
        case alipay2NotifyPc = "alipay2_notify_pc"

        case wxpayEnabled = "wxpay_enabled"
        case wxpayGateway = "wxpay_gateway"
        case wxpayPid = "wxpay_pid"
        case wxpaySecret = "wxpay_secret"
        case wxpayNotifyWeb = "wxpay_notify_web"
        case wxpayNotifyMobile = "wxpay_notify_mobile"
        case wxpayNotifyPc = "wxpay_notify_pc"

        case wxpay2Enabled = "wxpay2_enabled"
        case wxpay2Gateway = "wxpay2_gateway"
        case wxpay2Pid = "wxpay2_pid"
        case wxpay2Secret = "wxpay2_secret"
        case wxpay2Channel = "wxpay2_channel"
        case wxpay2NotifyWeb = "wxpay2_notify_web"
        case wxpay2NotifyMobile = "wxpay2_notify_mobile"
        case wxpay2NotifyPc = "wxpay2_notify_pc"

        case ch3AlipayEnabled = "ch3_alipay_enabled"
        case ch3AlipayGateway = "ch3_alipay_gateway"
        case ch3AlipayPid = "ch3_alipay_pid"
        case ch3AlipaySecret = "ch3_alipay_secret"
        case ch3AlipayNotifyWeb = "ch3_alipay_notify_web"
        case ch3AlipayNotifyMobile = "ch3_alipay_notify_mobile"
        case ch3AlipayNotifyPc = "ch3_alipay_notify_pc"
        case ch3AlipayPaytype = "ch3_alipay_paytype"

        case ch3WxpayEnabled = "ch3_wxpay_enabled"
        case ch3WxpayGateway = "ch3_wxpay_gateway"
        case ch3WxpayPid = "ch3_wxpay_pid"
        case ch3WxpaySecret = "ch3_wxpay_secret"
        case ch3WxpayNotifyWeb = "ch3_wxpay_notify_web"
        case ch3WxpayNotifyMobile = "ch3_wxpay_notify_mobile"
        case ch3WxpayNotifyPc = "ch3_wxpay_notify_pc"
        case ch3WxpayPaytype = "ch3_wxpay_paytype"
    }
}

struct PaymentConfigResponse: Codable {
    let config: PaymentConfig
}

// MARK: - Telegram 配置
struct TelegramConfig: Codable {
    var token: String?
    var enabled: Bool?
    var adminIds: [Int]?
    var groupId: Int?
    var publicGroup: Int?
    var webhookUrl: String?
    var maxImages: Int?
    var parseMode: String?

    enum CodingKeys: String, CodingKey {
        case token, enabled
        case adminIds = "admin_ids"
        case groupId = "group_id"
        case publicGroup = "public_group"
        case webhookUrl = "webhook_url"
        case maxImages = "max_images"
        case parseMode = "parse_mode"
    }
}

struct TelegramConfigResponse: Codable {
    let config: TelegramConfig
}

// MARK: - 会员配置
struct MembershipConfig: Codable {
    var vipMonthlyPrice: Double?
    var vipQuarterlyPrice: Double?
    var vipYearlyPrice: Double?
    var svipMonthlyPrice: Double?
    var svipQuarterlyPrice: Double?
    var svipYearlyPrice: Double?
    var vipPrivileges: [String]?
    var svipPrivileges: [String]?

    enum CodingKeys: String, CodingKey {
        case vipMonthlyPrice = "vip_monthly_price"
        case vipQuarterlyPrice = "vip_quarterly_price"
        case vipYearlyPrice = "vip_yearly_price"
        case svipMonthlyPrice = "svip_monthly_price"
        case svipQuarterlyPrice = "svip_quarterly_price"
        case svipYearlyPrice = "svip_yearly_price"
        case vipPrivileges = "vip_privileges"
        case svipPrivileges = "svip_privileges"
    }
}

struct MembershipConfigResponse: Codable {
    let config: MembershipConfig
}

// MARK: - OAuth 配置
struct OAuthConfig: Codable {
    var googleClientId: String?
    var googleClientSecret: String?
    var googleEnabled: Bool?
    var googleRedirectUri: String?
    var telegramEnabled: Bool?
    var microsoftClientId: String?
    var microsoftClientSecret: String?
    var microsoftRedirectUri: String?
    var microsoftEnabled: Bool?
    var microsoftTenantId: String?

    enum CodingKeys: String, CodingKey {
        case googleClientId = "google_client_id"
        case googleClientSecret = "google_client_secret"
        case googleEnabled = "google_enabled"
        case googleRedirectUri = "google_redirect_uri"
        case telegramEnabled = "telegram_enabled"
        case microsoftClientId = "microsoft_client_id"
        case microsoftClientSecret = "microsoft_client_secret"
        case microsoftRedirectUri = "microsoft_redirect_uri"
        case microsoftEnabled = "microsoft_enabled"
        case microsoftTenantId = "microsoft_tenant_id"
    }
}

struct OAuthConfigResponse: Codable {
    let config: OAuthConfig
}

// MARK: - 促销活动配置
struct PromotionConfig: Codable {
    var enabled: Bool?
    var title: String?
    var description: String?
    var badgeText: String?
    var buttonText: String?
    var imageUrl: String?
    var linkUrl: String?
    var startTime: String?
    var endTime: String?

    enum CodingKeys: String, CodingKey {
        case enabled, title, description
        case badgeText = "badge_text"
        case buttonText = "button_text"
        case imageUrl = "image_url"
        case linkUrl = "link_url"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct PromotionConfigResponse: Codable {
    let config: PromotionConfig
}

// MARK: - 广告配置
struct AdConfig: Codable {
    var enabled: Bool?
    // 横幅广告
    var bannerUrl: String?
    var bannerLink: String?
    // 弹窗广告
    var popupEnabled: Bool?
    var popupImageUrl: String?
    var popupLink: String?
    var popupInterval: Int?
    // 开屏广告
    var splashEnabled: Bool?
    var splashImageUrl: String?
    var splashLink: String?
    var splashDuration: Int?

    enum CodingKeys: String, CodingKey {
        case enabled
        case bannerUrl = "banner_url"
        case bannerLink = "banner_link"
        case popupEnabled = "popup_enabled"
        case popupImageUrl = "popup_image_url"
        case popupLink = "popup_link"
        case popupInterval = "popup_interval"
        case splashEnabled = "splash_enabled"
        case splashImageUrl = "splash_image_url"
        case splashLink = "splash_link"
        case splashDuration = "splash_duration"
    }
}

struct AdConfigResponse: Codable {
    let config: AdConfig
}

// MARK: - 更新配置请求包装
struct UpdateConfigRequest<T: Codable>: Codable {
    let config: T
}
