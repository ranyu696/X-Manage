//
//  AnimeListView.swift
//  X-Manage
//
//  动漫管理视图

import SwiftUI

// MARK: - 动漫列表内容视图
struct AnimeListContentView: View {
    @StateObject private var viewModel = AnimeListViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: AnimeStatus?
    @State private var selectedAnimeId: Int?
    @State private var showCreateSheet = false
    @State private var showDeleteAlert = false
    @State private var animeToDelete: Anime?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧列表
            VStack(spacing: 0) {
                contentView
                paginationView
            }

            // 右侧详情面板
            if let animeId = selectedAnimeId {
                Divider()
                AnimeDetailPanel(
                    animeId: animeId,
                    onUpdate: {
                        Task { await viewModel.loadAnimes(page: viewModel.currentPage) }
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedAnimeId = nil
                        }
                    }
                )
                .id(animeId)
                .frame(width: 500)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedAnimeId)
        .task {
            await viewModel.loadAnimes()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task { await viewModel.loadAnimes() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadAnimes() }
        }
        .sheet(isPresented: $showCreateSheet) {
            AnimeCreateView {
                Task { await viewModel.loadAnimes() }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let anime = animeToDelete {
                    viewModel.deleteAnime(anime)
                }
            }
        } message: {
            Text("确定要删除动漫「\(animeToDelete?.title ?? "")」吗？此操作不可恢复。")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索动漫...", text: $searchText)
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
                    Text("全部状态").tag(nil as AnimeStatus?)
                    ForEach(AnimeStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as AnimeStatus?)
                    }
                }
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadAnimes() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建动漫", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - 内容视图
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.animes.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.animes.isEmpty {
            ContentUnavailableView(
                "暂无动漫",
                systemImage: "play.tv",
                description: Text("点击右上角按钮创建第一个动漫")
            )
        } else {
            animeTable
        }
    }

    private var animeTable: some View {
        Table(viewModel.animes, selection: $selectedAnimeId) {
            TableColumn("ID") { anime in
                Text(String(anime.id))
                    .font(.caption.monospaced())
            }
            .width(60)

            TableColumn("封面") { anime in
                AnimeCoverCell(cover: anime.cover)
            }
            .width(80)

            TableColumn("标题") { anime in
                AnimeTitleCell(title: anime.title, studio: anime.studio)
            }
            .width(min: 150, ideal: 200)

            TableColumn("状态") { anime in
                HStack(spacing: 4) {
                    AnimeStatusBadge(status: anime.status)
                    AnimeFlagsCell(isTop: anime.isTop, isCompleted: anime.isCompleted)
                }
            }
            .width(130)

            TableColumn("集数") { anime in
                Text("\(anime.currentEpisode ?? 0)/\(anime.episodeCount ?? 0)")
                    .font(.caption.monospacedDigit())
            }
            .width(70)

            TableColumn("统计") { anime in
                Text("\(anime.viewCount ?? 0)/\(anime.favoriteCount ?? 0)")
                    .font(.caption.monospacedDigit())
                    .help("浏览/收藏")
            }
            .width(80)

            TableColumn("操作") { anime in
                AnimeActionsCell(
                    anime: anime,
                    onView: { selectedAnimeId = anime.id },
                    onPublish: { viewModel.publish(anime) },
                    onUnpublish: { viewModel.unpublish(anime) },
                    onToggleTop: { viewModel.toggleTop(anime) },
                    onToggleComplete: { viewModel.toggleComplete(anime) },
                    onDelete: {
                        animeToDelete = anime
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
        if !viewModel.animes.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadAnimes(page: page) }
                }
            )
            .padding()
        }
    }
}

