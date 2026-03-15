//
//  APIClient.swift
//  X-Manage
//
//  网络请求客户端

import Foundation
import os.log

// MARK: - 日志
private let logger = Logger(subsystem: "com.xyouacg.X-Manage", category: "Network")

// MARK: - API 错误类型
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String)
    case unauthorized
    case forbidden
    case notFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .noData:
            return "没有返回数据"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .forbidden:
            return "您没有权限执行此操作"
        case .notFound:
            return "请求的资源不存在"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - RFC 7807 Problem Details
struct ProblemDetails: Codable {
    let detail: String
    let status: Int
    let title: String
    let type: String?
    let instance: String?
}

// MARK: - HTTP 方法
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API 客户端
@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    @Published var baseURL: String = ""

    /// 压缩阈值（字节），超过此大小的请求体会自动压缩
    private let compressionThreshold = 1024

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        // 不使用自动 snake_case 转换，因为模型已有 CodingKeys
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        // 不使用自动 snake_case 转换，因为模型已有 CodingKeys
        self.encoder.dateEncodingStrategy = .iso8601

        // 从 UserDefaults 加载 baseURL
        if let savedURL = UserDefaults.standard.string(forKey: "api_base_url") {
            self.baseURL = savedURL
        }
    }

    func setBaseURL(_ url: String) {
        self.baseURL = url
        UserDefaults.standard.set(url, forKey: "api_base_url")
    }

    // MARK: - 请求方法
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        skipAutoRefresh: Bool = false
    ) async throws -> T {
        let requestId = UUID().uuidString.prefix(8)
        let startTime = CFAbsoluteTimeGetCurrent()

        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            logger.error("[\(requestId)] ❌ Invalid URL: \(self.baseURL)\(endpoint)")
            throw APIError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            logger.error("[\(requestId)] ❌ Invalid URL components")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 添加认证 Token
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 添加请求体（大于阈值时自动 gzip 压缩）
        var bodyString = ""
        if let body = body {
            let bodyData = try encoder.encode(body)
            bodyString = String(data: bodyData, encoding: .utf8) ?? ""

            if bodyData.count > compressionThreshold, let compressedData = bodyData.gzipCompressed() {
                request.httpBody = compressedData
                request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
                let ratio = compressedData.count * 100 / bodyData.count
                logger.debug("[\(requestId)] 🗜️ Compressed: \(bodyData.count) -> \(compressedData.count) bytes (\(ratio)%)")
            } else {
                request.httpBody = bodyData
            }
        }

        // 日志：请求开始
        logger.info("[\(requestId)] ➡️ \(method.rawValue) \(url.absoluteString)")
        if !bodyString.isEmpty {
            logger.debug("[\(requestId)] 📦 Body: \(bodyString)")
        }

        do {
            let (data, response) = try await session.data(for: request)
            let duration = CFAbsoluteTimeGetCurrent() - startTime

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("[\(requestId)] ❌ Invalid response type")
                throw APIError.unknown
            }

            let statusCode = httpResponse.statusCode
            let responseString = String(data: data, encoding: .utf8) ?? "(binary data)"

            // 日志：响应
            if (200...299).contains(statusCode) {
                logger.info("[\(requestId)] ✅ \(statusCode) (\(String(format: "%.2f", duration * 1000))ms)")
                logger.debug("[\(requestId)] 📥 Response: \(responseString)")
            } else {
                logger.warning("[\(requestId)] ⚠️ \(statusCode) (\(String(format: "%.2f", duration * 1000))ms)")
                logger.warning("[\(requestId)] 📥 Response: \(responseString)")
            }

            // 处理状态码
            switch statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    logger.error("[\(requestId)] ❌ Decode error: \(error.localizedDescription)")
                    throw APIError.decodingError(error)
                }
            case 401:
                // 如果已经是刷新 Token 的请求，直接抛出错误，避免无限循环
                if skipAutoRefresh {
                    throw APIError.unauthorized
                }
                logger.warning("[\(requestId)] 🔐 Unauthorized, trying to refresh token...")
                // 尝试刷新 Token
                if await refreshTokenIfNeeded() {
                    logger.info("[\(requestId)] 🔐 Token refreshed, retrying request...")
                    // 重试请求
                    return try await self.request(endpoint: endpoint, method: method, body: body, queryItems: queryItems)
                }
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            default:
                // 尝试解析错误信息
                if let problemDetails = try? decoder.decode(ProblemDetails.self, from: data) {
                    throw APIError.serverError(problemDetails.status, problemDetails.detail)
                }
                throw APIError.serverError(statusCode, "请求失败")
            }
        } catch let error as APIError {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("[\(requestId)] ❌ API Error (\(String(format: "%.2f", duration * 1000))ms): \(error.localizedDescription)")
            throw error
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("[\(requestId)] ❌ Network Error (\(String(format: "%.2f", duration * 1000))ms): \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }

    // MARK: - 无返回值请求
    func requestVoid(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: method, body: body, queryItems: queryItems)
    }

    // MARK: - Token 刷新
    private func refreshTokenIfNeeded() async -> Bool {
        guard let refreshToken = AuthManager.shared.refreshToken else {
            AuthManager.shared.logout()
            return false
        }

        do {
            // 使用 skipAutoRefresh: true 避免刷新请求本身触发无限循环
            let response: LoginResponse = try await request(
                endpoint: APIEndpoints.Auth.refresh,
                method: .post,
                body: RefreshTokenRequest(refreshToken: refreshToken),
                skipAutoRefresh: true
            )
            AuthManager.shared.updateTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? ""
            )
            return true
        } catch {
            AuthManager.shared.logout()
            return false
        }
    }
}

// MARK: - 辅助类型
struct EmptyResponse: Codable {}

struct RefreshTokenRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
