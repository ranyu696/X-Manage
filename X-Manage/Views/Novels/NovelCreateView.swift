//
//  NovelCreateView.swift
//  X-Manage
//
//  小说创建视图

import SwiftUI

struct NovelCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovelCreateViewModel()
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("新建小说")
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
                    TextField("作者 *", text: $viewModel.author)
                    TextField("系列", text: $viewModel.series)
                    TextField("标签 (逗号分隔)", text: $viewModel.tags)
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

                Section("简介") {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 150)
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

                Button("创建小说") {
                    Task {
                        if await viewModel.createNovel() {
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
        .frame(minWidth: 500, minHeight: 500)
        .task {
            await viewModel.loadCategories()
            await viewModel.loadPricings()
        }
    }
}

// MARK: - ViewModel
@MainActor
class NovelCreateViewModel: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var series = ""
    @Published var tags = ""
    @Published var description = ""
    @Published var categoryId = 0
    @Published var pricingId = 0

    @Published var categories: [Category] = []
    @Published var pricings: [NovelPricing] = []
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let novelService = NovelService.shared
    private let categoryService = CategoryService.shared

    var isValid: Bool {
        !title.isEmpty && !author.isEmpty && categoryId > 0 && pricingId > 0
    }

    func loadCategories() async {
        do {
            // 使用 slug 获取小说分类
            let response = try await categoryService.getChildrenBySlug("novel")
            categories = response.categories
        } catch {
            // 忽略加载错误
        }
    }

    func loadPricings() async {
        do {
            let response = try await novelService.getPricings(page: 1, pageSize: 100)
            pricings = response.pricings
        } catch {
            // 忽略加载错误
        }
    }

    func createNovel() async -> Bool {
        isCreating = true
        errorMessage = nil

        do {
            let trimmedTags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
            let request = CreateNovelRequest(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                series: series.isEmpty ? nil : series.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: trimmedTags.isEmpty ? nil : trimmedTags,
                categoryId: categoryId,
                pricingId: pricingId
            )
            _ = try await novelService.create(request: request)
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
    NovelCreateView(onSuccess: {})
}
