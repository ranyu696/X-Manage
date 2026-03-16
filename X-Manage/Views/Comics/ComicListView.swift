//
//  ComicListView.swift
//  X-Manage
//
//  漫画管理视图

import SwiftUI

// MARK: - 漫画列表内容视图
struct ComicListContentView: View {
    @StateObject private var viewModel = ComicListViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: ComicStatus?
    @State private var selectedType: ComicType?
    @State private var selectedComicId: Int?
    @State private var showCreateSheet = false
    @State private var showDeleteAlert = false
    @State private var comicToDelete: Comic?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧列表
            VStack(spacing: 0) {
                contentView
                paginationView
            }

            // 右侧详情面板
            if let comicId = selectedComicId {
                Divider()
                ComicDetailPanel(
                    comicId: comicId,
                    onUpdate: {
                        Task { await viewModel.loadComics(page: viewModel.currentPage) }
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedComicId = nil
                        }
                    }
                )
                .id(comicId)
                .frame(width: 500)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedComicId)
        .task {
            await viewModel.loadComics()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task { await viewModel.loadComics() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadComics() }
        }
        .onChange(of: selectedType) { _, newValue in
            viewModel.filterType = newValue
            Task { await viewModel.loadComics() }
        }
        .sheet(isPresented: $showCreateSheet) {
            ComicCreateView {
                Task { await viewModel.loadComics() }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let comic = comicToDelete {
                    viewModel.deleteComic(comic)
                }
            }
        } message: {
            Text("确定要删除漫画「\(comicToDelete?.title ?? "")」吗？此操作不可恢复。")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索漫画...", text: $searchText)
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
                    Text("全部状态").tag(nil as ComicStatus?)
                    ForEach(ComicStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as ComicStatus?)
                    }
                }
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Picker("类型", selection: $selectedType) {
                    Text("全部类型").tag(nil as ComicType?)
                    ForEach(ComicType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type as ComicType?)
                    }
                }
                .frame(width: 90)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadComics() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建漫画", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - 内容视图
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.comics.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.comics.isEmpty {
            ContentUnavailableView(
                "暂无漫画",
                systemImage: "book.closed",
                description: Text("点击右上角按钮创建第一个漫画")
            )
        } else {
            comicTable
        }
    }

    private var comicTable: some View {
        Table(viewModel.comics, selection: $selectedComicId) {
            TableColumn("ID") { comic in
                Text(String(comic.id))
                    .font(.caption.monospaced())
            }
            .width(60)

            TableColumn("封面") { comic in
                ComicCoverCell(cover: comic.cover)
            }
            .width(60)

            TableColumn("标题") { comic in
                ComicTitleCell(title: comic.title, authors: comic.authors)
            }
            .width(min: 150, ideal: 200)

            TableColumn("状态") { comic in
                HStack(spacing: 4) {
                    ComicStatusBadge(status: comic.status)
                    ComicFlagsCell(isTop: comic.isTop, isCompleted: comic.isCompleted, is3d: comic.is3d, comicType: comic.comicType)
                }
            }
            .width(150)

            TableColumn("章节") { comic in
                Text("\(comic.chapterCount ?? 0)")
                    .font(.caption.monospacedDigit())
            }
            .width(60)

            TableColumn("统计") { comic in
                Text("\(comic.viewCount ?? 0)/\(comic.favoriteCount ?? 0)")
                    .font(.caption.monospacedDigit())
                    .help("浏览/收藏")
            }
            .width(80)

            TableColumn("创建时间") { comic in
                Text(formatDate(comic.createdAt ?? ""))
                    .font(.caption)
            }
            .width(100)

            TableColumn("操作") { comic in
                ComicActionsCell(
                    comic: comic,
                    onView: { selectedComicId = comic.id },
                    onPublish: { viewModel.publish(comic) },
                    onUnpublish: { viewModel.unpublish(comic) },
                    onToggleTop: { viewModel.toggleTop(comic) },
                    onToggleComplete: { viewModel.toggleComplete(comic) },
                    onDelete: {
                        comicToDelete = comic
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
        if !viewModel.comics.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadComics(page: page) }
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
struct ComicCoverCell: View {
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

struct ComicTitleCell: View {
    let title: String
    let authors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(authors.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct ComicFlagsCell: View {
    let isTop: Bool?
    let isCompleted: Bool?
    let is3d: Bool?
    let comicType: String?

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
            }
            if is3d == true {
                Text("3D")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.purple.opacity(0.2))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if let type = comicType {
                Text(type)
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

struct ComicActionsCell: View {
    let comic: Comic
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
                if comic.status == ComicStatus.published.rawValue {
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
                    Label(comic.isTop == true ? "取消置顶" : "置顶", systemImage: comic.isTop == true ? "pin.slash" : "pin")
                }

                Button {
                    onToggleComplete()
                } label: {
                    Label(comic.isCompleted == true ? "设为连载" : "设为完结", systemImage: comic.isCompleted == true ? "book" : "checkmark.circle")
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

// MARK: - 漫画状态徽章
struct ComicStatusBadge: View {
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
        ComicStatus(rawValue: status)?.displayName ?? status
    }

    private var backgroundColor: Color {
        switch status {
        case ComicStatus.published.rawValue:
            return .green
        case ComicStatus.pending.rawValue:
            return .orange
        case ComicStatus.unlisted.rawValue:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - 漫画定价列表
struct ComicPricingListView: View {
    @StateObject private var viewModel = ComicPricingListViewModel()
    @State private var showFormSheet = false
    @State private var editingPricing: ComicPricing?
    @State private var showDeleteAlert = false
    @State private var pricingToDelete: ComicPricing?

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
            ComicPricingFormView(pricing: editingPricing) {
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
                description: Text("暂无漫画定价数据")
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

            TableColumn("预览章节") { pricing in
                Text("\(pricing.previewCount)章")
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
                ComicPricingFreeFlags(pricing: pricing)
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

// MARK: - 漫画定价表单
struct ComicPricingFormView: View {
    let pricing: ComicPricing?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var previewCount = 0
    @State private var memberDiscount = ""
    @State private var vipDiscount = ""
    @State private var svipDiscount = ""
    @State private var memberFree = false
    @State private var vipFree = false
    @State private var svipFree = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let service = ComicService.shared
    private var isEditing: Bool { pricing != nil }

    var body: some View {
        VStack(spacing: 0) {
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
                    ComicPricingFormSection(title: "基本信息", systemImage: "tag") {
                        ComicPricingFieldRow(label: "方案名称") {
                            TextField("例：普通套餐", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        ComicPricingFieldRow(label: "售价（元）") {
                            HStack {
                                Text("¥").foregroundStyle(.secondary)
                                TextField("0.00", text: $price)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        ComicPricingFieldRow(label: "预览章节") {
                            HStack {
                                TextField("0", value: $previewCount, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Stepper("", value: $previewCount, in: 0...100)
                                    .labelsHidden()
                                Text("章").foregroundStyle(.secondary)
                            }
                        }
                    }

                    ComicPricingFormSection(title: "会员折扣", systemImage: "percent") {
                        ComicPricingDiscountRow(label: "普通会员", color: .green,   value: $memberDiscount, isFree: $memberFree)
                        Divider().padding(.leading, 8)
                        ComicPricingDiscountRow(label: "VIP 会员",  color: .orange, value: $vipDiscount,    isFree: $vipFree)
                        Divider().padding(.leading, 8)
                        ComicPricingDiscountRow(label: "SVIP 会员", color: .purple, value: $svipDiscount,   isFree: $svipFree)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(error).font(.caption).foregroundStyle(.red)
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

            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.escape)
                Spacer()
                Button {
                    Task { await submit() }
                } label: {
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
        previewCount = p.previewCount
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
                let req = UpdateComicPricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces), price: price, previewCount: previewCount,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree, vipFree: vipFree, svipFree: svipFree
                )
                _ = try await service.updatePricing(id: p.id, req)
            } else {
                let req = CreateComicPricingRequest(
                    name: name.trimmingCharacters(in: .whitespaces), price: price, previewCount: previewCount,
                    memberDiscount: memberDiscount.isEmpty ? "1.00" : memberDiscount,
                    vipDiscount: vipDiscount.isEmpty ? "1.00" : vipDiscount,
                    svipDiscount: svipDiscount.isEmpty ? "1.00" : svipDiscount,
                    memberFree: memberFree, vipFree: vipFree, svipFree: svipFree
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

private struct ComicPricingFormSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.caption).foregroundStyle(.secondary)
                Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).textCase(.uppercase)
            }
            VStack(spacing: 8) { content }
                .padding(12)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct ComicPricingFieldRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center) {
            Text(label).font(.callout).frame(width: 90, alignment: .trailing)
            content
        }
    }
}

private struct ComicPricingDiscountRow: View {
    let label: String
    let color: Color
    @Binding var value: String
    @Binding var isFree: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle().fill(color.opacity(0.2)).overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1)).frame(width: 8, height: 8)
            Text(label).font(.callout).frame(width: 82, alignment: .leading)
            if isFree {
                Text("免费").font(.caption).fontWeight(.medium).foregroundStyle(color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.12)).clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 4) {
                    TextField("1.00", text: $value).textFieldStyle(.roundedBorder).frame(width: 70)
                    Text("折").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle("免费", isOn: $isFree).toggleStyle(.switch).controlSize(.mini).labelsHidden().tint(color)
            Text("免费").font(.caption2).foregroundStyle(isFree ? color : .secondary)
        }
    }
}

struct ComicPricingFreeFlags: View {
    let pricing: ComicPricing

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

// MARK: - 漫画订单列表
struct ComicOrderListView: View {
    @StateObject private var viewModel = ComicOrderListViewModel()
    @State private var userIdFilter = ""
    @State private var comicIdFilter = ""

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
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
                TextField("漫画ID", text: $comicIdFilter)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("搜索") {
                viewModel.userId = Int(userIdFilter)
                viewModel.comicId = Int(comicIdFilter)
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
                description: Text("暂无漫画订单数据")
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

            TableColumn("漫画") { order in
                Text(order.comicTitle)
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
class ComicListViewModel: ObservableObject {
    @Published var comics: [Comic] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterStatus: ComicStatus?
    var filterType: ComicType?

    private let service = ComicService.shared

    func loadComics(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = ComicListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.status = filterStatus
        params.comicType = filterType

        do {
            let response = try await service.getList(params: params)
            comics = response.comics
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteComic(_ comic: Comic) {
        Task {
            do {
                try await service.delete(id: comic.id)
                await loadComics(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func publish(_ comic: Comic) {
        Task {
            do {
                try await service.publish(id: comic.id)
                await loadComics(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func unpublish(_ comic: Comic) {
        Task {
            do {
                try await service.unpublish(id: comic.id)
                await loadComics(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ comic: Comic) {
        Task {
            do {
                try await service.setTop(id: comic.id, isTop: !(comic.isTop ?? false))
                await loadComics(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleComplete(_ comic: Comic) {
        Task {
            do {
                try await service.setComplete(id: comic.id, isCompleted: !(comic.isCompleted ?? false))
                await loadComics(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
class ComicPricingListViewModel: ObservableObject {
    @Published var pricings: [ComicPricing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    private let service = ComicService.shared

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

    func deletePricing(_ pricing: ComicPricing) async {
        do {
            try await service.deletePricing(id: pricing.id)
            await loadPricings(page: currentPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class ComicOrderListViewModel: ObservableObject {
    @Published var orders: [ComicOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var userId: Int?
    var comicId: Int?

    private let service = ComicService.shared

    func loadOrders(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = ComicOrderListParams(page: page, pageSize: 25)
        params.userId = userId
        params.comicId = comicId

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
    ComicListContentView()
}
