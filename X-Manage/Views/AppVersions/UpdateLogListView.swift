//
//  UpdateLogListView.swift
//  X-Manage
//
//  更新日志列表视图

import SwiftUI

struct UpdateLogListView: View {
    @StateObject private var viewModel = UpdateLogListViewModel()
    @State private var versionIdFilter = ""
    @State private var userIdFilter = ""

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.logs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.logs.isEmpty {
                ContentUnavailableView(
                    "暂无更新日志",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("还没有更新记录")
                )
            } else {
                Table(viewModel.logs) {
                    TableColumn("ID") { log in
                        Text("\(log.id)")
                            .font(.caption.monospaced())
                    }
                    .width(50)

                    TableColumn("平台") { log in
                        if let platform = log.platformEnum {
                            HStack(spacing: 4) {
                                Image(systemName: platform.iconName)
                                    .foregroundStyle(.secondary)
                                Text(platform.displayName)
                            }
                        } else {
                            Text(log.platform ?? "-")
                        }
                    }
                    .width(90)

                    TableColumn("用户") { log in
                        if let userName = log.userName {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userName)
                                if let userId = log.userId {
                                    Text("ID: \(userId)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else if let userId = log.userId {
                            Text("ID: \(userId)")
                                .font(.caption)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 80, ideal: 120)

                    TableColumn("设备") { log in
                        VStack(alignment: .leading, spacing: 2) {
                            if let model = log.deviceModel {
                                Text(model)
                            }
                            if let deviceId = log.deviceId {
                                Text(deviceId.prefix(12) + "...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .width(min: 100, ideal: 140)

                    TableColumn("更新路径") { log in
                        HStack(spacing: 4) {
                            Text(log.fromVersion ?? "?")
                                .font(.caption.monospacedDigit())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())

                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(log.toVersion ?? "?")
                                .font(.caption.monospacedDigit())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                    .width(min: 150, ideal: 180)

                    TableColumn("状态") { log in
                        if log.isSuccess {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("成功")
                                    .font(.caption)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("失败")
                                    .font(.caption)
                            }
                        }
                    }
                    .width(70)

                    TableColumn("错误信息") { log in
                        if let error = log.errorMessage, !error.isEmpty {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(2)
                                .help(error)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 100, ideal: 150)

                    TableColumn("时间") { log in
                        if let createdAt = log.createdAt {
                            Text(formatDate(createdAt))
                                .font(.caption)
                        } else {
                            Text("-")
                        }
                    }
                    .width(min: 100, ideal: 130)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .id(viewModel.currentPage)
            }

            if !viewModel.logs.isEmpty {
                Divider()
                PaginationView(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageChange: { page in
                        Task {
                            await viewModel.loadLogs(page: page)
                        }
                    }
                )
                .padding()
            }
        }
        .task {
            await viewModel.loadLogs()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundStyle(.secondary)
                        TextField("版本ID", text: $versionIdFilter)
                            .textFieldStyle(.plain)
                            .frame(width: 70)
                        if !versionIdFilter.isEmpty {
                            Button {
                                versionIdFilter = ""
                                viewModel.filterVersionId = nil
                                Task { await viewModel.loadLogs() }
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
                    .onSubmit {
                        viewModel.filterVersionId = Int(versionIdFilter)
                        Task { await viewModel.loadLogs() }
                    }

                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                        TextField("用户ID", text: $userIdFilter)
                            .textFieldStyle(.plain)
                            .frame(width: 70)
                        if !userIdFilter.isEmpty {
                            Button {
                                userIdFilter = ""
                                viewModel.filterUserId = nil
                                Task { await viewModel.loadLogs() }
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
                    .onSubmit {
                        viewModel.filterUserId = Int(userIdFilter)
                        Task { await viewModel.loadLogs() }
                    }
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await viewModel.loadLogs(page: viewModel.currentPage)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

// MARK: - ViewModel
@MainActor
class UpdateLogListViewModel: ObservableObject {
    @Published var logs: [AppUpdateLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterVersionId: Int?
    var filterUserId: Int?

    private let service = AppVersionService.shared

    func loadLogs(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = AppUpdateLogListParams(page: page, pageSize: 20)
        params.versionId = filterVersionId
        params.userId = filterUserId

        do {
            let response = try await service.getUpdateLogs(params: params)
            logs = response.logs
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    UpdateLogListView()
}
