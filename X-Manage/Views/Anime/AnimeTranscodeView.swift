//
//  AnimeTranscodeView.swift
//  X-Manage
//
//  动漫转码任务管理

import SwiftUI

struct AnimeTranscodeView: View {
    @StateObject private var viewModel = AnimeTranscodeViewModel()
    @State private var selectedStatus: String?
    @State private var selectedTask: TranscodeTask?

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
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
            TranscodeTaskDetailView(task: task)
        }
    }

    // MARK: - 工具栏
    private var toolbarView: some View {
        HStack(spacing: 12) {
            statusPicker
            Spacer()
            refreshButton
        }
        .padding()
    }

    private var statusPicker: some View {
        Picker("状态", selection: $selectedStatus) {
            Text("全部状态").tag(nil as String?)
            Text("等待中").tag("PENDING" as String?)
            Text("转码中").tag("PROCESSING" as String?)
            Text("已完成").tag("COMPLETED" as String?)
            Text("失败").tag("FAILED" as String?)
        }
        .pickerStyle(.menu)
        .frame(width: 120)
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.loadTasks() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - 内容区域
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.tasks.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tasks.isEmpty {
            ContentUnavailableView(
                "暂无转码任务",
                systemImage: "waveform",
                description: Text("暂无符合条件的转码任务")
            )
        } else {
            TranscodeTaskTableView(
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
struct TranscodeTaskTableView: View {
    let tasks: [TranscodeTask]
    let onSelect: (TranscodeTask) -> Void

    var body: some View {
        Table(tasks) {
            TableColumn("ID") { (task: TranscodeTask) in
                Text("\(task.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(50)

            TableColumn("动漫ID") { (task: TranscodeTask) in
                Text("\(task.animeId)")
            }
            .width(70)

            TableColumn("集数") { (task: TranscodeTask) in
                Text("第\(task.episodeNo)集")
            }
            .width(70)

            TableColumn("标题") { (task: TranscodeTask) in
                Text(task.title ?? "-")
                    .lineLimit(1)
            }
            .width(min: 150, ideal: 200)

            TableColumn("状态") { (task: TranscodeTask) in
                TranscodeStatusBadge(status: task.status)
            }
            .width(80)

            TableColumn("进度") { (task: TranscodeTask) in
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

            TableColumn("耗时") { (task: TranscodeTask) in
                if let duration = task.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                } else {
                    Text("-")
                        .foregroundStyle(.secondary)
                }
            }
            .width(80)

            TableColumn("创建时间") { (task: TranscodeTask) in
                Text(formatDate(task.createdAt))
            }
            .width(100)

            TableColumn("操作") { (task: TranscodeTask) in
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

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - 转码状态徽章
struct TranscodeStatusBadge: View {
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
        case "PROCESSING": return "转码中"
        case "COMPLETED": return "已完成"
        case "FAILED": return "失败"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "PENDING": return .orange
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
struct TranscodeTaskDetailView: View {
    let task: TranscodeTask

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("转码任务详情")
                .font(.headline)

            GroupBox("基本信息") {
                LabeledContent("任务ID", value: "\(task.id)")
                LabeledContent("任务UUID", value: task.taskId)
                LabeledContent("动漫ID", value: "\(task.animeId)")
                LabeledContent("集数", value: "第\(task.episodeNo)集")
                if let title = task.title {
                    LabeledContent("标题", value: title)
                }
                LabeledContent("状态", value: task.status)
                LabeledContent("进度", value: "\(task.progress)%")
            }

            GroupBox("文件信息") {
                if let sourceSize = task.sourceSize {
                    LabeledContent("源文件大小", value: formatFileSize(sourceSize))
                }
                if let outputSize = task.outputSize {
                    LabeledContent("输出大小", value: formatFileSize(outputSize))
                }
                if let duration = task.duration {
                    LabeledContent("处理耗时", value: formatDuration(duration))
                }
                if let workerId = task.workerId {
                    LabeledContent("处理节点", value: workerId)
                }
            }

            GroupBox("时间信息") {
                LabeledContent("创建时间", value: formatDateTime(task.createdAt))
                if let startedAt = task.startedAt {
                    LabeledContent("开始时间", value: formatDateTime(startedAt))
                }
                if let endedAt = task.endedAt {
                    LabeledContent("结束时间", value: formatDateTime(endedAt))
                }
                LabeledContent("更新时间", value: formatDateTime(task.updatedAt))
            }

            Spacer()
        }
        .padding()
        .frame(width: 450, height: 500)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024.0)
        }
        return String(format: "%.2f MB", mb)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d小时%d分%d秒", hours, minutes, secs)
        }
        return String(format: "%d分%d秒", minutes, secs)
    }

    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        return dateString.replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

// MARK: - 模型
struct TranscodeTask: Identifiable, Hashable, Codable {
    let id: Int
    let taskId: String
    let animeId: Int
    let episodeNo: Int
    let title: String?
    let status: String
    let progress: Int
    let workerId: String?
    let sourceSize: Int?
    let outputSize: Int?
    let duration: Int?
    let createdAt: String
    let updatedAt: String
    let startedAt: String?
    let endedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case animeId = "anime_id"
        case episodeNo = "episode_no"
        case title
        case status
        case progress
        case workerId = "worker_id"
        case sourceSize = "source_size"
        case outputSize = "output_size"
        case duration
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }
}

struct TranscodeTaskListResponse: Codable {
    let tasks: [TranscodeTask]
    let pagination: PaginationMeta?
}

// MARK: - 视图模型
@MainActor
class AnimeTranscodeViewModel: ObservableObject {
    @Published var tasks: [TranscodeTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var filterStatus: String?

    func loadTasks(page: Int = 1) async {
        isLoading = true
        currentPage = page

        do {
            let response: TranscodeTaskListResponse = try await APIClient.shared.request(
                endpoint: APIEndpoints.Anime.transcode,
                method: .get,
                queryItems: buildQueryItems(page: page)
            )

            tasks = response.tasks
            if let pagination = response.pagination {
                totalPages = max(1, pagination.totalPages)
            } else {
                totalPages = 1
            }
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
    AnimeTranscodeView()
}
