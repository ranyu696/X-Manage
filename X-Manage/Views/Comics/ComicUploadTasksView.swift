//
//  ComicUploadTasksView.swift
//  X-Manage
//
//  漫画上传任务管理

import SwiftUI

struct ComicUploadTasksView: View {
    @StateObject private var viewModel = ComicUploadTasksViewModel()
    @State private var selectedStatus: String?
    @State private var selectedTask: ComicUploadTask?

    var body: some View {
        VStack(spacing: 0) {
            contentView
            paginationView
        }
        .task {
            await viewModel.loadTasks()
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadTasks() }
        }
        .sheet(item: $selectedTask) { task in
            ComicUploadTaskDetailView(task: task)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as String?)
                    Text("等待中").tag("PENDING" as String?)
                    Text("处理中").tag("PROCESSING" as String?)
                    Text("已完成").tag("COMPLETED" as String?)
                    Text("失败").tag("FAILED" as String?)
                }
                .pickerStyle(.segmented)
                .frame(width: 350)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadTasks() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - 内容区域
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.tasks.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tasks.isEmpty {
            ContentUnavailableView(
                "暂无上传任务",
                systemImage: "arrow.up.doc",
                description: Text("暂无符合条件的漫画上传任务")
            )
        } else {
            ComicUploadTaskTableView(
                tasks: viewModel.tasks,
                onSelect: { task in
                    selectedTask = task
                }
            )
        }
    }

    // MARK: - 分页
    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.tasks.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadTasks(page: page) }
                }
            )
            .padding()
        }
    }
}

// MARK: - 任务表格视图
struct ComicUploadTaskTableView: View {
    let tasks: [ComicUploadTask]
    let onSelect: (ComicUploadTask) -> Void

    var body: some View {
        Table(tasks) {
            TableColumn("漫画ID") { (task: ComicUploadTask) in
                Text("\(task.comicId)")
            }
            .width(70)

            TableColumn("漫画Slug") { (task: ComicUploadTask) in
                Text(task.comicSlug)
                    .font(.caption)
            }
            .width(min: 100, ideal: 120)

            TableColumn("文件名") { (task: ComicUploadTask) in
                Text(task.fileName)
                    .lineLimit(1)
            }
            .width(min: 120, ideal: 180)

            TableColumn("状态") { (task: ComicUploadTask) in
                TaskStatusBadge(status: task.status)
            }
            .width(80)

            TableColumn("章节") { (task: ComicUploadTask) in
                Text("\(task.completedChapters)/\(task.totalChapters)")
                    .font(.caption)
            }
            .width(70)

            TableColumn("页数") { (task: ComicUploadTask) in
                Text("\(task.uploadedPages)/\(task.totalPages)")
                    .font(.caption)
            }
            .width(80)

            TableColumn("进度") { (task: ComicUploadTask) in
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: Double(task.progress) / 100.0)
                        .progressViewStyle(.linear)
                    Text("\(task.progress)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80)
            }
            .width(100)

            TableColumn("创建时间") { (task: ComicUploadTask) in
                Text(formatDate(task.createdAt))
            }
            .width(100)

            TableColumn("操作") { (task: ComicUploadTask) in
                Button {
                    onSelect(task)
                } label: {
                    Image(systemName: "eye")
                }
                .buttonStyle(.borderless)
            }
            .width(50)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }
}

// MARK: - 任务状态徽章
struct TaskStatusBadge: View {
    let status: String

    var body: some View {
        Text(displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var displayName: String {
        switch status {
        case "PENDING": return "等待中"
        case "MERGING": return "合并中"
        case "PROCESSING": return "处理中"
        case "COMPLETED": return "已完成"
        case "FAILED": return "失败"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "PENDING": return .orange
        case "MERGING": return .cyan
        case "PROCESSING": return .blue
        case "COMPLETED": return .green
        case "FAILED": return .red
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 任务详情视图
struct ComicUploadTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let task: ComicUploadTask

    @State private var isRetrying = false
    @State private var isCanceling = false
    @State private var errorMessage: String?
    @State private var showCancelConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // 状态卡片
                    statusCard

                    // 进度信息
                    progressCard

                    // 文件信息
                    fileInfoCard

                    // 错误信息
                    if let error = task.error, !error.isEmpty {
                        errorCard(error)
                    }

                    // 时间信息
                    timeInfoCard

                    // 任务ID
                    taskIdCard
                }
                .padding()
            }

            Divider()

            // 操作按钮
            actionBar
        }
        .frame(width: 520, height: 600)
        .alert("确认取消", isPresented: $showCancelConfirm) {
            Button("返回", role: .cancel) {}
            Button("取消任务", role: .destructive) {
                cancelTask()
            }
        } message: {
            Text("确定要取消此上传任务吗？此操作不可撤销。")
        }
    }

