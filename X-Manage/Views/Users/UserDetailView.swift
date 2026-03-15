//
//  UserDetailView.swift
//  X-Manage
//
//  用户详情视图

import SwiftUI

struct UserDetailView: View {
    let user: User
    @StateObject private var viewModel: UserDetailViewModel
    @Environment(\.dismiss) private var dismiss

    // 弹窗状态
    @State private var showUpgradeSheet = false
    @State private var showRenewSheet = false
    @State private var showBalanceSheet = false
    @State private var showBanConfirm = false
    @State private var showCancelVipConfirm = false

    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: UserDetailViewModel(user: user))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            Divider()

            // 主体内容 - 左侧双列内容 + 右侧操作栏
            HStack(spacing: 0) {
                // 左侧内容区（双列）
                HStack(spacing: 0) {
                    // 第一列：基本信息 + 消费/支付记录
                    leftContentColumn
                        .frame(minWidth: 320)

                    Divider()

                    // 第二列：评论管理
                    rightContentColumn
                        .frame(minWidth: 350)
                }

                Divider()

                // 右侧操作栏
                operationSidebar
                    .frame(width: 220)
            }
        }
        .frame(minWidth: 1000, minHeight: 650)
        .frame(idealWidth: 1100, idealHeight: 750)
        .task {
            await viewModel.loadUserDetail()
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeVIPSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showRenewSheet) {
            RenewVIPSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showBalanceSheet) {
            BalanceOperationSheet(viewModel: viewModel)
        }
        .alert("确认封禁", isPresented: $showBanConfirm) {
            Button("取消", role: .cancel) { }
            Button("封禁", role: .destructive) {
                Task { await viewModel.banUser() }
            }
        } message: {
            Text("确定要封禁用户 \(viewModel.currentUser.username) 吗？封禁后该用户将无法登录。")
        }
        .alert("确认取消 VIP", isPresented: $showCancelVipConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                Task { await viewModel.cancelVip() }
            }
        } message: {
            Text("确定要取消用户 \(viewModel.currentUser.username) 的 VIP 权限吗？")
        }
    }

    // MARK: - 标题栏
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(viewModel.currentUser.username)
                        .font(.headline)
                    RoleBadge(role: viewModel.currentUser.role)
                    UserStatusBadge(status: viewModel.currentUser.status)
                }
                Text("ID: \(String(viewModel.currentUser.id)) | \(viewModel.currentUser.publicId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - 左侧内容列（基本信息 + 消费/支付记录）
    private var leftContentColumn: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 用户头像和基本信息
                userHeaderCard

                // 账户信息
                accountInfoSection

                // VIP 信息
                vipInfoSection

                // 消费记录
                userOrdersSection

                // 支付记录
                userPaymentsSection

                // 登录信息
                loginInfoSection

                // 注册信息
                registerInfoSection

                // 绑定信息
                bindingInfoSection

                // 推送设置
                pushSettingsSection
            }
            .padding()
        }
    }

    // MARK: - 右侧内容列（评论管理）
    private var rightContentColumn: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 用户评论
                userCommentsSection
            }
            .padding()
        }
    }

    // MARK: - 右侧操作栏
    private var operationSidebar: some View {
        ScrollView {
            VStack(spacing: 12) {
                // VIP 操作
                GroupBox("VIP 操作") {
                    VStack(spacing: 6) {
                        Button {
                            showUpgradeSheet = true
                        } label: {
                            Label("升级 VIP", systemImage: "crown")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        if viewModel.currentUser.isVip == true {
                            Button {
                                showRenewSheet = true
                            } label: {
                                Label("续费", systemImage: "arrow.clockwise")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button {
                                showCancelVipConfirm = true
                            } label: {
                                Label("取消", systemImage: "xmark.circle")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundStyle(.red)
                        }
                    }
                }

                // 余额操作
                GroupBox("余额操作") {
                    VStack(spacing: 6) {
                        Button {
                            viewModel.balanceOperationType = .add
                            showBalanceSheet = true
                        } label: {
                            Label("增加", systemImage: "plus.circle")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.green)

                        Button {
                            viewModel.balanceOperationType = .deduct
                            showBalanceSheet = true
                        } label: {
                            Label("扣减", systemImage: "minus.circle")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // 账户操作
                GroupBox("账户操作") {
                    if viewModel.currentUser.isBanned {
                        Button {
                            Task { await viewModel.unbanUser() }
                        } label: {
                            Label("解除封禁", systemImage: "lock.open")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.green)
                    } else {
                        Button {
                            showBanConfirm = true
                        } label: {
                            Label("封禁用户", systemImage: "lock")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }

                // 快捷复制
                GroupBox("快捷复制") {
                    VStack(spacing: 6) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(String(viewModel.currentUser.id), forType: .string)
                        } label: {
                            Label("用户ID", systemImage: "doc.on.doc")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(viewModel.currentUser.publicId, forType: .string)
                        } label: {
                            Label("公开ID", systemImage: "doc.on.doc")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        if let email = viewModel.currentUser.email {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(email, forType: .string)
                            } label: {
                                Label("邮箱", systemImage: "doc.on.doc")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                Spacer()

                // 消息提示
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if let success = viewModel.successMessage {
                    Text(success)
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(12)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - 用户头像卡片
    private var userHeaderCard: some View {
        HStack(spacing: 16) {
            // 头像
            UserAvatarView(
                username: viewModel.currentUser.username,
                role: viewModel.currentUser.role,
                avatar: viewModel.currentUser.avatar,
                size: 80
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.currentUser.username)
                    .font(.title2)
                    .fontWeight(.bold)

                if let email = viewModel.currentUser.email {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                            .font(.caption)
                        Text(email)
                            .font(.subheadline)
                        if viewModel.currentUser.emailVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    RoleBadge(role: viewModel.currentUser.role)
                    UserStatusBadge(status: viewModel.currentUser.status)
                }
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var roleGradient: LinearGradient {
        let colors: [Color] = {
            switch viewModel.currentUser.role {
            case "SVIP": return [.purple, .pink]
            case "VIP": return [.orange, .yellow]
            case "ADMIN", "SUPER_ADMIN": return [.blue, .cyan]
            default: return [.gray, .gray.opacity(0.7)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - 账户信息
    private var accountInfoSection: some View {
        GroupBox("账户信息") {
            VStack(spacing: 0) {
                InfoRow(title: "用户ID", value: String(viewModel.currentUser.id))
                Divider()
                InfoRow(title: "公开ID", value: viewModel.currentUser.publicId)
                Divider()
                HStack {
                    Text("余额")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("¥\(viewModel.currentUser.balance ?? "0.00")")
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - VIP 信息
    private var vipInfoSection: some View {
        GroupBox("VIP 信息") {
            VStack(spacing: 0) {
                HStack {
                    Text("当前等级")
                        .foregroundStyle(.secondary)
                    Spacer()
                    RoleBadge(role: viewModel.currentUser.role)
                }
                .padding(.vertical, 8)

                if viewModel.currentUser.isVipRole {
                    Divider()
                    if let startAt = viewModel.currentUser.vipStartAt {
                        InfoRow(title: "开通时间", value: formatDateTime(startAt))
                        Divider()
                    }
                    if let expireAt = viewModel.currentUser.vipExpireAt {
                        HStack {
                            Text("到期时间")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatDateTime(expireAt))
                                .foregroundStyle(isExpiringSoon(expireAt) ? .orange : .primary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    // MARK: - 消费记录
    private var userOrdersSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 标题和刷新按钮
                HStack {
                    Text("消费记录")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await viewModel.refreshCurrentOrders() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.isLoadingOrders)
                }

                // 订单类型 Tabs
                HStack(spacing: 0) {
                    ForEach(UserOrderType.allCases, id: \.self) { type in
                        Button {
                            viewModel.switchOrderType(type)
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                    Text(type.displayName)
                                        .font(.subheadline)
                                }
                                .foregroundStyle(viewModel.currentOrderType == type ? .primary : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)

                                Rectangle()
                                    .fill(viewModel.currentOrderType == type ? Color.accentColor : .clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                Divider()

                // 订单列表
                if viewModel.isLoadingOrders {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else {
                    switch viewModel.currentOrderType {
                    case .game:
                        gameOrdersView
                    case .comic:
                        comicOrdersView
                    case .novel:
                        novelOrdersView
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 游戏订单视图
    private var gameOrdersView: some View {
        VStack(spacing: 0) {
            if viewModel.gameOrders.isEmpty {
                emptyOrdersView
            } else {
                ForEach(viewModel.gameOrders) { order in
                    UserGameOrderRow(order: order)
                    Divider()
                }
                orderPaginationView
            }
        }
    }

    // MARK: - 漫画订单视图
    private var comicOrdersView: some View {
        VStack(spacing: 0) {
            if viewModel.comicOrders.isEmpty {
                emptyOrdersView
            } else {
                ForEach(viewModel.comicOrders) { order in
                    UserComicOrderRow(order: order)
                    Divider()
                }
                orderPaginationView
            }
        }
    }

    // MARK: - 小说订单视图
    private var novelOrdersView: some View {
        VStack(spacing: 0) {
            if viewModel.novelOrders.isEmpty {
                emptyOrdersView
            } else {
                ForEach(viewModel.novelOrders) { order in
                    UserNovelOrderRow(order: order)
                    Divider()
                }
                orderPaginationView
            }
        }
    }

    // MARK: - 空订单提示
    private var emptyOrdersView: some View {
        HStack {
            Spacer()
            Text("暂无消费记录")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - 订单分页
    private var orderPaginationView: some View {
        Group {
            if viewModel.orderTotalPages > 1 {
                HStack {
                    Spacer()
                    PaginationView(
                        currentPage: viewModel.orderCurrentPage,
                        totalPages: viewModel.orderTotalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadOrdersForCurrentType(page: page) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - 支付记录
    private var userPaymentsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 标题和刷新按钮
                HStack {
                    Text("支付记录")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await viewModel.loadUserPayments() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.isLoadingPayments)
                }

                // 状态筛选
                HStack {
                    Text("状态:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $viewModel.paymentStatusFilter) {
                        Text("全部").tag(String?.none)
                        Text("待支付").tag(String?.some("PENDING"))
                        Text("已支付").tag(String?.some("PAID"))
                        Text("超时").tag(String?.some("TIMEOUT"))
                        Text("失败").tag(String?.some("FAILED"))
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.paymentStatusFilter) { _, _ in
                        Task { await viewModel.loadUserPayments() }
                    }
                }

                Divider()

                // 支付列表
                if viewModel.isLoadingPayments {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if viewModel.userPayments.isEmpty {
                    HStack {
                        Spacer()
                        Text("暂无支付记录")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                } else {
                    ForEach(viewModel.userPayments) { payment in
                        UserPaymentRow(payment: payment)
                        Divider()
                    }

                    // 分页
                    if viewModel.paymentTotalPages > 1 {
                        HStack {
                            Spacer()
                            PaginationView(
                                currentPage: viewModel.paymentCurrentPage,
                                totalPages: viewModel.paymentTotalPages,
                                onPageChange: { page in
                                    Task { await viewModel.loadUserPayments(page: page) }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 用户评论
    private var userCommentsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 标题和刷新按钮
                HStack {
                    Text("用户评论")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await viewModel.refreshCurrentComments() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.isLoadingComments)
                }

                // 评论类型 Tabs
                HStack(spacing: 0) {
                    ForEach(UserCommentType.allCases, id: \.self) { type in
                        Button {
                            viewModel.switchCommentType(type)
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                    Text(type.displayName)
                                        .font(.subheadline)
                                }
                                .foregroundStyle(viewModel.currentCommentType == type ? .primary : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)

                                Rectangle()
                                    .fill(viewModel.currentCommentType == type ? Color.accentColor : .clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                // 状态筛选
                HStack {
                    Text("状态:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $viewModel.commentStatusFilter) {
                        Text("全部").tag(String?.none)
                        Text("待审核").tag(String?.some("PENDING"))
                        Text("已通过").tag(String?.some("APPROVED"))
                        Text("已拒绝").tag(String?.some("REJECTED"))
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.commentStatusFilter) { _, _ in
                        Task { await viewModel.refreshCurrentComments() }
                    }
                }

                Divider()

                // 评论列表
                if viewModel.isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else {
                    switch viewModel.currentCommentType {
                    case .game:
                        gameCommentsView
                    case .comic:
                        comicCommentsView
                    case .novel:
                        novelCommentsView
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 游戏评论视图
    private var gameCommentsView: some View {
        VStack(spacing: 0) {
            if viewModel.gameComments.isEmpty {
                emptyCommentsView
            } else {
                ForEach(viewModel.gameComments) { comment in
                    UserGameCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveGameComment(comment) },
                        onReject: { viewModel.rejectGameComment(comment) },
                        onDelete: { viewModel.deleteGameComment(comment) }
                    )
                    Divider()
                }
                commentPaginationView
            }
        }
    }

    // MARK: - 漫画评论视图
    private var comicCommentsView: some View {
        VStack(spacing: 0) {
            if viewModel.comicComments.isEmpty {
                emptyCommentsView
            } else {
                ForEach(viewModel.comicComments) { comment in
                    UserComicCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveComicComment(comment) },
                        onReject: { viewModel.rejectComicComment(comment) },
                        onDelete: { viewModel.deleteComicComment(comment) }
                    )
                    Divider()
                }
                commentPaginationView
            }
        }
    }

    // MARK: - 小说评论视图
    private var novelCommentsView: some View {
        VStack(spacing: 0) {
            if viewModel.novelComments.isEmpty {
                emptyCommentsView
            } else {
                ForEach(viewModel.novelComments) { comment in
                    UserNovelCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveNovelComment(comment) },
                        onReject: { viewModel.rejectNovelComment(comment) },
                        onDelete: { viewModel.deleteNovelComment(comment) }
                    )
                    Divider()
                }
                commentPaginationView
            }
        }
    }

    // MARK: - 空评论提示
    private var emptyCommentsView: some View {
        HStack {
            Spacer()
            Text("暂无评论")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - 评论分页
    private var commentPaginationView: some View {
        Group {
            if viewModel.commentTotalPages > 1 {
                HStack {
                    Spacer()
                    PaginationView(
                        currentPage: viewModel.commentCurrentPage,
                        totalPages: viewModel.commentTotalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadCommentsForCurrentType(page: page) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - 登录信息
    private var loginInfoSection: some View {
        GroupBox("最后登录") {
            VStack(spacing: 0) {
                if let lastLoginAt = viewModel.currentUser.lastLoginAt {
                    InfoRow(title: "登录时间", value: formatDateTime(lastLoginAt))
                    Divider()
                }
                if let lastLoginIp = viewModel.currentUser.lastLoginIp {
                    CopyableInfoRow(title: "登录 IP", value: lastLoginIp)
                    Divider()
                }
                if let lastLoginUserAgent = viewModel.currentUser.lastLoginUserAgent, !lastLoginUserAgent.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Agent")
                            .foregroundStyle(.secondary)
                        Text(lastLoginUserAgent)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - 注册信息
    private var registerInfoSection: some View {
        GroupBox("注册信息") {
            VStack(spacing: 0) {
                if let createdAt = viewModel.currentUser.createdAt {
                    InfoRow(title: "注册时间", value: formatDateTime(createdAt))
                    Divider()
                }
                if let registerIp = viewModel.currentUser.registerIp {
                    CopyableInfoRow(title: "注册 IP", value: registerIp)
                    Divider()
                }
                if let registerUserAgent = viewModel.currentUser.registerUserAgent, !registerUserAgent.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Agent")
                            .foregroundStyle(.secondary)
                        Text(registerUserAgent)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    Divider()
                }
                if let updatedAt = viewModel.currentUser.updatedAt {
                    InfoRow(title: "更新时间", value: formatDateTime(updatedAt))
                }
            }
        }
    }

    // MARK: - 绑定信息
    private var bindingInfoSection: some View {
        GroupBox("绑定信息") {
            VStack(spacing: 0) {
                HStack {
                    Text("Telegram")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let telegramId = viewModel.currentUser.telegramId, !telegramId.isEmpty {
                        Text(telegramId)
                            .textSelection(.enabled)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("未绑定")
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 8)

                Divider()

                HStack {
                    Text("Expo Push Token")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let token = viewModel.currentUser.expoPushToken, !token.isEmpty {
                        Text(token.prefix(20) + "...")
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(token, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Text("未设置")
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - 推送设置
    private var pushSettingsSection: some View {
        GroupBox("推送设置") {
            VStack(spacing: 0) {
                HStack {
                    Text("游戏推送")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: viewModel.currentUser.gamePush == true ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(viewModel.currentUser.gamePush == true ? .green : .secondary)
                }
                .padding(.vertical, 8)

                Divider()

                HStack {
                    Text("漫画推送")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: viewModel.currentUser.comicPush == true ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(viewModel.currentUser.comicPush == true ? .green : .secondary)
                }
                .padding(.vertical, 8)

                Divider()

                HStack {
                    Text("小说推送")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: viewModel.currentUser.novelPush == true ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(viewModel.currentUser.novelPush == true ? .green : .secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - 可复制信息行
    private struct CopyableInfoRow: View {
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .textSelection(.enabled)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 辅助方法
    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        return dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
            .prefix(19)
            .description
    }

    private func isExpiringSoon(_ dateString: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let expireDate = formatter.date(from: dateString) else { return false }
        let daysUntilExpire = Calendar.current.dateComponents([.day], from: Date(), to: expireDate).day ?? 0
        return daysUntilExpire <= 7 && daysUntilExpire >= 0
    }
}

// MARK: - 订单类型枚举
enum UserOrderType: String, CaseIterable {
    case game = "game"
    case comic = "comic"
    case novel = "novel"

    var displayName: String {
        switch self {
        case .game: return "游戏"
        case .comic: return "漫画"
        case .novel: return "小说"
        }
    }

    var icon: String {
        switch self {
        case .game: return "gamecontroller"
        case .comic: return "book"
        case .novel: return "text.book.closed"
        }
    }
}

// MARK: - 游戏订单行
struct UserGameOrderRow: View {
    let order: GameOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.gameTitle ?? "游戏#\(order.gameId)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                Text("¥\(order.amount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            HStack {
                if let versionName = order.versionName {
                    Text(versionName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }

                if order.discount != "0" && order.discount != "0.00" {
                    Text("优惠 ¥\(order.discount)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Text(order.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Text("订单号: \(order.orderNo)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(order.orderNo, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 漫画订单行
struct UserComicOrderRow: View {
    let order: ComicOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.comicTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                Text("¥\(order.amount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            HStack {
                Text("订单号: \(order.orderNo)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Text(order.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 小说订单行
struct UserNovelOrderRow: View {
    let order: NovelOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.novelTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                Text("¥\(order.amount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            if let discount = order.discount, discount != "0" && discount != "0.00" {
                Text("优惠 ¥\(discount)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                Text("订单号: \(order.orderNo)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Text(order.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 支付记录行
struct UserPaymentRow: View {
    let payment: Payment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(payment.payTypeDisplayName)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Text("¥\(payment.amount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(payment.status == "PAID" ? .green : .primary)
            }

            HStack {
                // 支付方式
                Text(payment.methodDisplayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())

                // 状态
                Text(payment.statusDisplayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(paymentStatusColor(payment.status).opacity(0.1))
                    .foregroundStyle(paymentStatusColor(payment.status))
                    .clipShape(Capsule())

                Spacer()

                Text(payment.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let tradeNo = payment.tradeNo, !tradeNo.isEmpty {
                HStack {
                    Text("交易号: \(tradeNo)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func paymentStatusColor(_ status: String) -> Color {
        switch status {
        case "PENDING": return .orange
        case "PAID": return .green
        case "TIMEOUT": return .gray
        case "FAILED": return .red
        default: return .gray
        }
    }
}

// MARK: - 评论类型枚举
enum UserCommentType: String, CaseIterable {
    case game = "game"
    case comic = "comic"
    case novel = "novel"

    var displayName: String {
        switch self {
        case .game: return "游戏"
        case .comic: return "漫画"
        case .novel: return "小说"
        }
    }

    var icon: String {
        switch self {
        case .game: return "gamecontroller"
        case .comic: return "book"
        case .novel: return "text.book.closed"
        }
    }
}

// MARK: - 评论状态辅助
private func commentStatusText(_ status: String) -> String {
    switch status {
    case "PENDING": return "待审核"
    case "APPROVED": return "已通过"
    case "REJECTED": return "已拒绝"
    default: return status
    }
}

private func commentStatusColor(_ status: String) -> Color {
    switch status {
    case "PENDING": return .orange
    case "APPROVED": return .green
    case "REJECTED": return .red
    default: return .gray
    }
}

// MARK: - 游戏评论行
struct UserGameCommentRow: View {
    let comment: GameComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.game?.name ?? "游戏#\(comment.gameId)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    if comment.isTop == true {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(commentStatusText(comment.status))
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(commentStatusColor(comment.status).opacity(0.1))
                        .foregroundStyle(commentStatusColor(comment.status))
                        .clipShape(Capsule())
                }
            }

            Text(comment.content)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            HStack {
                Text(comment.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if comment.status == "PENDING" {
                    Button { onApprove() } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.green)

                    Button { onReject() } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                }

                Button { onDelete() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 漫画评论行
struct UserComicCommentRow: View {
    let comment: ComicComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.comicTitle ?? "漫画#\(comment.comicId)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    if comment.isTop == true {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(commentStatusText(comment.status))
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(commentStatusColor(comment.status).opacity(0.1))
                        .foregroundStyle(commentStatusColor(comment.status))
                        .clipShape(Capsule())
                }
            }

            Text(comment.content)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            HStack {
                Text(comment.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if comment.status == "PENDING" {
                    Button { onApprove() } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.green)

                    Button { onReject() } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                }

                Button { onDelete() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 小说评论行
struct UserNovelCommentRow: View {
    let comment: NovelComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.novelTitle ?? "小说#\(comment.novelId)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    if comment.isTop == true {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(commentStatusText(comment.status))
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(commentStatusColor(comment.status).opacity(0.1))
                        .foregroundStyle(commentStatusColor(comment.status))
                        .clipShape(Capsule())
                }
            }

            Text(comment.content)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            HStack {
                Text(comment.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if comment.status == "PENDING" {
                    Button { onApprove() } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.green)

                    Button { onReject() } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                }

                Button { onDelete() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 升级 VIP 弹窗
struct UpgradeVIPSheet: View {
    @ObservedObject var viewModel: UserDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRole = "VIP"
    @State private var expireDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 默认30天后

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("升级/设置 VIP")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            // 内容
            VStack(spacing: 16) {
                // 当前状态
                GroupBox {
                    HStack {
                        Text("当前等级")
                            .foregroundStyle(.secondary)
                        Spacer()
                        RoleBadge(role: viewModel.currentUser.role)
                    }
                }

                // 选择新等级
                GroupBox("选择新等级") {
                    Picker("VIP 等级", selection: $selectedRole) {
                        Text("VIP").tag("VIP")
                        Text("SVIP").tag("SVIP")
                    }
                    .pickerStyle(.segmented)
                }

                // 选择到期时间
                GroupBox("到期时间") {
                    DatePicker(
                        "到期日期",
                        selection: $expireDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }

                // 快捷选择
                HStack(spacing: 8) {
                    Button("30天") {
                        expireDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
                    }
                    .buttonStyle(.bordered)

                    Button("90天") {
                        expireDate = Date().addingTimeInterval(90 * 24 * 60 * 60)
                    }
                    .buttonStyle(.bordered)

                    Button("180天") {
                        expireDate = Date().addingTimeInterval(180 * 24 * 60 * 60)
                    }
                    .buttonStyle(.bordered)

                    Button("365天") {
                        expireDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // 操作按钮
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("确认升级") {
                        Task {
                            await viewModel.upgradeVip(role: selectedRole, expireAt: formatDate(expireDate))
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isProcessing)
                }
            }
            .padding()
        }
        .frame(width: 400, height: 550)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

// MARK: - 续费 VIP 弹窗
struct RenewVIPSheet: View {
    @ObservedObject var viewModel: UserDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var durationDays = 30

    let durationOptions = [
        (days: 30, label: "1个月"),
        (days: 90, label: "3个月"),
        (days: 180, label: "6个月"),
        (days: 365, label: "1年")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("续费 VIP")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            // 内容
            VStack(spacing: 16) {
                // 当前状态
                GroupBox {
                    VStack(spacing: 8) {
                        HStack {
                            Text("当前等级")
                                .foregroundStyle(.secondary)
                            Spacer()
                            RoleBadge(role: viewModel.currentUser.role)
                        }
                        if let expireAt = viewModel.currentUser.vipExpireAt {
                            Divider()
                            HStack {
                                Text("当前到期")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatExpireDate(expireAt))
                            }
                        }
                    }
                }

                // 选择续费时长
                GroupBox("选择续费时长") {
                    VStack(spacing: 8) {
                        ForEach(durationOptions, id: \.days) { option in
                            Button {
                                durationDays = option.days
                            } label: {
                                HStack {
                                    Text(option.label)
                                    Spacer()
                                    Text("\(option.days) 天")
                                        .foregroundStyle(.secondary)
                                    if durationDays == option.days {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            if option.days != durationOptions.last?.days {
                                Divider()
                            }
                        }
                    }
                }

                // 自定义天数
                GroupBox("自定义天数") {
                    HStack {
                        TextField("天数", value: $durationDays, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("天")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                Spacer()

                // 操作按钮
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("确认续费") {
                        Task {
                            await viewModel.renewVip(durationDays: durationDays)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isProcessing || durationDays <= 0)
                }
            }
            .padding()
        }
        .frame(width: 350, height: 450)
    }

    private func formatExpireDate(_ dateString: String) -> String {
        dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
            .prefix(10)
            .description
    }
}

// MARK: - 余额操作弹窗
struct BalanceOperationSheet: View {
    @ObservedObject var viewModel: UserDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var reason = ""

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text(viewModel.balanceOperationType == .add ? "增加余额" : "扣减余额")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            // 内容
            VStack(spacing: 16) {
                // 当前余额
                GroupBox {
                    HStack {
                        Text("当前余额")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("¥\(viewModel.currentUser.balance ?? "0.00")")
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }

                // 输入金额
                GroupBox("操作金额") {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("输入金额", text: $amount)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // 输入原因
                GroupBox("操作原因") {
                    TextField("请输入原因", text: $reason)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                // 操作按钮
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button(viewModel.balanceOperationType == .add ? "确认增加" : "确认扣减") {
                        Task {
                            if viewModel.balanceOperationType == .add {
                                await viewModel.addBalance(amount: amount, reason: reason)
                            } else {
                                await viewModel.deductBalance(amount: amount, reason: reason)
                            }
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.balanceOperationType == .add ? .green : .orange)
                    .disabled(viewModel.isProcessing || amount.isEmpty || reason.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 350, height: 350)
    }
}

// MARK: - 余额操作类型
enum BalanceOperationType {
    case add
    case deduct
}

// MARK: - 用户详情视图模型
@MainActor
class UserDetailViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var balanceOperationType: BalanceOperationType = .add

    // 订单相关
    @Published var currentOrderType: UserOrderType = .game
    @Published var gameOrders: [GameOrder] = []
    @Published var comicOrders: [ComicOrder] = []
    @Published var novelOrders: [NovelOrder] = []
    @Published var isLoadingOrders = false
    @Published var orderCurrentPage = 1
    @Published var orderTotalPages = 1

    // 支付相关
    @Published var userPayments: [Payment] = []
    @Published var paymentStatusFilter: String?
    @Published var isLoadingPayments = false
    @Published var paymentCurrentPage = 1
    @Published var paymentTotalPages = 1

    // 评论相关
    @Published var currentCommentType: UserCommentType = .game
    @Published var commentStatusFilter: String?
    @Published var gameComments: [GameComment] = []
    @Published var comicComments: [ComicComment] = []
    @Published var novelComments: [NovelComment] = []
    @Published var isLoadingComments = false
    @Published var commentCurrentPage = 1
    @Published var commentTotalPages = 1

    private let service = UserService.shared
    private let commentService = CommentService.shared
    private let gameService = GameService.shared
    private let comicService = ComicService.shared
    private let novelService = NovelService.shared
    private let paymentService = PaymentService.shared

    init(user: User) {
        self.currentUser = user
    }

    func loadUserDetail() async {
        isLoading = true
        do {
            currentUser = try await service.getDetail(id: currentUser.id)
            // 同时加载订单、支付和评论
            await loadOrdersForCurrentType()
            await loadUserPayments()
            await loadCommentsForCurrentType()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 订单相关方法
    func switchOrderType(_ type: UserOrderType) {
        guard type != currentOrderType else { return }
        currentOrderType = type
        orderCurrentPage = 1
        Task { await loadOrdersForCurrentType() }
    }

    func refreshCurrentOrders() async {
        orderCurrentPage = 1
        await loadOrdersForCurrentType()
    }

    func loadOrdersForCurrentType(page: Int = 1) async {
        isLoadingOrders = true
        orderCurrentPage = page

        do {
            switch currentOrderType {
            case .game:
                var params = GameOrderListParams()
                params.page = page
                params.userId = currentUser.id
                let response = try await gameService.getOrders(params: params)
                gameOrders = response.orders
                orderTotalPages = response.pagination.totalPages
            case .comic:
                var params = ComicOrderListParams()
                params.page = page
                params.userId = currentUser.id
                let response = try await comicService.getOrders(params: params)
                comicOrders = response.orders
                orderTotalPages = response.pagination.totalPages
            case .novel:
                var params = NovelOrderListParams()
                params.page = page
                params.userId = currentUser.id
                let response = try await novelService.getOrders(params: params)
                novelOrders = response.orders
                orderTotalPages = response.pagination.totalPages
            }
        } catch {
            // 订单加载失败不影响主页面
        }

        isLoadingOrders = false
    }

    // MARK: - 支付相关方法
    func loadUserPayments(page: Int = 1) async {
        isLoadingPayments = true
        paymentCurrentPage = page

        do {
            var params = PaymentListParams()
            params.page = page
            params.userId = currentUser.id
            params.status = paymentStatusFilter
            let response = try await paymentService.getList(params: params)
            userPayments = response.payments
            paymentTotalPages = response.pagination.totalPages
        } catch {
            // 支付加载失败不影响主页面
        }

        isLoadingPayments = false
    }

    // MARK: - 评论相关方法
    func switchCommentType(_ type: UserCommentType) {
        guard type != currentCommentType else { return }
        currentCommentType = type
        commentCurrentPage = 1
        Task { await loadCommentsForCurrentType() }
    }

    func refreshCurrentComments() async {
        commentCurrentPage = 1
        await loadCommentsForCurrentType()
    }

    func loadCommentsForCurrentType(page: Int = 1) async {
        isLoadingComments = true
        commentCurrentPage = page

        do {
            switch currentCommentType {
            case .game:
                let response = try await commentService.getGameCommentsByUser(
                    userId: currentUser.id,
                    page: page,
                    status: commentStatusFilter
                )
                gameComments = response.comments
                commentTotalPages = response.pagination.totalPages
            case .comic:
                let response = try await commentService.getComicCommentsByUser(
                    userId: currentUser.id,
                    page: page,
                    status: commentStatusFilter
                )
                comicComments = response.comments
                commentTotalPages = response.pagination.totalPages
            case .novel:
                let response = try await commentService.getNovelCommentsByUser(
                    userId: currentUser.id,
                    page: page,
                    status: commentStatusFilter
                )
                novelComments = response.comments
                commentTotalPages = response.pagination.totalPages
            }
        } catch {
            // 评论加载失败不影响主页面
        }

        isLoadingComments = false
    }

    // MARK: - 游戏评论操作
    func approveGameComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.approveGameComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectGameComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.rejectGameComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteGameComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.deleteGameComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 漫画评论操作
    func approveComicComment(_ comment: ComicComment) {
        Task {
            do {
                try await commentService.approveComicComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComicComment(_ comment: ComicComment) {
        Task {
            do {
                try await commentService.rejectComicComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComicComment(_ comment: ComicComment) {
        Task {
            do {
                try await commentService.deleteComicComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 小说评论操作
    func approveNovelComment(_ comment: NovelComment) {
        Task {
            do {
                try await commentService.approveNovelComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectNovelComment(_ comment: NovelComment) {
        Task {
            do {
                try await commentService.rejectNovelComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteNovelComment(_ comment: NovelComment) {
        Task {
            do {
                try await commentService.deleteNovelComment(id: comment.id)
                await loadCommentsForCurrentType(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func upgradeVip(role: String, expireAt: String) async {
        isProcessing = true
        clearMessages()
        do {
            try await service.upgradeVip(id: currentUser.id, role: role, expireAt: expireAt)
            successMessage = "VIP 升级成功"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func renewVip(durationDays: Int) async {
        isProcessing = true
        clearMessages()
        do {
            try await service.renewVip(id: currentUser.id, durationDays: durationDays)
            successMessage = "VIP 续费成功"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func cancelVip() async {
        isProcessing = true
        clearMessages()
        do {
            try await service.cancelVip(id: currentUser.id)
            successMessage = "VIP 已取消"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func addBalance(amount: String, reason: String) async {
        isProcessing = true
        clearMessages()
        do {
            try await service.addBalance(id: currentUser.id, amount: amount, reason: reason)
            successMessage = "余额增加成功"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func deductBalance(amount: String, reason: String) async {
        isProcessing = true
        clearMessages()
        do {
            try await service.deductBalance(id: currentUser.id, amount: amount, reason: reason)
            successMessage = "余额扣减成功"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func banUser() async {
        isProcessing = true
        clearMessages()
        do {
            try await service.banUser(id: currentUser.id)
            successMessage = "用户已封禁"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func unbanUser() async {
        isProcessing = true
        clearMessages()
        do {
            try await service.unbanUser(id: currentUser.id)
            successMessage = "用户已解封"
            await loadUserDetail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

#Preview {
    UserDetailView(user: User(
        id: 1,
        publicId: "U-12345678",
        username: "testuser",
        email: "test@example.com",
        role: "VIP",
        status: "ACTIVE",
        balance: "99.00",
        avatar: nil,
        isVip: true,
        vipExpireAt: "2025-12-31T23:59:59Z",
        vipStartAt: "2024-01-01T00:00:00Z",
        emailVerified: true,
        lastLoginAt: "2024-12-06T10:00:00Z",
        lastLoginIp: "192.168.1.1",
        lastLoginUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
        registerIp: "192.168.1.1",
        registerUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)",
        telegramId: "123456789",
        expoPushToken: "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]",
        gamePush: true,
        comicPush: true,
        novelPush: false,
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-12-06T10:00:00Z"
    ))
}
