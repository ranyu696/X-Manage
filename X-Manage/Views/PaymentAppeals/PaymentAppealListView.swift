//
//  PaymentAppealListView.swift
//  X-Manage
//
//  支付申诉审核视图

import SwiftUI

struct PaymentAppealListView: View {
    @StateObject private var viewModel = PaymentAppealListViewModel()
    @State private var searchUserId = ""
    @State private var searchOutTradeNo = ""
    @State private var selectedStatus: String?
    @State private var selectedType: String?
    @State private var selectedAppeal: PaymentAppeal?

    var body: some View {
        VStack(spacing: 0) {
            contentView
            paginationView
        }
        .task {
            await viewModel.loadAppeals()
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadAppeals() }
        }
        .onChange(of: selectedType) { _, newValue in
            viewModel.filterType = newValue
            Task { await viewModel.loadAppeals() }
        }
        .sheet(item: $selectedAppeal) { appeal in
            PaymentAppealDetailView(appeal: appeal) {
                Task { await viewModel.loadAppeals(page: viewModel.currentPage) }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    // 用户ID搜索
                    searchBox(icon: "person", placeholder: "用户ID", width: 60, text: $searchUserId) {
                        searchUserId = ""
                        viewModel.searchUserId = nil
                        Task { await viewModel.loadAppeals() }
                    }
                    // 商户订单号搜索
                    searchBox(icon: "doc.text", placeholder: "商户订单号", width: 140, text: $searchOutTradeNo) {
                        searchOutTradeNo = ""
                        viewModel.searchOutTradeNo = nil
                        Task { await viewModel.loadAppeals() }
                    }
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
                    Text("待处理").tag("pending" as String?)
                    Text("需补充材料").tag("need_more_info" as String?)
                    Text("已批准").tag("approved" as String?)
                    Text("已驳回").tag("rejected" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }

            ToolbarItem(placement: .automatic) {
                Picker("类型", selection: $selectedType) {
                    Text("全部类型").tag(nil as String?)
                    Text("已支付未到账").tag("paid_not_received" as String?)
                    Text("金额错误").tag("amount_error" as String?)
                    Text("其他").tag("other" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadAppeals() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - 搜索框
    private func searchBox(icon: String, placeholder: String, width: CGFloat, text: Binding<String>, onClear: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .frame(width: width)
                .onSubmit { performSearch() }
            if !text.wrappedValue.isEmpty {
                Button {
                    onClear()
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
    }

    // MARK: - 执行搜索
    private func performSearch() {
        viewModel.searchUserId = searchUserId.isEmpty ? nil : searchUserId
        viewModel.searchOutTradeNo = searchOutTradeNo.isEmpty ? nil : searchOutTradeNo
        Task { await viewModel.loadAppeals() }
    }

    // MARK: - 内容区域
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.appeals.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.appeals.isEmpty {
            PaymentAppealEmptyView(
                hasFilters: selectedStatus != nil || selectedType != nil || !searchUserId.isEmpty || !searchOutTradeNo.isEmpty,
                onClearFilters: {
                    selectedStatus = nil
                    selectedType = nil
                    searchUserId = ""
                    searchOutTradeNo = ""
                    viewModel.searchUserId = nil
                    viewModel.searchOutTradeNo = nil
                    Task { await viewModel.loadAppeals() }
                }
            )
        } else {
            PaymentAppealTableView(
                appeals: viewModel.appeals,
                onSelect: { appeal in
                    selectedAppeal = appeal
                }
            )
            .id(viewModel.currentPage)
        }
    }

    // MARK: - 分页
    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.appeals.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadAppeals(page: page) }
                }
            )
            .padding()
        }
    }
}

// MARK: - 空数据视图
struct PaymentAppealEmptyView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(hasFilters ? "未找到匹配的申诉" : "暂无支付申诉")
                .font(.title3)
                .fontWeight(.semibold)
            Text(hasFilters ? "尝试调整筛选条件或清除筛选器" : "当用户提交支付申诉后，将显示在这里")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            if hasFilters {
                Button {
                    onClearFilters()
                } label: {
                    Label("清除筛选条件", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 申诉表格视图
struct PaymentAppealTableView: View {
    let appeals: [PaymentAppeal]
    let onSelect: (PaymentAppeal) -> Void
    @State private var selectedAppealId: PaymentAppeal.ID?

    var body: some View {
        Table(appeals, selection: $selectedAppealId) {
            TableColumn("申诉ID") { (appeal: PaymentAppeal) in
                Text(appeal.publicId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 130)

            TableColumn("用户ID") { (appeal: PaymentAppeal) in
                Text("\(appeal.userId)")
            }
            .width(70)

            TableColumn("订单号") { (appeal: PaymentAppeal) in
                Text(appeal.outTradeNo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 150)

            TableColumn("类型") { (appeal: PaymentAppeal) in
                AppealTypeBadge(type: appeal.type)
            }
            .width(110)

            TableColumn("状态") { (appeal: PaymentAppeal) in
                AppealStatusBadge(status: appeal.status)
            }
            .width(100)

            TableColumn("OCR预审") { (appeal: PaymentAppeal) in
                AppealOCRBadge(passed: appeal.ocrPassed, platform: appeal.ocrPlatform)
            }
            .width(100)

            TableColumn("创建时间") { (appeal: PaymentAppeal) in
                Text(formatDate(appeal.createdAt))
            }
            .width(100)

            TableColumn("操作") { (appeal: PaymentAppeal) in
                Button {
                    onSelect(appeal)
                } label: {
                    Image(systemName: appeal.isActionable ? "checkmark.circle" : "eye")
                }
                .buttonStyle(.borderless)
            }
            .width(50)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .onChange(of: selectedAppealId) { _, newValue in
            if let id = newValue,
               let appeal = appeals.first(where: { $0.id == id }) {
                onSelect(appeal)
                selectedAppealId = nil
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

// MARK: - 申诉类型徽章
struct AppealTypeBadge: View {
    let type: String

    var body: some View {
        Text(AppealType(rawValue: type)?.displayName ?? type)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.purple.opacity(0.1))
            .foregroundStyle(.purple)
            .clipShape(Capsule())
    }
}

// MARK: - 申诉状态徽章
struct AppealStatusBadge: View {
    let status: String

    var body: some View {
        Text(AppealStatus(rawValue: status)?.displayName ?? status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(textColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var textColor: Color {
        switch status {
        case "pending": return .orange
        case "approved": return .green
        case "rejected": return .red
        case "need_more_info": return .blue
        default: return .gray
        }
    }
}

// MARK: - OCR 预审徽章
struct AppealOCRBadge: View {
    let passed: Bool
    let platform: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal")
                .font(.caption2)
            Text(passed ? platformName : "未通过")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .foregroundStyle(passed ? Color.green : Color.gray)
        .background((passed ? Color.green : Color.gray).opacity(0.1))
        .clipShape(Capsule())
    }

    private var platformName: String {
        switch platform {
        case "wechat": return "微信"
        case "alipay": return "支付宝"
        default: return "已通过"
        }
    }
}

// MARK: - 申诉列表视图模型
@MainActor
class PaymentAppealListViewModel: ObservableObject {
    @Published var appeals: [PaymentAppeal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterStatus: String?
    var filterType: String?
    var searchUserId: String?
    var searchOutTradeNo: String?

    private let service = PaymentAppealService.shared

    func loadAppeals(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = PaymentAppealListParams(page: page, pageSize: 25)
        params.status = filterStatus
        params.type = filterType
        if let userIdStr = searchUserId, !userIdStr.isEmpty, let userId = Int(userIdStr) {
            params.userId = userId
        }
        if let outTradeNo = searchOutTradeNo, !outTradeNo.isEmpty {
            params.outTradeNo = outTradeNo
        }

        do {
            let response = try await service.getList(params: params)
            appeals = response.appeals
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    PaymentAppealListView()
}
