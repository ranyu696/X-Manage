//
//  LoginView.swift
//  X-Manage
//
//  登录视图

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSettings = false
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .padding()
            }

            Spacer()

            // 登录表单
            VStack(spacing: 24) {
                // Logo 和标题
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("X-Manage")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("ACG 内容管理系统")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)

                // 输入框
                VStack(spacing: 16) {
                    TextField("用户名或邮箱", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .textContentType(.username)
                        .autocorrectionDisabled()

                    // 密码输入框 - 支持显示/隐藏切换
                    HStack(spacing: 8) {
                        Group {
                            if showPassword {
                                TextField("密码", text: $viewModel.password)
                            } else {
                                SecureField("密码", text: $viewModel.password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .onSubmit {
                            Task {
                                await viewModel.login()
                            }
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(showPassword ? "隐藏密码" : "显示密码")
                    }
                    .frame(width: 300)
                }

                // 错误提示
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .frame(maxWidth: 300)
                }

                // 登录按钮
                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading || !viewModel.canLogin)
                .frame(width: 300)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            // 底部版本信息
            Text("v1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showSettings) {
            APISettingsView()
        }
    }
}

// MARK: - API 设置视图
struct APISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var baseURL: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("API 设置")
                .font(.headline)

            TextField("API 基础地址", text: $baseURL)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)

            Text("例如: https://api.example.com")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("保存") {
                    Task { @MainActor in
                        APIClient.shared.setBaseURL(baseURL)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(baseURL.isEmpty)
            }
        }
        .padding(40)
        .frame(width: 500, height: 200)
        .onAppear {
            Task { @MainActor in
                baseURL = APIClient.shared.baseURL
            }
        }
    }
}

// MARK: - 登录视图模型
@MainActor
class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }

    func login() async {
        guard canLogin else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await AuthManager.shared.login(username: username, password: password)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
}
