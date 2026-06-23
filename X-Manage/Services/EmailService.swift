//
//  EmailService.swift
//  X-Manage
//
//  邮件服务 - 使用 SwiftMail 库

import Foundation
import os.log
import SwiftMail

private let logger = Logger(subsystem: "com.xyouacg.X-Manage", category: "Email")

// MARK: - 邮件服务
@MainActor
class EmailService: ObservableObject {
    static let shared = EmailService()

    @Published var config: MailClientConfig
    @Published var emails: [Email] = []
    @Published var isConnected = false
    @Published var isFetching = false
    @Published var isLoadingMore = false
    @Published var isSending = false
    @Published var isLoadingContent = false
    @Published var errorMessage: String?

    // 分页相关
    @Published var totalEmailCount: Int = 0
    @Published var hasMoreEmails: Bool = true
    private var currentOffset: Int = 0
    private let pageSize: Int = 10

    private let configKey = "EmailConfig"

    private init() {
        // 从 UserDefaults 加载配置
        if let data = UserDefaults.standard.data(forKey: configKey),
           let savedConfig = try? JSONDecoder().decode(MailClientConfig.self, from: data) {
            self.config = savedConfig
        } else {
            self.config = .default
        }
    }

    // MARK: - 保存配置
    func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    // MARK: - 发送邮件
    func sendEmail(_ request: SendEmailRequest) async throws {
        isSending = true
        errorMessage = nil

        defer { isSending = false }

        // 创建 SMTP 服务器
        let smtpServer = SMTPServer(host: config.smtpServer, port: config.smtpPort)

        // 连接并登录
        try await smtpServer.connect()

        do {
            try await smtpServer.login(username: config.username, password: config.password)

            // 构建邮件
            let sender = SwiftMail.EmailAddress(name: config.senderName, address: config.username)
            let recipients = request.to.map { SwiftMail.EmailAddress(name: $0.name, address: $0.address) }

            let email = SwiftMail.Email(
                sender: sender,
                recipients: recipients,
                subject: request.subject,
                textBody: request.body,
                htmlBody: request.htmlBody
            )

            // 发送邮件
            try await smtpServer.sendEmail(email)
        } catch {
            await safeDisconnect(smtpServer)
            throw error
        }

        await safeDisconnect(smtpServer)
    }

    // MARK: - 连接清理
    private func safeDisconnect(_ server: SMTPServer) async {
        do {
            try await server.disconnect()
        } catch {
            logger.error("SMTP disconnect failed: \(error.localizedDescription)")
        }
    }

