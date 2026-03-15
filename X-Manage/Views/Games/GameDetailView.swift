//
//  GameDetailView.swift
//  X-Manage
//
//  游戏详情视图

import SwiftUI

struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GameDetailViewModel
    let onUpdate: () -> Void

    @State private var showEditSheet = false
    @State private var showNewVersionSheet = false
    @State private var editingVersion: GameVersion?
    @State private var showCoversUploadSheet = false
    @State private var showContentImagesUploadSheet = false
    @State private var showUpdateImagesUploadSheet = false

    init(gameId: Int, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let game = viewModel.game {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack(spacing: 8) {
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            GameStatusBadge(status: game.status)
                            if game.isTop == true {
                                Label("置顶", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } else {
                    Text("游戏详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.game != nil {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                }

                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let game = viewModel.game {
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本信息
                        basicInfoSection(game)

                        // 封面图片
                        imagesSection(title: "封面图片", images: game.covers, type: .covers) {
                            showCoversUploadSheet = true
                        }

                        // 内容图片
                        imagesSection(title: "内容图片", images: game.contentImages ?? [], type: .content) {
                            showContentImagesUploadSheet = true
                        }

                        // 更新图片
                        imagesSection(title: "更新图片", images: game.updateImages ?? [], type: .updates) {
                            showUpdateImagesUploadSheet = true
                        }

                        // 版本列表
                        versionsSection

                        // 统计信息
                        statsSection(game)

                        // 评论列表
                        commentsSection
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "加载失败",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "未知错误")
                )
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadGame()
            await viewModel.loadVersions()
        }
        .sheet(isPresented: $showEditSheet) {
            if let game = viewModel.game {
                GameEditSheet(game: game) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showNewVersionSheet) {
            GameVersionEditSheet(
                gameId: viewModel.gameId,
                version: nil
            ) {
                Task { await viewModel.loadVersions() }
            }
        }
        .sheet(item: $editingVersion) { version in
            GameVersionEditSheet(
                gameId: viewModel.gameId,
                version: version
            ) {
                Task { await viewModel.loadVersions() }
            }
        }
        .sheet(isPresented: $showCoversUploadSheet) {
            if let game = viewModel.game {
                GameImageUploadSheet(
                    game: game,
                    imageType: .covers,
                    existingImages: game.covers
                ) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showContentImagesUploadSheet) {
            if let game = viewModel.game {
                GameImageUploadSheet(
                    game: game,
                    imageType: .content,
                    existingImages: game.contentImages ?? []
                ) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showUpdateImagesUploadSheet) {
            if let game = viewModel.game {
                GameImageUploadSheet(
                    game: game,
                    imageType: .updates,
                    existingImages: game.updateImages ?? []
                ) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
    }

    // MARK: - 基本信息
    private func basicInfoSection(_ game: Game) -> some View {
        GroupBox("基本信息") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem("标题", game.title)
                infoItem("名称", game.name ?? "-")
                infoItem("原名", game.original ?? "-")
                infoItem("作者", game.author)
                infoItem("区域", GameRegion(rawValue: game.region ?? "")?.displayName ?? game.region ?? "-")
                infoItem("语言", GameLanguage(rawValue: game.language ?? "")?.displayName ?? game.language ?? "-")
                infoItem("画质", GameQuality(rawValue: game.quality ?? "")?.displayName ?? game.quality ?? "-")
                infoItem("类型", game.types?.joined(separator: ", ") ?? "-")
                infoItem("汉化", game.isTranslated == true ? "是" : "否")
            }
            .padding()
        }
    }

    private func infoItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 图片区域
    private func imagesSection(title: String, images: [String], type: ImageType, onUpload: @escaping () -> Void) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.headline)

                    Spacer()

                    Text("\(images.count) 张图片")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        onUpload()
                    } label: {
                        Label("上传", systemImage: "arrow.up.circle")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                if images.isEmpty {
                    Text("暂无图片")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(images, id: \.self) { url in
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                                .frame(width: type == .covers ? 160 : 200, height: type == .covers ? 90 : 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }

    enum ImageType {
        case covers, content, updates
    }

    // MARK: - 版本列表
    private var versionsSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("版本管理")
                        .font(.headline)

                    Spacer()

                    Button {
                        showNewVersionSheet = true
                    } label: {
                        Label("添加版本", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                if viewModel.versions.isEmpty {
                    Text("暂无版本")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.versions) { version in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("v\(version.version)")
                                            .fontWeight(.medium)

                                        if version.isLatest == true {
                                            Text("最新")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.green.opacity(0.2))
                                                .foregroundStyle(.green)
                                                .clipShape(Capsule())
                                        }

                                        if let status = version.status {
                                            Text(status.displayName)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.blue.opacity(0.2))
                                                .foregroundStyle(.blue)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    if let desc = version.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(String(format: "%.2f", version.size ?? 0)) GB")
                                        .font(.caption.monospacedDigit())

                                    if let createdAt = version.createdAt {
                                        Text(formatDateTime(createdAt))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Button {
                                    editingVersion = version
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)

                                Button {
                                    viewModel.deleteVersion(version)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding()

                            if version.id != viewModel.versions.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 统计信息
    private func statsSection(_ game: Game) -> some View {
        GroupBox("统计信息") {
            HStack(spacing: 32) {
                statItem("浏览量", game.viewCount ?? 0)
                statItem("点赞数", game.likeCount ?? 0)
                statItem("评论数", game.commentCount ?? 0)
                statItem("收藏数", game.favoriteCount ?? 0)
                statItem("销售数", game.saleCount ?? 0)
            }
            .padding()
        }
    }

    private func statItem(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 评论列表
    private var commentsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("评论列表")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await viewModel.loadComments() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.isLoadingComments)
                }

                if viewModel.isLoadingComments && viewModel.comments.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if viewModel.comments.isEmpty {
                    HStack {
                        Spacer()
                        Text("暂无评论")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                } else {
                    ForEach(viewModel.comments) { comment in
                        GameDetailCommentRow(
                            comment: comment,
                            onApprove: { viewModel.approveComment(comment) },
                            onReject: { viewModel.rejectComment(comment) },
                            onDelete: { viewModel.deleteComment(comment) },
                            onToggleTop: { viewModel.toggleCommentTop(comment) }
                        )
                        Divider()
                    }

                    // 分页
                    if viewModel.commentTotalPages > 1 {
                        HStack {
                            Spacer()
                            PaginationView(
                                currentPage: viewModel.commentCurrentPage,
                                totalPages: viewModel.commentTotalPages,
                                onPageChange: { page in
                                    Task { await viewModel.loadComments(page: page) }
                                }
                            )
                        }
                    }
                }
            }
            .padding()
        } label: {
            Label("评论管理", systemImage: "bubble.left.and.bubble.right")
        }
    }
}

// MARK: - 游戏详情评论行
struct GameDetailCommentRow: View {
    let comment: GameComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void
    let onToggleTop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text(String((comment.username ?? "U").prefix(1)).uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(comment.username ?? "用户\(comment.userId)")
                            .font(.callout)
                            .fontWeight(.medium)
                        if let role = comment.userRole {
                            Text(role)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    Text(comment.createdAt.prefix(16).replacingOccurrences(of: "T", with: " "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    if comment.isTop == true {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(statusText(comment.status))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(comment.status).opacity(0.1))
                        .foregroundStyle(statusColor(comment.status))
                        .clipShape(Capsule())
                }
            }

            Text(comment.content)
                .font(.callout)
                .lineLimit(2)

            HStack {
                Label("\(comment.likeCount ?? 0)", systemImage: "heart")
                Label("\(comment.replyCount ?? 0)", systemImage: "bubble.left")

                Spacer()

                if comment.status == "PENDING" {
                    Button { onApprove() } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.green)

                    Button { onReject() } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                }

                Button { onToggleTop() } label: {
                    Image(systemName: comment.isTop == true ? "pin.slash" : "pin")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(comment.isTop == true ? .orange : .secondary)

                Button { onDelete() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func statusText(_ status: String) -> String {
        switch status {
        case "PENDING": return "待审核"
        case "APPROVED": return "已通过"
        case "REJECTED": return "已拒绝"
        default: return status
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "PENDING": return .orange
        case "APPROVED": return .green
        case "REJECTED": return .red
        default: return .gray
        }
    }
}

// MARK: - 游戏编辑表单
struct GameEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let onUpdate: () -> Void

    // 表单字段
    @State private var title: String
    @State private var name: String
    @State private var original: String
    @State private var author: String
    @State private var region: String
    @State private var language: String
    @State private var quality: String
    @State private var description: String
    @State private var content: String
    @State private var isTranslated: Bool
    @State private var selectedTypes: Set<String>

    // 原始数据（用于对比变更）
    @State private var originalData: GameFormData?

    // UI状态
    @State private var isSaving = false
    @State private var errorMessage: String?

    // 游戏表单数据结构（用于对比）
    private struct GameFormData: Equatable {
        var title: String
        var name: String
        var original: String
        var author: String
        var region: String
        var language: String
        var quality: String
        var description: String
        var content: String
        var isTranslated: Bool
        var types: Set<String>
    }

    init(game: Game, onUpdate: @escaping () -> Void) {
        self.game = game
        self.onUpdate = onUpdate
        _title = State(initialValue: game.title)
        _name = State(initialValue: game.name ?? "")
        _original = State(initialValue: game.original ?? "")
        _author = State(initialValue: game.author)
        _region = State(initialValue: game.region ?? "")
        _language = State(initialValue: game.language ?? "")
        _quality = State(initialValue: game.quality ?? "")
        _description = State(initialValue: game.description ?? "")
        _content = State(initialValue: game.content ?? "")
        _isTranslated = State(initialValue: game.isTranslated ?? false)
        _selectedTypes = State(initialValue: Set(game.types ?? []))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑游戏")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("名称", text: $name)
                    TextField("原名", text: $original)
                    TextField("作者", text: $author)
                }

                Section("分类属性") {
                    Picker("区域", selection: $region) {
                        Text("未选择").tag("")
                        ForEach(GameRegion.allCases, id: \.rawValue) { r in
                            Text(r.displayName).tag(r.rawValue)
                        }
                    }

                    Picker("语言", selection: $language) {
                        Text("未选择").tag("")
                        ForEach(GameLanguage.allCases, id: \.rawValue) { l in
                            Text(l.displayName).tag(l.rawValue)
                        }
                    }

                    Picker("画质", selection: $quality) {
                        Text("未选择").tag("")
                        ForEach(GameQuality.allCases, id: \.rawValue) { q in
                            Text(q.displayName).tag(q.rawValue)
                        }
                    }

                    Toggle("已汉化", isOn: $isTranslated)
                }

                Section("游戏类型（可多选）") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(GameType.allCases, id: \.rawValue) { type in
                            TypeToggleButton(
                                title: type.displayName,
                                isSelected: selectedTypes.contains(type.rawValue),
                                action: {
                                    if selectedTypes.contains(type.rawValue) {
                                        selectedTypes.remove(type.rawValue)
                                    } else {
                                        selectedTypes.insert(type.rawValue)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("简介") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("详细内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .lineLimit(2)
                }
                Spacer()

                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                }

                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || title.isEmpty || author.isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 750)
        .onAppear {
            saveOriginalData()
        }
    }

    private func saveOriginalData() {
        originalData = GameFormData(
            title: game.title,
            name: game.name ?? "",
            original: game.original ?? "",
            author: game.author,
            region: game.region ?? "",
            language: game.language ?? "",
            quality: game.quality ?? "",
            description: game.description ?? "",
            content: game.content ?? "",
            isTranslated: game.isTranslated ?? false,
            types: Set(game.types ?? [])
        )
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                guard let original = originalData else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "原始数据丢失"])
                }

                // 只发送修改过的字段
                var request = UpdateGameRequest()
                var hasChanges = false

                if title != original.title {
                    request.title = title
                    hasChanges = true
                }
                if name != original.name {
                    request.name = name.isEmpty ? nil : name
                    hasChanges = true
                }
                if self.original != original.original {
                    request.original = self.original.isEmpty ? nil : self.original
                    hasChanges = true
                }
                if author != original.author {
                    request.author = author
                    hasChanges = true
                }
                if region != original.region {
                    request.region = region.isEmpty ? nil : region
                    hasChanges = true
                }
                if language != original.language {
                    request.language = language.isEmpty ? nil : language
                    hasChanges = true
                }
                if quality != original.quality {
                    request.quality = quality.isEmpty ? nil : quality
                    hasChanges = true
                }
                if description != original.description {
                    request.description = description.isEmpty ? nil : description
                    hasChanges = true
                }
                if content != original.content {
                    request.content = content.isEmpty ? nil : content
                    hasChanges = true
                }
                if isTranslated != original.isTranslated {
                    request.isTranslated = isTranslated
                    hasChanges = true
                }
                if selectedTypes != original.types {
                    request.types = Array(selectedTypes)
                    hasChanges = true
                }

                if hasChanges {
                    _ = try await GameService.shared.update(id: game.id, request: request)
                }

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 类型选择按钮
struct TypeToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 版本编辑表单
struct GameVersionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gameId: Int
    let version: GameVersion?
    let onUpdate: () -> Void

    // 表单字段
    @State private var versionNumber: String
    @State private var description: String
    @State private var size: Double
    @State private var pricingId: Int
    @State private var isLatest: Bool
    @State private var status: GameVersionStatus
    @State private var baiduUrl: String
    @State private var baiduPassword: String
    @State private var cloudUrl: String
    @State private var cloudPassword: String
    @State private var storagePath: String
    @State private var unzipCodes: String
    @State private var cheatCodesText: String

    // 原始数据（用于对比变更）
    @State private var originalData: VersionFormData?

    // UI状态
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var cheatCodesError: String?
    @State private var pricings: [GamePricing] = []
    @State private var isLoadingPricings = false

    // 版本表单数据结构（用于对比）
    private struct VersionFormData: Equatable {
        var version: String
        var description: String
        var size: Double
        var pricingId: Int
        var isLatest: Bool
        var status: GameVersionStatus
        var baiduUrl: String
        var baiduPassword: String
        var cloudUrl: String
        var cloudPassword: String
        var storagePath: String
        var unzipCodes: String
        var cheatCodes: [CheatCode]

        static func == (lhs: VersionFormData, rhs: VersionFormData) -> Bool {
            lhs.version == rhs.version &&
            lhs.description == rhs.description &&
            lhs.size == rhs.size &&
            lhs.pricingId == rhs.pricingId &&
            lhs.isLatest == rhs.isLatest &&
            lhs.status == rhs.status &&
            lhs.baiduUrl == rhs.baiduUrl &&
            lhs.baiduPassword == rhs.baiduPassword &&
            lhs.cloudUrl == rhs.cloudUrl &&
            lhs.cloudPassword == rhs.cloudPassword &&
            lhs.storagePath == rhs.storagePath &&
            lhs.unzipCodes == rhs.unzipCodes
        }
    }

    init(gameId: Int, version: GameVersion?, onUpdate: @escaping () -> Void) {
        self.gameId = gameId
        self.version = version
        self.onUpdate = onUpdate

        _versionNumber = State(initialValue: version?.version ?? "")
        _description = State(initialValue: version?.description ?? "")
        _size = State(initialValue: version?.size ?? 0)
        _pricingId = State(initialValue: version?.pricingId ?? 0)
        _isLatest = State(initialValue: version?.isLatest ?? true)
        _status = State(initialValue: version?.status ?? .active)
        _baiduUrl = State(initialValue: version?.baiduUrl ?? "")
        _baiduPassword = State(initialValue: version?.baiduPassword ?? "")
        _cloudUrl = State(initialValue: version?.cloudUrl ?? "")
        _cloudPassword = State(initialValue: version?.cloudPassword ?? "")
        _storagePath = State(initialValue: version?.storagePath ?? "")
        _unzipCodes = State(initialValue: version?.unzipCodes ?? "")

        // 初始化作弊码文本
        if let codes = version?.cheatCodes, !codes.isEmpty {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(codes),
               let text = String(data: data, encoding: .utf8) {
                _cheatCodesText = State(initialValue: text)
            } else {
                _cheatCodesText = State(initialValue: "[]")
            }
        } else {
            _cheatCodesText = State(initialValue: "[]")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(version == nil ? "添加版本" : "编辑版本")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("版本信息") {
                    TextField("版本号", text: $versionNumber)
                        .textContentType(.none)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("版本描述")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 60)
                            .font(.body)
                    }

                    HStack {
                        Text("大小")
                        Spacer()
                        TextField("GB", value: $size, format: .number)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("GB")
                            .foregroundStyle(.secondary)
                    }

                    // 定价方案选择
                    HStack {
                        Text("定价方案")
                        Spacer()
                        if isLoadingPricings {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("加载中...")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("", selection: $pricingId) {
                                Text("请选择").tag(0)
                                ForEach(pricings) { pricing in
                                    Text("\(pricing.name) - ¥\(pricing.price)")
                                        .tag(pricing.id)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    Toggle("最新版本", isOn: $isLatest)

                    // 版本状态选择（仅编辑模式）
                    if version != nil {
                        Picker("版本状态", selection: $status) {
                            Text(GameVersionStatus.active.displayName).tag(GameVersionStatus.active)
                            Text(GameVersionStatus.outdated.displayName).tag(GameVersionStatus.outdated)
                            Text(GameVersionStatus.disabled.displayName).tag(GameVersionStatus.disabled)
                        }
                    }
                }

                Section("百度网盘") {
                    TextField("链接", text: $baiduUrl)
                    TextField("提取码", text: $baiduPassword)
                }

                Section("其他网盘（可选）") {
                    TextField("链接", text: $cloudUrl)
                    TextField("提取码", text: $cloudPassword)
                }

                Section("存储信息") {
                    TextField("存储路径（可选）", text: $storagePath)
                    TextField("解压密码", text: $unzipCodes)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("作弊码")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let error = cheatCodesError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        TextEditor(text: $cheatCodesText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .onChange(of: cheatCodesText) { _, newValue in
                                validateCheatCodes(newValue)
                            }

                        Text("格式: [{\"code\": \"作弊码\", \"description\": \"说明\"}]")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("作弊码 (JSON格式)")
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .lineLimit(2)
                }
                Spacer()

                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                }

                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || !isFormValid)
            }
            .padding()
        }
        .frame(width: 550, height: 750)
        .task {
            await loadPricings()
            saveOriginalData()
        }
    }

    private var isFormValid: Bool {
        !versionNumber.isEmpty &&
        pricingId > 0 &&
        !baiduUrl.isEmpty &&
        !baiduPassword.isEmpty &&
        !unzipCodes.isEmpty &&
        cheatCodesError == nil
    }

    private func validateCheatCodes(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text == "[]" {
            cheatCodesError = nil
            return
        }

        guard let data = text.data(using: .utf8) else {
            cheatCodesError = "无效的文本"
            return
        }

        do {
            let codes = try JSONDecoder().decode([CheatCode].self, from: data)
            if codes.isEmpty {
                cheatCodesError = nil
            } else {
                cheatCodesError = nil
            }
        } catch {
            cheatCodesError = "JSON格式错误"
        }
    }

    private func parseCheatCodes() -> [CheatCode]? {
        let text = cheatCodesText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text == "[]" {
            return []
        }

        guard let data = text.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode([CheatCode].self, from: data)
    }

    private func saveOriginalData() {
        guard let v = version else { return }
        originalData = VersionFormData(
            version: v.version,
            description: v.description ?? "",
            size: v.size ?? 0,
            pricingId: v.pricingId ?? 0,
            isLatest: v.isLatest ?? true,
            status: v.status ?? .active,
            baiduUrl: v.baiduUrl ?? "",
            baiduPassword: v.baiduPassword ?? "",
            cloudUrl: v.cloudUrl ?? "",
            cloudPassword: v.cloudPassword ?? "",
            storagePath: v.storagePath ?? "",
            unzipCodes: v.unzipCodes ?? "",
            cheatCodes: v.cheatCodes ?? []
        )
    }

    private func loadPricings() async {
        isLoadingPricings = true
        do {
            let response = try await GameService.shared.getPricings()
            pricings = response.pricings
            // 如果没有选择定价或选择的定价不在列表中，自动选择第一个定价方案
            let validPricingIds = Set(pricings.map { $0.id })
            if pricingId == 0 || !validPricingIds.contains(pricingId) {
                if let firstPricing = pricings.first {
                    pricingId = firstPricing.id
                }
            }
        } catch {
            // 静默失败，用户仍可手动选择
        }
        isLoadingPricings = false
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let cheatCodes = parseCheatCodes()

                if let existingVersion = version, let original = originalData {
                    // 更新 - 只发送修改过的字段
                    var request = UpdateGameVersionRequest()
                    var hasChanges = false

                    if versionNumber != original.version {
                        request.version = versionNumber
                        hasChanges = true
                    }
                    if description != original.description {
                        request.description = description
                        hasChanges = true
                    }
                    if size != original.size {
                        request.size = size
                        hasChanges = true
                    }
                    if pricingId != original.pricingId {
                        request.pricingId = pricingId
                        hasChanges = true
                    }
                    if isLatest != original.isLatest {
                        request.isLatest = isLatest
                        hasChanges = true
                    }
                    if status != original.status {
                        request.status = status.rawValue
                        hasChanges = true
                    }
                    if baiduUrl != original.baiduUrl {
                        request.baiduUrl = baiduUrl
                        hasChanges = true
                    }
                    if baiduPassword != original.baiduPassword {
                        request.baiduPassword = baiduPassword
                        hasChanges = true
                    }
                    if cloudUrl != original.cloudUrl {
                        request.cloudUrl = cloudUrl.isEmpty ? nil : cloudUrl
                        hasChanges = true
                    }
                    if cloudPassword != original.cloudPassword {
                        request.cloudPassword = cloudPassword.isEmpty ? nil : cloudPassword
                        hasChanges = true
                    }
                    if storagePath != original.storagePath {
                        request.storagePath = storagePath.isEmpty ? nil : storagePath
                        hasChanges = true
                    }
                    if unzipCodes != original.unzipCodes {
                        request.unzipCodes = unzipCodes
                        hasChanges = true
                    }

                    // 对比作弊码
                    if let codes = cheatCodes {
                        let originalCodes = original.cheatCodes
                        let codesChanged = codes.count != originalCodes.count ||
                            zip(codes, originalCodes).contains { $0.code != $1.code || $0.description != $1.description }
                        if codesChanged {
                            request.cheatCodes = codes
                            hasChanges = true
                        }
                    }

                    if hasChanges {
                        _ = try await GameService.shared.updateVersion(
                            gameId: gameId,
                            versionId: existingVersion.id,
                            request: request
                        )
                    }
                } else {
                    // 创建
                    let request = CreateGameVersionRequest(
                        version: versionNumber,
                        description: description,
                        size: size,
                        pricingId: pricingId,
                        isLatest: isLatest,
                        baiduUrl: baiduUrl,
                        baiduPassword: baiduPassword,
                        cloudUrl: cloudUrl.isEmpty ? nil : cloudUrl,
                        cloudPassword: cloudPassword.isEmpty ? nil : cloudPassword,
                        storagePath: storagePath.isEmpty ? nil : storagePath,
                        unzipCodes: unzipCodes,
                        cheatCodes: cheatCodes
                    )

                    _ = try await GameService.shared.createVersion(gameId: gameId, request: request)
                }
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 图片上传表单
struct GameImageUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let imageType: GameDetailView.ImageType
    let existingImages: [String]
    let onUpdate: () -> Void

    @State private var selectedImages: [URL] = []
    @State private var isUploading = false
    @State private var uploadProgress: (current: Int, total: Int) = (0, 0)
    @State private var errorMessage: String?
    @State private var uploadedUrls: [String] = []

    private var title: String {
        switch imageType {
        case .covers: return "上传封面图片"
        case .content: return "上传内容图片"
        case .updates: return "上传更新图片"
        }
    }

    private var maxFiles: Int {
        switch imageType {
        case .covers: return 5
        case .content, .updates: return 10
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("上传说明", systemImage: "info.circle")
                                .font(.headline)

                            Text("• 选择图片后会自动上传到服务器")
                            Text("• 支持 JPG、PNG、WebP、GIF 格式")
                            Text("• 每次最多选择 \(maxFiles) 张图片")
                            Text("• 上传成功后会自动更新游戏数据")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // 目标游戏
                    GroupBox("目标游戏") {
                        HStack {
                            Text(game.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // 现有图片
                    if !existingImages.isEmpty {
                        GroupBox("现有图片 (\(existingImages.count) 张)") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(existingImages, id: \.self) { url in
                                        AsyncImage(url: URL(string: url)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 80, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                                .padding()
                            }
                        }
                    }

                    // 选择图片
                    GroupBox("选择新图片") {
                        VStack(spacing: 12) {
                            if selectedImages.isEmpty {
                                Button {
                                    selectImages()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.largeTitle)
                                        Text("点击选择图片")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(isUploading)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedImages, id: \.self) { url in
                                            ZStack(alignment: .topTrailing) {
                                                if let image = NSImage(contentsOf: url) {
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 80, height: 60)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }

                                                if !isUploading {
                                                    Button {
                                                        selectedImages.removeAll { $0 == url }
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.white, .red)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .offset(x: 4, y: -4)
                                                }
                                            }
                                        }
                                    }
                                }

                                HStack {
                                    Text("已选择 \(selectedImages.count) 张图片")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if !isUploading {
                                        Button("重新选择") {
                                            selectImages()
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // 上传进度
                    if isUploading {
                        GroupBox("上传进度") {
                            VStack(spacing: 12) {
                                ProgressView(value: Double(uploadProgress.current), total: Double(uploadProgress.total))

                                HStack {
                                    Text("正在上传...")
                                    Spacer()
                                    Text("\(uploadProgress.current)/\(uploadProgress.total)")
                                        .font(.caption.monospacedDigit())
                                }
                                .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }

                    // 错误信息
                    if let error = errorMessage {
                        GroupBox {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 操作按钮
            HStack {
                Spacer()

                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("上传中...")
                        .foregroundStyle(.secondary)
                } else {
                    Button("开始上传") {
                        uploadImages()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImages.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }

    private func selectImages() {
        let urls = UploadService.shared.selectImages(allowMultiple: true, maxCount: maxFiles)
        if !urls.isEmpty {
            selectedImages = urls
            errorMessage = nil
        }
    }

    private func uploadImages() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        errorMessage = nil
        uploadedUrls = []
        uploadProgress = (0, selectedImages.count)

        Task {
            do {
                // 先读取所有图片数据获取文件大小
                var imageDataList: [Data] = []
                var fileInfos: [UploadFileInfo] = []

                for (index, url) in selectedImages.enumerated() {
                    guard let imageData = UploadService.shared.imageData(from: url) else {
                        throw UploadError.fileReadError
                    }
                    imageDataList.append(imageData)

                    let fileName = url.lastPathComponent
                    let contentType = getContentType(for: url)
                    fileInfos.append(UploadFileInfo(
                        fileName: fileName,
                        contentType: contentType,
                        sortOrder: existingImages.count + index,
                        fileSize: imageData.count
                    ))
                }

                // 获取上传URL
                let uploadResult: UploadImagesResult
                switch imageType {
                case .covers:
                    uploadResult = try await UploadService.shared.getGameCoversUploadUrls(gameSlug: game.slug, files: fileInfos)
                case .content:
                    uploadResult = try await UploadService.shared.getGameContentsUploadUrls(gameSlug: game.slug, files: fileInfos)
                case .updates:
                    uploadResult = try await UploadService.shared.getGameUpdatesUploadUrls(gameSlug: game.slug, files: fileInfos)
                }

                // 上传每个文件
                for (index, uploadInfo) in uploadResult.uploadInfos.enumerated() {
                    guard index < imageDataList.count else { break }

                    try await UploadService.shared.uploadToPresignedUrl(
                        uploadInfo.uploadUrl,
                        data: imageDataList[index],
                        contentType: fileInfos[index].contentType
                    )

                    uploadedUrls.append(uploadInfo.fileUrl)
                    uploadProgress.current = index + 1
                }

                // 更新游戏图片
                let allImages = existingImages + uploadedUrls
                switch imageType {
                case .covers:
                    try await UploadService.shared.updateGameCovers(gameId: game.id, covers: allImages)
                case .content:
                    try await UploadService.shared.updateGameContentImages(gameId: game.id, contentImages: allImages)
                case .updates:
                    try await UploadService.shared.updateGameUpdateImages(gameId: game.id, updateImages: allImages)
                }

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploading = false
        }
    }

    private func getContentType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        default:
            return "image/jpeg"
        }
    }
}

// MARK: - ViewModel
@MainActor
class GameDetailViewModel: ObservableObject {
    @Published var game: Game?
    @Published var versions: [GameVersion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 评论相关
    @Published var comments: [GameComment] = []
    @Published var isLoadingComments = false
    @Published var commentCurrentPage = 1
    @Published var commentTotalPages = 1

    let gameId: Int
    private let service = GameService.shared
    private let commentService = CommentService.shared

    init(gameId: Int) {
        self.gameId = gameId
    }

    func loadGame() async {
        isLoading = true
        errorMessage = nil

        do {
            game = try await service.getDetail(id: gameId)
            // 同时加载评论
            await loadComments()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadVersions() async {
        do {
            let response = try await service.getVersions(gameId: gameId)
            versions = response.versions
        } catch {
            // 版本加载失败不影响主页面
        }
    }

    func deleteVersion(_ version: GameVersion) {
        Task {
            do {
                try await service.deleteVersion(gameId: gameId, versionId: version.id)
                await loadVersions()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 评论相关方法
    func loadComments(page: Int = 1) async {
        isLoadingComments = true
        commentCurrentPage = page

        do {
            let response = try await commentService.getGameCommentsByGame(gameId: gameId, page: page)
            comments = response.comments
            commentTotalPages = response.pagination.totalPages
        } catch {
            // 评论加载失败不影响主页面
        }

        isLoadingComments = false
    }

    func approveComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.approveGameComment(id: comment.id)
                await loadComments(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.rejectGameComment(id: comment.id)
                await loadComments(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComment(_ comment: GameComment) {
        Task {
            do {
                try await commentService.deleteGameComment(id: comment.id)
                await loadComments(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleCommentTop(_ comment: GameComment) {
        Task {
            do {
                _ = try await commentService.setGameCommentTop(id: comment.id, isTop: !(comment.isTop ?? false))
                await loadComments(page: commentCurrentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 辅助函数
private func formatDateTime(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }

    // 尝试不带毫秒的格式
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }

    return String(dateString.prefix(16))
}

// MARK: - 游戏详情面板 (嵌入式) - 保留用于其他场景
struct GameDetailPanel: View {
    @StateObject private var viewModel: GameDetailViewModel
    let onUpdate: () -> Void
    let onClose: () -> Void

    @State private var showEditSheet = false
    @State private var showCoverUploadSheet = false
    @State private var showContentImagesUploadSheet = false
    @State private var showUpdateImagesUploadSheet = false
    @State private var showNewVersionSheet = false
    @State private var editingVersion: GameVersion?

    init(gameId: Int, onUpdate: @escaping () -> Void, onClose: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
        self.onUpdate = onUpdate
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let game = viewModel.game {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            GameStatusBadge(status: game.status)
                        }
                    }
                } else {
                    Text("游戏详情")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.game != nil {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .help("编辑")
                }

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .help("关闭")
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let game = viewModel.game {
                ScrollView {
                    VStack(spacing: 16) {
                        // 封面和基本信息
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 8) {
                                AsyncImage(url: URL(string: game.covers.first ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                                .frame(width: 120, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                HStack(spacing: 4) {
                                    Button {
                                        showCoverUploadSheet = true
                                    } label: {
                                        Image(systemName: "photo")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("上传封面")

                                    Button {
                                        showContentImagesUploadSheet = true
                                    } label: {
                                        Image(systemName: "photo.stack")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("上传内容图")

                                    Button {
                                        showUpdateImagesUploadSheet = true
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("上传更新图")
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                if let name = game.name, !name.isEmpty {
                                    panelInfoRow("名称", name)
                                }
                                panelInfoRow("作者", game.author)
                                panelInfoRow("区域", GameRegion(rawValue: game.region ?? "")?.displayName ?? game.region ?? "-")
                                panelInfoRow("语言", GameLanguage(rawValue: game.language ?? "")?.displayName ?? game.language ?? "-")
                                panelInfoRow("画质", GameQuality(rawValue: game.quality ?? "")?.displayName ?? game.quality ?? "-")

                                HStack(spacing: 8) {
                                    if game.isTop == true {
                                        Label("置顶", systemImage: "pin.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if game.isTranslated == true {
                                        Text("汉化")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.blue.opacity(0.2))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 统计信息
                        panelStatsSection(game)

                        // 图片预览
                        panelImagesPreview(game)

                        // 版本列表
                        panelVersionsSection

                        // 类型
                        if let types = game.types, !types.isEmpty {
                            GroupBox("类型") {
                                FlowLayout(spacing: 8) {
                                    ForEach(types, id: \.self) { type in
                                        Text(type)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(8)
                            }
                        }

                        // 简介
                        if let desc = game.description, !desc.isEmpty {
                            GroupBox("简介") {
                                Text(desc)
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                        }

                        // 更新内容
                        if let update = game.update, !update.isEmpty {
                            GroupBox("更新内容") {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let updateTime = game.updateTime {
                                        Text(updateTime)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(update)
                                        .font(.callout)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "加载失败",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "未知错误")
                )
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .task {
            await viewModel.loadGame()
            await viewModel.loadVersions()
        }
        .sheet(isPresented: $showEditSheet) {
            if let game = viewModel.game {
                GameEditSheet(game: game) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCoverUploadSheet) {
            if let game = viewModel.game {
                GameCoverUploadSheet(game: game) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showContentImagesUploadSheet) {
            if let game = viewModel.game {
                GameContentImagesUploadSheet(game: game) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showUpdateImagesUploadSheet) {
            if let game = viewModel.game {
                GameUpdateImagesUploadSheet(game: game) {
                    Task {
                        await viewModel.loadGame()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showNewVersionSheet) {
            GameVersionEditSheet(
                gameId: viewModel.gameId,
                version: nil
            ) {
                Task { await viewModel.loadVersions() }
            }
        }
        .sheet(item: $editingVersion) { version in
            GameVersionEditSheet(
                gameId: viewModel.gameId,
                version: version
            ) {
                Task { await viewModel.loadVersions() }
            }
        }
    }

    // MARK: - 图片预览
    private func panelImagesPreview(_ game: Game) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("图片")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    HStack(spacing: 12) {
                        Text("封面 \(game.covers.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("内容 \(game.contentImages?.count ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("更新 \(game.updateImages?.count ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // 封面图片
                if !game.covers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("封面")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(game.covers, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quaternary)
                                    }
                                    .frame(width: 80, height: 45)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }

                // 内容图片
                if let contentImages = game.contentImages, !contentImages.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("内容图")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(contentImages, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quaternary)
                                    }
                                    .frame(width: 60, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }

                // 更新图片
                if let updateImages = game.updateImages, !updateImages.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("更新图")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(updateImages, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quaternary)
                                    }
                                    .frame(width: 60, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
        }
    }

    private func panelInfoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.callout)
                .lineLimit(2)
        }
    }

    private func panelStatsSection(_ game: Game) -> some View {
        GroupBox("统计") {
            HStack(spacing: 16) {
                panelStatItem("浏览", game.viewCount ?? 0)
                panelStatItem("收藏", game.favoriteCount ?? 0)
                panelStatItem("销售", game.saleCount ?? 0)
            }
            .padding(.vertical, 8)
        }
    }

    private func panelStatItem(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(formatPanelNumber(value))
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatPanelNumber(_ value: Int) -> String {
        if value >= 10000 {
            return String(format: "%.1f万", Double(value) / 10000.0)
        }
        return "\(value)"
    }

    private var panelVersionsSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("版本列表")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("共 \(viewModel.versions.count) 个")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showNewVersionSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("添加版本")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if viewModel.versions.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无版本")
                            .foregroundStyle(.secondary)
                        Button("添加第一个版本") {
                            showNewVersionSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.versions.prefix(10)) { version in
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text("v\(version.version)")
                                                    .font(.callout)
                                                    .fontWeight(.medium)
                                                if version.isLatest == true {
                                                    Text("最新")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 4)
                                                        .background(.green.opacity(0.2))
                                                        .foregroundStyle(.green)
                                                        .clipShape(Capsule())
                                                }
                                                if let status = version.status {
                                                    Text(status.displayName)
                                                        .font(.caption2)
                                                        .padding(.horizontal, 4)
                                                        .background(.blue.opacity(0.2))
                                                        .foregroundStyle(.blue)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            if let desc = version.description, !desc.isEmpty {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(String(format: "%.2f", version.size ?? 0)) GB")
                                                .font(.caption.monospacedDigit())
                                            if let createdAt = version.createdAt {
                                                Text(formatPanelDate(createdAt))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Button {
                                            editingVersion = version
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("编辑版本")
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)

                                    if version.id != viewModel.versions.prefix(10).last?.id {
                                        Divider()
                                            .padding(.leading)
                                    }
                                }
                            }
                            if viewModel.versions.count > 10 {
                                Text("还有 \(viewModel.versions.count - 10) 个版本...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                }
            }
        }
    }

    private func formatPanelDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd"
            return displayFormatter.string(from: date)
        }
        return String(dateString.prefix(10))
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: containerWidth, height: currentY + maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            maxHeight = max(maxHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - 游戏封面上传表单
struct GameCoverUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let onUpdate: () -> Void

    @State private var selectedImages: [URL] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("上传封面图片")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("上传说明", systemImage: "info.circle")
                                .font(.headline)

                            Text("• 可选择多张图片作为封面")
                            Text("• 支持 JPG、PNG、WebP、GIF 格式")
                            Text("• 推荐使用 16:9 横版图片")
                            Text("• 新上传的图片将替换现有封面")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // 目标游戏
                    GroupBox("目标游戏") {
                        HStack {
                            Text(game.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // 当前封面
                    if !game.covers.isEmpty {
                        GroupBox("当前封面 (\(game.covers.count) 张)") {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(game.covers, id: \.self) { cover in
                                        AsyncImage(url: URL(string: cover)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 120, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding()
                            }
                        }
                    }

                    // 选择图片
                    GroupBox("选择新封面") {
                        VStack(spacing: 12) {
                            if selectedImages.isEmpty {
                                Button {
                                    selectImages()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.largeTitle)
                                        Text("点击选择图片")
                                    }
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedImages, id: \.self) { url in
                                            if let nsImage = NSImage(contentsOf: url) {
                                                Image(nsImage: nsImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 70)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding()
                                }

                                HStack {
                                    Text("已选择 \(selectedImages.count) 张图片")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("重新选择") {
                                        selectImages()
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 错误信息
                    if let error = errorMessage {
                        GroupBox {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 操作按钮
            HStack {
                Spacer()

                if isUploading {
                    ProgressView(value: uploadProgress, total: 100)
                        .frame(width: 100)
                    Text("\(Int(uploadProgress))%")
                        .font(.caption.monospacedDigit())
                } else {
                    Button("开始上传") {
                        uploadCovers()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImages.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 650)
    }

    private func selectImages() {
        let urls = UploadService.shared.selectImages(allowMultiple: true, maxCount: 10)
        if !urls.isEmpty {
            selectedImages = urls
            errorMessage = nil
        }
    }

    private func uploadCovers() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        errorMessage = nil
        uploadProgress = 0

        Task {
            do {
                // 先读取所有图片数据获取文件大小
                var imageDataList: [Data] = []
                var files: [UploadFileInfo] = []

                for (index, url) in selectedImages.enumerated() {
                    guard let imageData = UploadService.shared.imageData(from: url) else {
                        throw UploadError.fileReadError
                    }
                    imageDataList.append(imageData)
                    files.append(UploadFileInfo(
                        fileName: url.lastPathComponent,
                        contentType: getContentType(for: url),
                        sortOrder: index + 1,
                        fileSize: imageData.count
                    ))
                }

                // 获取上传URL
                let uploadResult = try await UploadService.shared.getGameCoversUploadUrls(
                    gameSlug: game.slug,
                    files: files
                )

                // 上传每个文件
                var uploadedUrls: [String] = []
                for (index, imageData) in imageDataList.enumerated() {
                    let uploadInfo = uploadResult.uploadInfos[index]

                    try await UploadService.shared.uploadToPresignedUrl(
                        uploadInfo.uploadUrl,
                        data: imageData,
                        contentType: files[index].contentType
                    )

                    uploadedUrls.append(uploadInfo.fileUrl)
                    uploadProgress = Double(index + 1) / Double(selectedImages.count) * 100
                }

                // 更新游戏封面
                try await UploadService.shared.updateGameCovers(gameId: game.id, covers: uploadedUrls)

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploading = false
        }
    }

    private func getContentType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "image/jpeg"
        }
    }
}

// MARK: - 游戏内容图片上传表单
struct GameContentImagesUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let onUpdate: () -> Void

    @State private var selectedImages: [URL] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("上传内容图片")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("上传说明", systemImage: "info.circle")
                                .font(.headline)

                            Text("• 可选择多张图片作为内容展示图")
                            Text("• 支持 JPG、PNG、WebP、GIF 格式")
                            Text("• 这些图片将在游戏详情页展示")
                            Text("• 新上传的图片将替换现有内容图")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // 目标游戏
                    GroupBox("目标游戏") {
                        HStack {
                            Text(game.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // 当前内容图
                    if let contentImages = game.contentImages, !contentImages.isEmpty {
                        GroupBox("当前内容图 (\(contentImages.count) 张)") {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(contentImages, id: \.self) { image in
                                        AsyncImage(url: URL(string: image)) { img in
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 120, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding()
                            }
                        }
                    }

                    // 选择图片
                    GroupBox("选择新内容图") {
                        VStack(spacing: 12) {
                            if selectedImages.isEmpty {
                                Button {
                                    selectImages()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.stack")
                                            .font(.largeTitle)
                                        Text("点击选择图片")
                                    }
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedImages, id: \.self) { url in
                                            if let nsImage = NSImage(contentsOf: url) {
                                                Image(nsImage: nsImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 70)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding()
                                }

                                HStack {
                                    Text("已选择 \(selectedImages.count) 张图片")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("重新选择") {
                                        selectImages()
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 错误信息
                    if let error = errorMessage {
                        GroupBox {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 操作按钮
            HStack {
                Spacer()

                if isUploading {
                    ProgressView(value: uploadProgress, total: 100)
                        .frame(width: 100)
                    Text("\(Int(uploadProgress))%")
                        .font(.caption.monospacedDigit())
                } else {
                    Button("开始上传") {
                        uploadContentImages()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImages.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 650)
    }

    private func selectImages() {
        let urls = UploadService.shared.selectImages(allowMultiple: true, maxCount: 20)
        if !urls.isEmpty {
            selectedImages = urls
            errorMessage = nil
        }
    }

    private func uploadContentImages() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        errorMessage = nil
        uploadProgress = 0

        Task {
            do {
                // 先读取所有图片数据获取文件大小
                var imageDataList: [Data] = []
                var files: [UploadFileInfo] = []

                for (index, url) in selectedImages.enumerated() {
                    guard let imageData = UploadService.shared.imageData(from: url) else {
                        throw UploadError.fileReadError
                    }
                    imageDataList.append(imageData)
                    files.append(UploadFileInfo(
                        fileName: url.lastPathComponent,
                        contentType: getContentType(for: url),
                        sortOrder: index + 1,
                        fileSize: imageData.count
                    ))
                }

                // 获取上传URL
                let uploadResult = try await UploadService.shared.getGameContentsUploadUrls(
                    gameSlug: game.slug,
                    files: files
                )

                // 上传每个文件
                var uploadedUrls: [String] = []
                for (index, imageData) in imageDataList.enumerated() {
                    let uploadInfo = uploadResult.uploadInfos[index]

                    try await UploadService.shared.uploadToPresignedUrl(
                        uploadInfo.uploadUrl,
                        data: imageData,
                        contentType: files[index].contentType
                    )

                    uploadedUrls.append(uploadInfo.fileUrl)
                    uploadProgress = Double(index + 1) / Double(selectedImages.count) * 100
                }

                // 更新游戏内容图片
                try await UploadService.shared.updateGameContentImages(gameId: game.id, contentImages: uploadedUrls)

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploading = false
        }
    }

    private func getContentType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "image/jpeg"
        }
    }
}

// MARK: - 游戏更新图片上传表单
struct GameUpdateImagesUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let onUpdate: () -> Void

    @State private var selectedImages: [URL] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("上传更新图片")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("上传说明", systemImage: "info.circle")
                                .font(.headline)

                            Text("• 可选择多张图片作为更新展示图")
                            Text("• 支持 JPG、PNG、WebP、GIF 格式")
                            Text("• 这些图片将在游戏更新详情中展示")
                            Text("• 新上传的图片将替换现有更新图")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // 目标游戏
                    GroupBox("目标游戏") {
                        HStack {
                            Text(game.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(game.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // 当前更新图
                    if let updateImages = game.updateImages, !updateImages.isEmpty {
                        GroupBox("当前更新图 (\(updateImages.count) 张)") {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(updateImages, id: \.self) { image in
                                        AsyncImage(url: URL(string: image)) { img in
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 120, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding()
                            }
                        }
                    }

                    // 选择图片
                    GroupBox("选择新更新图") {
                        VStack(spacing: 12) {
                            if selectedImages.isEmpty {
                                Button {
                                    selectImages()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise.circle")
                                            .font(.largeTitle)
                                        Text("点击选择图片")
                                    }
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedImages, id: \.self) { url in
                                            if let nsImage = NSImage(contentsOf: url) {
                                                Image(nsImage: nsImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 70)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding()
                                }

                                HStack {
                                    Text("已选择 \(selectedImages.count) 张图片")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("重新选择") {
                                        selectImages()
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 错误信息
                    if let error = errorMessage {
                        GroupBox {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 操作按钮
            HStack {
                Spacer()

                if isUploading {
                    ProgressView(value: uploadProgress, total: 100)
                        .frame(width: 100)
                    Text("\(Int(uploadProgress))%")
                        .font(.caption.monospacedDigit())
                } else {
                    Button("开始上传") {
                        uploadUpdateImages()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImages.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 650)
    }

    private func selectImages() {
        let urls = UploadService.shared.selectImages(allowMultiple: true, maxCount: 20)
        if !urls.isEmpty {
            selectedImages = urls
            errorMessage = nil
        }
    }

    private func uploadUpdateImages() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        errorMessage = nil
        uploadProgress = 0

        Task {
            do {
                // 先读取所有图片数据获取文件大小
                var imageDataList: [Data] = []
                var files: [UploadFileInfo] = []

                for (index, url) in selectedImages.enumerated() {
                    guard let imageData = UploadService.shared.imageData(from: url) else {
                        throw UploadError.fileReadError
                    }
                    imageDataList.append(imageData)
                    files.append(UploadFileInfo(
                        fileName: url.lastPathComponent,
                        contentType: getContentType(for: url),
                        sortOrder: index + 1,
                        fileSize: imageData.count
                    ))
                }

                // 获取上传URL
                let uploadResult = try await UploadService.shared.getGameUpdatesUploadUrls(
                    gameSlug: game.slug,
                    files: files
                )

                // 上传每个文件
                var uploadedUrls: [String] = []
                for (index, imageData) in imageDataList.enumerated() {
                    let uploadInfo = uploadResult.uploadInfos[index]

                    try await UploadService.shared.uploadToPresignedUrl(
                        uploadInfo.uploadUrl,
                        data: imageData,
                        contentType: files[index].contentType
                    )

                    uploadedUrls.append(uploadInfo.fileUrl)
                    uploadProgress = Double(index + 1) / Double(selectedImages.count) * 100
                }

                // 更新游戏更新图片
                try await UploadService.shared.updateGameUpdateImages(gameId: game.id, updateImages: uploadedUrls)

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploading = false
        }
    }

    private func getContentType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "image/jpeg"
        }
    }
}

#Preview("GameDetailView") {
    GameDetailView(gameId: 1, onUpdate: {})
}

#Preview("GameDetailPanel") {
    GameDetailPanel(gameId: 1, onUpdate: {})
        .frame(width: 400, height: 600)
}
