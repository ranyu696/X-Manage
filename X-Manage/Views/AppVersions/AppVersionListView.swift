//
//  AppVersionListView.swift
//  X-Manage
//
//  应用版本列表视图

import SwiftUI

struct AppVersionListView: View {
    @StateObject private var viewModel = AppVersionListViewModel()
    @State private var selectedPlatform: AppPlatform?
    @State private var selectedStatus: AppVersionStatus?
    @State private var showCreateSheet = false
    @State private var selectedVersionForEdit: AppVersion?
    @State private var selectedVersionForDetail: AppVersion?
    @State private var showDeleteAlert = false
    @State private var versionToDelete: AppVersion?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.versions.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.versions.isEmpty {
                ContentUnavailableView(
                    "暂无版本",
                    systemImage: "app.badge",
                    description: Text("点击右上角按钮创建第一个版本")
                )
            } else {
                Table(viewModel.versions) {
                    TableColumn("ID") { version in
                        Text("\(version.id)")
                            .font(.caption.monospaced())
                    }
                    .width(50)

                    TableColumn("平台") { version in
                        HStack(spacing: 4) {
                            Image(systemName: version.platformEnum?.iconName ?? "questionmark")
                                .foregroundStyle(.secondary)
                            Text(version.platformEnum?.displayName ?? version.platform)
                        }
                    }
                    .width(100)

                    TableColumn("版本号") { version in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(version.version)
                                .font(.body.monospacedDigit())
                            Text("Build \(version.buildNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("标题", value: \.title)
                        .width(min: 120, ideal: 180)

                    TableColumn("状态") { version in
                        StatusBadge(status: version.statusEnum ?? .draft)
                    }
                    .width(80)

                    TableColumn("更新类型") { version in
                        Text(version.updateTypeEnum?.displayName ?? version.updateType)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(version.updateTypeEnum == .required ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                            .foregroundStyle(version.updateTypeEnum == .required ? .red : .blue)
                            .clipShape(Capsule())
                    }
                    .width(90)

                    TableColumn("文件大小") { version in
                        Text(version.formattedFileSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .width(80)

                    TableColumn("操作") { version in
                        HStack(spacing: 6) {
                            Button {
                                selectedVersionForDetail = version
                            } label: {
                                Image(systemName: "eye")
                            }
                            .buttonStyle(.borderless)
                            .help("查看详情")

                            Menu {
                                Button {
                                    selectedVersionForEdit = version
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }

                                Divider()

                                if version.statusEnum != .published {
                                    Button {
                                        viewModel.publishVersion(version)
                                    } label: {
                                        Label("发布", systemImage: "checkmark.circle")
                                    }
                                }

                                if version.statusEnum != .deprecated {
                                    Button {
                                        viewModel.deprecateVersion(version)
                                    } label: {
                                        Label("废弃", systemImage: "xmark.circle")
                                    }
                                }

                                Divider()

                                Button(role: .destructive) {
                                    versionToDelete = version
                                    showDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .width(70)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .id(viewModel.currentPage)
            }

            if !viewModel.versions.isEmpty {
                Divider()
                PaginationView(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageChange: { page in
                        Task {
                            await viewModel.loadVersions(page: page)
                        }
                    }
                )
                .padding()
            }
        }
        .task {
            await viewModel.loadVersions()
        }
        .onChange(of: selectedPlatform) { _, newValue in
            viewModel.filterPlatform = newValue
            Task {
                await viewModel.loadVersions()
            }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task {
                await viewModel.loadVersions()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            AppVersionFormView(mode: .create) { _ in
                Task {
                    await viewModel.loadVersions()
                }
            }
        }
        .sheet(item: $selectedVersionForEdit) { version in
            AppVersionFormView(mode: .edit(version)) { _ in
                Task {
                    await viewModel.loadVersions(page: viewModel.currentPage)
                }
            }
        }
        .sheet(item: $selectedVersionForDetail) { version in
            AppVersionDetailView(version: version) { updatedVersion in
                // 上传完成后刷新列表
                Task {
                    await viewModel.loadVersions(page: viewModel.currentPage)
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let version = versionToDelete {
                    viewModel.deleteVersion(version)
                }
            }
        } message: {
            if let version = versionToDelete {
                Text("确定要删除版本 \(version.version) (\(version.platformEnum?.displayName ?? version.platform)) 吗？此操作无法撤销。")
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Picker("平台", selection: $selectedPlatform) {
                        Text("全部平台").tag(nil as AppPlatform?)
                        Divider()
                        ForEach(AppPlatform.allCases, id: \.self) { platform in
                            Label(platform.displayName, systemImage: platform.iconName)
                                .tag(platform as AppPlatform?)
                        }
                    }
                    .frame(width: 130)

                    Picker("状态", selection: $selectedStatus) {
                        Text("全部状态").tag(nil as AppVersionStatus?)
                        Divider()
                        ForEach(AppVersionStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as AppVersionStatus?)
                        }
                    }
                    .frame(width: 110)
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await viewModel.loadVersions(page: viewModel.currentPage)
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
                    Label("新建版本", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: AppVersionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .draft: return Color.gray.opacity(0.15)
        case .testing: return Color.orange.opacity(0.15)
        case .published: return Color.green.opacity(0.15)
        case .deprecated: return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .draft: return .gray
        case .testing: return .orange
        case .published: return .green
        case .deprecated: return .red
        }
    }
}

// MARK: - ViewModel
@MainActor
class AppVersionListViewModel: ObservableObject {
    @Published var versions: [AppVersion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterPlatform: AppPlatform?
    var filterStatus: AppVersionStatus?

    private let service = AppVersionService.shared

    func loadVersions(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = AppVersionListParams(page: page, pageSize: 20)
        params.platform = filterPlatform
        params.status = filterStatus

        do {
            let response = try await service.getList(params: params)
            versions = response.versions
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteVersion(_ version: AppVersion) {
        Task {
            do {
                try await service.delete(id: version.id)
                await loadVersions(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func publishVersion(_ version: AppVersion) {
        Task {
            do {
                _ = try await service.publish(id: version.id)
                await loadVersions(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deprecateVersion(_ version: AppVersion) {
        Task {
            do {
                _ = try await service.deprecate(id: version.id)
                await loadVersions(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AppVersionListView()
}
