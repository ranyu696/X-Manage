//
//  DeviceListView.swift
//  X-Manage
//
//  设备列表视图

import SwiftUI

struct DeviceListView: View {
    @StateObject private var viewModel = DeviceListViewModel()
    @State private var selectedPlatform: AppPlatform?
    @State private var userIdFilter = ""
    @State private var selectedDevice: AppDevice?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.devices.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "暂无设备",
                    systemImage: "iphone.slash",
                    description: Text("还没有设备注册")
                )
            } else {
                Table(viewModel.devices) {
                    TableColumn("ID") { device in
                        Text("\(device.id)")
                            .font(.caption.monospaced())
                    }
                    .width(50)

                    TableColumn("平台") { device in
                        HStack(spacing: 4) {
                            Image(systemName: device.platformEnum?.iconName ?? "questionmark")
                                .foregroundStyle(.secondary)
                            Text(device.platformEnum?.displayName ?? device.platform)
                        }
                    }
                    .width(90)

                    TableColumn("设备型号") { device in
                        Text(device.model ?? "-")
                    }
                    .width(min: 100, ideal: 140)

                    TableColumn("系统版本") { device in
                        Text(device.osVersion ?? "-")
                            .font(.caption)
                    }
                    .width(80)

                    TableColumn("App版本") { device in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.appVersion ?? "-")
                                .font(.body.monospacedDigit())
                            if let build = device.buildNumber {
                                Text("Build \(build)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .width(90)

                    TableColumn("用户") { device in
                        if let userName = device.userName {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userName)
                                if let userId = device.userId {
                                    Text("ID: \(userId)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 80, ideal: 120)

                    TableColumn("状态") { device in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(device.isOnline == true ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(device.isOnline == true ? "在线" : "离线")
                                .font(.caption)
                        }
                    }
                    .width(60)

                    TableColumn("最后活跃") { device in
                        if let days = device.daysSinceCheck {
                            if days == 0 {
                                Text("今天")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else if days == 1 {
                                Text("昨天")
                                    .font(.caption)
                            } else {
                                Text("\(days)天前")
                                    .font(.caption)
                                    .foregroundStyle(days > 7 ? .secondary : .primary)
                            }
                        } else {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(70)

                    TableColumn("操作") { device in
                        Button {
                            selectedDevice = device
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("查看详情")
                    }
                    .width(50)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .id(viewModel.currentPage)
            }

            if !viewModel.devices.isEmpty {
                Divider()
                PaginationView(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageChange: { page in
                        Task {
                            await viewModel.loadDevices(page: page)
                        }
                    }
                )
                .padding()
            }
        }
        .task {
            await viewModel.loadDevices()
        }
        .onChange(of: selectedPlatform) { _, newValue in
            viewModel.filterPlatform = newValue
            Task {
                await viewModel.loadDevices()
            }
        }
        .sheet(item: $selectedDevice) { device in
            DeviceDetailView(device: device)
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

                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                        TextField("用户ID", text: $userIdFilter)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                        if !userIdFilter.isEmpty {
                            Button {
                                userIdFilter = ""
                                viewModel.filterUserId = nil
                                Task { await viewModel.loadDevices() }
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
                        Task { await viewModel.loadDevices() }
                    }
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await viewModel.loadDevices(page: viewModel.currentPage)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

// MARK: - Device Detail View
struct DeviceDetailView: View {
    let device: AppDevice

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("设备详情")
                        .font(.headline)
                    Text(device.model ?? "未知设备")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(device.isOnline == true ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(device.isOnline == true ? "在线" : "离线")
                        .font(.caption)
                }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    GroupBox("设备信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Text("设备ID")
                                    .foregroundStyle(.secondary)
                                Text(device.deviceId)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                            GridRow {
                                Text("平台")
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: device.platformEnum?.iconName ?? "questionmark")
                                    Text(device.platformEnum?.displayName ?? device.platform)
                                }
                            }
                            GridRow {
                                Text("型号")
                                    .foregroundStyle(.secondary)
                                Text(device.model ?? "-")
                            }
                            GridRow {
                                Text("系统版本")
                                    .foregroundStyle(.secondary)
                                Text(device.osVersion ?? "-")
                            }
                            if let channel = device.channel, !channel.isEmpty {
                                GridRow {
                                    Text("渠道")
                                        .foregroundStyle(.secondary)
                                    Text(channel)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }

                    GroupBox("应用信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Text("App版本")
                                    .foregroundStyle(.secondary)
                                Text(device.appVersion ?? "-")
                                    .font(.body.monospacedDigit())
                            }
                            if let build = device.buildNumber {
                                GridRow {
                                    Text("Build号")
                                        .foregroundStyle(.secondary)
                                    Text("\(build)")
                                        .font(.body.monospacedDigit())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }

                    if device.userId != nil || device.userName != nil {
                        GroupBox("用户信息") {
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                                if let userId = device.userId {
                                    GridRow {
                                        Text("用户ID")
                                            .foregroundStyle(.secondary)
                                        Text("\(userId)")
                                            .font(.body.monospacedDigit())
                                    }
                                }
                                if let userName = device.userName {
                                    GridRow {
                                        Text("用户名")
                                            .foregroundStyle(.secondary)
                                        Text(userName)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                    }

                    if let pushToken = device.pushToken, !pushToken.isEmpty {
                        GroupBox("推送信息") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Push Token")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(pushToken)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 500)
    }
}

// MARK: - ViewModel
@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [AppDevice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterPlatform: AppPlatform?
    var filterUserId: Int?

    private let service = AppVersionService.shared

    func loadDevices(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = AppDeviceListParams(page: page, pageSize: 20)
        params.platform = filterPlatform
        params.userId = filterUserId

        do {
            let response = try await service.getDevices(params: params)
            devices = response.devices
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    DeviceListView()
}
