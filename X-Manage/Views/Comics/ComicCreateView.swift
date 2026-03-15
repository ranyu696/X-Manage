//
//  ComicCreateView.swift
//  X-Manage
//
//  漫画创建视图

import SwiftUI

struct ComicCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ComicCreateViewModel()
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("新建漫画")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // 表单
            Form {
                Section("基本信息") {
                    TextField("标题 *", text: $viewModel.title)
                    TextField("标签 (逗号分隔)", text: $viewModel.tags)

                    Picker("类型", selection: $viewModel.comicType) {
                        ForEach(ComicType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                // 作者管理（最多3个）
                Section("作者 *") {
                    ForEach(viewModel.authors.indices, id: \.self) { index in
                        HStack {
                            TextField("作者 \(index + 1)", text: $viewModel.authors[index])

                            if viewModel.authors.count > 1 {
                                Button {
                                    viewModel.removeAuthor(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if viewModel.authors.count < 3 {
                        Button {
                            viewModel.addAuthor()
                        } label: {
                            Label("添加作者", systemImage: "plus.circle")
                        }
                    }

                    Text("最多可添加 3 位作者")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("分类与定价") {
                    Picker("分类", selection: $viewModel.categoryId) {
                        Text("请选择").tag(0)
                        ForEach(viewModel.categories, id: \.id) { category in
                            Text(category.name).tag(category.id)
                        }
                    }

                    Picker("定价方案", selection: $viewModel.pricingId) {
                        Text("请选择").tag(0)
                        ForEach(viewModel.pricings, id: \.id) { pricing in
                            Text("\(pricing.name) - ¥\(pricing.price)").tag(pricing.id)
                        }
                    }
                }

                Section("属性") {
                    Toggle("3D漫画", isOn: $viewModel.is3d)
                    Toggle("彩色", isOn: $viewModel.isColor)
                    Toggle("已完结", isOn: $viewModel.isCompleted)
                }

                Section("简介") {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                }
            }
            .formStyle(.grouped)

            Divider()

            // 底部操作栏
            HStack {
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Spacer()

                Button("创建漫画") {
                    Task {
                        if await viewModel.createComic() {
                            onSuccess()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValid || viewModel.isCreating)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 650)
        .task {
            await viewModel.loadCategories()
            await viewModel.loadPricings()
        }
    }
}

// MARK: - ViewModel
@MainActor
class ComicCreateViewModel: ObservableObject {
    @Published var title = ""
    @Published var authors: [String] = [""]  // 初始化一个空作者
    @Published var tags = ""
    @Published var description = ""
    @Published var comicType: ComicType = .bg
    @Published var categoryId = 0
    @Published var pricingId = 0
    @Published var is3d = false
    @Published var isColor = true
    @Published var isCompleted = false

    @Published var categories: [Category] = []
    @Published var pricings: [ComicPricing] = []
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let comicService = ComicService.shared
    private let categoryService = CategoryService.shared

    var isValid: Bool {
        !title.isEmpty && hasValidAuthors && categoryId > 0 && pricingId > 0
    }

    // 检查是否至少有一个有效作者
    private var hasValidAuthors: Bool {
        authors.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    // 添加作者
    func addAuthor() {
        if authors.count < 3 {
            authors.append("")
        }
    }

    // 移除作者
    func removeAuthor(at index: Int) {
        if authors.count > 1 {
            authors.remove(at: index)
        }
    }

    func loadCategories() async {
        do {
            // 使用 slug 获取漫画分类
            let response = try await categoryService.getChildrenBySlug("comic")
            categories = response.categories
        } catch {
            // 忽略加载错误
        }
    }

    func loadPricings() async {
        do {
            let response = try await comicService.getPricings(page: 1, pageSize: 100)
            pricings = response.pricings
        } catch {
            // 忽略加载错误
        }
    }

    func createComic() async -> Bool {
        isCreating = true
        errorMessage = nil

        do {
            // 过滤空作者
            let validAuthors = authors.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

            if validAuthors.isEmpty {
                errorMessage = "请至少添加一个作者"
                isCreating = false
                return false
            }

            let request = CreateComicRequest(
                title: title,
                description: description,
                is3d: is3d,
                isColor: isColor,
                comicType: comicType,
                authors: validAuthors,
                categoryId: categoryId,
                pricingId: pricingId,
                isCompleted: isCompleted,
                tags: tags
            )
            _ = try await comicService.create(request: request)
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
            return false
        }
    }
}

#Preview {
    ComicCreateView(onSuccess: {})
}