    // MARK: - 标题栏
    private var headerView: some View {
        HStack(spacing: 12) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("上传任务详情")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(task.comicSlug)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            TaskStatusBadge(status: task.status)

            Button("关闭") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - 状态卡片
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // 大进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: Double(task.progress) / 100.0)
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: task.progress)

                    VStack(spacing: 2) {
                        Text("\(task.progress)%")
                            .font(.title2.monospacedDigit())
                            .fontWeight(.bold)
                        Text(statusDisplayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                // 状态描述
                if task.status == "MERGING" {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("正在合并文件，大文件可能需要几分钟...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if task.status == "PROCESSING" {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("正在处理中...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if task.status == "COMPLETED" {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("任务已完成")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if task.status == "FAILED" {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("任务失败")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 进度卡片
    private var progressCard: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("处理进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()

                Divider()

                HStack(spacing: 0) {
                    // 章节进度
                    progressItem(
                        icon: "book.pages",
                        title: "章节",
                        current: task.completedChapters,
                        total: task.totalChapters,
                        color: .blue
                    )

                    Divider()
                        .frame(height: 60)

                    // 页数进度
                    progressItem(
                        icon: "photo.stack",
                        title: "页数",
                        current: task.uploadedPages,
                        total: task.totalPages,
                        color: .purple
                    )
                }
                .padding()
            }
        }
    }

    private func progressItem(icon: String, title: String, current: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(current)")
                .font(.title.monospacedDigit())
                .fontWeight(.semibold)
                + Text(" / \(total)")
                .font(.callout.monospacedDigit())
                .foregroundColor(.secondary)

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(width: total > 0 ? geometry.size.width * CGFloat(current) / CGFloat(total) : 0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 文件信息卡片
    private var fileInfoCard: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("文件信息")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()

                Divider()

                VStack(spacing: 12) {
                    infoRow(icon: "doc.zipper", label: "文件名", value: task.fileName)
                    infoRow(icon: "externaldrive", label: "文件大小", value: formatFileSize(task.fileSize))
                    infoRow(icon: "number", label: "漫画ID", value: "\(task.comicId)")
                }
                .padding()
            }
        }
    }

    // MARK: - 错误信息卡片
    private func errorCard(_ error: String) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("错误信息")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()

                Divider()

                HStack {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.red.opacity(0.05))
            }
        }
    }

