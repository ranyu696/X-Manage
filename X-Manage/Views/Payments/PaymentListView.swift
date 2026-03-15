//
//  PaymentListView.swift
//  X-Manage
//
//  支付订单视图

import SwiftUI

struct PaymentListView: View {
    @StateObject private var viewModel = PaymentListViewModel()
    @State private var searchUserId = ""
    @State private var searchTradeNo = ""
    @State private var searchOutTradeNo = ""
    @State private var selectedStatus: String?
    @State private var selectedPayType: String?
    @State private var selectedPayment: Payment?

    var body: some View {
        VStack(spacing: 0) {
            contentView
            paginationView
        }
        .task {
            await viewModel.loadPayments()
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadPayments() }
        }
        .onChange(of: selectedPayType) { _, newValue in
            viewModel.filterPayType = newValue
            Task { await viewModel.loadPayments() }
        }
        .sheet(item: $selectedPayment) { payment in
            PaymentDetailView(payment: payment)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    // 用户ID搜索框
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("用户ID", text: $searchUserId)
                            .textFieldStyle(.plain)
                            .frame(width: 60)
                            .onSubmit { performSearch() }
                        if !searchUserId.isEmpty {
                            Button {
                                searchUserId = ""
                                viewModel.searchUserId = nil
                                Task { await viewModel.loadPayments() }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // 商户订单号搜索框
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("商户订单号", text: $searchOutTradeNo)
                            .textFieldStyle(.plain)
                            .frame(width: 140)
                            .onSubmit { performSearch() }
                        if !searchOutTradeNo.isEmpty {
                            Button {
                                searchOutTradeNo = ""
                                viewModel.searchOutTradeNo = nil
                                Task { await viewModel.loadPayments() }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // 系统订单号搜索框
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("系统订单号", text: $searchTradeNo)
                            .textFieldStyle(.plain)
                            .frame(width: 140)
                            .onSubmit { performSearch() }
                        if !searchTradeNo.isEmpty {
                            Button {
                                searchTradeNo = ""
                                viewModel.searchTradeNo = nil
                                Task { await viewModel.loadPayments() }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // 搜索按钮
                    Button {
                        performSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                }
            }

            ToolbarItem(placement: .automatic) {
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as String?)
                    Text("待支付").tag("PENDING" as String?)
                    Text("已支付").tag("PAID" as String?)
                    Text("超时").tag("TIMEOUT" as String?)
                    Text("失败").tag("FAILED" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Picker("类型", selection: $selectedPayType) {
                    Text("全部类型").tag(nil as String?)
                    Text("余额充值").tag("RECHARGE" as String?)
                    Text("VIP购买").tag("VIP" as String?)
                    Text("SVIP购买").tag("SVIP" as String?)
                    Text("VIP续费").tag("VIP_RENEWAL" as String?)
                    Text("SVIP续费").tag("SVIP_RENEWAL" as String?)
                    Text("VIP升级").tag("VIP_UPGRADE" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadPayments() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - 执行搜索
    private func performSearch() {
        viewModel.searchUserId = searchUserId.isEmpty ? nil : searchUserId
        viewModel.searchTradeNo = searchTradeNo.isEmpty ? nil : searchTradeNo
        viewModel.searchOutTradeNo = searchOutTradeNo.isEmpty ? nil : searchOutTradeNo
        Task { await viewModel.loadPayments() }
    }

    // MARK: - 内容区域
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.payments.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.payments.isEmpty {
            PaymentEmptyView(
                hasFilters: selectedStatus != nil || selectedPayType != nil || !searchUserId.isEmpty || !searchTradeNo.isEmpty || !searchOutTradeNo.isEmpty,
                onClearFilters: {
                    selectedStatus = nil
                    selectedPayType = nil
                    searchUserId = ""
                    searchTradeNo = ""
                    searchOutTradeNo = ""
                    viewModel.searchUserId = nil
                    viewModel.searchTradeNo = nil
                    viewModel.searchOutTradeNo = nil
                    Task { await viewModel.loadPayments() }
                }
            )
        } else {
            PaymentTableView(
                payments: viewModel.payments,
                onSelect: { payment in
                    selectedPayment = payment
                }
            )
            .id(viewModel.currentPage) // 页面变化时重置滚动位置
        }
    }

    // MARK: - 分页
    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.payments.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadPayments(page: page) }
                }
            )
            .padding()
        }
    }
}

// MARK: - 空数据视图
struct PaymentEmptyView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 图标区域
            ZStack {
                // 背景圆环
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // 装饰元素
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)

                // 主图标
                VStack(spacing: 4) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // 装饰小图标
                Image(systemName: "yensign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .offset(x: 50, y: -40)

                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .offset(x: -55, y: 35)
            }

            // 文字区域
            VStack(spacing: 12) {
                Text(hasFilters ? "未找到匹配的订单" : "暂无支付订单")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(hasFilters ? "尝试调整筛选条件或清除筛选器" : "当有用户完成支付后，订单将显示在这里")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            // 操作按钮
            if hasFilters {
                Button {
                    onClearFilters()
                } label: {
                    Label("清除筛选条件", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }

            // 提示信息
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    tipItem(icon: "creditcard.fill", text: "支付宝/微信支付")
                    tipItem(icon: "wallet.pass.fill", text: "余额消费")
                    tipItem(icon: "crown.fill", text: "VIP购买")
                }
            }
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tipItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - 支付表格视图
struct PaymentTableView: View {
    let payments: [Payment]
    let onSelect: (Payment) -> Void
    @State private var selectedPaymentId: Payment.ID?

    var body: some View {
        Table(payments, selection: $selectedPaymentId) {
            TableColumn("ID") { (payment: Payment) in
                Text("\(payment.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(60)

            TableColumn("用户ID") { (payment: Payment) in
                Text("\(payment.userId)")
            }
            .width(80)

            TableColumn("金额") { (payment: Payment) in
                Text("¥\(payment.amount)")
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
            .width(80)

            TableColumn("支付方式") { (payment: Payment) in
                PaymentMethodBadge(method: payment.method)
            }
            .width(100)

            TableColumn("类型") { (payment: Payment) in
                PaymentTypeBadge(payType: payment.payType)
            }
            .width(100)

            TableColumn("状态") { (payment: Payment) in
                PaymentStatusBadge(status: payment.status)
            }
            .width(80)

            TableColumn("订单号") { (payment: Payment) in
                Text(payment.outTradeNo ?? "-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 150)

            TableColumn("创建时间") { (payment: Payment) in
                Text(formatDate(payment.createdAt))
            }
            .width(100)

            TableColumn("操作") { (payment: Payment) in
                Button {
                    onSelect(payment)
                } label: {
                    Image(systemName: "eye")
                }
                .buttonStyle(.borderless)
            }
            .width(50)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .onChange(of: selectedPaymentId) { _, newValue in
            if let paymentId = newValue,
               let payment = payments.first(where: { $0.id == paymentId }) {
                onSelect(payment)
                selectedPaymentId = nil // 重置选择，允许再次点击同一行
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }
}

// MARK: - 支付类型徽章
struct PaymentTypeBadge: View {
    let payType: String

    var body: some View {
        Text(displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.purple.opacity(0.1))
            .foregroundStyle(.purple)
            .clipShape(Capsule())
    }

    private var displayName: String {
        switch payType {
        case "RECHARGE": return "余额充值"
        case "PAYMENT_VIP": return "VIP购买"
        case "PAYMENT_SVIP": return "SVIP购买"
        case "VIP_UPGRADE": return "VIP升级"
        case "VIP_RENEWAL": return "VIP续费"
        case "SVIP_RENEWAL": return "SVIP续费"
        default: return payType
        }
    }
}

// MARK: - 支付状态徽章
struct PaymentStatusBadge: View {
    let status: String

    var body: some View {
        Text(displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var displayName: String {
        switch status {
        case "PENDING": return "待支付"
        case "PAID": return "已支付"
        case "TIMEOUT": return "超时"
        case "FAILED": return "失败"
        case "CANCELLED": return "已取消"
        case "REFUNDED": return "已退款"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "PENDING": return .orange
        case "PAID": return .green
        case "TIMEOUT", "FAILED": return .red
        case "CANCELLED": return .gray
        case "REFUNDED": return .blue
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 支付方式徽章
struct PaymentMethodBadge: View {
    let method: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .foregroundStyle(textColor)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var displayName: String {
        switch method {
        case "ALIPAY": return "支付宝"
        case "WXPAY": return "微信"
        case "CARD": return "银行卡"
        case "BALANCE": return "余额"
        default: return method
        }
    }

    private var iconName: String {
        switch method {
        case "ALIPAY": return "a.circle"
        case "WXPAY": return "message"
        case "CARD": return "creditcard"
        case "BALANCE": return "wallet.pass"
        default: return "questionmark.circle"
        }
    }

    private var textColor: Color {
        switch method {
        case "ALIPAY": return .blue
        case "WXPAY": return .green
        case "CARD": return .purple
        case "BALANCE": return .orange
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 支付列表视图模型
@MainActor
class PaymentListViewModel: ObservableObject {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterStatus: String?
    var filterPayType: String?
    var searchUserId: String?
    var searchTradeNo: String?
    var searchOutTradeNo: String?

    private let service = PaymentService.shared

    func loadPayments(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = PaymentListParams(page: page, pageSize: 25)
        params.status = filterStatus
        params.payType = filterPayType

        // 用户ID搜索
        if let userIdStr = searchUserId, !userIdStr.isEmpty, let userId = Int(userIdStr) {
            params.userId = userId
        }
        // 系统订单号搜索
        if let tradeNo = searchTradeNo, !tradeNo.isEmpty {
            params.tradeNo = tradeNo
        }
        // 商户订单号搜索
        if let outTradeNo = searchOutTradeNo, !outTradeNo.isEmpty {
            params.outTradeNo = outTradeNo
        }

        do {
            let response = try await service.getList(params: params)
            payments = response.payments
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    PaymentListView()
}
