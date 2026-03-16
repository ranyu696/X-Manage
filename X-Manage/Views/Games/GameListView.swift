//
//  GameListView.swift
//  X-Manage
//
//  游戏管理视图

import SwiftUI

// MARK: - 游戏列表内容视图
struct GameListContentView: View {
    @StateObject private var viewModel = GameListViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: String?
    @State private var selectedGameId: Int?
    @State private var showCreateSheet = false
    @State private var showDeleteAlert = false
    @State private var gameToDelete: Game?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧列表
            VStack(spacing: 0) {
                contentView
                paginationView
            }

            // 右侧详情面板
            if let gameId = selectedGameId {
                Divider()
                GameDetailPanel(
                    gameId: gameId,
                    onUpdate: {
                        Task { await viewModel.loadGames(page: viewModel.currentPage) }
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGameId = nil
                        }
                    }
                )
                .id(gameId)
                .frame(width: 500)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedGameId)
        .task {
            await viewModel.loadGames()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task { await viewModel.loadGames() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadGames() }
        }
        .sheet(isPresented: $showCreateSheet) {
            GameCreateView {
                Task { await viewModel.loadGames() }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let game = gameToDelete {
                    viewModel.deleteGame(game)
                }
            }
        } message: {
            Text("确定要删除游戏「\(gameToDelete?.title ?? "")」吗？此操作不可恢复。")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索游戏...", text: $searchText)
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
                    ForEach(GameStatus.allCases, id: \.rawValue) { status in
                        Text(status.displayName).tag(status.rawValue as String?)
                    }
                }
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadGames() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建游戏", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - 内容视图
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.games.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.games.isEmpty {
            ContentUnavailableView(
                "暂无游戏",
                systemImage: "gamecontroller",
                description: Text("点击右上角按钮创建第一个游戏")
            )
        } else {
            gameTable
        }
    }

    private var gameTable: some View {
        Table(viewModel.games, selection: $selectedGameId) {
            TableColumn("ID") { game in
                Text(String(game.id))
                    .font(.caption.monospaced())
            }
            .width(60)

            TableColumn("封面") { game in
                GameCoverCell(covers: game.covers)
            }
            .width(100)

            TableColumn("标题") { game in
                GameTitleCell(title: game.title, name: game.name)
            }
            .width(min: 150, ideal: 200)

            TableColumn("作者", value: \.author)
                .width(100)

            TableColumn("状态") { game in
                HStack(spacing: 4) {
                    GameStatusBadge(status: game.status)
                    GameFlagsCell(isTop: game.isTop, isTranslated: game.isTranslated)
                }
            }
            .width(120)

            TableColumn("统计") { game in
                Text("\(game.viewCount ?? 0)/\(game.favoriteCount ?? 0)/\(game.saleCount ?? 0)")
                    .font(.caption.monospacedDigit())
                    .help("浏览/收藏/销量")
            }
            .width(100)

            TableColumn("创建时间") { game in
                Text(formatDate(game.createdAt ?? ""))
                    .font(.caption)
            }
            .width(100)

            TableColumn("操作") { game in
                GameActionsCell(
                    game: game,
                    onView: { selectedGameId = game.id },
                    onPublish: { viewModel.publish(game) },
                    onUnpublish: { viewModel.unpublish(game) },
                    onToggleTop: { viewModel.toggleTop(game) },
                    onDelete: {
                        gameToDelete = game
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
        if !viewModel.games.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadGames(page: page) }
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
}

// MARK: - 表格单元格组件
struct GameCoverCell: View {
    let covers: [String]

    var body: some View {
        AsyncImage(url: URL(string: covers.first ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(.quaternary)
        }
        .frame(width: 80, height: 45)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct GameTitleCell: View {
    let title: String
    let name: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.medium)
                .lineLimit(1)
            if let name = name, !name.isEmpty {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct GameFlagsCell: View {
    let isTop: Bool?
    let isTranslated: Bool?

    var body: some View {
        HStack(spacing: 4) {
            if isTop == true {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if isTranslated == true {
                Text("汉")
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

struct GameActionsCell: View {
    let game: Game
    let onView: () -> Void
    let onPublish: () -> Void
    let onUnpublish: () -> Void
    let onToggleTop: () -> Void
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
                if game.status == GameStatus.published.rawValue {
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
                    Label(game.isTop == true ? "取消置顶" : "置顶", systemImage: game.isTop == true ? "pin.slash" : "pin")
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

// MARK: - 游戏状态徽章
struct GameStatusBadge: View {
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
        GameStatus(rawValue: status)?.displayName ?? status
    }

    private var backgroundColor: Color {
        switch status {
        case GameStatus.published.rawValue:
            return .green
        case GameStatus.pending.rawValue:
            return .orange
        case GameStatus.unlisted.rawValue:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - 游戏定价列表
struct GamePricingListView: View {
    @StateObject private var viewModel = GamePricingListViewModel()
    @State private var showFormSheet = false
    @State private var editingPricing: GamePricing?
    @State private var showDeleteAlert = false
    @State private var pricingToDelete: GamePricing?

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
        .sheet(isPresented: $showFormSheet) {
            GamePricingFormView(pricing: editingPricing) {
                Task { await viewModel.loadPricings(page: viewModel.currentPage) }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let p = pricingToDelete {
                    Task { await viewModel.deletePricing(p) }
                }
            }
        } message: {
            Text("确定要删除定价方案「\(pricingToDelete?.name ?? "")」吗？")
        }
    }

    private var toolbarView: some View {
        HStack {
            Spacer()
            Button {
                editingPricing = nil
                showFormSheet = true
            } label: {
                Label("新建定价", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)

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
                description: Text("暂无游戏定价数据")
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

            TableColumn("游戏ID") { pricing in
                Text(pricing.gameId != nil ? String(pricing.gameId!) : "-")
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

            TableColumn("普通折扣") { pricing in
                Text(pricing.memberDiscount ?? "-")
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
                PricingFreeFlags(pricing: pricing)
            }
            .width(100)

            TableColumn("操作") { pricing in
                HStack(spacing: 8) {
                    Button("编辑") {
                        editingPricing = pricing
                        showFormSheet = true
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)

                    Button("删除") {
                        pricingToDelete = pricing
                        showDeleteAlert = true
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
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

struct PricingFreeFlags: View {
    let pricing: GamePricing

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

// MARK: - 游戏定价表单
struct GamePricingFormView: View {
    let pricing: GamePricing?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var memberDiscount = ""
    @State private var vipDiscount = ""
    @State private var svipDiscount = ""
    @State private var memberFree = false
    @State private var vipFree = false
    @State private var svipFree = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let service = GameService.shared
    private var isEditing: Bool { pricing != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? "编辑定价方案" : "新建定价方案").font(.headline)
                    if isEditing, let p = pricing {
                        Text("ID: \(p.id)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    GamePricingFormSection(title: "基本信息", systemImage: "tag") {
                        GamePricingFieldRow(label: "方案名称") {
                            TextField("例：标准版", text: $name).textFieldStyle(.roundedBorder)
                        }
                        GamePricingFieldRow(label: "售价（元）") {
                            HStack {
                                Text("¥").foregroundStyle(.secondary)
                                TextField("0.00", text: $price).textFieldStyle(.roundedBorder)
                            }
                        }
                    }

                    GamePricingFormSection(title: "会员折扣", systemImage: "percent") {
                        GamePricingDiscountRow(label: "普通会员", color: .green,   value: $memberDiscount, isFree: $memberFree)
                        Divider().padding(.leading, 8)
                        GamePricingDiscountRow(label: "VIP 会员",  color: .orange, value: $vipDiscount,    isFree: $vipFree)
                        Divider().padding(.leading, 8)
                        GamePricingDiscountRow(label: "SVIP 会员", color: .purple, value: $svipDiscount,   isFree: $svipFree)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.escape)
                Spacer()
                Button { Task { await submit() } } label: {
                    if isSubmitting {
                        HStack(spacing: 6) { ProgressView().controlSize(.small); Text("提交中...") }
                    } else {
                        Text(isEditing ? "保存更改" : "创建方案")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || name.trimmingCharacters(in: .whitespaces).isEmpty || price.isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
        .frame(width: 460)
        .onAppear { populateFields() }
    }

    private func populateFields() {
        guard let p = pricing else { return }
        name = p.name; price = p.price
        memberDiscount = p.memberDiscount ?? ""
        vipDiscount = p.vipDiscount ?? ""
        svipDiscount = p.svipDiscount ?? ""
        memberFree = p.memberFree; vipFree = p.vipFree; svipFree = p.svipFree
    }

    private func submit() async {
        isSubmitting = true; errorMessage = nil
        do {
            if let p = pricing {
                let req = UpdateGamePricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces), price: price,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree, vipFree: vipFree, svipFree: svipFree
                )
                _ = try await service.updatePricing(id: p.id, req)
            } else {
                let req = CreateGamePricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces), price: price,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree, vipFree: vipFree, svipFree: svipFree
                )
                _ = try await service.createPricing(req)
            }
            onSave(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSubmitting = false
    }
}

private struct GamePricingFormSection<Content: View>: View {
    let title: String; let systemImage: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.caption).foregroundStyle(.secondary)
                Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).textCase(.uppercase)
            }
            VStack(spacing: 8) { content }.padding(12).background(.background.secondary).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct GamePricingFieldRow<Content: View>: View {
    let label: String; @ViewBuilder let content: Content
    var body: some View {
        HStack(alignment: .center) {
            Text(label).font(.callout).frame(width: 90, alignment: .trailing)
            content
        }
    }
}

private struct GamePricingDiscountRow: View {
    let label: String; let color: Color
    @Binding var value: String; @Binding var isFree: Bool
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle().fill(color.opacity(0.2)).overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1)).frame(width: 8, height: 8)
            Text(label).font(.callout).frame(width: 82, alignment: .leading)
            if isFree {
                Text("免费").font(.caption).fontWeight(.medium).foregroundStyle(color)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(color.opacity(0.12)).clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 4) {
                    TextField("1.00", text: $value).textFieldStyle(.roundedBorder).frame(width: 70)
                    Text("折").font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle("免费", isOn: $isFree).toggleStyle(.switch).controlSize(.mini).labelsHidden().tint(color)
            Text("免费").font(.caption2).foregroundStyle(isFree ? color : .secondary)
        }
    }
}

// MARK: - 游戏订单列表
struct GameOrderListView: View {
    @StateObject private var viewModel = GameOrderListViewModel()
    @State private var userIdFilter = ""
    @State private var gameIdFilter = ""

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
                Image(systemName: "gamecontroller")
                    .foregroundStyle(.secondary)
                TextField("游戏ID", text: $gameIdFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("搜索") {
                viewModel.userId = Int(userIdFilter)
                viewModel.gameId = Int(gameIdFilter)
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
                description: Text("暂无游戏订单数据")
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
                OrderUserCell(userId: order.userId, userRole: order.userRole)
            }
            .width(100)

            TableColumn("游戏") { order in
                OrderGameCell(gameTitle: order.gameTitle, versionName: order.versionName)
            }
            .width(min: 150, ideal: 200)

            TableColumn("金额") { order in
                OrderAmountCell(amount: order.amount, discount: order.discount)
            }
            .width(80)

            TableColumn("原价") { order in
                Text("¥\(order.originalPrice)")
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

struct OrderUserCell: View {
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

struct OrderGameCell: View {
    let gameTitle: String?
    let versionName: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(gameTitle ?? "-")
                .lineLimit(1)
            if let version = versionName {
                Text("v\(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct OrderAmountCell: View {
    let amount: String
    let discount: String

    var body: some View {
        VStack(alignment: .trailing) {
            Text("¥\(amount)")
                .fontWeight(.medium)
            if discount != "0" && discount != "0.00" {
                Text("-\(discount)")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - ViewModels
@MainActor
class GameListViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterStatus: String?

    private let service = GameService.shared

    func loadGames(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = GameListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.status = filterStatus

        do {
            let response = try await service.getList(params: params)
            games = response.games
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteGame(_ game: Game) {
        Task {
            do {
                try await service.delete(id: game.id)
                await loadGames(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func publish(_ game: Game) {
        Task {
            do {
                try await service.publish(id: game.id)
                await loadGames(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func unpublish(_ game: Game) {
        Task {
            do {
                try await service.unpublish(id: game.id)
                await loadGames(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ game: Game) {
        Task {
            do {
                try await service.setTop(id: game.id, isTop: !(game.isTop ?? false))
                await loadGames(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
class GamePricingListViewModel: ObservableObject {
    @Published var pricings: [GamePricing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    private let service = GameService.shared

    func loadPricings(page: Int = 1) async {
        isLoading = true
        currentPage = page

        do {
            let response = try await service.getPricings(page: page, pageSize: 25)
            pricings = response.pricings
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deletePricing(_ pricing: GamePricing) async {
        do {
            try await service.deletePricing(id: pricing.id)
            await loadPricings(page: currentPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class GameOrderListViewModel: ObservableObject {
    @Published var orders: [GameOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var userId: Int?
    var gameId: Int?

    private let service = GameService.shared

    func loadOrders(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = GameOrderListParams(page: page, pageSize: 25)
        params.userId = userId
        params.gameId = gameId

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
    GameListContentView()
}