    // MARK: - 时间信息卡片
    private var timeInfoCard: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack {
                    Text("时间信息")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()

                Divider()

                VStack(spacing: 12) {
                    infoRow(icon: "calendar.badge.plus", label: "创建时间", value: formatDateTime(task.createdAt))
                    infoRow(icon: "arrow.triangle.2.circlepath", label: "更新时间", value: formatDateTime(task.updatedAt))

                    if !task.createdAt.isEmpty && !task.updatedAt.isEmpty {
                        infoRow(icon: "clock", label: "耗时", value: calculateDuration())
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - 任务ID卡片
    private var taskIdCard: some View {
        GroupBox {
            HStack {
                Text("任务ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(task.taskId)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(task.taskId, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("复制任务ID")
            }
            .padding(12)
        }
    }

    // MARK: - 操作按钮栏
    private var actionBar: some View {
        HStack {
            if task.status == "FAILED" {
                Button {
                    retryTask()
                } label: {
                    Label("重试", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isRetrying)
            }

            if task.status == "PENDING" || task.status == "MERGING" || task.status == "PROCESSING" {
                Button(role: .destructive) {
                    showCancelConfirm = true
                } label: {
                    Label("取消任务", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .disabled(isCanceling)
            }

            Spacer()

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }

    // MARK: - 辅助视图
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .lineLimit(1)
        }
    }

    // MARK: - 计算属性
    private var statusColor: Color {
        switch task.status {
        case "PENDING": return .orange
        case "MERGING": return .cyan
        case "PROCESSING": return .blue
        case "COMPLETED": return .green
        case "FAILED": return .red
        default: return .gray
        }
    }

    private var statusIcon: String {
        switch task.status {
        case "PENDING": return "clock"
        case "MERGING": return "square.stack.3d.up"
        case "PROCESSING": return "arrow.up.circle"
        case "COMPLETED": return "checkmark.circle"
        case "FAILED": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private var statusDisplayName: String {
        switch task.status {
        case "PENDING": return "等待中"
        case "MERGING": return "合并中"
        case "PROCESSING": return "处理中"
        case "COMPLETED": return "已完成"
        case "FAILED": return "失败"
        default: return task.status
        }
    }

    // MARK: - 辅助函数
    private func formatFileSize(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024.0)
        }
        return String(format: "%.2f MB", mb)
    }

    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }

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

        return dateString.replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }

    private func calculateDuration() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var startDate: Date?
        var endDate: Date?

        if let date = formatter.date(from: task.createdAt) {
            startDate = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            startDate = formatter.date(from: task.createdAt)
        }

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: task.updatedAt) {
            endDate = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            endDate = formatter.date(from: task.updatedAt)
        }

        guard let start = startDate, let end = endDate else {
            return "-"
        }

        let interval = end.timeIntervalSince(start)
        if interval < 60 {
            return String(format: "%.0f 秒", interval)
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            return "\(minutes) 分 \(seconds) 秒"
        } else {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours) 小时 \(minutes) 分"
        }
    }

    // MARK: - 操作
    private func retryTask() {
        isRetrying = true
        errorMessage = nil

        Task {
            do {
                try await APIClient.shared.requestVoid(
                    endpoint: APIEndpoints.ComicTasks.retry(task.taskId),
                    method: .post
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isRetrying = false
        }
    }

    private func cancelTask() {
        isCanceling = true
        errorMessage = nil

        Task {
            do {
                try await APIClient.shared.requestVoid(
                    endpoint: APIEndpoints.ComicTasks.action(task.taskId),
                    method: .post,
                    body: ["action": "cancel"]
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCanceling = false
        }
    }
}

// MARK: - 模型
struct ComicUploadTask: Identifiable, Hashable, Codable {
    var id: String { taskId }
    let taskId: String
    let comicId: Int
    let comicSlug: String
    let fileName: String
    let fileSize: Int
    let status: String
    let progress: Int
    let totalChapters: Int
    let completedChapters: Int
    let totalPages: Int
    let uploadedPages: Int
    let error: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case comicId = "comic_id"
        case comicSlug = "comic_slug"
        case fileName = "file_name"
        case fileSize = "file_size"
        case status
        case progress
        case totalChapters = "total_chapters"
        case completedChapters = "completed_chapters"
        case totalPages = "total_pages"
        case uploadedPages = "uploaded_pages"
        case error
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ComicUploadTaskListResponse: Codable {
    let tasks: [ComicUploadTask]
    let pagination: ComicUploadTaskPagination
}

struct ComicUploadTaskPagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPage: Int
    let hasNext: Bool
    let hasPrev: Bool

    enum CodingKeys: String, CodingKey {
        case page
        case pageSize = "page_size"
        case total
        case totalPage = "total_page"
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
}

// MARK: - 视图模型
@MainActor
class ComicUploadTasksViewModel: ObservableObject {
    @Published var tasks: [ComicUploadTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterStatus: String?

    func loadTasks(page: Int = 1) async {
        isLoading = true
        currentPage = page

        do {
            let response: ComicUploadTaskListResponse = try await APIClient.shared.request(
                endpoint: APIEndpoints.ComicTasks.list,
                method: .get,
                queryItems: buildQueryItems(page: page)
            )

            tasks = response.tasks
            totalPages = response.pagination.totalPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildQueryItems(page: Int) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "25")
        ]
        if let status = filterStatus {
            items.append(URLQueryItem(name: "status", value: status))
        }
        return items
    }
}

#Preview {
    ComicUploadTasksView()
}
