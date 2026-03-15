//
//  TicketDetailView.swift
//  X-Manage
//
//  工单详情视图

import SwiftUI

struct TicketDetailView: View {
    let ticket: Ticket
    @StateObject private var viewModel: TicketDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var replyText = ""
    @State private var showStatusPicker = false

    // AI 优化相关状态
    @State private var isGeneratingAI = false
    @State private var showAIPreview = false
    @State private var aiGeneratedText = ""
    @State private var aiError: String?

    // 图片预览状态
    @State private var selectedImageURL: String?

    init(ticket: Ticket) {
        self.ticket = ticket
        self._viewModel = StateObject(wrappedValue: TicketDetailViewModel(ticket: ticket))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            Divider()

            // 主体内容
            HSplitView {
                // 左侧：工单详情和回复
                leftPanel
                    .frame(minWidth: 400)

                // 右侧：工单信息
                rightPanel
                    .frame(width: 280)
            }
        }
        .frame(width: 900, height: 700)
        .task {
            await viewModel.loadReplies()
        }
        .sheet(isPresented: $showAIPreview) {
            AIPreviewSheet(
                generatedText: aiGeneratedText,
                onApply: {
                    replyText = aiGeneratedText
                    showAIPreview = false
                },
                onCancel: {
                    showAIPreview = false
                }
            )
        }
        .overlay {
            // 图片预览
            if let imageURL = selectedImageURL {
                ImagePreviewOverlay(imageURL: imageURL) {
                    selectedImageURL = nil
                }
            }
        }
    }

    // MARK: - 标题栏
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(ticket.publicId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TicketStatusBadge(status: viewModel.currentStatus)
                    TicketCategoryBadge(category: ticket.category)
                }
            }

            Spacer()

            // 状态操作按钮
            statusButtons

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - 状态操作按钮
    private var statusButtons: some View {
        HStack(spacing: 8) {
            if viewModel.currentStatus != "RESOLVED" && viewModel.currentStatus != "TICKET_RESOLVED" {
                Button {
                    Task { await viewModel.updateStatus("RESOLVED") }
                } label: {
                    Label("标记已解决", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            if viewModel.currentStatus != "CLOSED" && viewModel.currentStatus != "TICKET_CLOSED" {
                Button {
                    Task { await viewModel.updateStatus("CLOSED") }
                } label: {
                    Label("关闭工单", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - 左侧面板
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // 工单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 原始工单内容
                    ticketContentCard

                    // 附件图片
                    if let images = ticket.images, !images.isEmpty {
                        attachmentsSection(images)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // 回复列表
                    repliesSection
                }
                .padding()
            }

            Divider()

            // 回复输入框
            replyInputSection
        }
    }

    // MARK: - 工单内容卡片
    private var ticketContentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("用户 #\(ticket.userId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(formatDateTime(ticket.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(ticket.content)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - 附件区域
    private func attachmentsSection(_ images: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("附件 (\(images.count))")
                .font(.subheadline)
                .fontWeight(.medium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(images, id: \.self) { imagePath in
                        let fullURL = imagePath.hasPrefix("http") ? imagePath : "https://game.xyou.me/\(imagePath)"
                        AsyncImage(url: URL(string: fullURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                        }
                        .frame(width: 120, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            selectedImageURL = fullURL
                        }
                    }
                }
            }
        }
    }

    // MARK: - 回复列表
    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("回复 (\(viewModel.replies.count))")
                .font(.subheadline)
                .fontWeight(.medium)

            if viewModel.isLoadingReplies {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.replies.isEmpty {
                Text("暂无回复")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.replies) { reply in
                    ReplyBubbleView(reply: reply) { imageURL in
                        selectedImageURL = imageURL
                    }
                }
            }
        }
    }

    // MARK: - 回复输入区域
    private var replyInputSection: some View {
        VStack(spacing: 8) {
            TextEditor(text: $replyText)
                .font(.body)
                .frame(height: 80)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                // AI 错误提示
                if let error = aiError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                // AI 优化按钮
                Button {
                    generateAIReply()
                } label: {
                    if isGeneratingAI {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                        Text("生成中...")
                    } else {
                        Label("AI 优化", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGeneratingAI)

                // 发送按钮
                Button {
                    Task {
                        await viewModel.sendReply(replyText)
                        replyText = ""
                    }
                } label: {
                    Label("发送回复", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
        }
        .padding()
    }

    // MARK: - 生成 AI 回复
    private func generateAIReply() {
        isGeneratingAI = true
        aiError = nil

        Task {
            do {
                let generatedText = try await GeminiService.shared.generateTicketReply(
                    ticket: ticket,
                    replies: viewModel.replies,
                    currentInput: replyText
                )
                aiGeneratedText = generatedText
                showAIPreview = true
            } catch {
                aiError = error.localizedDescription
            }
            isGeneratingAI = false
        }
    }

    // MARK: - 右侧面板
    private var rightPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 基本信息
                GroupBox("基本信息") {
                    VStack(spacing: 0) {
                        InfoRow(title: "工单ID", value: ticket.publicId)
                        Divider()
                        InfoRow(title: "用户ID", value: "\(ticket.userId)")
                        Divider()
                        InfoRow(title: "来源", value: ticket.sourceDisplayName)
                        Divider()
                        HStack {
                            Text("分类")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $viewModel.currentCategory) {
                                Text("游戏").tag("GAME")
                                Text("漫画").tag("COMIC")
                                Text("小说").tag("NOVEL")
                                Text("动漫").tag("ANIME")
                                Text("账号").tag("ACCOUNT")
                                Text("支付").tag("PAYMENT")
                                Text("其他").tag("OTHER")
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .onChange(of: viewModel.currentCategory) { oldValue, newValue in
                                if oldValue != newValue {
                                    Task { await viewModel.updateCategory(newValue) }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // 状态信息
                GroupBox("状态信息") {
                    VStack(spacing: 0) {
                        HStack {
                            Text("当前状态")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TicketStatusBadge(status: viewModel.currentStatus)
                        }
                        .padding(.vertical, 8)

                        Divider()
                        InfoRow(title: "回复数", value: "\(ticket.replyCount ?? 0)")
                    }
                }

                // 时间信息
                GroupBox("时间信息") {
                    VStack(spacing: 0) {
                        InfoRow(title: "创建时间", value: formatDateTime(ticket.createdAt))
                        if let updatedAt = ticket.updatedAt {
                            Divider()
                            InfoRow(title: "更新时间", value: formatDateTime(updatedAt))
                        }
                    }
                }

                // 快捷操作
                GroupBox("快捷操作") {
                    VStack(spacing: 8) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ticket.publicId, forType: .string)
                        } label: {
                            Label("复制工单ID", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ticket.content, forType: .string)
                        } label: {
                            Label("复制工单内容", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - 格式化日期时间
    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        return dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 回复气泡视图
struct ReplyBubbleView: View {
    let reply: TicketReply
    var onImageTap: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if reply.isAdmin {
                Spacer()
            }

            VStack(alignment: reply.isAdmin ? .trailing : .leading, spacing: 4) {
                HStack {
                    if reply.isAdmin {
                        Spacer()
                    }
                    Text(reply.isAdmin ? "客服" : "用户 #\(reply.userId)")
                        .font(.caption)
                        .fontWeight(.medium)
                    if !reply.isAdmin {
                        Spacer()
                    }
                }

                Text(reply.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(reply.isAdmin ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // 回复图片
                if let images = reply.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images, id: \.self) { imagePath in
                                let fullURL = imagePath.hasPrefix("http") ? imagePath : "https://ceshi.xyou.me/\(imagePath)"
                                AsyncImage(url: URL(string: fullURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                                .frame(width: 100, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    onImageTap?(fullURL)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 400)
                }

                Text(formatDateTime(reply.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 500)

            if !reply.isAdmin {
                Spacer()
            }
        }
    }

    private func formatDateTime(_ dateString: String) -> String {
        dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

// MARK: - 工单详情视图模型
@MainActor
class TicketDetailViewModel: ObservableObject {
    @Published var replies: [TicketReply] = []
    @Published var isLoadingReplies = false
    @Published var isSending = false
    @Published var currentStatus: String
    @Published var currentCategory: String
    @Published var errorMessage: String?

    private let ticket: Ticket
    private let service = TicketService.shared

    init(ticket: Ticket) {
        self.ticket = ticket
        self.currentStatus = ticket.status
        self.currentCategory = ticket.category
    }

    func loadReplies() async {
        isLoadingReplies = true
        do {
            let response = try await service.getReplies(ticketId: ticket.id)
            replies = response.replies
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingReplies = false
    }

    func sendReply(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSending = true
        do {
            let request = CreateTicketReplyRequest(content: content, isAdmin: true)
            let reply = try await service.createReply(ticketId: ticket.id, request: request)
            replies.append(reply)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func updateStatus(_ status: String) async {
        do {
            try await service.updateStatus(id: ticket.id, status: status)
            currentStatus = status
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCategory(_ category: String) async {
        do {
            try await service.updateCategory(id: ticket.id, category: category)
            currentCategory = category
        } catch {
            errorMessage = error.localizedDescription
            // 恢复原值
            currentCategory = ticket.category
        }
    }
}

// MARK: - AI 预览弹窗
struct AIPreviewSheet: View {
    let generatedText: String
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI 生成的回复")
                    .font(.headline)
                Spacer()
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 内容预览
            ScrollView {
                Text(generatedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(.ultraThinMaterial)

            Divider()

            // 操作按钮
            HStack {
                Text("是否使用此内容替换输入框？")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button {
                    onApply()
                } label: {
                    Label("使用此回复", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - 图片预览 Overlay
struct ImagePreviewOverlay: View {
    let imageURL: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // 图片
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(40)
                case .failure(_):
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                        Text("图片加载失败")
                    }
                    .foregroundStyle(.white)
                case .empty:
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }

            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    TicketDetailView(ticket: Ticket(
        id: 1,
        publicId: "T-12345678",
        userId: 12345,
        title: "测试工单",
        content: "这是一个测试工单的内容",
        status: "TICKET_OPEN",
        category: "GAME",
        source: "WEB",
        replyCount: 2,
        images: nil,
        createdAt: "2024-01-01T12:00:00Z",
        updatedAt: "2024-01-01T12:30:00Z"
    ))
}
