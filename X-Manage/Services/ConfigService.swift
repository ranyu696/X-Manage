//
//  ConfigService.swift
//  X-Manage
//
//  系统配置服务

import Foundation

@MainActor
class ConfigService {
    static let shared = ConfigService()
    private let api = APIClient.shared

    private init() {}

    // MARK: - 站点配置
    func getSiteConfig() async throws -> SiteConfig {
        let response: SiteConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.site
        )
        return response.config
    }

    func updateSiteConfig(_ config: SiteConfig) async throws -> SiteConfig {
        let response: SiteConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.site,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 公告配置
    func getAnnouncementConfig() async throws -> AnnouncementConfig {
        let response: AnnouncementConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.announcement
        )
        return response.config
    }

    func updateAnnouncementConfig(_ config: AnnouncementConfig) async throws -> AnnouncementConfig {
        let response: AnnouncementConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.announcement,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - CDN 配置
    func getCDNConfig() async throws -> CDNConfig {
        let response: CDNConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.cdn
        )
        return response.config
    }

    func updateCDNConfig(_ config: CDNConfig) async throws -> CDNConfig {
        let response: CDNConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.cdn,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 邮箱配置
    func getEmailConfig() async throws -> EmailConfig {
        let response: EmailConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.email
        )
        return response.config
    }

    func updateEmailConfig(_ config: EmailConfig) async throws -> EmailConfig {
        let response: EmailConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.email,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 支付配置
    func getPaymentConfig() async throws -> PaymentConfig {
        let response: PaymentConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.payment
        )
        return response.config
    }

    func updatePaymentConfig(_ config: PaymentConfig) async throws -> PaymentConfig {
        let response: PaymentConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.payment,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - Telegram 配置
    func getTelegramConfig() async throws -> TelegramConfig {
        let response: TelegramConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.telegram
        )
        return response.config
    }

    func updateTelegramConfig(_ config: TelegramConfig) async throws -> TelegramConfig {
        let response: TelegramConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.telegram,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 会员配置
    func getMembershipConfig() async throws -> MembershipConfig {
        let response: MembershipConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.membership
        )
        return response.config
    }

    func updateMembershipConfig(_ config: MembershipConfig) async throws -> MembershipConfig {
        let response: MembershipConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.membership,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - OAuth 配置
    func getOAuthConfig() async throws -> OAuthConfig {
        let response: OAuthConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.oauth
        )
        return response.config
    }

    func updateOAuthConfig(_ config: OAuthConfig) async throws -> OAuthConfig {
        let response: OAuthConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.oauth,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 促销活动配置
    func getPromotionConfig() async throws -> PromotionConfig {
        let response: PromotionConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.promotion
        )
        return response.config
    }

    func updatePromotionConfig(_ config: PromotionConfig) async throws -> PromotionConfig {
        let response: PromotionConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.promotion,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - 广告配置
    func getAdConfig() async throws -> AdConfig {
        let response: AdConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.ad
        )
        return response.config
    }

    func updateAdConfig(_ config: AdConfig) async throws -> AdConfig {
        let response: AdConfigResponse = try await api.request(
            endpoint: APIEndpoints.Configs.ad,
            method: .put,
            body: UpdateConfigRequest(config: config)
        )
        return response.config
    }

    // MARK: - AI 助手 FAQ 知识库
    // FAQ 是一整篇 Markdown，没有字段可拆，所以不套 UpdateConfigRequest
    func getAssistantFAQ() async throws -> String {
        let response: AssistantFAQResponse = try await api.request(
            endpoint: APIEndpoints.Configs.assistantFAQ
        )
        return response.faq
    }

    func updateAssistantFAQ(_ faq: String) async throws {
        let _: AssistantFAQResponse = try await api.request(
            endpoint: APIEndpoints.Configs.assistantFAQ,
            method: .put,
            body: AssistantFAQResponse(faq: faq)
        )
    }
}

// MARK: - AI 助手 FAQ
struct AssistantFAQResponse: Codable {
    let faq: String
}
