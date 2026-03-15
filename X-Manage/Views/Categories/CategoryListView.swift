//
//  CategoryListView.swift
//  X-Manage
//
//  分类列表视图 - 树形结构

import SwiftUI

struct CategoryListView: View {
    @StateObject private var viewModel = CategoryListViewModel()
    @State private var showCreateSheet = false
    @State private var editingCategory: Category?
    @State private var addChildParent: Category?
    @State private var expandedIds: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.categories.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.categories.isEmpty {
                ContentUnavailableView(
                    "暂无分类",
                    systemImage: "folder",
                    description: Text("点击右上角按钮创建第一个分类")
                )
            } else {
                List {
                    ForEach(viewModel.categories) { category in
                        CategoryTreeNode(
                            category: category,
                            expandedIds: $expandedIds,
                            onEdit: { editingCategory = $0 },
                            onAddChild: { addChildParent = $0 },
                            onDelete: { viewModel.deleteCategory($0) }
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .task {
            await viewModel.loadCategoryTree()
        }
        .sheet(isPresented: $showCreateSheet) {
            CategoryFormView(
                mode: .create,
                parentCategories: viewModel.flattenedCategories
            ) { _ in
                Task {
                    await viewModel.loadCategoryTree()
                }
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(
                mode: .edit(category),
                parentCategories: viewModel.flattenedCategories.filter { $0.id != category.id }
            ) { _ in
                Task {
                    await viewModel.loadCategoryTree()
                }
            }
        }
        .sheet(item: $addChildParent) { parent in
            CategoryFormView(
                mode: .createChild(parent),
                parentCategories: viewModel.flattenedCategories
            ) { _ in
                Task {
                    await viewModel.loadCategoryTree()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await viewModel.loadCategoryTree()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    expandedIds = Set(viewModel.allCategoryIds)
                } label: {
                    Label("展开全部", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                .buttonStyle(.bordered)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    expandedIds = []
                } label: {
                    Label("折叠全部", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.bordered)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建分类", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - 树节点视图
struct CategoryTreeNode: View {
    let category: Category
    @Binding var expandedIds: Set<Int>
    let onEdit: (Category) -> Void
    let onAddChild: (Category) -> Void
    let onDelete: (Category) -> Void

    private var isExpanded: Bool {
        expandedIds.contains(category.id)
    }

    private var hasChildren: Bool {
        !(category.children?.isEmpty ?? true)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 当前节点
            HStack(spacing: 12) {
                // 展开/折叠按钮
                if hasChildren {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isExpanded {
                                expandedIds.remove(category.id)
                            } else {
                                expandedIds.insert(category.id)
                            }
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 16)
                }

                // 图标
                if !category.picture.isEmpty {
                    AsyncImage(url: URL(string: category.picture)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: hasChildren ? "folder.fill" : "doc.fill")
                        .foregroundStyle(hasChildren ? .yellow : .secondary)
                        .frame(width: 32)
                }

                // 名称
                Text(category.name)
                    .fontWeight(.medium)

                // Slug 标签
                Text(category.slug)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                // 项目数量
                Text("内容: \(category.itemCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())

                // 状态
                Text(category.status == "active" ? "启用" : "禁用")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.status == "active" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundStyle(category.status == "active" ? .green : .gray)
                    .clipShape(Capsule())

                // 操作按钮
                HStack(spacing: 4) {
                    Button {
                        onAddChild(category)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
                    .help("添加子分类")

                    Button {
                        onEdit(category)
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                    .help("编辑分类")

                    Button {
                        onDelete(category)
                    } label: {
                        Image(systemName: "trash.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                    .help("删除分类")
                }
            }
            .padding(.vertical, 6)

            // 子节点
            if hasChildren && isExpanded {
                VStack(spacing: 0) {
                    ForEach(category.children ?? []) { child in
                        HStack(spacing: 0) {
                            // 缩进
                            Color.clear
                                .frame(width: 24)

                            CategoryTreeNode(
                                category: child,
                                expandedIds: $expandedIds,
                                onEdit: onEdit,
                                onAddChild: onAddChild,
                                onDelete: onDelete
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 分类表单
struct CategoryFormView: View {
    enum Mode {
        case create
        case createChild(Category)
        case edit(Category)
    }

    let mode: Mode
    let parentCategories: [FlatCategory]
    let onSave: (Category) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var slug = ""
    @State private var description = ""
    @State private var parentId: Int? = nil
    @State private var sort = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(mode: Mode, parentCategories: [FlatCategory], onSave: @escaping (Category) -> Void) {
        self.mode = mode
        self.parentCategories = parentCategories
        self.onSave = onSave

        switch mode {
        case .edit(let category):
            _name = State(initialValue: category.name)
            _slug = State(initialValue: category.slug)
            _description = State(initialValue: category.description)
            _parentId = State(initialValue: category.parentId)
            _sort = State(initialValue: category.sort)
        case .createChild(let parent):
            _parentId = State(initialValue: parent.id)
        case .create:
            break
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            Form {
                Section("基本信息") {
                    TextField("名称 *", text: $name)
                    TextField("Slug *", text: $slug)
                    TextField("排序", value: $sort, format: .number)
                        .frame(width: 100)
                }

                Section("父分类") {
                    Picker("父分类", selection: $parentId) {
                        Text("无（根分类）").tag(nil as Int?)
                        ForEach(parentCategories) { cat in
                            Text(cat.displayName).tag(cat.id as Int?)
                        }
                    }
                }

                Section("描述") {
                    TextEditor(text: $description)
                        .frame(height: 80)
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || slug.isEmpty || isSaving)
            }
            .padding()
        }
        .frame(width: 450, height: 480)
    }

    private var title: String {
        switch mode {
        case .create: return "新建分类"
        case .createChild(let parent): return "添加子分类 - \(parent.name)"
        case .edit: return "编辑分类"
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let service = CategoryService.shared

                switch mode {
                case .create, .createChild:
                    let request = CreateCategoryRequest(
                        name: name,
                        slug: slug,
                        description: description,
                        picture: "",
                        parentId: parentId,
                        sort: sort
                    )
                    let category = try await service.create(request: request)
                    onSave(category)
                    dismiss()

                case .edit(let existing):
                    let request = UpdateCategoryRequest(
                        name: name,
                        slug: slug,
                        description: description,
                        picture: nil,
                        parentId: parentId,
                        sort: sort
                    )
                    let category = try await service.update(id: existing.id, request: request)
                    onSave(category)
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 扁平化分类（用于父分类选择）
struct FlatCategory: Identifiable {
    let id: Int
    let name: String
    let level: Int

    var displayName: String {
        String(repeating: "— ", count: level) + name
    }
}

// MARK: - ViewModel
@MainActor
class CategoryListViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = CategoryService.shared

    // 获取所有分类ID（用于展开全部）
    var allCategoryIds: [Int] {
        func collectIds(_ cats: [Category]) -> [Int] {
            var ids: [Int] = []
            for cat in cats {
                ids.append(cat.id)
                if let children = cat.children {
                    ids.append(contentsOf: collectIds(children))
                }
            }
            return ids
        }
        return collectIds(categories)
    }

    // 扁平化分类列表（用于父分类选择下拉框）
    var flattenedCategories: [FlatCategory] {
        func flatten(_ cats: [Category], level: Int) -> [FlatCategory] {
            var result: [FlatCategory] = []
            for cat in cats {
                result.append(FlatCategory(id: cat.id, name: cat.name, level: level))
                if let children = cat.children {
                    result.append(contentsOf: flatten(children, level: level + 1))
                }
            }
            return result
        }
        return flatten(categories, level: 0)
    }

    func loadCategoryTree() async {
        isLoading = true

        do {
            let response = try await service.getTree()
            categories = response.categories
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteCategory(_ category: Category) {
        Task {
            do {
                try await service.delete(id: category.id)
                await loadCategoryTree()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    CategoryListView()
}
