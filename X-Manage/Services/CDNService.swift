//
//  CDNService.swift
//  X-Manage
//
//  CDN 代理服务 - 直连 cdn-proxy 管理 API

import Foundation

@MainActor
class CDNService: ObservableObject {
    static let shared = CDNService()

    @Published var baseURL: String = UserDefaults.standard.string(forKey: "cdnProxyBaseURL") ?? ""
    @Published var adminToken: String = UserDefaults.standard.string(forKey: "cdnProxyAdminToken") ?? ""

    private init() {}

    func saveConfig() {
        UserDefaults.standard.set(baseURL, forKey: "cdnProxyBaseURL")
        UserDefaults.standard.set(adminToken, forKey: "cdnProxyAdminToken")
    }

    // MARK: - 私有请求方法

    private func request<T: Decodable>(path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> T {
        guard !baseURL.isEmpty else { throw CDNError.notConfigured }
        guard let url = URL(string: baseURL.trimmingCharacters(in: .init(charactersIn: "/")) + path) else {
            throw CDNError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")

        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw CDNError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "未知错误"
            throw CDNError.serverError(http.statusCode, msg)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestVoid(path: String, method: String = "POST", body: (any Encodable)? = nil) async throws {
        guard !baseURL.isEmpty else { throw CDNError.notConfigured }
        guard let url = URL(string: baseURL.trimmingCharacters(in: .init(charactersIn: "/")) + path) else {
            throw CDNError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")

        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw CDNError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw CDNError.serverError(http.statusCode, "请求失败")
        }
    }

    // MARK: - 缓存管理

    func getCacheStats() async throws -> CDNCacheStats {
        try await request(path: "/admin/cache/stats")
    }

    func evictCache() async throws -> CDNCacheEvictResult {
        try await request(path: "/admin/cache/evict", method: "POST")
    }

    func clearCache() async throws -> CDNCacheClearResult {
        try await request(path: "/admin/cache/clear", method: "POST")
    }

    // MARK: - 反代域名管理

    func listDomains() async throws -> [CDNDomainConfig] {
        try await request(path: "/admin/proxy/domains")
    }

    func addDomain(domain: String, target: String) async throws -> CDNDomainConfig {
        try await request(
            path: "/admin/proxy/domains",
            method: "POST",
            body: CDNDomainRequest(domain: domain, target: target, enabled: true)
        )
    }

    func updateDomain(_ config: CDNDomainConfig) async throws -> CDNDomainConfig {
        try await request(
            path: "/admin/proxy/domains/\(config.domain)",
            method: "PUT",
            body: CDNDomainRequest(domain: config.domain, target: config.target, enabled: config.enabled)
        )
    }

    func deleteDomain(domain: String) async throws {
        try await requestVoid(path: "/admin/proxy/domains/\(domain)", method: "DELETE")
    }
}

// MARK: - 错误类型
enum CDNError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "CDN 代理地址未配置，请在系统设置中配置"
        case .invalidURL: return "无效的 CDN 代理地址"
        case .invalidResponse: return "无效的响应"
        case .serverError(let code, let msg): return "服务器错误 (\(code)): \(msg)"
        }
    }
}
