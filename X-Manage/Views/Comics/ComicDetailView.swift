//
//  ComicDetailView.swift
//  X-Manage
//
//  漫画详情视图

import SwiftUI

struct ComicDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ComicDetailViewModel
    let onUpdate: () -> Void

    @State private var showEditSheet = false
    @State private var showZipUploadSheet = false
    @State private var showCoverUploadSheet = false
    @State private var showChapterSheet = false
    @State private var selectedChapter: Chapter?

    init(comicId: Int, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ComicDetailViewModel(comicId: comicId))
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let comic = viewModel.comic {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comic.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack(spacing: 8) {
                            Text("ID: \(comic.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            ComicStatusBadge(status: comic.status)
                            if comic.isTop == true {
                                Label("置顶", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if comic.isCompleted == true {
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
                    Text("漫画详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.comic != nil {
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
            } else if let comic = viewModel.comic {
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本信息
                        basicInfoSection(comic)

                        // 封面图片
                        coverSection(comic)

                        // 章节列表
                        chaptersSection

                        // 统计信息
                        statsSection(comic)

                        // 描述
                        if let description = comic.description, !description.isEmpty {
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
            await viewModel.loadComic()
            await viewModel.loadChapters()
        }
        .sheet(isPresented: $showEditSheet) {
            if let comic = viewModel.comic {
                ComicEditSheet(comic: comic) {
                    Task {
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showZipUploadSheet) {
            if let comic = viewModel.comic {
                ComicZipUploadSheet(comic: comic) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCoverUploadSheet) {
            if let comic = viewModel.comic {
                ComicCoverUploadSheet(comic: comic) {
                    Task {
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showChapterSheet) {
            if let chapter = selectedChapter {
                ChapterDetailSheet(chapter: chapter) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
    }

    // MARK: - 基本信息
    private func basicInfoSection(_ comic: Comic) -> some View {
        GroupBox("基本信息") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem("标题", comic.title)
                infoItem("作者", comic.authors.joined(separator: ", "))
                infoItem("类型", comic.comicType ?? "-")
                infoItem("分类ID", String(comic.categoryId))
                infoItem("3D漫画", comic.is3d == true ? "是" : "否")
                infoItem("彩色", comic.isColor == true ? "是" : "否")
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

    // MARK: - 封面区域
    private func coverSection(_ comic: Comic) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("封面")
                        .font(.headline)
                    Spacer()
                    Button {
                        showCoverUploadSheet = true
                    } label: {
                        Label("上传新封面", systemImage: "arrow.up.circle")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                HStack {
                    AsyncImage(url: URL(string: comic.cover)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    .frame(width: 150, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()
                }
                .padding()
            }
        }
    }

    // MARK: - 章节列表
    private var chaptersSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("章节列表")
                        .font(.headline)

                    Spacer()

                    Text("共 \(viewModel.chapters.count) 章")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await viewModel.loadChapters()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("刷新章节列表")

                    Button {
                        showZipUploadSheet = true
                    } label: {
                        Label("ZIP批量上传", systemImage: "doc.zipper")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                if viewModel.chapters.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无章节")
                            .foregroundStyle(.secondary)
                        Button("ZIP批量上传章节") {
                            showZipUploadSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.chapters) { chapter in
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text("第 \(chapter.sort) 话")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(chapter.title)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                            }

                                            HStack(spacing: 12) {
                                                Text("\(chapter.pageCount) 页")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text("\(chapter.viewCount) 次浏览")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Text(formatDateTime(chapter.createdAt))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Button {
                                            selectedChapter = chapter
                                            showChapterSheet = true
                                        } label: {
                                            Image(systemName: "eye")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("查看/编辑章节")
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedChapter = chapter
                                        showChapterSheet = true
                                    }

                                    if chapter.id != viewModel.chapters.last?.id {
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
    private func statsSection(_ comic: Comic) -> some View {
        GroupBox("统计信息") {
            HStack(spacing: 32) {
                statItem("章节数", comic.chapterCount ?? 0)
                statItem("浏览量", comic.viewCount ?? 0)
                statItem("点赞数", comic.likeCount ?? 0)
                statItem("评论数", comic.commentCount ?? 0)
                statItem("收藏数", comic.favoriteCount ?? 0)
                statItem("销售数", comic.saleCount ?? 0)
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

    // MARK: - 描述
    private func descriptionSection(_ description: String) -> some View {
        GroupBox("简介") {
            Text(description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

// MARK: - 漫画编辑表单
struct ComicEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let comic: Comic
    let onUpdate: () -> Void

    @State private var title: String
    @State private var authors: String
    @State private var comicType: ComicType
    @State private var is3d: Bool
    @State private var isColor: Bool
    @State private var isCompleted: Bool
    @State private var description: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(comic: Comic, onUpdate: @escaping () -> Void) {
        self.comic = comic
        self.onUpdate = onUpdate
        _title = State(initialValue: comic.title)
        _authors = State(initialValue: comic.authors.joined(separator: ","))
        _comicType = State(initialValue: ComicType(rawValue: comic.comicType ?? "BG") ?? .bg)
        _is3d = State(initialValue: comic.is3d ?? false)
        _isColor = State(initialValue: comic.isColor ?? true)
        _isCompleted = State(initialValue: comic.isCompleted ?? false)
        _description = State(initialValue: comic.description ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑漫画")
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
                    TextField("作者 (逗号分隔)", text: $authors)
                    Picker("类型", selection: $comicType) {
                        ForEach(ComicType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("属性") {
                    Toggle("3D漫画", isOn: $is3d)
                    Toggle("彩色", isOn: $isColor)
                    Toggle("已完结", isOn: $isCompleted)
                }

                Section("简介") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
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
                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var request = UpdateComicRequest()
                request.title = title
                request.authors = authors.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                request.comicType = comicType
                request.is3d = is3d
                request.isColor = isColor
                request.isCompleted = isCompleted
                request.description = description.isEmpty ? nil : description

                _ = try await ComicService.shared.update(id: comic.id, request: request)
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 封面上传表单
struct ComicCoverUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let comic: Comic
    let onUpdate: () -> Void

    @State private var selectedImage: URL?
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("上传封面")
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
                            Text("• 推荐使用竖版封面图 (2:3 比例)")
                            Text("• 上传成功后会自动替换当前封面")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // 目标漫画
                    GroupBox("目标漫画") {
                        HStack {
                            Text(comic.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(comic.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // 当前封面 vs 新封面
                    HStack(spacing: 20) {
                        // 当前封面
                        VStack(spacing: 8) {
                            Text("当前封面")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            AsyncImage(url: URL(string: comic.cover)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.quaternary)
                            }
                            .frame(width: 120, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        // 新封面
                        VStack(spacing: 8) {
                            Text("新封面")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let selectedImage = selectedImage,
                               let nsImage = NSImage(contentsOf: selectedImage) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 170)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Button {
                                    selectImage()
                                } label: {
                                    Rectangle()
                                        .fill(.quaternary)
                                        .frame(width: 120, height: 170)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.largeTitle)
                                                Text("点击选择")
                                                    .font(.caption)
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if selectedImage != nil {
                        HStack {
                            Spacer()
                            Button("重新选择") {
                                selectImage()
                            }
                            .buttonStyle(.borderless)
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
                        uploadCover()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }

    private func selectImage() {
        let urls = UploadService.shared.selectImages(allowMultiple: false, maxCount: 1)
        if let url = urls.first {
            selectedImage = url
            errorMessage = nil
        }
    }

    private func uploadCover() {
        guard let imageUrl = selectedImage else { return }

        isUploading = true
        errorMessage = nil

        Task {
            do {
                // 先读取图片数据获取文件大小
                guard let imageData = UploadService.shared.imageData(from: imageUrl) else {
                    throw UploadError.fileReadError
                }

                // 获取上传URL
                let fileName = imageUrl.lastPathComponent
                let contentType = getContentType(for: imageUrl)
                let uploadResult = try await UploadService.shared.getComicCoverUploadUrl(
                    comicSlug: comic.slug,
                    fileName: fileName,
                    contentType: contentType,
                    fileSize: imageData.count
                )

                // 上传文件
                try await UploadService.shared.uploadToPresignedUrl(
                    uploadResult.uploadUrl,
                    data: imageData,
                    contentType: contentType
                )

                // 更新漫画封面（使用 storage_path）
                try await UploadService.shared.updateComicCover(comicId: comic.id, cover: uploadResult.storagePath)

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
class ComicDetailViewModel: ObservableObject {
    @Published var comic: Comic?
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let comicId: Int
    private let service = ComicService.shared

    init(comicId: Int) {
        self.comicId = comicId
    }

    func loadComic() async {
        isLoading = true
        errorMessage = nil

        do {
            comic = try await service.getDetail(id: comicId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadChapters() async {
        do {
            let response = try await service.getChapters(comicId: comicId, page: 1, pageSize: 100)
            chapters = response.chapters
        } catch {
            // 章节加载失败不影响主页面
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

    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }

    return String(dateString.prefix(16))
}

// MARK: - 漫画详情面板 (嵌入式)
struct ComicDetailPanel: View {
    @StateObject private var viewModel: ComicDetailViewModel
    let onUpdate: () -> Void
    let onClose: () -> Void

    @State private var showEditSheet = false
    @State private var showCoverUploadSheet = false
    @State private var showZipUploadSheet = false
    @State private var showChapterSheet = false
    @State private var selectedChapter: Chapter?

    init(comicId: Int, onUpdate: @escaping () -> Void, onClose: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: ComicDetailViewModel(comicId: comicId))
        self.onUpdate = onUpdate
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let comic = viewModel.comic {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comic.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("ID: \(comic.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            ComicStatusBadge(status: comic.status)
                        }
                    }
                } else {
                    Text("漫画详情")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.comic != nil {
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
            } else if let comic = viewModel.comic {
                ScrollView {
                    VStack(spacing: 20) {
                        // 封面和基本信息
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 8) {
                                AsyncImage(url: URL(string: comic.cover)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                                .frame(width: 100, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    showCoverUploadSheet = true
                                } label: {
                                    Label("换封面", systemImage: "arrow.up.circle")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                panelInfoRow("作者", comic.authors.joined(separator: ", "))
                                panelInfoRow("类型", comic.comicType ?? "-")

                                HStack(spacing: 8) {
                                    if comic.isTop == true {
                                        Label("置顶", systemImage: "pin.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if comic.isCompleted == true {
                                        Text("已完结")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.2))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    }
                                    if comic.is3d == true {
                                        Text("3D")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.purple.opacity(0.2))
                                            .foregroundStyle(.purple)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 统计信息
                        panelStatsSection(comic)

                        // 章节列表
                        panelChaptersSection

                        // 简介
                        if let description = comic.description, !description.isEmpty {
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
            await viewModel.loadComic()
            await viewModel.loadChapters()
        }
        .sheet(isPresented: $showEditSheet) {
            if let comic = viewModel.comic {
                ComicEditSheet(comic: comic) {
                    Task {
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCoverUploadSheet) {
            if let comic = viewModel.comic {
                ComicCoverUploadSheet(comic: comic) {
                    Task {
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showZipUploadSheet) {
            if let comic = viewModel.comic {
                ComicZipUploadSheet(comic: comic) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadComic()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showChapterSheet) {
            if let chapter = selectedChapter {
                ChapterDetailSheet(chapter: chapter) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadComic()
                        onUpdate()
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

    private func panelStatsSection(_ comic: Comic) -> some View {
        GroupBox("统计") {
            HStack(spacing: 16) {
                panelStatItem("章节", comic.chapterCount ?? 0)
                panelStatItem("浏览", comic.viewCount ?? 0)
                panelStatItem("收藏", comic.favoriteCount ?? 0)
                panelStatItem("销售", comic.saleCount ?? 0)
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

    private var panelChaptersSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("章节列表")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("共 \(viewModel.chapters.count) 章")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await viewModel.loadChapters()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("刷新章节列表")

                    Button {
                        showZipUploadSheet = true
                    } label: {
                        Image(systemName: "doc.zipper")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("ZIP批量上传")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if viewModel.chapters.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无章节")
                            .foregroundStyle(.secondary)
                        Button("ZIP批量上传") {
                            showZipUploadSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.chapters.prefix(20)) { chapter in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("第 \(chapter.sort) 话")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                        Text(chapter.title)
                                            .font(.callout)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(chapter.pageCount)页")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Button {
                                            selectedChapter = chapter
                                            showChapterSheet = true
                                        } label: {
                                            Image(systemName: "eye")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("查看/编辑")
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedChapter = chapter
                                        showChapterSheet = true
                                    }

                                    if chapter.id != viewModel.chapters.prefix(20).last?.id {
                                        Divider()
                                            .padding(.leading)
                                    }
                                }
                            }
                            if viewModel.chapters.count > 20 {
                                Text("还有 \(viewModel.chapters.count - 20) 章...")
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

// MARK: - ZIP上传表单
struct ComicZipUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let comic: Comic
    let onUpdate: () -> Void

    @State private var selectedFile: URL?
    @State private var isUploading = false
    @State private var uploadProgress: ComicZipUploadProgress?
    @State private var errorMessage: String?
    @State private var uploadResult: CompleteComicZipUploadResponse?
    @State private var startChapterSort: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("ZIP批量上传章节")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            VStack(spacing: 24) {
                // 说明
                GroupBox("使用说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. 准备一个ZIP文件，包含要上传的漫画章节")
                        Text("2. ZIP内每个文件夹代表一个章节，文件夹名作为章节名")
                        Text("3. 每个章节文件夹内放置该章节的图片文件")
                        Text("4. 图片会按文件名排序")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
                }

                // 漫画信息
                GroupBox("目标漫画") {
                    HStack {
                        AsyncImage(url: URL(string: comic.cover)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                        }
                        .frame(width: 60, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(comic.title)
                                .fontWeight(.medium)
                            Text("ID: \(comic.id) | Slug: \(comic.slug)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                }

                // 文件选择
                GroupBox("选择ZIP文件") {
                    VStack(spacing: 12) {
                        if let selectedFile = selectedFile {
                            HStack {
                                Image(systemName: "doc.zipper")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(selectedFile.lastPathComponent)
                                        .fontWeight(.medium)
                                    if let size = fileSize(url: selectedFile) {
                                        Text(size)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button("重新选择") {
                                    selectFile()
                                }
                                .buttonStyle(.borderless)
                            }
                        } else {
                            Button {
                                selectFile()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "doc.zipper")
                                        .font(.largeTitle)
                                    Text("点击选择ZIP文件")
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }

                // 起始章节号
                GroupBox("章节设置") {
                    HStack {
                        Text("起始章节号")
                        Spacer()
                        TextField("自动", text: $startChapterSort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("（留空自动递增）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                // 上传进度
                if let progress = uploadProgress {
                    GroupBox("上传进度") {
                        VStack(spacing: 8) {
                            ProgressView(value: progress.percentage, total: 100)

                            HStack {
                                Text(statusText(progress.status))
                                    .font(.callout)
                                Spacer()
                                Text("\(Int(progress.percentage))%")
                                    .font(.callout.monospacedDigit())
                            }

                            if progress.totalChunks > 0 {
                                Text("分块: \(progress.uploadedChunks)/\(progress.totalChunks)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                }

                // 上传结果
                if let result = uploadResult {
                    GroupBox("上传完成") {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                            Text(result.message)
                                .font(.callout)
                            Text("任务ID: \(result.taskId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }

                // 错误信息
                if let error = errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
            }
            .padding()

            Divider()

            // 操作按钮
            HStack {
                Spacer()

                if uploadResult != nil {
                    Button("完成") {
                        onUpdate()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else if isUploading {
                    Button("取消上传") {
                        // TODO: 取消上传
                    }
                    .buttonStyle(.bordered)
                    .disabled(true) // 暂不支持取消
                } else {
                    Button("开始上传") {
                        startUpload()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFile == nil)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }

    private func selectFile() {
        if let url = UploadService.shared.selectZipFile() {
            selectedFile = url
            errorMessage = nil
            uploadResult = nil
            uploadProgress = nil
        }
    }

    private func fileSize(url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int else {
            return nil
        }
        let mb = Double(size) / 1024.0 / 1024.0
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024.0)
        }
        return String(format: "%.2f MB", mb)
    }

    private func statusText(_ status: ComicZipUploadProgress.Status) -> String {
        switch status {
        case .pending: return "准备中..."
        case .uploading: return "上传中..."
        case .completing: return "处理中..."
        case .completed: return "上传完成"
        case .failed: return "上传失败"
        case .aborted: return "已取消"
        }
    }

    private func startUpload() {
        guard let fileUrl = selectedFile else { return }

        isUploading = true
        errorMessage = nil

        // 解析起始章节号
        let startSort = Int(startChapterSort.trimmingCharacters(in: .whitespaces))

        Task {
            let uploader = ComicZipUploader(
                comicId: comic.id,
                comicSlug: comic.slug,
                fileUrl: fileUrl,
                startChapterSort: startSort,
                onProgress: { progress in
                    Task { @MainActor in
                        self.uploadProgress = progress
                    }
                }
            )

            do {
                let result = try await uploader.upload()
                await MainActor.run {
                    uploadResult = result
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - 章节详情/编辑表单
struct ChapterDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chapter: Chapter
    let onUpdate: () -> Void

    @State private var title: String
    @State private var sort: Int
    @State private var pages: [Page] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @State private var isEditing = false

    init(chapter: Chapter, onUpdate: @escaping () -> Void) {
        self.chapter = chapter
        self.onUpdate = onUpdate
        _title = State(initialValue: chapter.title)
        _sort = State(initialValue: chapter.sort)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditing ? "编辑章节" : "章节详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("ID: \(chapter.id)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !isEditing {
                    Button {
                        isEditing = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                }
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本信息
                        GroupBox("基本信息") {
                            VStack(spacing: 12) {
                                if isEditing {
                                    HStack {
                                        Text("标题")
                                            .frame(width: 60, alignment: .leading)
                                        TextField("章节标题", text: $title)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    HStack {
                                        Text("排序")
                                            .frame(width: 60, alignment: .leading)
                                        TextField("排序号", value: $sort, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                        Spacer()
                                    }
                                } else {
                                    HStack {
                                        infoRow("标题", chapter.title)
                                        Spacer()
                                    }
                                    HStack {
                                        infoRow("排序", "第 \(chapter.sort) 话")
                                        Spacer()
                                    }
                                }
                                HStack {
                                    infoRow("页数", "\(chapter.pageCount) 页")
                                    Spacer()
                                }
                                HStack {
                                    infoRow("浏览量", "\(chapter.viewCount) 次")
                                    Spacer()
                                }
                                HStack {
                                    infoRow("创建时间", formatChapterDateTime(chapter.createdAt))
                                    Spacer()
                                }
                                HStack {
                                    infoRow("更新时间", formatChapterDateTime(chapter.updatedAt))
                                    Spacer()
                                }
                            }
                            .padding()
                        }

                        // 页面预览
                        GroupBox {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("页面预览")
                                        .font(.headline)
                                    Spacer()
                                    Text("共 \(pages.count) 页")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()

                                Divider()

                                if pages.isEmpty {
                                    Text("暂无页面")
                                        .foregroundStyle(.secondary)
                                        .padding()
                                } else {
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        LazyHStack(spacing: 8) {
                                            ForEach(pages) { page in
                                                VStack(spacing: 4) {
                                                    AsyncImage(url: URL(string: page.displayUrl)) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(.quaternary)
                                                            .overlay {
                                                                ProgressView()
                                                            }
                                                    }
                                                    .frame(width: 120, height: 170)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                                    Text("P\(page.sort)")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding()
                                    }
                                    .frame(height: 210)
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
            }

            Divider()

            // 操作按钮
            HStack {
                if isEditing {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除章节", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDeleting || isSaving)
                }

                Spacer()

                if isEditing {
                    Button("取消") {
                        title = chapter.title
                        sort = chapter.sort
                        isEditing = false
                        errorMessage = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)

                    Button("保存") {
                        save()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || title.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 650)
        .task {
            await loadPages()
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteChapter()
            }
        } message: {
            Text("确定要删除「\(chapter.title)」吗？此操作不可撤销。")
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.callout)
        }
    }

    private func loadPages() async {
        isLoading = true
        do {
            pages = try await ComicService.shared.getChapterPages(chapterId: chapter.id)
        } catch {
            errorMessage = "加载页面失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var request = UpdateChapterRequest()
                if title != chapter.title {
                    request.title = title
                }
                if sort != chapter.sort {
                    request.sort = sort
                }
                _ = try await ComicService.shared.updateChapter(id: chapter.id, request: request)
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func deleteChapter() {
        isDeleting = true
        errorMessage = nil

        Task {
            do {
                try await ComicService.shared.deleteChapter(id: chapter.id)
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isDeleting = false
        }
    }

    private func formatChapterDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return displayFormatter.string(from: date)
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return displayFormatter.string(from: date)
        }

        return String(dateString.prefix(19))
    }
}

#Preview("ComicDetailView") {
    ComicDetailView(comicId: 1, onUpdate: {})
}

#Preview("ComicDetailPanel") {
    ComicDetailPanel(comicId: 1, onUpdate: {})
        .frame(width: 400, height: 600)
}

#Preview("ChapterDetailSheet") {
    ChapterDetailSheet(
        chapter: Chapter(
            id: 1,
            comicId: 1,
            title: "第一话",
            sort: 1,
            pageCount: 20,
            viewCount: 100,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        ),
        onUpdate: {}
    )
}
