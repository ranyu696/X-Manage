//
//  SystemConfigView.swift
//  X-Manage
//
//  系统配置视图

import SwiftUI

struct SystemConfigView: View {
    var body: some View {
        TabView {
            SiteConfigView()
                .tabItem {
                    Label("站点配置", systemImage: "globe")
                }

            CDNConfigView()
                .tabItem {
                    Label("CDN配置", systemImage: "server.rack")
                }

            PaymentConfigView()
                .tabItem {
                    Label("支付配置", systemImage: "creditcard")
                }

            MembershipConfigView()
                .tabItem {
                    Label("会员配置", systemImage: "crown")
                }

            EmailConfigView()
                .tabItem {
                    Label("邮箱配置", systemImage: "envelope")
                }

            TelegramConfigView()
                .tabItem {
                    Label("Telegram", systemImage: "paperplane")
                }

            OAuthConfigView()
                .tabItem {
                    Label("OAuth", systemImage: "person.badge.key")
                }

            AnnouncementConfigView()
                .tabItem {
                    Label("公告", systemImage: "megaphone")
                }

            PromotionConfigView()
                .tabItem {
                    Label("促销活动", systemImage: "tag")
                }

            AdConfigView()
                .tabItem {
                    Label("广告配置", systemImage: "rectangle.on.rectangle")
                }
        }
    }
}

