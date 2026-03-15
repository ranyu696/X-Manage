//
//  EmailListView.swift
//  X-Manage
//
//  邮件列表视图

import SwiftUI
import WebKit
import AppKit

// MARK: - HTML 邮件渲染视图
struct HTMLEmailView: NSViewRepresentable {
    let htmlContent: String
    @Environment(\.colorScheme) var colorScheme

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        // 允许加载远程内容
        if #available(macOS 11.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let isDarkMode = colorScheme == .dark

        // 暗模式下强制覆盖所有文字颜色
        let darkModeOverride = isDarkMode ? """
            /* 强制覆盖所有元素的颜色 */
            body, body * {
                color: #e0e0e0 !important;
                background-color: transparent !important;
            }
            /* 保持链接可识别 */
            a, a * {
                color: #6cb6ff !important;
            }
            /* 引用块样式 */
            blockquote, blockquote * {
                color: #a0a0a0 !important;
                border-color: #555 !important;
            }
            /* 代码块 */
            pre, code {
                background-color: #2d2d2d !important;
                color: #e0e0e0 !important;
            }
            /* 表格边框 */
            table, th, td {
                border-color: #555 !important;
            }
            /* 分割线 */
            hr {
                border-color: #555 !important;
                background-color: #555 !important;
            }
        """ : ""

        // 包装 HTML 内容，添加基本样式
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: \(isDarkMode ? "#e0e0e0" : "#333");
                    padding: 8px;
                    margin: 0;
                    word-wrap: break-word;
                    background-color: transparent;
                }
                a { color: \(isDarkMode ? "#6cb6ff" : "#0066cc"); }
                img { max-width: 100%; height: auto; }
                blockquote {
                    margin: 16px 0;
                    padding: 8px 16px;
                    border-left: 3px solid \(isDarkMode ? "#555" : "#ccc");
                    color: \(isDarkMode ? "#a0a0a0" : "#666");
                }
                pre {
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    background: \(isDarkMode ? "#2d2d2d" : "#f5f5f5");
                    padding: 8px;
                    border-radius: 4px;
                }
                \(darkModeOverride)
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}

struct EmailListView: View {
    @StateObject private var emailService = EmailService.shared
    @State private var selectedFolder: EmailFolder = .inbox
    @State private var selectedEmail: Email?
    @State private var showComposeSheet = false
    @State private var showSettingsSheet = false
    @State private var searchText = ""

