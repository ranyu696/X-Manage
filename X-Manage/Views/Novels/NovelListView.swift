//
//  NovelListView.swift
//  X-Manage
//
//  小说管理视图

import SwiftUI

// MARK: - 小说列表内容视图
struct NovelListContentView: View {
    @StateObject private var viewModel = NovelListViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: String?
    @State private var selectedNovelId: Int?
    @State private var showCreateSheet = false
    @State private var showDeleteAlert = false
    @State private var novelToDelete: Novel?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧列表
            VStack(spacing: 0) {
                contentView
                paginationView
            }

            // 右侧详情面板
            if let novelId = selectedNovelId {
                Divider()
                NovelDetailPanel(
                    novelId: novelId,
                    onUpdate: {
                        Task { await viewModel.loadNovels(page: viewModel.currentPage) }
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedNovelId = nil
                        }
                    }
                )
                .id(novelId)
                .frame(width: 500)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedNovelId)
        .task {
            await viewModel.loadNovels()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task { await viewModel.loadNovels() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadNovels() }
        }
        .sheet(isPresented: $showCreateSheet) {
            NovelCreateView {
                Task { await viewModel.loadNovels() }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let novel = novelToDelete {
                    viewModel.deleteNovel(novel)
                }
            }
        } message: {
            Text("确定要删除小说「\(novelToDelete?.title ?? "")」吗？此操作不可恢复。")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索小说...", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            ToolbarItem(placement: .automatic) {
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as String?)
                    ForEach(NovelStatus.allCases, id: \.rawValue) { status in
                        Text(status.displayName).tag(status.rawValue as String?)
                    }
                }
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadNovels() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建小说", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - 内容视图
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.novels.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.novels.isEmpty {
            ContentUnavailableView(
                "暂无小说",
                systemImage: "text.book.closed",
                description: Text("点击右上角按钮创建第一个小说")
            )
        } else {
            novelTable
        }
    }

    private var novelTable: some View {
        Table(viewModel.novels, selection: $selectedNovelId) {
            TableColumn("ID") { novel in
                Text(String(novel.id))
                    .font(.caption.monospaced())
            }
            .width(60)

            TableColumn("封面") { novel in
                NovelCoverCell(cover: novel.cover)
            }
            .width(60)

            TableColumn("标题") { novel in
                NovelTitleCell(title: novel.title, author: novel.author)
            }
            .width(min: 150, ideal: 200)

            TableColumn("状态") { novel in
                HStack(spacing: 4) {
                    NovelStatusBadge(status: novel.status)
                    NovelFlagsCell(isTop: novel.isTop, isCompleted: novel.isCompleted)
                }
            }
            .width(120)

            TableColumn("章节/字数") { novel in
                VStack(alignment: .leading) {
                    Text("\(novel.chapterCount ?? 0) 章")
                        .font(.caption)
                    Text(formatWordCount(novel.wordCount ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .width(80)

            TableColumn("统计") { novel in
                Text("\(novel.viewCount ?? 0)/\(novel.favoriteCount ?? 0)")
                    .font(.caption.monospacedDigit())
                    .help("浏览/收藏")
            }
            .width(80)

            TableColumn("创建时间") { novel in
                Text(formatDate(novel.createdAt ?? ""))
                    .font(.caption)
            }
            .width(100)

            TableColumn("操作") { novel in
                NovelActionsCell(
                    novel: novel,
                    onView: { selectedNovelId = novel.id },
                    onPublish: { viewModel.publish(novel) },
                    onUnpublish: { viewModel.unpublish(novel) },
                    onToggleTop: { viewModel.toggleTop(novel) },
                    onToggleComplete: { viewModel.toggleComplete(novel) },
                    onDelete: {
                        novelToDelete = novel
                        showDeleteAlert = true
                    }
                )
            }
            .width(70)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .id(viewModel.currentPage) // 页面变化时重置滚动位置
    }

    // MARK: - 分页
    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.novels.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadNovels(page: page) }
                }
            )
            .padding()
        }
    }

    private func formatDate(_ dateString: String) -> String {
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }

    private func formatWordCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万字", Double(count) / 10000.0)
        }
        return "\(count)字"
    }
}

// MARK: - 表格单元格组件
struct NovelCoverCell: View {
    let cover: String