// MARK: - 站点配置视图
struct SiteConfigView: View {
    @StateObject private var viewModel = SiteConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("基本信息") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "站点标题", text: $viewModel.config.title.bound)
                        ConfigTextField(label: "站点域名", text: $viewModel.config.domain.bound)
                        ConfigTextField(label: "站点描述", text: $viewModel.config.description.bound)
                        ConfigTextField(label: "关键词", text: $viewModel.config.keywords.bound)
                    }
                    .padding()
                }

                GroupBox("资源配置") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "Logo URL", text: $viewModel.config.logo.bound)
                        ConfigTextField(label: "Favicon URL", text: $viewModel.config.favicon.bound)
                        ConfigTextField(label: "永久页面", text: $viewModel.config.permanentPage.bound)
                    }
                    .padding()
                }

                GroupBox("联系方式") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "邮箱", text: $viewModel.config.email.bound)
                        ConfigTextField(label: "Telegram", text: $viewModel.config.telegram.bound)
                        ConfigTextField(label: "TG群组", text: $viewModel.config.tgGroup.bound)
                    }
                    .padding()
                }

                GroupBox("页脚") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "页脚内容", text: $viewModel.config.footer.bound)
                    }
                    .padding()
                }

                GroupBox("网站列表") {
                    ConfigStringArrayEditor(items: $viewModel.config.websites.bound)
                        .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - CDN 配置视图
struct CDNConfigView: View {
    @StateObject private var viewModel = CDNConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("CDN 域名配置") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "全局域名", text: $viewModel.config.globalDomain.bound)
                        ConfigTextField(label: "漫画域名", text: $viewModel.config.comicDomain.bound)
                        ConfigTextField(label: "小说域名", text: $viewModel.config.novelDomain.bound)
                        ConfigTextField(label: "游戏域名", text: $viewModel.config.gameDomain.bound)
                        ConfigTextField(label: "动漫域名", text: $viewModel.config.animeDomain.bound)
                        ConfigTextField(label: "工单域名", text: $viewModel.config.ticketDomain.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 支付配置视图
struct PaymentConfigView: View {
    @StateObject private var viewModel = PaymentConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 支付宝配置
                GroupBox("支付宝配置") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用支付宝", isOn: $viewModel.config.alipayEnabled.bound)
                        ConfigTextField(label: "网关地址", text: $viewModel.config.alipayGateway.bound)
                        ConfigTextField(label: "商户ID", text: $viewModel.config.alipayPid.bound)
                        ConfigSecureField(label: "密钥", text: $viewModel.config.alipaySecret.bound)
                        ConfigTextField(label: "Web回调", text: $viewModel.config.alipayNotifyWeb.bound)
                        ConfigTextField(label: "移动端回调", text: $viewModel.config.alipayNotifyMobile.bound)
                        ConfigTextField(label: "PC回调", text: $viewModel.config.alipayNotifyPc.bound)
                    }
                    .padding()
                }

                // 支付宝2配置
                GroupBox("支付宝2配置（备用通道）") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用支付宝2", isOn: $viewModel.config.alipay2Enabled.bound)
                        ConfigTextField(label: "网关地址", text: $viewModel.config.alipay2Gateway.bound)
                        ConfigTextField(label: "商户ID", text: $viewModel.config.alipay2Pid.bound)
                        ConfigSecureField(label: "密钥", text: $viewModel.config.alipay2Secret.bound)
                        ConfigTextField(label: "渠道", text: $viewModel.config.alipay2Channel.bound)
                        ConfigTextField(label: "Web回调", text: $viewModel.config.alipay2NotifyWeb.bound)
                        ConfigTextField(label: "移动端回调", text: $viewModel.config.alipay2NotifyMobile.bound)
                        ConfigTextField(label: "PC回调", text: $viewModel.config.alipay2NotifyPc.bound)
                    }
                    .padding()
                }

                // 微信支付配置
                GroupBox("微信支付配置") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用微信支付", isOn: $viewModel.config.wxpayEnabled.bound)
                        ConfigTextField(label: "网关地址", text: $viewModel.config.wxpayGateway.bound)
                        ConfigTextField(label: "商户ID", text: $viewModel.config.wxpayPid.bound)
                        ConfigSecureField(label: "密钥", text: $viewModel.config.wxpaySecret.bound)
                        ConfigTextField(label: "Web回调", text: $viewModel.config.wxpayNotifyWeb.bound)
                        ConfigTextField(label: "移动端回调", text: $viewModel.config.wxpayNotifyMobile.bound)
                        ConfigTextField(label: "PC回调", text: $viewModel.config.wxpayNotifyPc.bound)
                    }
                    .padding()
                }

                // 微信支付2配置
                GroupBox("微信支付2配置（备用通道）") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用微信支付2", isOn: $viewModel.config.wxpay2Enabled.bound)
                        ConfigTextField(label: "网关地址", text: $viewModel.config.wxpay2Gateway.bound)
                        ConfigTextField(label: "商户ID", text: $viewModel.config.wxpay2Pid.bound)
                        ConfigSecureField(label: "密钥", text: $viewModel.config.wxpay2Secret.bound)
                        ConfigTextField(label: "渠道", text: $viewModel.config.wxpay2Channel.bound)
                        ConfigTextField(label: "Web回调", text: $viewModel.config.wxpay2NotifyWeb.bound)
                        ConfigTextField(label: "移动端回调", text: $viewModel.config.wxpay2NotifyMobile.bound)
                        ConfigTextField(label: "PC回调", text: $viewModel.config.wxpay2NotifyPc.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 会员配置视图
struct MembershipConfigView: View {
    @StateObject private var viewModel = MembershipConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("VIP 价格") {
                    VStack(spacing: 12) {
                        ConfigNumberField(label: "月费", value: $viewModel.config.vipMonthlyPrice.bound)
                        ConfigNumberField(label: "季费", value: $viewModel.config.vipQuarterlyPrice.bound)
                        ConfigNumberField(label: "年费", value: $viewModel.config.vipYearlyPrice.bound)
                    }
                    .padding()
                }

                GroupBox("VIP 特权") {
                    ConfigStringArrayEditor(items: $viewModel.config.vipPrivileges.bound)
                        .padding()
                }

                GroupBox("SVIP 价格") {
                    VStack(spacing: 12) {
                        ConfigNumberField(label: "月费", value: $viewModel.config.svipMonthlyPrice.bound)
                        ConfigNumberField(label: "季费", value: $viewModel.config.svipQuarterlyPrice.bound)
                        ConfigNumberField(label: "年费", value: $viewModel.config.svipYearlyPrice.bound)
                    }
                    .padding()
                }

                GroupBox("SVIP 特权") {
                    ConfigStringArrayEditor(items: $viewModel.config.svipPrivileges.bound)
                        .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 邮箱配置视图
struct EmailConfigView: View {
    @StateObject private var viewModel = EmailConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("SMTP 配置") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "SMTP 主机", text: $viewModel.config.host.bound)
                        ConfigIntField(label: "端口", value: $viewModel.config.port.bound)
                        ConfigTextField(label: "用户名", text: $viewModel.config.user.bound)
                        ConfigSecureField(label: "密码", text: $viewModel.config.password.bound)
                    }
                    .padding()
                }

                GroupBox("发件人配置") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "发件人名称", text: $viewModel.config.from.bound)
                        ConfigTextField(label: "发件人地址", text: $viewModel.config.fromAddr.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - Telegram 配置视图
struct TelegramConfigView: View {
    @StateObject private var viewModel = TelegramConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("Telegram Bot 配置") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用", isOn: $viewModel.config.enabled.bound)
                        ConfigSecureField(label: "Bot Token", text: $viewModel.config.token.bound)
                        ConfigTextField(label: "Webhook URL", text: $viewModel.config.webhookUrl.bound)
                    }
                    .padding()
                }

                GroupBox("管理员配置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("管理员ID列表")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ConfigIntArrayEditor(items: $viewModel.config.adminIds.bound)
                    }
                    .padding()
                }

                GroupBox("群组配置") {
                    VStack(spacing: 12) {
                        ConfigInt64Field(label: "管理群ID", value: $viewModel.config.groupId.boundInt64)
                        ConfigInt64Field(label: "公开群ID", value: $viewModel.config.publicGroup.boundInt64)
                    }
                    .padding()
                }

                GroupBox("其他设置") {
                    VStack(spacing: 12) {
                        ConfigIntField(label: "最大图片数", value: $viewModel.config.maxImages.bound)
                        ConfigTextField(label: "解析模式", text: $viewModel.config.parseMode.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - OAuth 配置视图
struct OAuthConfigView: View {
    @StateObject private var viewModel = OAuthConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("Google OAuth") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用", isOn: $viewModel.config.googleEnabled.bound)
                        ConfigTextField(label: "Client ID", text: $viewModel.config.googleClientId.bound)
                        ConfigSecureField(label: "Client Secret", text: $viewModel.config.googleClientSecret.bound)
                        ConfigTextField(label: "Redirect URI", text: $viewModel.config.googleRedirectUri.bound)
                    }
                    .padding()
                }

                GroupBox("Microsoft OAuth") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用", isOn: $viewModel.config.microsoftEnabled.bound)
                        ConfigTextField(label: "Client ID", text: $viewModel.config.microsoftClientId.bound)
                        ConfigSecureField(label: "Client Secret", text: $viewModel.config.microsoftClientSecret.bound)
                        ConfigTextField(label: "Redirect URI", text: $viewModel.config.microsoftRedirectUri.bound)
                        ConfigTextField(label: "Tenant ID", text: $viewModel.config.microsoftTenantId.bound)
                    }
                    .padding()
                }

                GroupBox("Telegram OAuth") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用Telegram登录", isOn: $viewModel.config.telegramEnabled.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 公告配置视图
