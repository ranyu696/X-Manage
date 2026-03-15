//
//  NovelDetailView.swift
//  X-Manage
//
//  小说详情视图

import SwiftUI
import UniformTypeIdentifiers

struct NovelDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NovelDetailViewModel
    let onUpdate: () -> Void

    @State private var showEditSheet = false
    @State private var showCreateChapterSheet = false
    @State private var selectedChapterForEdit: NovelChapter?
    @State private var showCoverUploadSheet = false

    init(novelId: Int, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: NovelDetailViewModel(novelId: novelId))
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let novel = viewModel.novel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(novel.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack(spacing: 8) {
                            Text("ID: \(novel.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            NovelStatusBadge(status: novel.status)
                            if novel.isTop == true {
                                Label("置顶", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if novel.isCompleted == true {
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
                } else {
                    Text("小说详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.novel != nil {
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
            } else if let novel = viewModel.novel {
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本信息
                        basicInfoSection(novel)

                        // 封面图片
                        coverSection(novel)

                        // 章节列表
                        chaptersSection

                        // 统计信息
                        statsSection(novel)

                        // 描述
                        if let description = novel.description, !description.isEmpty {
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
            await viewModel.loadNovel()
            await viewModel.loadChapters()
        }
        .sheet(isPresented: $showEditSheet) {
            if let novel = viewModel.novel {
                NovelEditSheet(novel: novel) {
                    Task {
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateChapterSheet) {
            if let novel = viewModel.novel {
                NovelChapterCreateSheet(
                    novelId: novel.id,
                    nextSort: viewModel.chapters.count + 1
                ) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(item: $selectedChapterForEdit) { chapter in
            NovelChapterEditSheet(chapter: chapter) {
                Task {
                    await viewModel.loadChapters()
                    await viewModel.loadNovel()
                    onUpdate()
                }
            }
        }
        .sheet(isPresented: $showCoverUploadSheet) {
            if let novel = viewModel.novel {
                NovelCoverUploadSheet(novel: novel) {
                    Task {
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
    }

    // MARK: - 基本信息
    private func basicInfoSection(_ novel: Novel) -> some View {
        GroupBox("基本信息") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem("标题", novel.title)
                infoItem("作者", novel.author)
                infoItem("系列", novel.series ?? "-")
                infoItem("标签", novel.tags?.joined(separator: ", ") ?? "-")
                infoItem("分类ID", String(novel.categoryId))
                infoItem("定价ID", novel.pricingId != nil ? String(novel.pricingId!) : "-")
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
    private func coverSection(_ novel: Novel) -> some View {
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
                    AsyncImage(url: URL(string: novel.cover)) { image in
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
                        showCreateChapterSheet = true
                    } label: {
                        Label("添加章节", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                if viewModel.chapters.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无章节")
                            .foregroundStyle(.secondary)
                        Button("添加第一章") {
                            showCreateChapterSheet = true
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
                                                Text("第 \(chapter.sort) 章")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(chapter.title)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                            }

                                            HStack(spacing: 12) {
                                                Text("\(chapter.wordCount) 字")
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
                                            selectedChapterForEdit = chapter
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("编辑章节")

                                        Button {
                                            Task {
                                                await viewModel.deleteChapter(chapter)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundStyle(.red)
                                        .help("删除章节")
                                    }
                                    .padding()

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
    private func statsSection(_ novel: Novel) -> some View {
        GroupBox("统计信息") {
            HStack(spacing: 32) {
                statItem("章节数", novel.chapterCount ?? 0)
                statItem("总字数", novel.wordCount ?? 0)
                statItem("浏览量", novel.viewCount ?? 0)
                statItem("点赞数", novel.likeCount ?? 0)
                statItem("评论数", novel.commentCount ?? 0)
                statItem("收藏数", novel.favoriteCount ?? 0)
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

// MARK: - 小说编辑表单
struct NovelEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let novel: Novel
    let onUpdate: () -> Void

    @State private var title: String
    @State private var author: String
    @State private var series: String
    @State private var tags: String
    @State private var description: String
    @State private var isCompleted: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(novel: Novel, onUpdate: @escaping () -> Void) {
        self.novel = novel
        self.onUpdate = onUpdate
        _title = State(initialValue: novel.title)
        _author = State(initialValue: novel.author)
        _series = State(initialValue: novel.series ?? "")
        _tags = State(initialValue: novel.tags?.joined(separator: ",") ?? "")
        _description = State(initialValue: novel.description ?? "")
        _isCompleted = State(initialValue: novel.isCompleted ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑小说")
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
                    TextField("作者", text: $author)
                    TextField("系列", text: $series)
                    TextField("标签 (逗号分隔)", text: $tags)
                }

                Section("状态") {
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
                var request = UpdateNovelRequest()
                request.title = title
                request.author = author
                request.series = series.isEmpty ? nil : series
                request.tags = tags.isEmpty ? nil : tags
                request.description = description.isEmpty ? nil : description
                request.isCompleted = isCompleted

                _ = try await NovelService.shared.update(id: novel.id, request: request)
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - 章节创建表单
struct NovelChapterCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let novelId: Int
    let nextSort: Int
    let onUpdate: () -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var sort: Int
    @State private var continuousMode = true
    @State private var createdCount = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(novelId: Int, nextSort: Int, onUpdate: @escaping () -> Void) {
        self.novelId = novelId
        self.nextSort = nextSort
        self.onUpdate = onUpdate
        _sort = State(initialValue: nextSort)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("添加章节")
                    .font(.title2)
                    .fontWeight(.semibold)

                if createdCount > 0 {
                    Text("已创建 \(createdCount) 章")
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
                Section("章节信息") {
                    TextField("标题 (可选，留空自动从内容提取)", text: $title)
                    TextField("排序", value: $sort, format: .number)
                        .frame(width: 100)
                }

                Section("章节内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 300)
                        .font(.body.monospaced())
                }

                Section("选项") {
                    Toggle("连续创建模式", isOn: $continuousMode)
                        .help("创建后继续添加下一章，不关闭窗口")
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

                Button("创建章节") {
                    createChapter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.isEmpty || isSaving)
            }
            .padding()
        }
        .frame(width: 700, height: 600)
    }

    private func createChapter() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let request = CreateNovelChapterRequest(
                    novelId: novelId,
                    title: title.isEmpty ? nil : title,
                    content: content,
                    sort: sort
                )
                _ = try await NovelService.shared.createChapter(request: request)
                createdCount += 1
                onUpdate()

                if continuousMode {
                    // 清空表单，准备下一章
                    title = ""
                    content = ""
                    sort += 1
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

// MARK: - 章节编辑表单
struct NovelChapterEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chapter: NovelChapter
    let onUpdate: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var sort: Int
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(chapter: NovelChapter, onUpdate: @escaping () -> Void) {
        self.chapter = chapter
        self.onUpdate = onUpdate
        _title = State(initialValue: chapter.title)
        _content = State(initialValue: "")
        _sort = State(initialValue: chapter.sort)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑章节")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView("加载章节内容...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section("章节信息") {
                        TextField("标题", text: $title)
                        TextField("排序", value: $sort, format: .number)
                            .frame(width: 100)
                    }

                    Section("章节内容") {
                        TextEditor(text: $content)
                            .frame(minHeight: 300)
                            .font(.body.monospaced())
                    }
                }
                .formStyle(.grouped)
            }

            Divider()

            HStack {
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()
                Button("保存") {
                    saveChapter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || isSaving)
            }
            .padding()
        }
        .frame(width: 700, height: 600)
        .task {
            await loadChapterContent()
        }
    }

    private func loadChapterContent() async {
        do {
            let fullChapter = try await NovelService.shared.getChapterDetail(chapterId: chapter.id)
            content = fullChapter.content ?? ""
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func saveChapter() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                var request = UpdateNovelChapterRequest()
                request.title = title
                request.content = content
                request.sort = sort

                _ = try await NovelService.shared.updateChapter(chapterId: chapter.id, request: request)
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
struct NovelCoverUploadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let novel: Novel
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

                    // 目标小说
                    GroupBox("目标小说") {
                        HStack {
                            Text(novel.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text("ID: \(novel.id)")
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
                            AsyncImage(url: URL(string: novel.cover)) { image in
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
                let uploadResult = try await UploadService.shared.getNovelCoverUploadUrl(
                    novelSlug: novel.slug,
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

                // 更新小说封面（使用 storage_path）
                try await UploadService.shared.updateNovelCover(novelId: novel.id, cover: uploadResult.storagePath)

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
class NovelDetailViewModel: ObservableObject {
    @Published var novel: Novel?
    @Published var chapters: [NovelChapter] = []
    @Published var isLoading = false
    @Published var isLoadingMoreChapters = false
    @Published var errorMessage: String?
    @Published var hasMoreChapters = true

    let novelId: Int
    private let service = NovelService.shared
    private var currentPage = 1
    private let pageSize = 50

    init(novelId: Int) {
        self.novelId = novelId
    }

    func loadNovel() async {
        isLoading = true
        errorMessage = nil

        do {
            novel = try await service.getDetail(id: novelId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadChapters() async {
        currentPage = 1
        do {
            let response = try await service.getChapters(novelId: novelId, page: currentPage, pageSize: pageSize)
            chapters = response.chapters
            hasMoreChapters = response.chapters.count >= pageSize
        } catch {
            // 章节加载失败不影响主页面
        }
    }

    func loadMoreChapters() async {
        guard hasMoreChapters, !isLoadingMoreChapters else { return }
        isLoadingMoreChapters = true

        do {
            currentPage += 1
            let response = try await service.getChapters(novelId: novelId, page: currentPage, pageSize: pageSize)
            chapters.append(contentsOf: response.chapters)
            hasMoreChapters = response.chapters.count >= pageSize
        } catch {
            currentPage -= 1
        }

        isLoadingMoreChapters = false
    }

    func deleteChapter(_ chapter: NovelChapter) async {
        do {
            try await service.deleteChapter(chapterId: chapter.id)
            chapters.removeAll { $0.id == chapter.id }
        } catch {
            errorMessage = error.localizedDescription
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

// MARK: - 小说详情面板 (嵌入式)
struct NovelDetailPanel: View {
    @StateObject private var viewModel: NovelDetailViewModel
    let onUpdate: () -> Void
    let onClose: () -> Void

    @State private var showEditSheet = false
    @State private var showCoverUploadSheet = false
    @State private var showCreateChapterSheet = false
    @State private var selectedChapterForEdit: NovelChapter?

    init(novelId: Int, onUpdate: @escaping () -> Void, onClose: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: NovelDetailViewModel(novelId: novelId))
        self.onUpdate = onUpdate
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if let novel = viewModel.novel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(novel.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("ID: \(novel.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            NovelStatusBadge(status: novel.status)
                        }
                    }
                } else {
                    Text("小说详情")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.novel != nil {
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
            } else if let novel = viewModel.novel {
                ScrollView {
                    VStack(spacing: 20) {
                        // 封面和基本信息
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 8) {
                                AsyncImage(url: URL(string: novel.cover)) { image in
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
                                panelInfoRow("作者", novel.author)
                                panelInfoRow("系列", novel.series ?? "-")
                                panelInfoRow("标签", novel.tags?.joined(separator: ", ") ?? "-")

                                HStack(spacing: 8) {
                                    if novel.isTop == true {
                                        Label("置顶", systemImage: "pin.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if novel.isCompleted == true {
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
                        panelStatsSection(novel)

                        // 章节列表
                        panelChaptersSection

                        // 简介
                        if let description = novel.description, !description.isEmpty {
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
            await viewModel.loadNovel()
            await viewModel.loadChapters()
        }
        .sheet(isPresented: $showEditSheet) {
            if let novel = viewModel.novel {
                NovelEditSheet(novel: novel) {
                    Task {
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCoverUploadSheet) {
            if let novel = viewModel.novel {
                NovelCoverUploadSheet(novel: novel) {
                    Task {
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateChapterSheet) {
            if let novel = viewModel.novel {
                ChapterCreateSheet(
                    novelId: novel.id,
                    novelSlug: novel.slug,
                    nextSort: (viewModel.chapters.map { $0.sort }.max() ?? 0) + 1
                ) {
                    Task {
                        await viewModel.loadChapters()
                        await viewModel.loadNovel()
                        onUpdate()
                    }
                }
            }
        }
        .sheet(item: $selectedChapterForEdit) { chapter in
            NovelChapterEditSheet(chapter: chapter) {
                Task {
                    await viewModel.loadChapters()
                    await viewModel.loadNovel()
                    onUpdate()
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

    private func panelStatsSection(_ novel: Novel) -> some View {
        GroupBox("统计") {
            HStack(spacing: 16) {
                panelStatItem("章节", novel.chapterCount ?? 0)
                panelStatItem("字数", novel.wordCount ?? 0)
                panelStatItem("浏览", novel.viewCount ?? 0)
                panelStatItem("收藏", novel.favoriteCount ?? 0)
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
                    Text("共 \(viewModel.novel?.chapterCount ?? viewModel.chapters.count) 章")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showCreateChapterSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("添加章节")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if viewModel.chapters.isEmpty {
                    VStack(spacing: 12) {
                        Text("暂无章节")
                            .foregroundStyle(.secondary)
                        Button("添加第一章") {
                            showCreateChapterSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.chapters) { chapter in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("第 \(chapter.sort) 章")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                        Text(chapter.title)
                                            .font(.callout)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(chapter.wordCount)字")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Button {
                                            selectedChapterForEdit = chapter
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("编辑章节")

                                        Button {
                                            Task {
                                                await viewModel.deleteChapter(chapter)
                                                onUpdate()
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundStyle(.red)
                                        .help("删除章节")
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)

                                    if chapter.id != viewModel.chapters.last?.id {
                                        Divider()
                                            .padding(.leading)
                                    }
                                }
                                .onAppear {
                                    // 无限滚动：当显示倒数第 5 个时加载更多
                                    if chapter.id == viewModel.chapters.dropLast(5).last?.id {
                                        Task {
                                            await viewModel.loadMoreChapters()
                                        }
                                    }
                                }
                            }

                            // 加载更多指示器
                            if viewModel.isLoadingMoreChapters {
                                ProgressView()
                                    .padding()
                            } else if viewModel.hasMoreChapters {
                                Button("加载更多") {
                                    Task {
                                        await viewModel.loadMoreChapters()
                                    }
                                }
                                .font(.caption)
                                .padding()
                            }
                        }
                    }
                    .frame(maxHeight: 300)
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

// MARK: - 解析的章节
struct ParsedChapter: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    var wordCount: Int { content.count }
}

// MARK: - 章节创建表单
struct ChapterCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let novelId: Int
    let novelSlug: String
    let nextSort: Int
    let onUpdate: () -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var sort: Int
    @State private var createdCount = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    // TXT 导入相关
    @State private var showFileImporter = false
    @State private var parsedChapters: [ParsedChapter] = []
    @State private var currentChapterIndex = 0
    @State private var parseError: String?
    @State private var titleExcludeChars = ""  // 标题排除字符
    @State private var showStartIndexAlert = false
    @State private var startIndexInput = "1"
    @State private var pendingChapters: [ParsedChapter] = []  // 待确认的章节

    init(novelId: Int, novelSlug: String, nextSort: Int, onUpdate: @escaping () -> Void) {
        self.novelId = novelId
        self.novelSlug = novelSlug
        self.nextSort = nextSort
        self.onUpdate = onUpdate
        _sort = State(initialValue: nextSort)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()

            // 主体内容
            if parsedChapters.isEmpty {
                // 普通模式：手动输入或导入文件
                normalModeView
            } else {
                // 批量模式：逐章审核
                batchModeView
            }

            Divider()

            // 底部操作栏
            footerView
        }
        .frame(width: 750, height: 650)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("设置起始序号", isPresented: $showStartIndexAlert) {
            TextField("起始序号", text: $startIndexInput)
            Button("取消", role: .cancel) {
                pendingChapters = []
            }
            Button("确定") {
                confirmStartIndex()
            }
        } message: {
            Text("已识别 \(pendingChapters.count) 个章节，请输入起始排序序号")
        }
    }

    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("添加章节")
                .font(.title2)
                .fontWeight(.semibold)

            if createdCount > 0 {
                Text("已创建 \(createdCount) 章")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .clipShape(Capsule())
            }

            if !parsedChapters.isEmpty {
                Text("剩余 \(parsedChapters.count - currentChapterIndex) 章")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .clipShape(Capsule())
            }

            Spacer()

            if !parsedChapters.isEmpty {
                Button("退出批量模式") {
                    parsedChapters = []
                    currentChapterIndex = 0
                    title = ""
                    content = ""
                }
                .buttonStyle(.bordered)
            }

            Button("关闭") { dismiss() }
        }
        .padding()
    }

    // MARK: - 普通模式
    private var normalModeView: some View {
        Form {
            Section {
                HStack {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("导入TXT文件", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)

                    Text("自动识别章节格式：第X章XXX")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = parseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("章节信息") {
                TextField("标题 (留空自动提取)", text: $title)
                HStack {
                    Text("排序")
                    TextField("", value: $sort, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("章节内容") {
                TextEditor(text: $content)
                    .frame(minHeight: 280)
                    .font(.body)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - 批量模式
    private var batchModeView: some View {
        HSplitView {
            // 左侧：章节列表
            VStack(spacing: 0) {
                HStack {
                    Text("章节列表")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // 排除字符输入框
                HStack {
                    Text("排除:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("如：、", text: $titleExcludeChars)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onChange(of: titleExcludeChars) { _, _ in
                            applyTitleExclusion()
                        }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(parsedChapters.enumerated()), id: \.element.id) { index, chapter in
                                HStack(spacing: 6) {
                                    // 序号
                                    Text(verbatim: "\(index + 1)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, alignment: .trailing)

                                    if index < currentChapterIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    } else if index == currentChapterIndex {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cleanTitle(chapter.title))
                                            .font(.callout)
                                            .lineLimit(1)
                                        Text("\(chapter.wordCount)字")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(index == currentChapterIndex ? Color.accentColor.opacity(0.1) : Color.clear)
                                .id(index)
                            }
                        }
                    }
                    .onChange(of: currentChapterIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            .frame(width: 240)
            .background(Color(nsColor: .controlBackgroundColor))

            // 右侧：当前章节编辑
            VStack(spacing: 0) {
                if currentChapterIndex < parsedChapters.count {
                    HStack {
                        Text("当前章节")
                            .font(.headline)
                        Spacer()
                        Text("第 \(currentChapterIndex + 1) / \(parsedChapters.count) 章")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    Divider()

                    Form {
                        Section("章节信息") {
                            TextField("标题", text: $title)
                            HStack {
                                Text("排序")
                                TextField("", value: $sort, format: .number)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        Section("章节内容 (\(content.count)字)") {
                            TextEditor(text: $content)
                                .frame(minHeight: 250)
                                .font(.body)
                        }
                    }
                    .formStyle(.grouped)
                    .onAppear {
                        loadCurrentChapter()
                    }
                    .onChange(of: currentChapterIndex) { _, _ in
                        loadCurrentChapter()
                    }
                } else {
                    ContentUnavailableView(
                        "全部完成",
                        systemImage: "checkmark.circle.fill",
                        description: Text("所有章节已创建完成")
                    )
                }
            }
        }
    }

    // MARK: - 底部操作栏
    private var footerView: some View {
        HStack {
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(2)
            }

            Spacer()

            if parsedChapters.isEmpty {
                // 普通模式
                Button("创建章节") {
                    createChapter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.isEmpty || isSaving)
            } else if currentChapterIndex < parsedChapters.count {
                // 批量模式
                Button("跳过") {
                    skipCurrentChapter()
                }
                .buttonStyle(.bordered)

                Button("创建并下一章") {
                    createAndNext()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.isEmpty || isSaving)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding()
    }

    // MARK: - 清理标题（移除排除字符）
    private func cleanTitle(_ originalTitle: String) -> String {
        guard !titleExcludeChars.isEmpty else { return originalTitle }
        var result = originalTitle
        for char in titleExcludeChars {
            result = result.replacingOccurrences(of: String(char), with: "")
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - 应用排除字符到当前编辑的标题
    private func applyTitleExclusion() {
        if currentChapterIndex < parsedChapters.count {
            title = cleanTitle(parsedChapters[currentChapterIndex].title)
        }
    }

    // MARK: - 加载当前章节
    private func loadCurrentChapter() {
        guard currentChapterIndex < parsedChapters.count else { return }
        let chapter = parsedChapters[currentChapterIndex]
        title = cleanTitle(chapter.title)
        content = chapter.content
        // sort 在 confirmStartIndex 中设置起始值，之后每次创建成功会 +1
    }

    // MARK: - 文件导入
    private func handleFileImport(_ result: Result<[URL], Error>) {
        parseError = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                parseError = "无法访问文件"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                parseChapters(from: fileContent)
            } catch {
                // 尝试 GBK 编码
                if let data = try? Data(contentsOf: url),
                   let gbkContent = String(data: data, encoding: .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
                    parseChapters(from: gbkContent)
                } else {
                    parseError = "无法读取文件: \(error.localizedDescription)"
                }
            }

        case .failure(let error):
            parseError = "选择文件失败: \(error.localizedDescription)"
        }
    }

    // MARK: - 章节解析
    private func parseChapters(from content: String) {
        // 匹配章节标题，捕获章节号和标题两部分
        let pattern = #"第[0-9零一二三四五六七八九十百千万]+章\s*([^\n]*)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            parseError = "正则表达式错误"
            return
        }

        let nsContent = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))

        if matches.isEmpty {
            parseError = "未识别到章节，请确保格式为「第X章XXX」"
            return
        }

        var chapters: [ParsedChapter] = []

        for (index, match) in matches.enumerated() {
            // 提取标题（去除"第X章"部分）
            var chapterTitle = ""
            if match.numberOfRanges > 1 {
                let titleRange = match.range(at: 1)
                if titleRange.location != NSNotFound {
                    chapterTitle = nsContent.substring(with: titleRange).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            // 如果标题为空，使用默认标题
            if chapterTitle.isEmpty {
                chapterTitle = "第\(index + 1)章"
            }

            let contentStart = match.range.location + match.range.length
            let contentEnd: Int
            if index + 1 < matches.count {
                contentEnd = matches[index + 1].range.location
            } else {
                contentEnd = nsContent.length
            }

            let contentRange = NSRange(location: contentStart, length: contentEnd - contentStart)
            let chapterContent = nsContent.substring(with: contentRange).trimmingCharacters(in: .whitespacesAndNewlines)

            if !chapterContent.isEmpty {
                chapters.append(ParsedChapter(title: chapterTitle, content: chapterContent))
            }
        }

        if chapters.isEmpty {
            parseError = "章节内容为空"
            return
        }

        // 存储待确认的章节，显示起始序号询问
        pendingChapters = chapters
        startIndexInput = "\(nextSort)"
        showStartIndexAlert = true
    }

    // MARK: - 确认起始序号
    private func confirmStartIndex() {
        let startIndex = Int(startIndexInput) ?? nextSort
        sort = startIndex
        parsedChapters = pendingChapters
        pendingChapters = []
        currentChapterIndex = 0
        loadCurrentChapter()
    }

    // MARK: - 创建章节
    private func createChapter() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let request = CreateNovelChapterRequest(
                    novelId: novelId,
                    title: title.isEmpty ? nil : title,
                    content: content,
                    sort: sort
                )
                let createdChapter = try await NovelService.shared.createChapter(request: request)
                createdCount += 1

                // 根据返回的章节 sort 设置下一章序号
                sort = createdChapter.sort + 1

                onUpdate()

                // 清空准备下一章
                title = ""
                content = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    // MARK: - 创建并下一章
    private func createAndNext() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let request = CreateNovelChapterRequest(
                    novelId: novelId,
                    title: title.isEmpty ? nil : title,
                    content: content,
                    sort: sort
                )
                let createdChapter = try await NovelService.shared.createChapter(request: request)
                createdCount += 1

                // 根据返回的章节 sort 设置下一章序号
                sort = createdChapter.sort + 1

                onUpdate()

                // 移动到下一章
                currentChapterIndex += 1
                if currentChapterIndex < parsedChapters.count {
                    loadCurrentChapter()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    // MARK: - 跳过当前章节
    private func skipCurrentChapter() {
        currentChapterIndex += 1
        if currentChapterIndex < parsedChapters.count {
            loadCurrentChapter()
        }
    }
}

#Preview("NovelDetailView") {
    NovelDetailView(novelId: 1, onUpdate: {})
}

#Preview("NovelDetailPanel") {
    NovelDetailPanel(novelId: 1, onUpdate: {})
        .frame(width: 400, height: 600)
}
