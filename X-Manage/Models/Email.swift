//
//  Email.swift
//  X-Manage
//
//  邮件模型

import Foundation

// MARK: - 邮件客户端配置
struct MailClientConfig: Codable {
    // IMAP 配置（收件）
    var imapServer: String
    var imapPort: Int
    var imapUseSSL: Bool

    // SMTP 配置（发件）
    var smtpServer: String
    var smtpPort: Int
    var smtpUseSSL: Bool

    // 认证信息
    var username: String
    var password: String

    // 发件人显示名称
    var senderName: String

    static let `default` = MailClientConfig(
        imapServer: "mail.spacemail.com",
        imapPort: 993,
        imapUseSSL: true,
        smtpServer: "mail.spacemail.com",
        smtpPort: 465,
        smtpUseSSL: true,
        username: "help@xyou.ai",
        password: "RYCeAjdhQ2cR.",
        senderName: "X游社 客服"
    )
}

// MARK: - 邮件
struct Email: Identifiable, Codable, Hashable {
    let id: String  // Message-ID
    let sequenceNumber: Int  // IMAP 序列号，用于获取完整内容
    let from: EmailAddress
    let to: [EmailAddress]
    let cc: [EmailAddress]?
    let subject: String
    var body: String  // 可变，支持后续加载正文
    var htmlBody: String?
    let date: Date
    var isRead: Bool
    let attachments: [EmailAttachment]?

    // 用于回复时引用
    var inReplyTo: String?
    var references: [String]?

    // 是否已加载完整内容
    var isFullyLoaded: Bool = false

    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Email, rhs: Email) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 邮件地址
struct EmailAddress: Codable, Hashable {
    let name: String?
    let address: String

    var displayString: String {
        if let name = name, !name.isEmpty {
            return "\(name) <\(address)>"
        }
        return address
    }

    init(name: String? = nil, address: String) {
        self.name = name
        self.address = address
    }

    init?(string: String) {
        // 解析 "Name <email@example.com>" 或 "email@example.com" 格式
        let pattern = #"^(?:(.+?)\s*<)?([^<>]+@[^<>]+)>?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }

        if let nameRange = Range(match.range(at: 1), in: string) {
            self.name = String(string[nameRange]).trimmingCharacters(in: .whitespaces)
        } else {
            self.name = nil
        }

        if let addressRange = Range(match.range(at: 2), in: string) {
            self.address = String(string[addressRange]).trimmingCharacters(in: .whitespaces)
        } else {
            return nil
        }
    }
}

// MARK: - 邮件附件
struct EmailAttachment: Codable, Identifiable {
    let id: String
    let filename: String
    let mimeType: String
    let size: Int
    let data: Data?
}

// MARK: - 发送邮件请求
struct SendEmailRequest {
    let to: [EmailAddress]
    let cc: [EmailAddress]?
    let subject: String
    let body: String
    let htmlBody: String?
    let attachments: [EmailAttachment]?

    // 回复相关
    let inReplyTo: String?
    let references: [String]?
}

// MARK: - 邮件文件夹
enum EmailFolder: String, CaseIterable {
    case inbox = "INBOX"
    case sent = "Sent"
    case drafts = "Drafts"
    case trash = "Trash"
    case spam = "Spam"

    var displayName: String {
        switch self {
        case .inbox: return "收件箱"
        case .sent: return "已发送"
        case .drafts: return "草稿箱"
        case .trash: return "回收站"
        case .spam: return "垃圾邮件"
        }
    }
}