struct AnnouncementConfigView: View {
    @StateObject private var viewModel = AnnouncementConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("公告设置") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用公告", isOn: $viewModel.config.enabled.bound)
                        ConfigTextField(label: "公告标题", text: $viewModel.config.title.bound)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("公告内容")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $viewModel.config.content.bound)
                                .frame(minHeight: 150)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 促销活动配置视图
struct PromotionConfigView: View {
    @StateObject private var viewModel = PromotionConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("基本设置") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用促销", isOn: $viewModel.config.enabled.bound)
                        ConfigTextField(label: "活动标题", text: $viewModel.config.title.bound)
                        ConfigTextField(label: "徽章文字", text: $viewModel.config.badgeText.bound)
                        ConfigTextField(label: "按钮文字", text: $viewModel.config.buttonText.bound)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("活动描述")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $viewModel.config.description.bound)
                                .frame(minHeight: 100)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }

                GroupBox("资源配置") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "活动图片URL", text: $viewModel.config.imageUrl.bound)
                        ConfigTextField(label: "跳转链接", text: $viewModel.config.linkUrl.bound)
                    }
                    .padding()
                }

                GroupBox("时间范围") {
                    VStack(spacing: 12) {
                        ConfigDateTimePicker(label: "开始时间", dateString: $viewModel.config.startTime.bound)
                        ConfigDateTimePicker(label: "结束时间", dateString: $viewModel.config.endTime.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 广告配置视图
struct AdConfigView: View {
    @StateObject private var viewModel = AdConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("总开关") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用广告", isOn: $viewModel.config.enabled.bound)
                    }
                    .padding()
                }

                GroupBox("横幅广告") {
                    VStack(spacing: 12) {
                        ConfigTextField(label: "图片URL", text: $viewModel.config.bannerUrl.bound)
                        ConfigTextField(label: "跳转链接", text: $viewModel.config.bannerLink.bound)
                    }
                    .padding()
                }

                GroupBox("弹窗广告") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用弹窗", isOn: $viewModel.config.popupEnabled.bound)
                        ConfigTextField(label: "图片URL", text: $viewModel.config.popupImageUrl.bound)
                        ConfigTextField(label: "跳转链接", text: $viewModel.config.popupLink.bound)
                        ConfigIntField(label: "弹出间隔(秒)", value: $viewModel.config.popupInterval.bound)
                    }
                    .padding()
                }

                GroupBox("开屏广告") {
                    VStack(spacing: 12) {
                        ConfigToggle(label: "启用开屏", isOn: $viewModel.config.splashEnabled.bound)
                        ConfigTextField(label: "图片URL", text: $viewModel.config.splashImageUrl.bound)
                        ConfigTextField(label: "跳转链接", text: $viewModel.config.splashLink.bound)
                        ConfigIntField(label: "展示时长(秒)", value: $viewModel.config.splashDuration.bound)
                    }
                    .padding()
                }

                configActionButtons(
                    isLoading: viewModel.isLoading,
                    isSaving: viewModel.isSaving,
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onRefresh: { Task { await viewModel.loadConfig() } },
                    onSave: { Task { await viewModel.saveConfig() } }
                )
            }
            .padding()
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}

