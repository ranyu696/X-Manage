//
//  CDNManagementView.swift
//  X-Manage
//
//  CDN 代理管理视图

import SwiftUI

struct CDNManagementView: View {
    @StateObject private var service = CDNService.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CDNCacheView()
                .tabItem { Label("缓存管理", systemImage: "internaldrive") }
                .tag(0)

            CDNProxyDomainsView()
                .tabItem { Label("反代域名", systemImage: "network") }
                .tag(1)
        }
        .padding()
    }
}

// MARK: - 缓存管理
struct CDNCacheView: View {
    @StateObject private var service = CDNService.shared
    @State private var stats: CDNCacheStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // 统计卡片
            if let stats = stats {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    CDNStatCard(title: "缓存大小", value: "\(stats.cacheSizeMb) MB", icon: "internaldrive", color: .blue)
                    CDNStatCard(title: "缓存文件", value: "\(stats.cacheFiles) 个", icon: "doc.fill", color: .purple)
                    CDNStatCard(title: "最大容量", value: "\(stats.maxSizeGb) GB", icon: "arrow.up.circle", color: .orange)
                    CDNStatCard(title: "磁盘总量", value: "\(stats.diskTotalGb) GB", icon: "cylinder", color: .gray)
                    CDNStatCard(title: "磁盘剩余", value: "\(stats.diskFreeGb) GB", icon: "cylinder.split.1x2", color: .green)
                    CDNStatCard(title: "磁盘占用", value: "\(stats.diskUsedPct)%", icon: "chart.pie.fill",
                             color: stats.diskUsedPct > 80 ? .red : stats.diskUsedPct > 60 ? .orange : .blue)
                }
            } else if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ContentUnavailableView(
                    "暂无数据",
                    systemImage: "internaldrive.fill",
                    description: Text(errorMessage ?? "点击刷新加载缓存统计")
                )
                .frame(minHeight: 200)
            }

            if let success = successMessage {
                Label(success, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            }

            if let error = errorMessage, stats == nil {
                EmptyView()
            } else if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            Divider()

            // 操作按钮
            HStack(spacing: 16) {
                Button {
                    loadStats()
                } label: {
                    Label("刷新统计", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)

                Spacer()

                Button {
                    evictCache()
                } label: {
                    Label("触发淘汰", systemImage: "trash.slash")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)

                Button(role: .destructive) {
                    clearCache()
                } label: {
                    Label("清空缓存", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(isLoading)
            }
        }
        .padding()
        .task {
            loadStats()
        }
    }

    private func loadStats() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                stats = try await service.getCacheStats()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func evictCache() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let result = try await service.evictCache()
                successMessage = "已淘汰 \(result.evictedFiles) 个文件，释放 \(result.evictedMb) MB，当前缓存 \(result.currentMb) MB"
                stats = try await service.getCacheStats()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func clearCache() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let result = try await service.clearCache()
                successMessage = "已清空 \(result.clearedFiles) 个文件，释放 \(result.clearedMb) MB"
                stats = try await service.getCacheStats()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - CDN 统计卡片
struct CDNStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 反代域名管理
struct CDNProxyDomainsView: View {
    @StateObject private var service = CDNService.shared
    @State private var domains: [CDNDomainConfig] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingDomain: CDNDomainConfig?
    @State private var selectedDomain: String?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && domains.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if domains.isEmpty {
                ContentUnavailableView(
                    "暂无反代域名",
                    systemImage: "network.slash",
                    description: Text(errorMessage ?? "点击右上角添加反代域名")
                )
            } else {
                Table(domains, selection: $selectedDomain) {
                    TableColumn("域名") { d in
                        Text(d.domain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 180, ideal: 220)

                    TableColumn("目标地址") { d in
                        Text(d.target)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    TableColumn("状态") { d in
                        Toggle("", isOn: Binding(
                            get: { d.enabled },
                            set: { newVal in
                                var updated = d
                                updated.enabled = newVal
                                toggleDomain(updated)
                            }
                        ))
                        .labelsHidden()
                    }
                    .width(60)

                    TableColumn("操作") { d in
                        HStack(spacing: 4) {
                            Button {
                                editingDomain = d
                            } label: {
                                Image(systemName: "pencil.circle")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.orange)
                            .help("编辑")

                            Button {
                                deleteDomain(d.domain)
                            } label: {
                                Image(systemName: "trash.circle")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                            .help("删除")
                        }
                    }
                    .width(80)
                }
            }

            if let error = errorMessage, !domains.isEmpty {
                HStack {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.red.opacity(0.05))
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    loadDomains()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("添加域名", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            CDNDomainFormView(mode: .add) { newDomain, newTarget in
                addDomain(domain: newDomain, target: newTarget)
            }
        }
        .sheet(item: $editingDomain) { d in
            CDNDomainFormView(mode: .edit(d)) { _, newTarget in
                var updated = d
                updated.target = newTarget
                toggleDomain(updated)
            }
        }
        .task {
            loadDomains()
        }
    }

    private func loadDomains() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                domains = try await service.listDomains()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func addDomain(domain: String, target: String) {
        Task {
            do {
                let d = try await service.addDomain(domain: domain, target: target)
                domains.append(d)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleDomain(_ config: CDNDomainConfig) {
        Task {
            do {
                let updated = try await service.updateDomain(config)
                if let idx = domains.firstIndex(where: { $0.domain == updated.domain }) {
                    domains[idx] = updated
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteDomain(_ domain: String) {
        Task {
            do {
                try await service.deleteDomain(domain: domain)
                domains.removeAll { $0.domain == domain }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 域名表单
struct CDNDomainFormView: View {
    enum Mode {
        case add
        case edit(CDNDomainConfig)
    }

    let mode: Mode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var domain = ""
    @State private var target = ""

    init(mode: Mode, onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let d) = mode {
            _domain = State(initialValue: d.domain)
            _target = State(initialValue: d.target)
        }
    }

    var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEdit ? "编辑反代域名" : "添加反代域名")
                    .font(.headline)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("域名") {
                    TextField("example.com", text: $domain)
                        .disabled(isEdit)
                }

                Section("目标地址") {
                    TextField("http://127.0.0.1:8080", text: $target)
                }

                Section {
                    Text("将对该域名的所有请求反向代理到目标地址。\n如已配置 SSL 证书自动申请，系统将在首次 TLS 握手时自动为该域名申请 Let's Encrypt 证书。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("保存") {
                    onSave(domain, target)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(domain.isEmpty || target.isEmpty)
            }
            .padding()
        }
        .frame(width: 420, height: 360)
    }
}

#Preview {
    CDNManagementView()
}