    var body: some View {
        AsyncImage(url: URL(string: cover)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(.quaternary)
        }
        .frame(width: 40, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct NovelTitleCell: View {
    let title: String
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(author)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct NovelFlagsCell: View {
    let isTop: Bool?
    let isCompleted: Bool?

    var body: some View {
        HStack(spacing: 4) {
            if isTop == true {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if isCompleted == true {
                Text("完")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text("连")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}

struct NovelActionsCell: View {
    let novel: Novel
    let onView: () -> Void
    let onPublish: () -> Void
    let onUnpublish: () -> Void
    let onToggleTop: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button {
                onView()
            } label: {
                Image(systemName: "eye")
            }
            .buttonStyle(.borderless)
            .help("查看详情")

            Menu {
                if novel.status == NovelStatus.published.rawValue {
                    Button {
                        onUnpublish()
                    } label: {
                        Label("下架", systemImage: "arrow.down.square")
                    }
                } else {
                    Button {
                        onPublish()
                    } label: {
                        Label("发布", systemImage: "arrow.up.square")
                    }
                }

                Button {
                    onToggleTop()
                } label: {
                    Label(novel.isTop == true ? "取消置顶" : "置顶", systemImage: novel.isTop == true ? "pin.slash" : "pin")
                }

                Button {
                    onToggleComplete()
                } label: {
                    Label(novel.isCompleted == true ? "设为连载" : "设为完结", systemImage: novel.isCompleted == true ? "book" : "checkmark.circle")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
    }
}

// MARK: - 小说状态徽章
struct NovelStatusBadge: View {
    let status: String

    var body: some View {
        Text(displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var displayName: String {
        NovelStatus(rawValue: status)?.displayName ?? status
    }

    private var backgroundColor: Color {
        switch status {
        case NovelStatus.published.rawValue:
            return .green
        case NovelStatus.pending.rawValue:
            return .orange
        case NovelStatus.unlisted.rawValue:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - 小说定价列表
struct NovelPricingListView: View {
    @StateObject private var viewModel = NovelPricingListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            contentView
            paginationView
        }
        .task {
            await viewModel.loadPricings()
        }
    }

    private var toolbarView: some View {
        HStack {
            Spacer()
            Button {
                Task { await viewModel.loadPricings() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.pricings.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.pricings.isEmpty {
            ContentUnavailableView(
                "暂无定价",
                systemImage: "dollarsign.circle",
                description: Text("暂无小说定价数据")
            )
        } else {
            pricingTable
        }
    }

    private var pricingTable: some View {
        Table(viewModel.pricings) {
            TableColumn("ID") { pricing in
                Text(String(pricing.id))
                    .font(.caption.monospaced())
            }
            .width(60)

            TableColumn("小说ID") { pricing in
                Text(pricing.novelId != nil ? String(pricing.novelId!) : "-")
                    .font(.caption.monospaced())
            }
            .width(80)

            TableColumn("名称", value: \.name)
                .width(min: 100, ideal: 150)

            TableColumn("价格") { pricing in
                Text("¥\(pricing.price)")
                    .fontWeight(.medium)
            }
            .width(80)

            TableColumn("预览章节") { pricing in
                Text(pricing.previewCount != nil ? "\(pricing.previewCount!)章" : "-")
            }
            .width(80)

            TableColumn("VIP折扣") { pricing in
                Text(pricing.vipDiscount ?? "-")
            }
            .width(80)

            TableColumn("SVIP折扣") { pricing in
                Text(pricing.svipDiscount ?? "-")
            }
            .width(80)

            TableColumn("免费标记") { pricing in
                NovelPricingFreeFlags(pricing: pricing)
            }
            .width(100)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }

    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.pricings.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadPricings(page: page) }
                }
            )
            .padding()
        }
    }
}

struct NovelPricingFreeFlags: View {
    let pricing: NovelPricing

    var body: some View {
        HStack(spacing: 4) {
            if pricing.memberFree {
                Text("普")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if pricing.vipFree {
                Text("V")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if pricing.svipFree {
                Text("S")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(.purple.opacity(0.2))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}

// MARK: - 小说订单列表
struct NovelOrderListView: View {
    @StateObject private var viewModel = NovelOrderListViewModel()
    @State private var userIdFilter = ""
    @State private var novelIdFilter = ""

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            contentView
            paginationView
        }
        .task {
            await viewModel.loadOrders()
        }
    }

    private var toolbarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "person")
                    .foregroundStyle(.secondary)
                TextField("用户ID", text: $userIdFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Image(systemName: "text.book.closed")
                    .foregroundStyle(.secondary)
                TextField("小说ID", text: $novelIdFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("搜索") {
                viewModel.userId = Int(userIdFilter)
                viewModel.novelId = Int(novelIdFilter)
                Task { await viewModel.loadOrders() }
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                Task { await viewModel.loadOrders() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.orders.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.orders.isEmpty {
            ContentUnavailableView(
                "暂无订单",
                systemImage: "list.clipboard",
                description: Text("暂无小说订单数据")
            )
        } else {
            orderTable
        }
    }

    private var orderTable: some View {
        Table(viewModel.orders) {
            TableColumn("订单号") { order in
                Text(order.orderNo)
                    .font(.caption.monospaced())
            }
            .width(min: 120, ideal: 150)

            TableColumn("用户") { order in
                NovelOrderUserCell(userId: order.userId, userRole: order.userRole)
            }
            .width(100)

            TableColumn("小说") { order in
                Text(order.novelTitle)
                    .lineLimit(1)
            }
            .width(min: 150, ideal: 200)

            TableColumn("金额") { order in
                NovelOrderAmountCell(amount: order.amount, discount: order.discount)
            }
            .width(80)

            TableColumn("原价") { order in
                Text("¥\(order.originalPrice ?? "-")")
                    .foregroundStyle(.secondary)
            }
            .width(80)

            TableColumn("时间") { order in
                Text(formatOrderDate(order.createdAt))
                    .font(.caption)
            }
            .width(100)

            TableColumn("IP") { order in
                Text(order.ip ?? "-")
                    .font(.caption.monospaced())
            }
            .width(120)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }

    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.orders.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadOrders(page: page) }
                }
            )
            .padding()
        }
    }

    private func formatOrderDate(_ dateString: String) -> String {
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }
}

struct NovelOrderUserCell: View {
    let userId: Int
    let userRole: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("ID: \(userId)")
                .font(.caption.monospaced())
            if let role = userRole {
                RoleBadge(role: role)
            }
        }
    }
}

struct NovelOrderAmountCell: View {
    let amount: String
    let discount: String?

    var body: some View {
        VStack(alignment: .trailing) {
            Text("¥\(amount)")
                .fontWeight(.medium)
            if let discount = discount, discount != "0" && discount != "0.00" {
                Text("-\(discount)")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - ViewModels
@MainActor
class NovelListViewModel: ObservableObject {
    @Published var novels: [Novel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterStatus: String?

    private let service = NovelService.shared

    func loadNovels(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = NovelListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.status = filterStatus

        do {
            let response = try await service.getList(params: params)
            novels = response.novels
            totalPages = response.pagination.totalPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteNovel(_ novel: Novel) {
        Task {
            do {
                try await service.delete(id: novel.id)
                await loadNovels(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func publish(_ novel: Novel) {
        Task {
            do {
                try await service.publish(id: novel.id)
                await loadNovels(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func unpublish(_ novel: Novel) {
        Task {
            do {
                try await service.unpublish(id: novel.id)
                await loadNovels(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ novel: Novel) {
        Task {
            do {
                try await service.setTop(id: novel.id, isTop: !(novel.isTop ?? false))
                await loadNovels(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleComplete(_ novel: Novel) {
        Task {
            do {
                try await service.setComplete(id: novel.id, isCompleted: !(novel.isCompleted ?? false))
                await loadNovels(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
class NovelPricingListViewModel: ObservableObject {
    @Published var pricings: [NovelPricing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    private let service = NovelService.shared

    func loadPricings(page: Int = 1) async {
        isLoading = true
        currentPage = page

        do {
            let response = try await service.getPricings(page: page, pageSize: 25)
            pricings = response.pricings
            totalPages = response.pagination.totalPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

@MainActor
class NovelOrderListViewModel: ObservableObject {
    @Published var orders: [NovelOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var userId: Int?
    var novelId: Int?

    private let service = NovelService.shared

    func loadOrders(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = NovelOrderListParams(page: page, pageSize: 25)
        params.userId = userId
        params.novelId = novelId

        do {
            let response = try await service.getOrders(params: params)
            orders = response.orders
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NovelListContentView()
}
