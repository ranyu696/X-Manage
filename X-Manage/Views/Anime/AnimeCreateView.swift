//
//  AnimeCreateView.swift
//  X-Manage
//
//  动漫创建视图

import SwiftUI

struct AnimeCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AnimeCreateViewModel()
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("新建动漫")
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
                    TextField("原名", text: $viewModel.titleOriginal)
                    TextField("番号 (逗号分隔)", text: $viewModel.codesInput)
                    TextField("制作公司 *", text: $viewModel.studio)
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

                Section("剧集信息") {
                    TextField("总集数 *", value: $viewModel.totalEpisodes, format: .number)
                    TextField("季度", value: $viewModel.season, format: .number)
                    TextField("播出日期 (YYYY-MM-DD)", text: $viewModel.airDate)
                    TextField("完结日期 (YYYY-MM-DD)", text: $viewModel.endDate)
                }

                Section("其他") {
                    Picker("区域", selection: $viewModel.region) {
                        Text("请选择").tag("")
                        Text("日本").tag("japan")
                        Text("中国").tag("china")
                        Text("欧美").tag("europe")
                        Text("韩国").tag("korea")
                    }

                    Picker("画质", selection: $viewModel.quality) {
                        Text("请选择").tag("")
                        Text("4K").tag("4k")
                        Text("1080P").tag("1080")
                        Text("720P").tag("720")
                    }

                    Picker("制作状态 *", selection: $viewModel.productionStatus) {
                        Text("请选择").tag("")
                        Text("连载中").tag("ongoing")
                        Text("已完结").tag("completed")
                        Text("即将上映").tag("upcoming")
                    }
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

                Button("创建动漫") {
                    Task {
                        if await viewModel.createAnime() {
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
        .frame(minWidth: 500, minHeight: 700)
        .task {
            await viewModel.loadCategories()
            await viewModel.loadPricings()
        }
    }
}

// MARK: - ViewModel
@MainActor
class AnimeCreateViewModel: ObservableObject {
    @Published var title = ""
    @Published var titleOriginal = ""
    @Published var codesInput = ""
    @Published var studio = ""
    @Published var tags = ""
    @Published var description = ""
    @Published var categoryId = 0
    @Published var pricingId = 0
    @Published var totalEpisodes = 12
    @Published var season: Int?
    @Published var airDate = ""
    @Published var endDate = ""
    @Published var region = ""
    @Published var quality = ""
    @Published var productionStatus = ""

    @Published var categories: [Category] = []
    @Published var pricings: [AnimePricing] = []
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let animeService = AnimeService.shared
    private let categoryService = CategoryService.shared

    var isValid: Bool {
        !title.isEmpty && !studio.isEmpty && categoryId > 0 && pricingId > 0 && totalEpisodes > 0 && !productionStatus.isEmpty
    }

    func loadCategories() async {
        do {
            // 使用 slug 获取动漫分类
            let response = try await categoryService.getChildrenBySlug("anime")
            categories = response.categories
        } catch {
            // 忽略加载错误
        }
    }

    func loadPricings() async {
        do {
            let response = try await animeService.getPricings(page: 1, pageSize: 100)
            pricings = response.pricings
        } catch {
            // 忽略加载错误
        }
    }

    func createAnime() async -> Bool {
        isCreating = true
        errorMessage = nil

        do {
            let request = CreateAnimeRequest(
                title: title,
                titleOriginal: titleOriginal.isEmpty ? nil : titleOriginal,
                cover: nil,
                description: description,
                codes: codesInput.isEmpty ? nil : codesInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                studio: studio,
                categoryId: categoryId,
                pricingId: pricingId,
                totalEpisodes: totalEpisodes,
                season: season,
                airDate: airDate.isEmpty ? nil : airDate,
                endDate: endDate.isEmpty ? nil : endDate,
                region: region.isEmpty ? nil : region,
                quality: quality.isEmpty ? nil : quality,
                productionStatus: productionStatus,
                tags: tags.isEmpty ? nil : tags
            )
            _ = try await animeService.create(request: request)
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
    AnimeCreateView(onSuccess: {})
}
