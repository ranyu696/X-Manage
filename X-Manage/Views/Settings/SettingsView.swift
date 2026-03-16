//
//  SettingsView.swift
//  X-Manage
//
//  系统设置视图

import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var cdnService = CDNService.shared
    @State private var baseURL = ""
    @State private var geminiApiKey = ""
    @State private var showingLogoutAlert = false
    @AppStorage("geminiApiKey") private var savedGeminiApiKey = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 账户信息
                GroupBox("账户信息") {
                    VStack(alignment: .leading, spacing: 16) {
                        if let user = authManager.currentUser {
                            HStack(spacing: 16) {
                                // 头像
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                    Text(String(user.username.prefix(1)).uppercased())
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }
                                .frame(width: 60, height: 60)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.title2)
                                        .fontWeight(.semibold)

                                    Text(user.email ?? "")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        Text(user.role)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())

                                        Text(user.status)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.1))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    }
                                }

                                Spacer()
                            }
                        } else {
                            Text("未登录")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingLogoutAlert = true
                        } label: {
                            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }

                // API 设置
                GroupBox("API 设置") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API 基础地址")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("https://api.example.com", text: $baseURL)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("保存") {
                                Task { @MainActor in
                                    APIClient.shared.setBaseURL(baseURL)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(baseURL.isEmpty)

                            Button("测试连接") {
                                // TODO: 测试 API 连接
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }

                // CDN 代理设置
                GroupBox("CDN 代理设置") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CDN 代理地址")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("http://cdn.example.com", text: $cdnService.baseURL)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Admin Token")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SecureField("管理员 Token", text: $cdnService.adminToken)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button("保存") {
                            cdnService.saveConfig()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cdnService.baseURL.isEmpty)
                    }
                    .padding()
                }

                // AI 设置
                GroupBox("AI 设置") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gemini API Key")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            SecureField("输入 Gemini API Key", text: $geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("保存") {
                                savedGeminiApiKey = geminiApiKey
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(geminiApiKey.isEmpty)

                            if !savedGeminiApiKey.isEmpty {
                                Text("已配置")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding()
                }

                // 关于
                GroupBox("关于") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("应用名称")
                            Spacer()
                            Text("X-Manage")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            Text("平台")
                            Spacer()
                            Text("macOS")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            Text("开发框架")
                            Spacer()
                            Text("SwiftUI + Swift")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            Task { @MainActor in
                baseURL = APIClient.shared.baseURL
            }
            if !savedGeminiApiKey.isEmpty {
                geminiApiKey = savedGeminiApiKey
            }
        }
        .alert("确认退出", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}

#Preview {
    SettingsView()
}
