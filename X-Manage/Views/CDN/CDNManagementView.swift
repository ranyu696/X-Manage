//
//  CDNManagementView.swift
//  X-Manage
//
//  CDN 节点管理视图（多节点 + 详情面板）

import SwiftUI

// MARK: - CDN 管理主视图

struct CDNManagementView: View {
    @StateObject private var vm = CDNManagementViewModel()
    @State private var selectedNodeId: Int?
    @State private var showCreateSheet = false
    @State private var nodeToEdit: CDNNode?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧节点列表
            nodeListPanel

            Divider()

            // 右侧详情
            if let nodeId = selectedNodeId, let node = vm.nodes.first(where: { $0.id == nodeId }) {
                CDNNodeDetailView(node: node, onRefresh: {
                    Task { await vm.load() }
                })
                .id(nodeId)
                .frame(maxWidth: .infinity)
            } else {
                ContentUnavailableView(
                    "选择节点",
                    systemImage: "server.rack",
                    description: Text("从左侧列表选择 CDN 节点查看详情")
                )
                .frame(maxWidth: .infinity)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showCreateSheet) {
            CDNNodeCreateView(node: nil) {
                Task { await vm.load() }
            }
        }
        .sheet(item: $nodeToEdit) { node in
            CDNNodeCreateView(node: node) {
                Task { await vm.load() }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await vm.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("新建节点", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .alert("错误", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("确定") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - 节点列表面板

    private var nodeListPanel: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("CDN 节点")
                    .font(.headline)
                Spacer()
                if vm.isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if vm.nodes.isEmpty && !vm.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无节点")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.nodes, selection: $selectedNodeId) { node in
                    CDNNodeRow(node: node)
                        .tag(node.id)
                        .contextMenu {
                            Button("编辑") { nodeToEdit = node }
                            Button("推送配置") {
                                Task { await vm.pushConfig(nodeId: node.id) }
                            }
                            Divider()
                            Button("删除", role: .destructive) {
                                Task { await vm.deleteNode(node.id); selectedNodeId = nil }
                            }
                        }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(width: 220)
    }
}

// MARK: - 节点行

struct CDNNodeRow: View {
    let node: CDNNode

    var healthColor: Color {
        switch node.healthStatus {
        case "online": return .green
        case "offline": return .red
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle()
                    .fill(healthColor)
                    .frame(width: 8, height: 8)
                Text(node.name)
                    .font(.body)
                    .lineLimit(1)
                if !node.enabled {
                    Text("已禁用")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            HStack(spacing: 4) {
                if !node.region.isEmpty {
                    Text(node.region.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Text(node.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 节点详情视图

struct CDNNodeDetailView: View {
    let node: CDNNode
    let onRefresh: () -> Void
    @State private var selectedTab = "cache"

    var body: some View {
        VStack(spacing: 0) {
            nodeHeader
            Divider()
            tabBar
            Divider()
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var nodeHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(node.name).font(.headline)
                    healthBadge
                }
                Text(node.url).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !node.region.isEmpty {
                Text(node.region.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.05))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                let isSelected = selectedTab == tab.id
                Button { selectedTab = tab.id } label: {
                    Label(tab.label, systemImage: tab.icon)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor.opacity(0.15) : .clear)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .background(Color.secondary.opacity(0.03))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case "cache":    CDNNodeCacheTab(node: node)
        case "domains":  CDNNodeDomainsTab(node: node)
        case "config":   CDNNodeConfigTab(node: node, onPushDone: onRefresh)
        case "downloads": CDNNodeDownloadsTab(node: node)
        default:         EmptyView()
        }
    }

    private var tabs: [(id: String, label: String, icon: String)] {
        [
            ("cache", "缓存", "internaldrive"),
            ("domains", "域名", "network"),
            ("config", "配置", "slider.horizontal.3"),
            ("downloads", "下载", "arrow.down.circle"),
        ]
    }

    private var healthBadge: some View {
        let (label, color): (String, Color) = {
            switch node.healthStatus {
            case "online": return ("在线", .green)
            case "offline": return ("离线", .red)
            default: return ("未知", .secondary)
            }
        }()
        return Text(label)
            .font(.caption2)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - 缓存 Tab

struct CDNNodeCacheTab: View {
    let node: CDNNode
    @State private var stats: CDNCacheStats?
    @State private var isLoading = false
    @State private var message: (text: String, isError: Bool)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let stats = stats {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        CDNStatCard(title: "缓存大小", value: "\(stats.cacheSizeMb) MB", icon: "internaldrive", color: .blue)
                        CDNStatCard(title: "缓存文件", value: "\(stats.cacheFiles) 个", icon: "doc.fill", color: .purple)
                        CDNStatCard(title: "缓存上限", value: "\(stats.maxSizeGb) GB", icon: "arrow.up.circle", color: .orange)
                        CDNStatCard(title: "磁盘总量", value: "\(stats.diskTotalGb) GB", icon: "cylinder", color: .gray)
                        CDNStatCard(title: "磁盘剩余", value: "\(stats.diskFreeGb) GB", icon: "cylinder.split.1x2", color: .green)
                        CDNStatCard(
                            title: "磁盘占用",
                            value: "\(stats.diskUsedPct)%",
                            icon: "chart.pie.fill",
                            color: stats.diskUsedPct > 80 ? .red : stats.diskUsedPct > 60 ? .orange : .blue
                        )
                    }
                } else if isLoading {
                    ProgressView().padding(40)
                } else {
                    ContentUnavailableView("无数据", systemImage: "internaldrive", description: Text("点击刷新加载缓存统计"))
                        .padding()
                }

                if let msg = message {
                    Label(msg.text, systemImage: msg.isError ? "exclamationmark.triangle" : "checkmark.circle.fill")
                        .foregroundStyle(msg.isError ? .red : .green)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                HStack(spacing: 12) {
                    Button {
                        Task { await loadStats() }
                    } label: {
                        Label("刷新统计", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    Spacer()

                    Button {
                        Task { await evict() }
                    } label: {
                        Label("触发淘汰", systemImage: "trash.slash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    Button(role: .destructive) {
                        Task { await clear() }
                    } label: {
                        Label("清空缓存", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isLoading)
                }
            }
            .padding(16)
        }
        .task { await loadStats() }
    }

    private func loadStats() async {
        isLoading = true
        message = nil
        do {
            stats = try await CDNService.shared.getNodeStats(node.id)
        } catch {
            message = (error.localizedDescription, true)
        }
        isLoading = false
    }

    private func evict() async {
        isLoading = true
        message = nil
        do {
            let r = try await CDNService.shared.evictNodeCache(node.id)
            message = ("已淘汰 \(r.evictedFiles) 个文件，释放 \(r.evictedMb) MB，当前 \(r.currentMb) MB", false)
            stats = try await CDNService.shared.getNodeStats(node.id)
        } catch {
            message = (error.localizedDescription, true)
        }
        isLoading = false
    }

    private func clear() async {
        isLoading = true
        message = nil
        do {
            let r = try await CDNService.shared.clearNodeCache(node.id)
            message = ("已清空 \(r.clearedFiles) 个文件，释放 \(r.clearedMb) MB", false)
            stats = try await CDNService.shared.getNodeStats(node.id)
        } catch {
            message = (error.localizedDescription, true)
        }
        isLoading = false
    }
}

// MARK: - 域名 Tab

struct CDNNodeDomainsTab: View {
    let node: CDNNode
    @State private var domains: [CDNNodeDomain] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingDomain: CDNNodeDomain?
    @State private var syncMessage: (text: String, isError: Bool)?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && domains.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if domains.isEmpty {
                ContentUnavailableView("暂无域名", systemImage: "network.slash", description: Text(errorMessage ?? "点击添加域名"))
            } else {
                Table(domains) {
                    TableColumn("域名") { d in
                        Text(d.domain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 160, ideal: 200)

                    TableColumn("目标地址") { d in
                        if d.target.isEmpty {
                            Text("R2: \(d.bucketName)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.blue)
                        } else {
                            Text(d.target)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }

                    TableColumn("状态") { d in
                        Text(d.enabled ? "启用" : "禁用")
                            .foregroundStyle(d.enabled ? .green : .secondary)
                            .font(.caption)
                    }
                    .width(50)

                    TableColumn("同步状态") { d in
                        if let err = d.certError, !err.isEmpty {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(2)
                        } else {
                            Text("正常")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TableColumn("操作") { d in
                        HStack(spacing: 4) {
                            Button {
                                editingDomain = d
                            } label: {
                                Image(systemName: "pencil.circle")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.orange)

                            Button {
                                Task { await deleteDomain(d) }
                            } label: {
                                Image(systemName: "trash.circle")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                        }
                    }
                    .width(70)
                }
            }

            if let msg = syncMessage {
                HStack {
                    Label(msg.text, systemImage: msg.isError ? "exclamationmark.triangle" : "checkmark.circle.fill")
                        .foregroundStyle(msg.isError ? .red : .green)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(msg.isError ? .red.opacity(0.05) : .green.opacity(0.05))
            }

            if let err = errorMessage, !domains.isEmpty {
                HStack {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red.opacity(0.05))
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { Task { await loadDomains() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            ToolbarItem(placement: .automatic) {
                Button { Task { await syncDomains() } } label: {
                    Label("全量同步", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Label("添加域名", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            CDNDomainFormView(mode: .add) { req in
                Task { await addDomain(req) }
            }
        }
        .sheet(item: $editingDomain) { d in
            CDNDomainFormView(mode: .edit(d)) { req in
                Task { await updateDomain(d.id, req: req) }
            }
        }
        .task { await loadDomains() }
    }

    private func loadDomains() async {
        isLoading = true
        errorMessage = nil
        do {
            domains = try await CDNService.shared.listNodeDomains(node.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func addDomain(_ req: CDNDomainAddRequest) async {
        do {
            let d = try await CDNService.shared.addNodeDomain(node.id, req: req)
            domains.append(d)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateDomain(_ domainId: Int, req: CDNDomainAddRequest) async {
        do {
            let d = try await CDNService.shared.updateNodeDomain(node.id, domainId: domainId, req: req)
            if let idx = domains.firstIndex(where: { $0.id == domainId }) {
                domains[idx] = d
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteDomain(_ domain: CDNNodeDomain) async {
        do {
            try await CDNService.shared.deleteNodeDomain(node.id, domainId: domain.id)
            domains.removeAll { $0.id == domain.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncDomains() async {
        isLoading = true
        syncMessage = nil
        do {
            let result = try await CDNService.shared.syncNodeDomains(node.id)
            if let errors = result.errors, !errors.isEmpty {
                syncMessage = ("同步部分失败 (成功 \(result.synced)/跳过 \(result.skipped))：\(errors.joined(separator: "；"))", true)
            } else {
                syncMessage = ("同步成功：\(result.synced) 个域名已推送，\(result.skipped) 个已跳过", false)
            }
        } catch {
            syncMessage = (error.localizedDescription, true)
        }
        isLoading = false
    }
}

// MARK: - 配置 Tab

struct CDNNodeConfigTab: View {
    let node: CDNNode
    let onPushDone: () -> Void
    @State private var runningConfig: CDNRunningConfig?
    @State private var isLoading = false
    @State private var message: (text: String, isError: Bool)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 操作按钮
                HStack(spacing: 12) {
                    Button {
                        Task { await loadConfig() }
                    } label: {
                        Label("读取运行配置", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    Button {
                        Task { await pushConfig() }
                    } label: {
                        Label("推送配置到节点", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    if isLoading {
                        ProgressView().scaleEffect(0.8)
                    }
                }

                if let msg = message {
                    Label(msg.text, systemImage: msg.isError ? "exclamationmark.triangle" : "checkmark.circle.fill")
                        .foregroundStyle(msg.isError ? .red : .green)
                        .font(.subheadline)
                }

                Divider()

                // DB 存储的目标配置
                GroupBox("数据库配置（下次推送将使用此值）") {
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                        configRow("日志级别", node.logLevel)
                        configRow("限流启用", node.rateLimitEnabled ? "是" : "否")
                        configRow("下载限流 (req/s/IP)", "\(node.rateLimitPerIp)")
                        configRow("分片限流 (req/s/IP)", "\(node.segmentRateLimitPerIp)")
                        configRow("图片限流 (req/s/IP)", "\(node.imageRateLimitPerIp)")
                        configRow("带宽限制 (MB/s)", node.bandwidthLimitMbps == 0 ? "不限" : "\(node.bandwidthLimitMbps)")
                        configRow("缓存上限 (字节)", "\(node.cacheMaxSize)")
                        configRow("缓存目录", node.cacheDir ?? "—")
                        configRow("R2 账号 ID", node.r2AccountId ?? "—")
                        configRow("R2 区域", node.r2Region ?? "—")
                        configRow("动漫视频桶", node.animeR2BucketName ?? "—")
                        configRow("下载桶", node.downloadR2BucketName ?? "—")
                        configRow("图片桶", node.comicR2BucketName ?? "—")
                    }
                    .padding(.top, 4)
                }

                // 节点当前实际运行配置
                if let cfg = runningConfig {
                    GroupBox("节点当前运行配置") {
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                            configRow("日志级别", cfg.logLevel)
                            configRow("限流启用", cfg.rateLimitEnabled ? "是" : "否")
                            configRow("下载限流", "\(cfg.rateLimitPerIp) req/s/IP")
                            configRow("分片限流", "\(cfg.segmentRateLimitPerIp) req/s/IP")
                            configRow("图片限流", "\(cfg.imageRateLimitPerIp) req/s/IP")
                            configRow("带宽限制", cfg.bandwidthLimitMbps == 0 ? "不限" : "\(cfg.bandwidthLimitMbps) MB/s")
                            configRow("缓存上限", "\(cfg.cacheMaxSize) 字节")
                            configRow("缓存目录", cfg.cacheDir)
                            configRow("R2 账号", cfg.r2AccountId)
                            configRow("R2 区域", cfg.r2Region)
                            configRow("HTTPS", cfg.httpsEnabled ? "已启用" : "未启用")
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(16)
        }
        .task { await loadConfig() }
    }

    @ViewBuilder
    private func configRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .gridColumnAlignment(.leading)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .fontDesign(.monospaced)
                .gridColumnAlignment(.leading)
        }
    }

    private func loadConfig() async {
        isLoading = true
        message = nil
        do {
            runningConfig = try await CDNService.shared.getNodeRunningConfig(node.id)
        } catch {
            message = (error.localizedDescription, true)
        }
        isLoading = false
    }

    private func pushConfig() async {
        isLoading = true
        message = nil
        do {
            try await CDNService.shared.pushNodeConfig(node.id)
            message = ("配置已成功推送到节点", false)
            onPushDone()
            runningConfig = try? await CDNService.shared.getNodeRunningConfig(node.id)
        } catch {
            message = (error.localizedDescription, true)
        }
        isLoading = false
    }
}

// MARK: - 下载监控 Tab

struct CDNNodeDownloadsTab: View {
    let node: CDNNode
    @State private var snapshot: CDNDownloadSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 汇总栏
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(snapshot?.totalActive ?? 0)")
                        .font(.title2).fontWeight(.bold)
                    Text("活跃下载")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text(formatBandwidth(snapshot?.totalBandwidthBps ?? 0))
                        .font(.title2).fontWeight(.bold)
                    Text("总带宽")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await load() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))

            Divider()

            if isLoading && snapshot == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let downloads = snapshot?.activeDownloads, !downloads.isEmpty {
                Table(downloads) {
                    TableColumn("文件") { d in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.fileKey)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                            Text(d.userId)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TableColumn("进度") { d in
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: d.progress, total: 1)
                                .frame(maxWidth: 100)
                            Text("\(Int(d.progress * 100))%")
                                .font(.caption2)
                        }
                    }
                    .width(120)

                    TableColumn("速度") { d in
                        Text(formatBandwidth(d.speedBps))
                            .font(.caption)
                    }
                    .width(80)

                    TableColumn("IP") { d in
                        Text(d.clientIp)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .width(120)

                    TableColumn("缓存") { d in
                        Image(systemName: d.cacheHit ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(d.cacheHit ? .green : .secondary)
                    }
                    .width(50)
                }
            } else {
                ContentUnavailableView(
                    "暂无活跃下载",
                    systemImage: "arrow.down.circle",
                    description: Text(errorMessage ?? "当前没有正在进行的下载")
                )
            }

            if let err = errorMessage {
                HStack {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red.opacity(0.05))
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            snapshot = try await CDNService.shared.getNodeDownloads(node.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func formatBandwidth(_ bps: Double) -> String {
        if bps >= 1_000_000 {
            return String(format: "%.1f MB/s", bps / 1_000_000)
        } else if bps >= 1_000 {
            return String(format: "%.1f KB/s", bps / 1_000)
        }
        return String(format: "%.0f B/s", bps)
    }
}

// MARK: - 统计卡片

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
                    .font(.title3).fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 域名表单

struct CDNDomainFormView: View {
    enum Mode {
        case add
        case edit(CDNNodeDomain)
    }

    let mode: Mode
    let onSave: (CDNDomainAddRequest) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var domain = ""
    @State private var target = ""
    @State private var bucketName = ""
    @State private var note = ""
    @State private var enabled = true
    @State private var forceHttps = true
    @State private var cacheTtl = 0

    init(mode: Mode, onSave: @escaping (CDNDomainAddRequest) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let d) = mode {
            _domain = State(initialValue: d.domain)
            _target = State(initialValue: d.target)
            _bucketName = State(initialValue: d.bucketName)
            _note = State(initialValue: d.note)
            _enabled = State(initialValue: d.enabled)
            _forceHttps = State(initialValue: d.forceHttps)
            _cacheTtl = State(initialValue: d.cacheTtl)
        }
    }

    var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEdit ? "编辑域名" : "添加域名")
                    .font(.headline)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("域名") {
                    TextField("img.example.com", text: $domain)
                        .disabled(isEdit)
                }
                Section("反代目标（可选，不填则 R2 直连）") {
                    TextField("http://backend:8080", text: $target)
                }
                Section("R2 存储桶名称（反代目标为空时必填）") {
                    TextField("xyouacg-anime", text: $bucketName)
                }
                Section("备注") {
                    TextField("用途说明", text: $note)
                }
                Section {
                    Toggle("启用", isOn: $enabled)
                    Toggle("强制 HTTPS 跳转", isOn: $forceHttps)
                    HStack {
                        Text("缓存 TTL（秒，0=节点默认）")
                        Spacer()
                        TextField("0", value: $cacheTtl, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("保存") {
                    onSave(CDNDomainAddRequest(
                        domain: domain,
                        target: target,
                        bucketName: bucketName,
                        note: note,
                        enabled: enabled,
                        forceHttps: forceHttps,
                        cacheTtl: cacheTtl
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(domain.isEmpty)
            }
            .padding()
        }
        .frame(width: 420, height: 520)
    }
}

// MARK: - ViewModel

@MainActor
class CDNManagementViewModel: ObservableObject {
    @Published var nodes: [CDNNode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        do {
            nodes = try await CDNService.shared.listNodes()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteNode(_ id: Int) async {
        do {
            try await CDNService.shared.deleteNode(id)
            nodes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pushConfig(nodeId: Int) async {
        do {
            try await CDNService.shared.pushNodeConfig(nodeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CDNManagementView()
}