// MARK: - 通用配置输入组件
struct ConfigTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct ConfigSecureField: View {
    let label: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            if showPassword {
                TextField(label, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(label, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
        }
    }
}

struct ConfigToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            Toggle("", isOn: $isOn)
                .labelsHidden()
            Spacer()
        }
    }
}

struct ConfigNumberField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            TextField(label, value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct ConfigIntField: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            TextField(label, value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct ConfigDateTimePicker: View {
    let label: String
    @Binding var dateString: String

    @State private var date: Date = Date()
    @State private var isInitialized = false

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .onChange(of: date) { _, newValue in
                if isInitialized {
                    dateString = Self.iso8601Formatter.string(from: newValue)
                }
            }

            Spacer()
        }
        .onAppear {
            if !dateString.isEmpty, let parsed = Self.iso8601Formatter.date(from: dateString) {
                date = parsed
            }
            isInitialized = true
        }
        .onChange(of: dateString) { _, newValue in
            if !newValue.isEmpty, let parsed = Self.iso8601Formatter.date(from: newValue) {
                date = parsed
            }
        }
    }
}

struct ConfigStringArrayEditor: View {
    @Binding var items: [String]
    @State private var newItem = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField("特权项", text: $items[index])
                        .textFieldStyle(.roundedBorder)
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                TextField("添加新特权", text: $newItem)
                    .textFieldStyle(.roundedBorder)
                Button {
                    if !newItem.isEmpty {
                        items.append(newItem)
                        newItem = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
                .disabled(newItem.isEmpty)
            }
        }
    }
}

