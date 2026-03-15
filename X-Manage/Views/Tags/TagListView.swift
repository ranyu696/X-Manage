//
//  TagListView.swift
//  X-Manage
//
//  标签列表视图

import SwiftUI

struct TagListView: View {
    @StateObject private var viewModel = TagListViewModel()
    @State private var searchText = ""
    @State private var showCreateSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.tags.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tags.isEmpty {
                ContentUnavailableView(
                    "暂无标签",
                    systemImage: "tag",
                    description: Text("点击右上角按钮创建第一个标签")
                )
            } else {
                Table(viewModel.tags) {
                    TableColumn("名称", value: \.name)
                        .width(min: 100, ideal: 150)

                    TableColumn("Slug", value: \.slug)
                        .width(min: 100, ideal: 150)

                    TableColumn("漫画") { tag in
                        Text("\(tag.comicCount)")
                    }
                    .width(60)

                    TableColumn("小说") { tag in
                        Text("\(tag.novelCount)")
                    }
                    .width(60)

                    TableColumn("游戏") { tag in
                        Text("\(tag.gameCount)")
                    }
                    .width(60)

                    TableColumn("总使用") { tag in
                        Text("\(tag.count)")
                            .fontWeight(.medium)
                    }
                    .width(80)

                    TableColumn("描述", value: \.description)
                        .width(min: 150, ideal: 200)

                    TableColumn("操作") { tag in
                        HStack(spacing: 8) {
                            Button {
                                viewModel.editTag(tag)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button {
                                viewModel.deleteTag(tag)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .width(80)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .id(viewModel.currentPage) // 页面变化时重置滚动位置
            }

            if !viewModel.tags.isEmpty {
                Divider()
                PaginationView(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageChange: { page in
                        Task {
                            await viewModel.loadTags(page: page)
                        }
                    }
                )
                .padding()
            }
        }
        .task {
            await viewModel.loadTags()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task {
                await viewModel.loadTags()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            TagFormView(mode: .create) { _ in
                Task {
                    await viewModel.loadTags()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索标签...", text: $searchText)
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
                Button {
                    Task {
                        await viewModel.loadTags()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建标签", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct TagFormView: View {
    enum Mode {
        case create
        case edit(Tag)
    }

    let mode: Mode
    let onSave: (Tag) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var slug = ""
    @State private var description = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(mode.isCreate ? "新建标签" : "编辑标签")
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
                    TextField("名称", text: $name)
                    TextField("Slug", text: $slug)
                }

                Section("描述") {
                    TextEditor(text: $description)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("保存") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || slug.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
    }
}

extension TagFormView.Mode {
    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
}

@MainActor
class TagListViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""

    private let service = TagService.shared

    func loadTags(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = TagListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword

        do {
            let response = try await service.getList(params: params)
            tags = response.tags
            totalPages = response.pagination.totalPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func editTag(_ tag: Tag) {
        // TODO: 编辑标签
    }

    func deleteTag(_ tag: Tag) {
        Task {
            do {
                try await service.delete(id: tag.id)
                await loadTags(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    TagListView()
}
