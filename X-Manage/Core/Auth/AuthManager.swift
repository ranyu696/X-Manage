//
//  AuthManager.swift
//  X-Manage
//
//  认证管理器

import Foundation
import Security

// MARK: - Keychain 辅助
enum KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - 认证管理器
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    private let service = "com.xyouacg.X-Manage"

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: AdminUser?

    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    private init() {
        loadStoredCredentials()
    }

    // MARK: - 登录
    func login(username: String, password: String) async throws {
        let request = LoginRequest(username: username, password: password)
        let response: LoginResponse = try await APIClient.shared.request(
            endpoint: APIEndpoints.Auth.login,
            method: .post,
            body: request
        )

        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.isAuthenticated = true

        // 如果响应包含用户信息则直接使用，否则单独获取
        if let user = response.user {
            self.currentUser = user
        } else {
            try await fetchCurrentUser()
        }

        saveCredentials()
    }

    // MARK: - 登出
    func logout() {
        self.accessToken = nil
        self.refreshToken = nil
        self.currentUser = nil
        self.isAuthenticated = false

        clearCredentials()
    }

    // MARK: - 更新 Token
    func updateTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveCredentials()
    }

    // MARK: - 获取当前用户信息
    func fetchCurrentUser() async throws {
        let response: AdminUserResponse = try await APIClient.shared.request(
            endpoint: APIEndpoints.Auth.me
        )
        self.currentUser = response.user
    }

    // MARK: - 持久化
    private func saveCredentials() {
        if let token = accessToken, let data = token.data(using: .utf8) {
            KeychainHelper.save(data, service: service, account: "accessToken")
        }
        if let token = refreshToken, let data = token.data(using: .utf8) {
            KeychainHelper.save(data, service: service, account: "refreshToken")
        }
        if let user = currentUser, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }

    private func loadStoredCredentials() {
        if let data = KeychainHelper.read(service: service, account: "accessToken"),
           let token = String(data: data, encoding: .utf8) {
            self.accessToken = token
        }
        if let data = KeychainHelper.read(service: service, account: "refreshToken"),
           let token = String(data: data, encoding: .utf8) {
            self.refreshToken = token
        }
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AdminUser.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    private func clearCredentials() {
        KeychainHelper.delete(service: service, account: "accessToken")
        KeychainHelper.delete(service: service, account: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

// MARK: - 认证相关模型
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?
    let user: AdminUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct AdminUser: Codable, Identifiable {
    let id: Int
    let publicId: String?
    let username: String
    let email: String?
    let nickname: String?
    let role: String
    let status: String
    let avatar: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email, nickname, role, status, avatar
        case publicId = "public_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AdminUserResponse: Codable {
    let user: AdminUser
}
