//
//  AnimeDetailView.swift
//  X-Manage
//
//  动漫详情视图

import SwiftUI
import AVKit

struct AnimeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AnimeDetailViewModel
    let onUpdate: () -> Void

    @State private var showCreateEpisodeSheet = false
    @State private var showEditSheet = false
    @State private var selectedEpisodeForDetail: Episode?
    @State private var selectedEpisodeForEdit: Episode?
    @State private var selectedEpisodeForUpload: Episode?

    init(animeId: Int, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(animeId: animeId))
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let anime = viewModel.anime {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(anime.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack(spacing: 8) {
                            Text("ID: \(anime.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            AnimeStatusBadge(status: anime.status)
                            if anime.isTop == true {
                                Label("置顶", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if anime.isCompleted == true {
                                Text("已完结")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } else {
                    Text("动漫详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.anime != nil {
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
            } else if let anime = viewModel.anime {
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本信息
                        basicInfoSection(anime)

                        // 封面和背景图
                        imagesSection(anime)

                        // 剧集列表
                        episodesSection

                        // 统计信息
                        statsSection(anime)

                        // 描述
                        if let description = anime.description, !description.isEmpty {
                            descriptionSection(description)
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
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadAnime()
            await viewModel.loadEpisodes()
        }
        .sheet(isPresented: $showCreateEpisodeSheet) {
            if let anime = viewModel.anime {
                EpisodeCreateSheet(
                    animeId: anime.id,
                    nextEpisodeNo: (viewModel.episodes.map { $0.episodeNo ?? 0 }.max() ?? 0) + 1
                ) {
                    Task {
                        await viewModel.loadEpisodes()
                        await viewModel.loadAnime()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(item: $selectedEpisodeForDetail) { episode in
            EpisodeDetailSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(item: $selectedEpisodeForEdit) { episode in
            EpisodeEditSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(item: $selectedEpisodeForUpload) { episode in
            EpisodeVideoUploadSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let anime = viewModel.anime {
                AnimeEditSheet(anime: anime) {
                    Task {
                        await viewModel.loadAnime()
                        onUpdate()
                    }
                }
            }
        }
    }

    // MARK: - 基本信息
    private func basicInfoSection(_ anime: AnimeDetail) -> some View {
        GroupBox("基本信息") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem("标题", anime.title)
                infoItem("原名", anime.titleOriginal ?? "-")
                infoItem("制作公司", anime.studio ?? "-")
                infoItem("分类ID", String(anime.categoryId))
                infoItem("区域", anime.region ?? "-")
                infoItem("画质", anime.quality ?? "-")
                infoItem("季度", anime.season != nil ? "第\(anime.season!)季" : "-")
                infoItem("总集数", anime.totalEpisodes != nil ? "\(anime.totalEpisodes!)集" : "-")
                infoItem("当前集数", anime.currentEpisode != nil ? "第\(anime.currentEpisode!)集" : "-")
                infoItem("播出日期", anime.airDate ?? "-")
                infoItem("完结日期", anime.endDate ?? "-")
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
    private func imagesSection(_ anime: AnimeDetail) -> some View {
        GroupBox("图片") {
            HStack(spacing: 24) {
                VStack {
                    Text("封面")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AsyncImage(url: URL(string: anime.cover)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    .frame(width: 150, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let fanart = anime.fanart, !fanart.isEmpty {
                    VStack {
                        Text("背景图")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        AsyncImage(url: URL(string: fanart)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                        }
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - 剧集列表
    private var episodesSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("剧集列表")
                        .font(.headline)

                    Spacer()

                    Text("共 \(viewModel.episodes.count) 集")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showCreateEpisodeSheet = true
                    } label: {
                        Label("添加剧集", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                if viewModel.episodes.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无剧集")
                            .foregroundStyle(.secondary)
                        Button("添加第一集") {
                            showCreateEpisodeSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.episodes) { episode in
                                VStack(spacing: 0) {
                                    HStack {
                                        if let cover = episode.cover, !cover.isEmpty {
                                            AsyncImage(url: URL(string: cover)) { image in
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

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text("第 \(episode.episodeNo ?? 0) 集")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(episode.title)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)

                                                EpisodeStatusBadge(isActive: episode.isActive, status: episode.status)
                                            }

                                            HStack(spacing: 12) {
                                                if let duration = episode.duration {
                                                    Text(formatDuration(duration))
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Text("\(episode.viewCount ?? 0) 次播放")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Text(formatDateTime(episode.createdAt ?? ""))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        // 操作按钮组
                                        HStack(spacing: 4) {
                                            Button {
                                                selectedEpisodeForUpload = episode
                                            } label: {
                                                Image(systemName: "arrow.up.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.blue)
                                            .help("上传视频")

                                            Button {
                                                selectedEpisodeForDetail = episode
                                            } label: {
                                                Image(systemName: "play.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.green)
                                            .help("查看详情")

                                            Button {
                                                selectedEpisodeForEdit = episode
                                            } label: {
                                                Image(systemName: "pencil.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.orange)
                                            .help("编辑剧集")

                                            Button {
                                                Task {
                                                    await viewModel.deleteEpisode(episode)
                                                }
                                            } label: {
                                                Image(systemName: "trash.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.red)
                                            .help("删除剧集")
                                        }
                                    }
                                    .padding()

                                    if episode.id != viewModel.episodes.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }

    // MARK: - 统计信息
    private func statsSection(_ anime: AnimeDetail) -> some View {
        GroupBox("统计信息") {
            HStack(spacing: 32) {
                statItem("浏览量", anime.viewCount ?? 0)
                statItem("点赞数", anime.likeCount ?? 0)
                statItem("评论数", anime.commentCount ?? 0)
                statItem("收藏数", anime.favoriteCount ?? 0)
            }
            .padding()
        }
    }

    private func statItem(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text(formatNumber(value))
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatNumber(_ value: Int) -> String {
        if value >= 10000 {
            return String(format: "%.1f万", Double(value) / 10000.0)
        }
        return "\(value)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - 描述
    private func descriptionSection(_ description: String) -> some View {
        GroupBox("简介") {
            Text(description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

// MARK: - 剧集状态徽章
struct EpisodeStatusBadge: View {
    let isActive: Bool?
    let status: String?

    init(isActive: Bool? = nil, status: String? = nil) {
        self.isActive = isActive
        self.status = status
    }

    var body: some View {
        Text(displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var displayName: String {
        // 优先使用 status，如果有的话
        if let status = status {
            return EpisodeStatus(rawValue: status)?.displayName ?? status
        }
        // 否则使用 isActive
        if let isActive = isActive {
            return isActive ? "已激活" : "未激活"
        }
        return "未知"
    }

    private var backgroundColor: Color {
        // 优先使用 status
        if let status = status {
            switch status {
            case EpisodeStatus.completed.rawValue:
                return .green
            case EpisodeStatus.processing.rawValue:
                return .blue
            case EpisodeStatus.pending.rawValue:
                return .orange
            case EpisodeStatus.failed.rawValue:
                return .red
            default:
                return .gray
            }
        }
        // 否则使用 isActive
        if let isActive = isActive {
            return isActive ? .green : .gray
        }
        return .gray
    }
}

// MARK: - ViewModel
@MainActor
class AnimeDetailViewModel: ObservableObject {
    @Published var anime: AnimeDetail?
    @Published var episodes: [Episode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let animeId: Int
    private let service = AnimeService.shared

    init(animeId: Int) {
        self.animeId = animeId
    }

    func loadAnime() async {
        isLoading = true
        errorMessage = nil

        do {
            anime = try await service.getDetail(id: animeId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadEpisodes() async {
        do {
            let response = try await service.getEpisodes(animeId: animeId, page: 1, pageSize: 100)
            episodes = response.episodes
        } catch {
            // 剧集加载失败不影响主页面
        }
    }

    func deleteEpisode(_ episode: Episode) async {
        do {
            try await service.deleteEpisode(episodeId: episode.id)
            episodes.removeAll { $0.id == episode.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - 剧集创建表单
struct EpisodeCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let animeId: Int
    let nextEpisodeNo: Int
    let onUpdate: () -> Void

    @State private var title = ""
    @State private var episodeNo: Int
    @State private var continuousMode = true
    @State private var createdCount = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(animeId: Int, nextEpisodeNo: Int, onUpdate: @escaping () -> Void) {
        self.animeId = animeId
        self.nextEpisodeNo = nextEpisodeNo
        self.onUpdate = onUpdate
        _episodeNo = State(initialValue: nextEpisodeNo)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("添加剧集")
                    .font(.title2)
                    .fontWeight(.semibold)

                if createdCount > 0 {
                    Text("已创建 \(createdCount) 集")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("剧集信息") {
                    TextField("标题", text: $title)
                    TextField("集数", value: $episodeNo, format: .number)
                        .frame(width: 100)
                }

                Section("选项") {
                    Toggle("连续创建模式", isOn: $continuousMode)
                        .help("创建后继续添加下一集，不关闭窗口")
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()

                Button("创建剧集") {
                    createEpisode()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || isSaving)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }

    private func createEpisode() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let request = CreateEpisodeRequest(
                    title: title,
                    episodeNo: episodeNo
                )
                _ = try await AnimeService.shared.createEpisode(animeId: animeId, request: request)
                createdCount += 1
                onUpdate()

                if continuousMode {
                    title = ""
                    episodeNo += 1
                } else {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 剧集详情视图（查看）
struct EpisodeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let episode: Episode
    let animeSlug: String
    let onUpdate: () -> Void

    @State private var episodeDetail: EpisodeDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showEditSheet = false

    init(episode: Episode, animeSlug: String, onUpdate: @escaping () -> Void) {
        self.episode = episode
        self.animeSlug = animeSlug
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("剧集详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                    HStack(spacing: 8) {
                        Text("第 \(episode.episodeNo ?? 0) 集")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        EpisodeStatusBadge(isActive: episode.isActive, status: episode.status)
                        if let duration = episode.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()

                Button {
                    showEditSheet = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .buttonStyle(.bordered)

                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView("加载详情...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = episodeDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 视频播放器
                        if let manifestUrl = detail.manifestUrl, !manifestUrl.isEmpty {
                            GroupBox {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("视频播放")
                                            .font(.headline)
                                        Spacer()
                                        if let qualities = detail.qualities {
                                            Text(qualities)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding()

                                    Divider()

                                    DashVideoPlayer(
                                        manifestUrl: manifestUrl,
                                        encryption: detail.encryption,
                                        autoPlay: false
                                    )
                                    .frame(height: 360)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding()
                                }
                            }
                        }

                        // 基本信息
                        GroupBox("基本信息") {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                detailInfoItem("标题", detail.title)
                                detailInfoItem("集数", "第 \(detail.episodeNo ?? 0) 集")
                                detailInfoItem("时长", detail.duration != nil ? formatDuration(detail.duration!) : "-")
                                detailInfoItem("播放量", "\(detail.viewCount ?? 0) 次")
                                detailInfoItem("分辨率", detail.width != nil && detail.height != nil ? "\(detail.width!)×\(detail.height!)" : "-")
                                detailInfoItem("码率", detail.bitrate != nil ? "\(detail.bitrate! / 1000) kbps" : "-")
                            }
                            .padding()
                        }

                        // 截图预览
                        if let screenshots = detail.screenshots, !screenshots.isEmpty {
                            GroupBox {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("视频截图")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(screenshots.count) 张")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()

                                    Divider()

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(screenshots, id: \.self) { url in
                                                AsyncImage(url: URL(string: url)) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Rectangle()
                                                        .fill(.quaternary)
                                                }
                                                .frame(width: 192, height: 108)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }

                        // 封面和横图
                        HStack(spacing: 16) {
                            // 封面
                            GroupBox("封面") {
                                if let cover = detail.cover, !cover.isEmpty {
                                    AsyncImage(url: URL(string: cover)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quaternary)
                                    }
                                    .frame(width: 160, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding()
                                } else {
                                    Rectangle()
                                        .fill(.quaternary)
                                        .frame(width: 160, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            Text("无封面")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                }
                            }

                            // 横图
                            GroupBox("横图") {
                                if let fanart = detail.fanart, !fanart.isEmpty {
                                    AsyncImage(url: URL(string: fanart)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quaternary)
                                    }
                                    .frame(width: 200, height: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding()
                                } else {
                                    Rectangle()
                                        .fill(.quaternary)
                                        .frame(width: 200, height: 112)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            Text("无横图")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                }
                            }

                            Spacer()
                        }

                        // 技术信息
                        if detail.storagePath != nil || detail.frameRate != nil {
                            GroupBox("技术信息") {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let path = detail.storagePath, !path.isEmpty {
                                        HStack {
                                            Text("存储路径")
                                                .foregroundStyle(.secondary)
                                            Text(path)
                                                .font(.caption.monospaced())
                                        }
                                    }
                                    if let frameRate = detail.frameRate {
                                        HStack {
                                            Text("帧率")
                                                .foregroundStyle(.secondary)
                                            Text("\(String(format: "%.2f", frameRate)) fps")
                                        }
                                    }
                                    if let createdAt = detail.createdAt {
                                        HStack {
                                            Text("创建时间")
                                                .foregroundStyle(.secondary)
                                            Text(formatDateTime(createdAt))
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .padding()
                }
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "加载失败",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            }
        }
        .frame(width: 900, height: 800)
        .task {
            await loadEpisodeDetail()
        }
        .sheet(isPresented: $showEditSheet) {
            EpisodeEditSheet(episode: episode, animeSlug: animeSlug) {
                Task {
                    await loadEpisodeDetail()
                    onUpdate()
                }
            }
        }
    }

    private func loadEpisodeDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            episodeDetail = try await AnimeService.shared.getEpisodeDetail(episodeId: episode.id)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func detailInfoItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - 剧集编辑表单
struct EpisodeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let episode: Episode
    let animeSlug: String
    let onUpdate: () -> Void

    @State private var title: String
    @State private var episodeNo: Int
    @State private var selectedCover: URL?
    @State private var selectedFanart: URL?
    @State private var selectedVideo: URL?
    @State private var isSaving = false
    @State private var isUploadingCover = false
    @State private var isUploadingFanart = false
    @State private var isUploadingVideo = false
    @State private var videoUploadProgress: VideoUploadProgress?
    @State private var videoUploadResult: CompleteVideoUploadResponse?
    @State private var errorMessage: String?

    init(episode: Episode, animeSlug: String, onUpdate: @escaping () -> Void) {
        self.episode = episode
        self.animeSlug = animeSlug
        self.onUpdate = onUpdate
        _title = State(initialValue: episode.title)
        _episodeNo = State(initialValue: episode.episodeNo ?? 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("编辑剧集")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息编辑
                    GroupBox("基本信息") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("标题")
                                    .frame(width: 60, alignment: .leading)
                                    .foregroundStyle(.secondary)
                                TextField("", text: $title)
                            }
                            HStack {
                                Text("集数")
                                    .frame(width: 60, alignment: .leading)
                                    .foregroundStyle(.secondary)
                                TextField("", value: $episodeNo, format: .number)
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                    }

                    // 封面上传
                    GroupBox {
                        VStack(spacing: 0) {
                            HStack {
                                Text("封面图片")
                                    .font(.headline)
                                Spacer()
                                if isUploadingCover {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button("选择图片") {
                                        selectCover()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()

                            Divider()

                            HStack(spacing: 20) {
                                VStack(spacing: 8) {
                                    Text("当前封面")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let cover = episode.cover, !cover.isEmpty {
                                        AsyncImage(url: URL(string: cover)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 160, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Rectangle()
                                            .fill(.quaternary)
                                            .frame(width: 160, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay {
                                                Text("无封面")
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                }

                                if let selectedCover = selectedCover,
                                   let nsImage = NSImage(contentsOf: selectedCover) {
                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)

                                    VStack(spacing: 8) {
                                        Text("新封面")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 160, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                        }
                    }

                    // 横图上传
                    GroupBox {
                        VStack(spacing: 0) {
                            HStack {
                                Text("横图 (Fanart)")
                                    .font(.headline)
                                Spacer()
                                if isUploadingFanart {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button("选择图片") {
                                        selectFanart()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()

                            Divider()

                            HStack(spacing: 20) {
                                VStack(spacing: 8) {
                                    Text("当前横图")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let fanart = episode.fanart, !fanart.isEmpty {
                                        AsyncImage(url: URL(string: fanart)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(.quaternary)
                                        }
                                        .frame(width: 200, height: 112)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Rectangle()
                                            .fill(.quaternary)
                                            .frame(width: 200, height: 112)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay {
                                                Text("无横图")
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                }

                                if let selectedFanart = selectedFanart,
                                   let nsImage = NSImage(contentsOf: selectedFanart) {
                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)

                                    VStack(spacing: 8) {
                                        Text("新横图")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 200, height: 112)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                        }
                    }

                    // 视频上传
                    GroupBox {
                        VStack(spacing: 0) {
                            HStack {
                                Text("上传视频")
                                    .font(.headline)
                                Spacer()

                                if let progress = videoUploadProgress, progress.status == .uploading || progress.status == .completing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(String(format: "%.1f%%", progress.percentage))
                                        .font(.caption.monospacedDigit())
                                } else {
                                    Button("选择视频") {
                                        selectVideo()
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isUploadingVideo)
                                }
                            }
                            .padding()

                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                if let selectedVideo = selectedVideo {
                                    HStack {
                                        Image(systemName: "video.fill")
                                            .foregroundStyle(.blue)
                                        Text(selectedVideo.lastPathComponent)
                                            .lineLimit(1)
                                        Spacer()
                                        if let size = getFileSize(selectedVideo) {
                                            Text(formatFileSize(size))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }

                                if let progress = videoUploadProgress {
                                    VStack(spacing: 8) {
                                        ProgressView(value: progress.percentage, total: 100)
                                        HStack {
                                            switch progress.status {
                                            case .uploading:
                                                Text("正在上传...")
                                            case .completing:
                                                Text("正在处理...")
                                            case .completed:
                                                Text("上传完成!")
                                                    .foregroundStyle(.green)
                                            case .failed:
                                                Text("上传失败")
                                                    .foregroundStyle(.red)
                                            default:
                                                EmptyView()
                                            }
                                            Spacer()
                                            Text("\(progress.uploadedChunks)/\(progress.totalChunks) 分块")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                                if let result = videoUploadResult {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading) {
                                            Text("上传成功,转码任务已创建")
                                            Text("任务ID: \(result.taskId)")
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }

                                Text("支持 MP4、MOV、AVI 等格式,上传后将自动开始转码处理")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("保存中...")
                        .foregroundStyle(.secondary)
                } else {
                    Button("保存") {
                        saveEpisode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 750)
    }

    private func selectCover() {
        let urls = UploadService.shared.selectImages(allowMultiple: false, maxCount: 1)
        if let url = urls.first {
            selectedCover = url
            uploadCover(url)
        }
    }

    private func selectFanart() {
        let urls = UploadService.shared.selectImages(allowMultiple: false, maxCount: 1)
        if let url = urls.first {
            selectedFanart = url
            uploadFanart(url)
        }
    }

    private func uploadCover(_ url: URL) {
        isUploadingCover = true
        errorMessage = nil

        Task {
            do {
                let uploadResult = try await UploadService.shared.getEpisodeCoverUploadUrl(episodeId: episode.id)

                guard let imageData = UploadService.shared.imageData(from: url) else {
                    throw UploadError.fileReadError
                }

                try await UploadService.shared.uploadToPresignedUrl(
                    uploadResult.uploadUrl,
                    data: imageData,
                    contentType: "image/jpeg"
                )

                try await AnimeService.shared.updateEpisodeCover(episodeId: episode.id, cover: uploadResult.storagePath)

                onUpdate()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploadingCover = false
        }
    }

    private func uploadFanart(_ url: URL) {
        isUploadingFanart = true
        errorMessage = nil

        Task {
            do {
                let uploadResult = try await UploadService.shared.getEpisodeFanartUploadUrl(episodeId: episode.id)

                guard let imageData = UploadService.shared.imageData(from: url) else {
                    throw UploadError.fileReadError
                }

                try await UploadService.shared.uploadToPresignedUrl(
                    uploadResult.uploadUrl,
                    data: imageData,
                    contentType: "image/jpeg"
                )

                try await AnimeService.shared.updateEpisodeFanart(episodeId: episode.id, fanart: uploadResult.storagePath)

                onUpdate()
            } catch {
                errorMessage = error.localizedDescription
            }

            isUploadingFanart = false
        }
    }

    private func saveEpisode() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var request = UpdateEpisodeRequest()
                request.title = title
                request.episodeNo = episodeNo

                _ = try await AnimeService.shared.updateEpisode(episodeId: episode.id, request: request)

                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func selectVideo() {
        if let url = UploadService.shared.selectVideo() {
            selectedVideo = url
            uploadVideo(url)
        }
    }

    private func uploadVideo(_ url: URL) {
        isUploadingVideo = true
        errorMessage = nil
        videoUploadResult = nil
        videoUploadProgress = VideoUploadProgress(
            status: .pending,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0
        )

        Task {
            let uploader = AnimeVideoUploader(
                animeId: episode.animeId,
                animeSlug: animeSlug,
                episodeNo: episode.episodeNo ?? 1,
                fileUrl: url,
                concurrency: 2,
                maxRetries: 3
            ) { progress in
                Task { @MainActor in
                    self.videoUploadProgress = progress
                }
            }

            do {
                let result = try await uploader.upload()
                videoUploadResult = result
                onUpdate()
            } catch {
                errorMessage = error.localizedDescription
                videoUploadProgress?.status = .failed
            }

            isUploadingVideo = false
        }
    }

    private func getFileSize(_ url: URL) -> Int? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int
        } catch {
            return nil
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - 剧集视频上传表单
struct EpisodeVideoUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let episode: Episode
    let animeSlug: String
    let onUpdate: () -> Void

    @State private var selectedVideo: URL?
    @State private var isUploading = false
    @State private var uploadProgress: VideoUploadProgress?
    @State private var uploadResult: CompleteVideoUploadResponse?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("上传视频")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("第 \(episode.episodeNo ?? 0) 集 - \(episode.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                // 选择视频
                GroupBox {
                    VStack(spacing: 16) {
                        if selectedVideo == nil {
                            VStack(spacing: 12) {
                                Image(systemName: "video.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("选择要上传的视频文件")
                                    .foregroundStyle(.secondary)
                                Button("选择视频") {
                                    selectVideo()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isUploading)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let video = selectedVideo {
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.lastPathComponent)
                                        .fontWeight(.medium)
                                    if let size = getFileSize(video) {
                                        Text(formatFileSize(size))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if !isUploading {
                                    Button("重新选择") {
                                        selectVideo()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                        }

                        // 上传进度
                        if let progress = uploadProgress {
                            VStack(spacing: 12) {
                                ProgressView(value: progress.percentage, total: 100)
                                    .progressViewStyle(.linear)

                                HStack {
                                    switch progress.status {
                                    case .uploading:
                                        HStack(spacing: 4) {
                                            ProgressView()
                                                .scaleEffect(0.6)
                                            Text("正在上传...")
                                        }
                                    case .completing:
                                        HStack(spacing: 4) {
                                            ProgressView()
                                                .scaleEffect(0.6)
                                            Text("正在处理...")
                                        }
                                    case .completed:
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("上传完成!")
                                        }
                                    case .failed:
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                            Text("上传失败")
                                        }
                                    default:
                                        EmptyView()
                                    }

                                    Spacer()

                                    Text(String(format: "%.1f%%", progress.percentage))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)

                                    Text("(\(progress.uploadedChunks)/\(progress.totalChunks))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                        }

                        // 上传结果
                        if let result = uploadResult {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("上传成功，转码任务已创建")
                                        .fontWeight(.medium)
                                    Text("任务 ID: \(result.taskId)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // 错误信息
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // 说明
                GroupBox("说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("支持 MP4、MOV、MKV、AVI 等格式", systemImage: "film")
                        Label("上传后将自动开始转码处理", systemImage: "gearshape.2")
                        Label("转码完成后可在详情页预览播放", systemImage: "play.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                }
            }
            .padding()

            Spacer()

            Divider()

            // 操作按钮
            HStack {
                Spacer()
                if uploadResult != nil {
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 550)
    }

    private func selectVideo() {
        if let url = UploadService.shared.selectVideo() {
            selectedVideo = url
            uploadVideo(url)
        }
    }

    private func uploadVideo(_ url: URL) {
        isUploading = true
        errorMessage = nil
        uploadResult = nil
        uploadProgress = VideoUploadProgress(
            status: .pending,
            uploadedChunks: 0,
            totalChunks: 0,
            uploadedBytes: 0,
            totalBytes: 0
        )

        Task {
            let uploader = AnimeVideoUploader(
                animeId: episode.animeId,
                animeSlug: animeSlug,
                episodeNo: episode.episodeNo ?? 1,
                fileUrl: url,
                concurrency: 2,
                maxRetries: 3
            ) { progress in
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }

            do {
                let result = try await uploader.upload()
                uploadResult = result
                onUpdate()
            } catch {
                errorMessage = error.localizedDescription
                uploadProgress?.status = .failed
            }

            isUploading = false
        }
    }

    private func getFileSize(_ url: URL) -> Int? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int
        } catch {
            return nil
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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

    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }

    return String(dateString.prefix(16))
}

// MARK: - 动漫详情面板 (嵌入式)
struct AnimeDetailPanel: View {
    @StateObject private var viewModel: AnimeDetailViewModel
    let onUpdate: () -> Void
    let onClose: () -> Void

    @State private var showCreateEpisodeSheet = false
    @State private var showEditSheet = false
    @State private var selectedEpisodeForDetail: Episode?
    @State private var selectedEpisodeForEdit: Episode?
    @State private var selectedEpisodeForUpload: Episode?

    init(animeId: Int, onUpdate: @escaping () -> Void, onClose: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(animeId: animeId))
        self.onUpdate = onUpdate
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let anime = viewModel.anime {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(anime.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("ID: \(anime.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            AnimeStatusBadge(status: anime.status)
                        }
                    }
                } else {
                    Text("动漫详情")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.anime != nil {
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
            } else if let anime = viewModel.anime {
                ScrollView {
                    VStack(spacing: 20) {
                        // 封面和基本信息
                        HStack(alignment: .top, spacing: 16) {
                            AsyncImage(url: URL(string: anime.cover)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.quaternary)
                            }
                            .frame(width: 100, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 8) {
                                panelInfoRow("制作", anime.studio ?? "-")
                                panelInfoRow("区域", anime.region ?? "-")
                                panelInfoRow("画质", anime.quality ?? "-")

                                HStack(spacing: 8) {
                                    if anime.isTop == true {
                                        Label("置顶", systemImage: "pin.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if anime.isCompleted == true {
                                        Text("已完结")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.2))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    } else {
                                        Text("连载中")
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
                        panelStatsSection(anime)

                        // 剧集列表
                        panelEpisodesSection

                        // 简介
                        if let description = anime.description, !description.isEmpty {
                            panelDescriptionSection(description)
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
            await viewModel.loadAnime()
            await viewModel.loadEpisodes()
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

    private func panelStatsSection(_ anime: AnimeDetail) -> some View {
        GroupBox("统计") {
            HStack(spacing: 16) {
                panelStatItem("集数", anime.currentEpisode ?? 0)
                panelStatItem("浏览", anime.viewCount ?? 0)
                panelStatItem("收藏", anime.favoriteCount ?? 0)
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

    private var panelEpisodesSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("剧集列表")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("共 \(viewModel.episodes.count) 集")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showCreateEpisodeSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("添加剧集")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if viewModel.episodes.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无剧集")
                            .foregroundStyle(.secondary)
                        Button("添加第一集") {
                            showCreateEpisodeSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.episodes.prefix(20)) { episode in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("第 \(episode.episodeNo ?? 0) 集")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                        Text(episode.title)
                                            .font(.callout)
                                            .lineLimit(1)
                                        Spacer()
                                        EpisodeStatusBadge(isActive: episode.isActive, status: episode.status)

                                        HStack(spacing: 2) {
                                            Button {
                                                selectedEpisodeForUpload = episode
                                            } label: {
                                                Image(systemName: "arrow.up.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.blue)
                                            .help("上传视频")

                                            Button {
                                                selectedEpisodeForDetail = episode
                                            } label: {
                                                Image(systemName: "play.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.green)
                                            .help("查看详情")

                                            Button {
                                                selectedEpisodeForEdit = episode
                                            } label: {
                                                Image(systemName: "pencil.circle")
                                            }
                                            .buttonStyle(.borderless)
                                            .foregroundStyle(.orange)
                                            .help("编辑剧集")
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)

                                    if episode.id != viewModel.episodes.prefix(20).last?.id {
                                        Divider()
                                            .padding(.leading)
                                    }
                                }
                            }
                            if viewModel.episodes.count > 20 {
                                Text("还有 \(viewModel.episodes.count - 20) 集...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .sheet(isPresented: $showCreateEpisodeSheet) {
            if let anime = viewModel.anime {
                EpisodeCreateSheet(
                    animeId: anime.id,
                    nextEpisodeNo: (viewModel.episodes.map { $0.episodeNo ?? 0 }.max() ?? 0) + 1
                ) {
                    Task {
                        await viewModel.loadEpisodes()
                        await viewModel.loadAnime()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(item: $selectedEpisodeForDetail) { episode in
            EpisodeDetailSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(item: $selectedEpisodeForEdit) { episode in
            EpisodeEditSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(item: $selectedEpisodeForUpload) { episode in
            EpisodeVideoUploadSheet(episode: episode, animeSlug: viewModel.anime?.slug ?? "") {
                Task {
                    await viewModel.loadEpisodes()
                    await viewModel.loadAnime()
                    onUpdate()
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let anime = viewModel.anime {
                AnimeEditSheet(anime: anime) {
                    Task {
                        await viewModel.loadAnime()
                        onUpdate()
                    }
                }
            }
        }
    }

    private func panelDescriptionSection(_ description: String) -> some View {
        GroupBox("简介") {
            Text(description)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
    }
}

// MARK: - 动漫编辑表单
struct AnimeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AnimeEditViewModel
    let onSuccess: () -> Void

    init(anime: AnimeDetail, onSuccess: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AnimeEditViewModel(anime: anime))
        self.onSuccess = onSuccess
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("编辑动漫")
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
                    TextField("标题", text: $viewModel.title)
                    TextField("原名", text: $viewModel.titleOriginal)
                    TextField("制作公司", text: $viewModel.studio)
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
                    TextField("总集数", value: $viewModel.totalEpisodes, format: .number)
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

                    Picker("制作状态", selection: $viewModel.productionStatus) {
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

                Button("保存") {
                    Task {
                        if await viewModel.updateAnime() {
                            onSuccess()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValid || viewModel.isSaving)
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

// MARK: - AnimeEditViewModel
@MainActor
class AnimeEditViewModel: ObservableObject {
    @Published var title = ""
    @Published var titleOriginal = ""
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
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let animeId: Int
    private let animeService = AnimeService.shared
    private let categoryService = CategoryService.shared

    var isValid: Bool {
        !title.isEmpty && !studio.isEmpty && categoryId > 0 && pricingId > 0 && totalEpisodes > 0
    }

    init(anime: AnimeDetail) {
        self.animeId = anime.id
        self.title = anime.title
        self.titleOriginal = anime.titleOriginal ?? ""
        self.studio = anime.studio ?? ""
        self.description = anime.description ?? ""
        self.categoryId = anime.categoryId
        self.pricingId = anime.pricingId ?? 0
        self.totalEpisodes = anime.totalEpisodes ?? 12
        self.season = anime.season
        self.airDate = anime.airDate ?? ""
        self.endDate = anime.endDate ?? ""
        self.region = anime.region ?? ""
        self.quality = anime.quality ?? ""
        self.productionStatus = anime.productionStatus ?? ""

        // 标签转换为逗号分隔字符串
        if let animeTags = anime.tags {
            self.tags = animeTags.map { $0.name }.joined(separator: ", ")
        }
    }

    func loadCategories() async {
        do {
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

    func updateAnime() async -> Bool {
        isSaving = true
        errorMessage = nil

        do {
            let request = UpdateAnimeRequest(
                title: title,
                titleOriginal: titleOriginal.isEmpty ? nil : titleOriginal,
                description: description.isEmpty ? nil : description,
                studio: studio,
                categoryId: categoryId,
                pricingId: pricingId,
                totalEpisodes: totalEpisodes,
                season: season,
                airDate: airDate.isEmpty ? nil : airDate,
                endDate: endDate.isEmpty ? nil : endDate,
                region: region.isEmpty ? nil : region,
                quality: quality.isEmpty ? nil : quality,
                productionStatus: productionStatus.isEmpty ? nil : productionStatus,
                tags: tags.isEmpty ? nil : tags
            )
            _ = try await animeService.update(id: animeId, request: request)
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}

#Preview("AnimeDetailView") {
    AnimeDetailView(animeId: 1, onUpdate: {})
}

#Preview("AnimeDetailPanel") {
    AnimeDetailPanel(animeId: 1, onUpdate: {})
        .frame(width: 400, height: 600)
}