// MARK: - 表格单元格组件
struct AnimeCoverCell: View {
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
        .frame(width: 60, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct AnimeTitleCell: View {
    let title: String
    let studio: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.medium)
                .lineLimit(1)
            if let studio = studio, !studio.isEmpty {
                Text(studio)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct AnimeFlagsCell: View {
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

struct AnimeActionsCell: View {
    let anime: Anime
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
                if anime.status == AnimeStatus.published.rawValue {
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
                    Label(anime.isTop == true ? "取消置顶" : "置顶", systemImage: anime.isTop == true ? "pin.slash" : "pin")
                }

                Button {
                    onToggleComplete()
                } label: {
                    Label(anime.isCompleted == true ? "设为连载" : "设为完结", systemImage: anime.isCompleted == true ? "book" : "checkmark.circle")
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

// MARK: - 动漫状态徽章
struct AnimeStatusBadge: View {
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
        AnimeStatus(rawValue: status)?.displayName ?? status
    }

    private var backgroundColor: Color {
        switch status {
        case AnimeStatus.published.rawValue:
            return .green
        case AnimeStatus.pending.rawValue:
            return .orange
        case AnimeStatus.unlisted.rawValue:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - 动漫定价列表
struct AnimePricingListView: View {
    @StateObject private var viewModel = AnimePricingListViewModel()
    @State private var showFormSheet = false
    @State private var editingPricing: AnimePricing?
    @State private var showDeleteAlert = false
    @State private var pricingToDelete: AnimePricing?

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
            AnimePricingFormView(pricing: editingPricing) {
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
                description: Text("暂无动漫定价数据")
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

            TableColumn("名称", value: \.name)
                .width(min: 100, ideal: 150)

            TableColumn("价格") { pricing in
                Text("¥\(pricing.price)")
                    .fontWeight(.medium)
            }
            .width(80)

            TableColumn("预览时长") { pricing in
                Text("\(pricing.previewSeconds)秒")
            }
            .width(80)

            TableColumn("VIP折扣") { pricing in
                Text(pricing.vipDiscount)
            }
            .width(80)

            TableColumn("SVIP折扣") { pricing in
                Text(pricing.svipDiscount)
            }
            .width(80)

            TableColumn("免费标记") { pricing in
                AnimePricingFreeFlags(pricing: pricing)
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

struct AnimePricingFreeFlags: View {
    let pricing: AnimePricing

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

// MARK: - 动漫定价表单
struct AnimePricingFormView: View {
    let pricing: AnimePricing?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var previewSeconds = 0
    @State private var memberDiscount = ""
    @State private var vipDiscount = ""
    @State private var svipDiscount = ""
    @State private var memberFree = false
    @State private var vipFree = false
    @State private var svipFree = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let service = AnimeService.shared
    private var isEditing: Bool { pricing != nil }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? "编辑定价方案" : "新建定价方案")
                        .font(.headline)
                    if isEditing, let p = pricing {
                        Text("ID: \(p.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // 基本信息
                    PricingFormSection(title: "基本信息", systemImage: "tag") {
                        PricingFieldRow(label: "方案名称") {
                            TextField("例：普通套餐", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        PricingFieldRow(label: "售价（元）") {
                            HStack {
                                Text("¥")
                                    .foregroundStyle(.secondary)
                                TextField("0.00", text: $price)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        PricingFieldRow(label: "试看时长") {
                            HStack {
                                TextField("0", value: $previewSeconds, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Stepper("", value: $previewSeconds, in: 0...3600, step: 60)
                                    .labelsHidden()
                                Text("秒")
                                    .foregroundStyle(.secondary)
                                if previewSeconds > 0 {
                                    Text("(\(previewSeconds / 60)分\(previewSeconds % 60)秒)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // 会员折扣
                    PricingFormSection(title: "会员折扣", systemImage: "percent") {
                        PricingDiscountRow(
                            label: "普通会员",
                            color: .green,
                            value: $memberDiscount,
                            isFree: $memberFree
                        )
                        Divider().padding(.leading, 8)
                        PricingDiscountRow(
                            label: "VIP 会员",
                            color: .orange,
                            value: $vipDiscount,
                            isFree: $vipFree
                        )
                        Divider().padding(.leading, 8)
                        PricingDiscountRow(
                            label: "SVIP 会员",
                            color: .purple,
                            value: $svipDiscount,
                            isFree: $svipFree
                        )
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }

            Divider()

            // 底部按钮
            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("提交中...")
                        }
                    } else {
                        Text(isEditing ? "保存更改" : "创建方案")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || name.trimmingCharacters(in: .whitespaces).isEmpty || price.isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 480)
        .onAppear { populateFields() }
    }

    private func populateFields() {
        guard let p = pricing else { return }
        name = p.name
        price = p.price
        previewSeconds = p.previewSeconds
        memberDiscount = p.memberDiscount
        vipDiscount = p.vipDiscount
        svipDiscount = p.svipDiscount
        memberFree = p.memberFree
        vipFree = p.vipFree
        svipFree = p.svipFree
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            if let p = pricing {
                let req = UpdateAnimePricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces),
                    price: price,
                    previewSeconds: previewSeconds,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree,
                    vipFree: vipFree,
                    svipFree: svipFree
                )
                _ = try await service.updatePricing(id: p.id, req)
            } else {
                let req = CreateAnimePricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces),
                    price: price,
                    previewSeconds: previewSeconds,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree,
                    vipFree: vipFree,
                    svipFree: svipFree
                )
                _ = try await service.createPricing(req)
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - 定价表单共用组件
private struct PricingFormSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            VStack(spacing: 8) {
                content
            }
            .padding(12)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct PricingFieldRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.callout)
                .frame(width: 90, alignment: .trailing)
                .foregroundStyle(.primary)
            content
        }
    }
}

private struct PricingDiscountRow: View {
    let label: String
    let color: Color
    @Binding var value: String
    @Binding var isFree: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(color.opacity(0.2))
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.callout)
                .frame(width: 82, alignment: .leading)

            if isFree {
                Text("免费")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 4) {
                    TextField("1.00", text: $value)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("折")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Toggle("免费", isOn: $isFree)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(color)

            Text("免费")
                .font(.caption2)
                .foregroundStyle(isFree ? color : .secondary)
        }
    }
}

// MARK: - 动漫订单列表
struct AnimeOrderListView: View {
    @StateObject private var viewModel = AnimeOrderListViewModel()
    @State private var userIdFilter = ""
    @State private var animeIdFilter = ""

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
                Image(systemName: "play.tv")
                    .foregroundStyle(.secondary)
                TextField("动漫ID", text: $animeIdFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("搜索") {
                viewModel.userId = Int(userIdFilter)
                viewModel.animeId = Int(animeIdFilter)
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
                description: Text("暂无动漫订单数据")
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

            TableColumn("用户ID") { order in
                Text("ID: \(order.userId)")
                    .font(.caption.monospaced())
            }
            .width(100)

            TableColumn("动漫") { order in
                Text(order.animeTitle)
                    .lineLimit(1)
            }
            .width(min: 150, ideal: 200)

            TableColumn("金额") { order in
                Text("¥\(order.amount)")
                    .fontWeight(.medium)
            }
            .width(80)

            TableColumn("时间") { order in
                Text(formatOrderDate(order.createdAt))
                    .font(.caption)
            }
            .width(100)
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

// MARK: - ViewModels
@MainActor
class AnimeListViewModel: ObservableObject {
    @Published var animes: [Anime] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterStatus: AnimeStatus?

    private let service = AnimeService.shared

    func loadAnimes(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = AnimeListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.status = filterStatus

        do {
            let response = try await service.getList(params: params)
            animes = response.animes
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteAnime(_ anime: Anime) {
        Task {
            do {
                try await service.delete(id: anime.id)
                await loadAnimes(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func publish(_ anime: Anime) {
        Task {
            do {
                try await service.publish(id: anime.id)
                await loadAnimes(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func unpublish(_ anime: Anime) {
        Task {
            do {
                try await service.unpublish(id: anime.id)
                await loadAnimes(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ anime: Anime) {
        Task {
            do {
                try await service.setTop(id: anime.id, isTop: !(anime.isTop ?? false))
                await loadAnimes(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleComplete(_ anime: Anime) {
        Task {
            do {
                try await service.setComplete(id: anime.id, isCompleted: !(anime.isCompleted ?? false))
                await loadAnimes(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
class AnimePricingListViewModel: ObservableObject {
    @Published var pricings: [AnimePricing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    private let service = AnimeService.shared

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

    func deletePricing(_ pricing: AnimePricing) async {
        do {
            try await service.deletePricing(id: pricing.id)
            await loadPricings(page: currentPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class AnimeOrderListViewModel: ObservableObject {
    @Published var orders: [AnimeOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var userId: Int?
    var animeId: Int?

    private let service = AnimeService.shared

    func loadOrders(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = AnimeOrderListParams(page: page, pageSize: 25)
        params.userId = userId
        params.animeId = animeId

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
    AnimeListContentView()
}