    var body: some View {
        HSplitView {
            // 左侧：邮件列表
            VStack(spacing: 0) {
                // 邮件列表
                if emailService.isFetching && emailService.emails.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView("正在获取邮件...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if emailService.emails.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "envelope")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("暂无邮件")
                            .font(.title2)
                            .padding(.top, 8)
                        Text("点击刷新获取邮件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        List(selection: $selectedEmail) {
                            ForEach(filteredEmails) { email in
                                EmailRowView(email: email)
                                    .tag(email)
                                    .id(email.id)
                            }

                            // 加载更多按钮
                            if emailService.hasMoreEmails && searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    if emailService.isLoadingMore {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("加载中...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Button {
                                            loadMore()
                                        } label: {
                                            Label("加载更多", systemImage: "arrow.down.circle")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.blue)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .onAppear {
                                    // 自动加载更多
                                    loadMore()
                                }
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                    }
                }

                // 底部状态栏
                if !emailService.emails.isEmpty {
                    Divider()
                    HStack {
                        Text("共 \(emailService.totalEmailCount) 封邮件，已加载 \(emailService.emails.count) 封")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .frame(minWidth: 350, maxWidth: 450)

            // 右侧：邮件详情
            VStack {
                if let email = selectedEmail {
                    EmailDetailView(email: email, selectedFolder: selectedFolder)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "envelope.open")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("选择邮件")
                            .font(.title2)
                            .padding(.top, 8)
                        Text("从左侧列表选择邮件查看详情")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposeEmailView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            EmailSettingsView()
        }
        .alert("错误", isPresented: .init(
            get: { emailService.errorMessage != nil },
            set: { if !$0 { emailService.errorMessage = nil } }
        )) {
            Button("确定") { emailService.errorMessage = nil }
        } message: {
            Text(emailService.errorMessage ?? "")
        }
        .onChange(of: selectedFolder) { _, newFolder in
            Task {
                try? await emailService.refreshEmails(folder: newFolder)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Picker("文件夹", selection: $selectedFolder) {
                        ForEach(EmailFolder.allCases, id: \.self) { folder in
                            Label(folder.displayName, systemImage: folderIcon(folder))
                                .tag(folder)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索邮件...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 150)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
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
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        try? await emailService.refreshEmails(folder: selectedFolder)
                    }
                } label: {
                    if emailService.isFetching {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(emailService.isFetching)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showComposeSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }

    // MARK: - 过滤邮件
    private var filteredEmails: [Email] {
        if searchText.isEmpty {
            return emailService.emails
        }
        return emailService.emails.filter { email in
            email.subject.localizedCaseInsensitiveContains(searchText) ||
            email.from.address.localizedCaseInsensitiveContains(searchText) ||
            email.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func folderIcon(_ folder: EmailFolder) -> String {
        switch folder {
        case .inbox: return "tray"
        case .sent: return "paperplane"
        case .drafts: return "doc"
        case .trash: return "trash"
        case .spam: return "exclamationmark.triangle"
        }
    }

    private func loadMore() {
        guard !emailService.isLoadingMore && emailService.hasMoreEmails else { return }
        Task {
            try? await emailService.loadMoreEmails(folder: selectedFolder)
        }
    }
}

// MARK: - 邮件行视图
struct EmailRowView: View {
    let email: Email

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // 未读标记
                Circle()
                    .fill(email.isRead ? .clear : .blue)
                    .frame(width: 8, height: 8)

                // 发件人
                Text(email.from.name ?? email.from.address)
                    .fontWeight(email.isRead ? .regular : .semibold)
                    .lineLimit(1)

                Spacer()

                // 时间
                Text(formatDate(email.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 主题
            Text(email.subject)
                .font(.subheadline)
                .lineLimit(1)

            // 预览（如果没有正文则显示提示）
            if email.body.isEmpty {
                Text("点击查看详情...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                Text(email.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}

// MARK: - 邮件详情视图
struct EmailDetailView: View {
    let email: Email
    let selectedFolder: EmailFolder
    @StateObject private var emailService = EmailService.shared
    @State private var showReplySheet = false
    @State private var loadedEmail: Email?
    @State private var isLoading = false

    private var displayEmail: Email {
        loadedEmail ?? email
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部信息
            VStack(alignment: .leading, spacing: 8) {
                Text(email.subject)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("发件人:")
                                .foregroundStyle(.secondary)
                            Text(email.from.displayString)
                        }
                        HStack {
                            Text("收件人:")
                                .foregroundStyle(.secondary)
                            Text(email.to.map { $0.displayString }.joined(separator: ", "))
                        }
                        HStack {
                            Text("时间:")
                                .foregroundStyle(.secondary)
                            Text(formatDateTime(email.date))
                        }
                    }
                    .font(.caption)

                    Spacer()

                    Button {
                        showReplySheet = true
                    } label: {
                        Label("回复", systemImage: "arrowshape.turn.up.left")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            // 邮件正文
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("正在加载邮件内容...")
                    Spacer()
                }
            } else {
                if let htmlBody = displayEmail.htmlBody, !htmlBody.isEmpty {
                    // 使用 WebView 渲染 HTML 内容
                    HTMLEmailView(htmlContent: htmlBody)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !displayEmail.body.isEmpty {
                    ScrollView {
                        Text(displayEmail.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .textSelection(.enabled)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("无邮件内容")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }

            // 附件
            if let attachments = displayEmail.attachments, !attachments.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("附件 (\(attachments.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(attachments) { attachment in
                                AttachmentView(attachment: attachment)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showReplySheet) {
            ReplyEmailView(originalEmail: displayEmail)
        }
        .onAppear {
            loadEmailContent()
        }
        .onChange(of: email.id) { _, _ in
            loadedEmail = nil
            loadEmailContent()
        }
    }

    private func loadEmailContent() {
        // 如果邮件已经完全加载，不需要再次加载
        if email.isFullyLoaded || !email.body.isEmpty {
            loadedEmail = email
            return
        }

        isLoading = true
        Task {
            do {
                loadedEmail = try await emailService.fetchEmailContent(for: email, folder: selectedFolder)
            } catch {
                print("加载邮件内容失败: \(error)")
            }
            isLoading = false
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 附件视图
struct AttachmentView: View {
    let attachment: EmailAttachment
    @State private var showPreview = false

    private var isImage: Bool {
        attachment.mimeType.hasPrefix("image/")
    }

    private var iconName: String {
        if isImage {
            return "photo"
        } else if attachment.mimeType.contains("pdf") {
            return "doc.richtext"
        } else if attachment.mimeType.contains("zip") || attachment.mimeType.contains("compressed") {
            return "doc.zipper"
        } else {
            return "doc"
        }
    }

    var body: some View {
        Button {
            showPreview = true
        } label: {
            VStack(spacing: 4) {
                // 如果是图片且有数据，显示缩略图
                if isImage, let data = attachment.data, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .frame(width: 60, height: 60)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                VStack(spacing: 2) {
                    Text(attachment.filename)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(formatSize(attachment.size))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPreview) {
            AttachmentPreviewSheet(attachment: attachment)
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - 附件预览弹窗
struct AttachmentPreviewSheet: View {
    let attachment: EmailAttachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(attachment.filename)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            // 预览内容
            if attachment.mimeType.hasPrefix("image/"), let data = attachment.data, let nsImage = NSImage(data: data) {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "doc")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("无法预览此类型的附件")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Text(attachment.mimeType)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }

            Divider()

            // 底部操作
            HStack {
                Text(formatSize(attachment.size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let data = attachment.data {
                    Button {
                        saveAttachment(data: data, filename: attachment.filename)
                    } label: {
                        Label("保存", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private func formatSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func saveAttachment(data: Data, filename: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.canCreateDirectories = true

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? data.write(to: url)
        }
    }
}

// MARK: - 撰写邮件视图
struct ComposeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var emailService = EmailService.shared

    @State private var toAddress = ""
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("新建邮件")
                    .font(.headline)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                TextField("收件人", text: $toAddress)
                TextField("主题", text: $subject)

                Section("正文") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 200)
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button {
                    sendEmail()
                } label: {
                    Label("发送", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(toAddress.isEmpty || subject.isEmpty || bodyText.isEmpty || isSending)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
    }

    private func sendEmail() {
        guard let recipient = EmailAddress(string: toAddress) else {
            errorMessage = "无效的收件人地址"
            return
        }

        isSending = true
        errorMessage = nil

        Task {
            do {
                let request = SendEmailRequest(
                    to: [recipient],
                    cc: nil,
                    subject: subject,
                    body: bodyText,
                    htmlBody: nil,
                    attachments: nil,
                    inReplyTo: nil,
                    references: nil
                )
                try await emailService.sendEmail(request)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

// MARK: - 回复邮件视图（带AI功能）
struct ReplyEmailView: View {
    let originalEmail: Email
    @Environment(\.dismiss) private var dismiss
    @StateObject private var emailService = EmailService.shared

    @State private var replyText = ""
    @State private var isSending = false
    @State private var isGeneratingAI = false
    @State private var errorMessage: String?
    @State private var showAIPreview = false
    @State private var aiGeneratedText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("回复: \(originalEmail.subject)")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("收件人") {
                    Text(originalEmail.from.displayString)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextEditor(text: $replyText)
                        .frame(minHeight: 150)
                } header: {
                    HStack {
                        Text("回复内容")
                        Spacer()
                        // AI 优化按钮
                        Button {
                            generateAIReply()
                        } label: {
                            if isGeneratingAI {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Label("AI 优化", systemImage: "sparkles")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isGeneratingAI)
                    }
                }

                Section("原始邮件") {
                    Text(originalEmail.body.isEmpty ? "(无内容)" : originalEmail.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(10)
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button {
                    sendReply()
                } label: {
                    Label("发送回复", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(replyText.isEmpty || isSending)
            }
            .padding()
        }
        .frame(width: 550, height: 550)
        .sheet(isPresented: $showAIPreview) {
            EmailAIPreviewSheet(
                originalText: replyText,
                aiText: aiGeneratedText,
                onApply: { text in
                    replyText = text
                    showAIPreview = false
                },
                onCancel: {
                    showAIPreview = false
                }
            )
        }
    }

    private func sendReply() {
        isSending = true
        errorMessage = nil

        Task {
            do {
                try await emailService.replyToEmail(originalEmail, body: replyText)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }

    private func generateAIReply() {
        isGeneratingAI = true
        errorMessage = nil

        Task {
            do {
                aiGeneratedText = try await emailService.generateAIReply(
                    for: originalEmail,
                    currentDraft: replyText
                )
                showAIPreview = true
            } catch {
                errorMessage = "AI 生成失败: \(error.localizedDescription)"
            }
            isGeneratingAI = false
        }
    }
}

// MARK: - 邮件 AI 预览弹窗
struct EmailAIPreviewSheet: View {
    let originalText: String
    let aiText: String
    let onApply: (String) -> Void
    let onCancel: () -> Void

    @State private var editableText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI 生成的回复")
                    .font(.headline)
                Spacer()
                Button("取消") { onCancel() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("您可以编辑后应用：")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $editableText)
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.3))
            }
            .padding()

            Divider()

            HStack {
                if !originalText.isEmpty {
                    Button("保留原文") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button {
                    onApply(editableText)
                } label: {
                    Label("应用", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            editableText = aiText
        }
    }
}

// MARK: - 邮件设置视图
struct EmailSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var emailService = EmailService.shared

    @State private var config: MailClientConfig = .default
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("邮件设置")
                    .font(.headline)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            Form {
                Section("账户信息") {
                    TextField("用户名", text: $config.username)
                    SecureField("密码", text: $config.password)
                    TextField("发件人名称", text: $config.senderName)
                }

                Section("IMAP 设置（收件）") {
                    TextField("服务器", text: $config.imapServer)
                    TextField("端口", value: $config.imapPort, format: .number)
                    Toggle("使用 SSL", isOn: $config.imapUseSSL)
                }

                Section("SMTP 设置（发件）") {
                    TextField("服务器", text: $config.smtpServer)
                    TextField("端口", value: $config.smtpPort, format: .number)
                    Toggle("使用 SSL", isOn: $config.smtpUseSSL)
                }

                if let result = testResult {
                    Section {
                        Text(result)
                            .foregroundStyle(result.contains("成功") ? .green : .red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button {
                    testConnection()
                } label: {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("测试连接", systemImage: "network")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isTesting)

                Spacer()

                Button("保存") {
                    emailService.config = config
                    emailService.saveConfig()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
        .onAppear {
            config = emailService.config
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        Task {
            do {
                // 先保存配置再测试
                emailService.config = config
                try await emailService.testConnection()
                testResult = "连接成功！"
            } catch {
                testResult = "连接失败: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}

#Preview {
    EmailListView()
}