    private func safeDisconnect(_ server: IMAPServer) async {
        do {
            try await server.disconnect()
        } catch {
            logger.error("IMAP disconnect failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 刷新邮件列表（重置并获取最新）
    func refreshEmails(folder: EmailFolder = .inbox) async throws {
        // 重置分页状态
        currentOffset = 0
        emails = []
        hasMoreEmails = true

        try await fetchEmails(folder: folder)
    }

    // MARK: - 获取邮件列表（首次或刷新）
    func fetchEmails(folder: EmailFolder = .inbox) async throws {
        guard !isFetching else { return }

        isFetching = true
        errorMessage = nil

        defer { isFetching = false }

        let imapServer = IMAPServer(host: config.imapServer, port: config.imapPort)

        do {
            try await imapServer.connect()
            try await imapServer.login(username: config.username, password: config.password)

            let mailboxStatus = try await imapServer.selectMailbox(folder.rawValue)
            totalEmailCount = mailboxStatus.messageCount
            logger.info("Mailbox status: \(self.totalEmailCount) emails")

            guard totalEmailCount > 0 else {
                emails = []
                hasMoreEmails = false
                await safeDisconnect(imapServer)
                return
            }

            // 计算获取范围（从最新开始）
            let endIndex = totalEmailCount - currentOffset
            let startIndex = max(1, endIndex - pageSize + 1)

            guard endIndex >= 1 && startIndex <= endIndex else {
                hasMoreEmails = false
                await safeDisconnect(imapServer)
                return
            }

            logger.info("Fetching emails \(startIndex)...\(endIndex)")

            let startSeq = SequenceNumber(startIndex)
            let endSeq = SequenceNumber(endIndex)
            let sequenceSet = SequenceNumberSet(startSeq...endSeq)

            var fetchedEmails: [Email] = []
            let messageInfoStream = imapServer.fetchMessageInfos(using: sequenceSet)

            for try await messageInfo in messageInfoStream {
                let email = Email(
                    id: messageInfo.messageId ?? UUID().uuidString,
                    sequenceNumber: Int(messageInfo.sequenceNumber.value),
                    from: EmailAddress(name: nil, address: messageInfo.from ?? "unknown@example.com"),
                    to: messageInfo.to.map { EmailAddress(name: nil, address: $0) },
                    cc: messageInfo.cc.isEmpty ? nil : messageInfo.cc.map { EmailAddress(name: nil, address: $0) },
                    subject: messageInfo.subject ?? "(无主题)",
                    body: "",
                    htmlBody: nil,
                    date: messageInfo.date ?? Date(),
                    isRead: messageInfo.flags.contains(.seen),
                    attachments: nil,
                    isFullyLoaded: false
                )
                fetchedEmails.append(email)
            }

            // 按序列号降序排列（最新的在前）
            fetchedEmails.sort { $0.sequenceNumber > $1.sequenceNumber }

            emails = fetchedEmails
            currentOffset = totalEmailCount - startIndex + 1
            hasMoreEmails = startIndex > 1

            await safeDisconnect(imapServer)
            logger.info("Fetched \(self.emails.count) emails, hasMore=\(self.hasMoreEmails)")

        } catch {
            await safeDisconnect(imapServer)
            logger.error("Fetch emails failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 加载更多邮件
    func loadMoreEmails(folder: EmailFolder = .inbox) async throws {
        guard !isLoadingMore && hasMoreEmails else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let imapServer = IMAPServer(host: config.imapServer, port: config.imapPort)

        do {
            try await imapServer.connect()
            try await imapServer.login(username: config.username, password: config.password)

            let mailboxStatus = try await imapServer.selectMailbox(folder.rawValue)
            totalEmailCount = mailboxStatus.messageCount

            // 计算下一批邮件的范围
            let endIndex = totalEmailCount - currentOffset
            let startIndex = max(1, endIndex - pageSize + 1)

            guard endIndex >= 1 && startIndex <= endIndex else {
                hasMoreEmails = false
                await safeDisconnect(imapServer)
                return
            }

            logger.info("Loading more emails \(startIndex)...\(endIndex)")

            let startSeq = SequenceNumber(startIndex)
            let endSeq = SequenceNumber(endIndex)
            let sequenceSet = SequenceNumberSet(startSeq...endSeq)

            var fetchedEmails: [Email] = []
            let messageInfoStream = imapServer.fetchMessageInfos(using: sequenceSet)

            for try await messageInfo in messageInfoStream {
                let email = Email(
                    id: messageInfo.messageId ?? UUID().uuidString,
                    sequenceNumber: Int(messageInfo.sequenceNumber.value),
                    from: EmailAddress(name: nil, address: messageInfo.from ?? "unknown@example.com"),
                    to: messageInfo.to.map { EmailAddress(name: nil, address: $0) },
                    cc: messageInfo.cc.isEmpty ? nil : messageInfo.cc.map { EmailAddress(name: nil, address: $0) },
                    subject: messageInfo.subject ?? "(无主题)",
                    body: "",
                    htmlBody: nil,
                    date: messageInfo.date ?? Date(),
                    isRead: messageInfo.flags.contains(.seen),
                    attachments: nil,
                    isFullyLoaded: false
                )
                fetchedEmails.append(email)
            }

            // 按序列号降序排列
            fetchedEmails.sort { $0.sequenceNumber > $1.sequenceNumber }

            // 追加到现有列表
            emails.append(contentsOf: fetchedEmails)
            currentOffset = totalEmailCount - startIndex + 1
            hasMoreEmails = startIndex > 1

            await safeDisconnect(imapServer)
            logger.info("Loaded \(fetchedEmails.count) more, total=\(self.emails.count)")

        } catch {
            await safeDisconnect(imapServer)
            throw error
        }
    }

    // MARK: - 获取邮件完整内容
    func fetchEmailContent(for email: Email, folder: EmailFolder = .inbox) async throws -> Email {
        isLoadingContent = true
        defer { isLoadingContent = false }

        let imapServer = IMAPServer(host: config.imapServer, port: config.imapPort)

        do {
            try await imapServer.connect()
            try await imapServer.login(username: config.username, password: config.password)
            _ = try await imapServer.selectMailbox(folder.rawValue)

            // 获取单封邮件的完整内容
            let seqNum = SequenceNumber(email.sequenceNumber)
            let sequenceSet = SequenceNumberSet(seqNum...seqNum)

            let messageStream = imapServer.fetchMessages(using: sequenceSet)

            var updatedEmail = email

            for try await message in messageStream {
                updatedEmail.body = message.textBody ?? ""
                var htmlContent = message.htmlBody

                // 处理内嵌图片 (CID) - 替换为 base64 data URL
                for cidPart in message.cids {
                    if let contentId = cidPart.contentId,
                       let data = cidPart.decodedData() {
                        let base64String = data.base64EncodedString()
                        let dataURL = "data:\(cidPart.contentType);base64,\(base64String)"
                        // 替换 cid:xxx 引用（处理各种格式）
                        let cidRef = contentId.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
                        htmlContent = htmlContent?.replacingOccurrences(of: "cid:\(cidRef)", with: dataURL)
                        htmlContent = htmlContent?.replacingOccurrences(of: "cid:\(contentId)", with: dataURL)
                    }
                }

                updatedEmail.htmlBody = htmlContent

                // 提取附件（不包括内嵌图片）
                let attachments = message.attachments.map { part in
                    EmailAttachment(
                        id: part.contentId ?? UUID().uuidString,
                        filename: part.filename ?? part.suggestedFilename,
                        mimeType: part.contentType,
                        size: part.data?.count ?? 0,
                        data: part.decodedData()
                    )
                }
                if !attachments.isEmpty {
                    updatedEmail = Email(
                        id: updatedEmail.id,
                        sequenceNumber: updatedEmail.sequenceNumber,
                        from: updatedEmail.from,
                        to: updatedEmail.to,
                        cc: updatedEmail.cc,
                        subject: updatedEmail.subject,
                        body: updatedEmail.body,
                        htmlBody: updatedEmail.htmlBody,
                        date: updatedEmail.date,
                        isRead: updatedEmail.isRead,
                        attachments: attachments,
                        inReplyTo: updatedEmail.inReplyTo,
                        references: updatedEmail.references,
                        isFullyLoaded: true
                    )
                } else {
                    updatedEmail.isFullyLoaded = true
                }
                break
            }

            await safeDisconnect(imapServer)

            // 更新缓存中的邮件
            if let index = emails.firstIndex(where: { $0.id == email.id }) {
                emails[index] = updatedEmail
            }

            return updatedEmail

        } catch {
            await safeDisconnect(imapServer)
            throw error
        }
    }

    // MARK: - 回复邮件
    func replyToEmail(_ original: Email, body: String, htmlBody: String? = nil) async throws {
        let request = SendEmailRequest(
            to: [original.from],
            cc: nil,
            subject: original.subject.hasPrefix("Re:") ? original.subject : "Re: \(original.subject)",
            body: body,
            htmlBody: htmlBody,
            attachments: nil,
            inReplyTo: original.id,
            references: (original.references ?? []) + [original.id]
        )
        try await sendEmail(request)
    }

    // MARK: - 测试连接
    func testConnection() async throws {
        let imapServer = IMAPServer(host: config.imapServer, port: config.imapPort)
        try await imapServer.connect()
        do {
            try await imapServer.login(username: config.username, password: config.password)
        } catch {
            await safeDisconnect(imapServer)
            throw error
        }
        await safeDisconnect(imapServer)
    }

    // MARK: - AI 生成邮件回复
    func generateAIReply(for email: Email, currentDraft: String = "") async throws -> String {
        let geminiService = GeminiService.shared

        let systemPrompt = """
        你是一个专业的客服人员，负责回复用户的邮件咨询。

        【要求】
        1. 回复要礼貌、专业、有同理心
        2. 直接给出解决方案或下一步建议
        3. 语言简洁明了，不要过于冗长
        4. 使用中文回复
        5. 只输出纯文本回复内容，不要包含任何标记或格式符号
        6. 不需要包含称呼和签名，只需要正文内容
        """

        var userPrompt = """
        【邮件信息】
        发件人: \(email.from.displayString)
        主题: \(email.subject)
        内容: \(email.body.isEmpty ? "(无内容)" : email.body)
        """

        if !currentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userPrompt += "\n\n【客服草稿】\n\(currentDraft)\n\n请基于上述草稿内容进行优化，使其更加专业和友好。"
        } else {
            userPrompt += "\n\n请根据邮件内容，生成一个合适的客服回复。"
        }

        return try await geminiService.generateContent(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
}

// MARK: - 邮件错误
enum EmailError: LocalizedError {
    case connectionFailed(String)
    case connectionCancelled
    case notConnected
    case sendFailed(String)
    case receiveFailed(String)
    case serverError(String)
    case authenticationFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "连接失败: \(msg)"
        case .connectionCancelled: return "连接已取消"
        case .notConnected: return "未连接到服务器"
        case .sendFailed(let msg): return "发送失败: \(msg)"
        case .receiveFailed(let msg): return "接收失败: \(msg)"
        case .serverError(let msg): return "服务器错误: \(msg)"
        case .authenticationFailed: return "认证失败"
        case .invalidResponse: return "无效的响应"
        }
    }
}