struct ConfigIntArrayEditor: View {
    @Binding var items: [Int]
    @State private var newItemText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField("管理员ID", text: Binding(
                        get: { String(items[index]) },
                        set: { if let value = Int($0) { items[index] = value } }
                    ))
                    .textFieldStyle(.roundedBorder)
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                TextField("添加管理员ID", text: $newItemText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    if let value = Int(newItemText) {
                        items.append(value)
                        newItemText = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
                .disabled(Int(newItemText) == nil)
            }
        }
    }
}

struct ConfigInt64Field: View {
    let label: String
    @Binding var value: Int64

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundStyle(.secondary)
            TextField(label, text: Binding(
                get: { value == 0 ? "" : String(value) },
                set: { value = Int64($0) ?? 0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - 通用操作按钮
@ViewBuilder
private func configActionButtons(
    isLoading: Bool,
    isSaving: Bool,
    errorMessage: String?,
    successMessage: String?,
    onRefresh: @escaping () -> Void,
    onSave: @escaping () -> Void
) -> some View {
    VStack(spacing: 12) {
        if let error = errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }

        if let success = successMessage {
            Text(success)
                .font(.caption)
                .foregroundStyle(.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }

        HStack {
            Spacer()
            Button {
                onRefresh()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            Button {
                onSave()
            } label: {
                Label("保存", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
    }
}

// MARK: - Optional 扩展
extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}

extension Optional where Wrapped == Bool {
    var bound: Bool {
        get { self ?? false }
        set { self = newValue }
    }
}

extension Optional where Wrapped == Int {
    var bound: Int {
        get { self ?? 0 }
        set { self = newValue }
    }
}

extension Optional where Wrapped == Double {
    var bound: Double {
        get { self ?? 0 }
        set { self = newValue }
    }
}

extension Optional where Wrapped == [String] {
    var bound: [String] {
        get { self ?? [] }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}

extension Optional where Wrapped == [Int] {
    var bound: [Int] {
        get { self ?? [] }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}

extension Optional where Wrapped == Int {
    var boundInt64: Int64 {
        get { Int64(self ?? 0) }
        set { self = Int(newValue) }
    }
}

// MARK: - ViewModels
@MainActor
class SiteConfigViewModel: ObservableObject {
    @Published var config = SiteConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getSiteConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateSiteConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class CDNConfigViewModel: ObservableObject {
    @Published var config = CDNConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getCDNConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateCDNConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class PaymentConfigViewModel: ObservableObject {
    @Published var config = PaymentConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getPaymentConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updatePaymentConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class MembershipConfigViewModel: ObservableObject {
    @Published var config = MembershipConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getMembershipConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateMembershipConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class EmailConfigViewModel: ObservableObject {
    @Published var config = EmailConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getEmailConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateEmailConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class TelegramConfigViewModel: ObservableObject {
    @Published var config = TelegramConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getTelegramConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateTelegramConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class OAuthConfigViewModel: ObservableObject {
    @Published var config = OAuthConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getOAuthConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateOAuthConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class AnnouncementConfigViewModel: ObservableObject {
    @Published var config = AnnouncementConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getAnnouncementConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateAnnouncementConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class PromotionConfigViewModel: ObservableObject {
    @Published var config = PromotionConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getPromotionConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updatePromotionConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

@MainActor
class AdConfigViewModel: ObservableObject {
    @Published var config = AdConfig()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = ConfigService.shared

    func loadConfig() async {
        isLoading = true
        clearMessages()
        do {
            config = try await service.getAdConfig()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveConfig() async {
        isSaving = true
        clearMessages()
        do {
            config = try await service.updateAdConfig(config)
            successMessage = "保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

#Preview {
    SystemConfigView()
}
