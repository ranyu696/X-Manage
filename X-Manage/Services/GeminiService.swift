//
//  GeminiService.swift
//  X-Manage
//
//  Gemini AI 服务

import Foundation

// MARK: - Gemini API 响应模型
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiError: Codable {
    let message: String?
    let code: Int?
}

// MARK: - Gemini 请求模型
struct GeminiRequest: Codable {
    let contents: [GeminiRequestContent]
    let systemInstruction: GeminiRequestContent?
    let generationConfig: GenerationConfig?

    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig
    }
}

struct GeminiRequestContent: Codable {
    let role: String?
    let parts: [GeminiRequestPart]

    init(role: String? = nil, parts: [GeminiRequestPart]) {
        self.role = role
        self.parts = parts
    }
}

struct GeminiRequestPart: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let temperature: Double?
    let maxOutputTokens: Int?
}

// MARK: - Gemini 服务
@MainActor
class GeminiService {
    static let shared = GeminiService()

    private let defaultApiKey = "AIzaSyBW2ffJRahtsnsDAqTgresV8PoP5L7gUf4"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"

    private var apiKey: String {
        let savedKey = UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
        return savedKey.isEmpty ? defaultApiKey : savedKey
    }

    private init() {}

    /// 生成优化的工单回复
    func generateTicketReply(
        ticket: Ticket,
        replies: [TicketReply],
        currentInput: String
    ) async throws -> String {
        // 构建系统指令和用户消息
        let (systemPrompt, userPrompt) = buildTicketReplyPrompts(ticket: ticket, replies: replies, currentInput: currentInput)

        // 调用 API
        return try await generateContent(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }

    /// 通用内容生成
    func generateContent(systemPrompt: String? = nil, userPrompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemInstruction: GeminiRequestContent?
        if let systemPrompt = systemPrompt {
            systemInstruction = GeminiRequestContent(parts: [GeminiRequestPart(text: systemPrompt)])
        } else {
            systemInstruction = nil
        }

        let requestBody = GeminiRequest(
            contents: [
                GeminiRequestContent(role: "user", parts: [GeminiRequestPart(text: userPrompt)])
            ],
            systemInstruction: systemInstruction,
            generationConfig: GenerationConfig(
                temperature: 1.0,
                maxOutputTokens: 1024
            )
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        // 调试：打印响应
        if let responseString = String(data: data, encoding: .utf8) {
            print("Gemini API Response: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Gemini API Error Response: \(responseString)")
            }
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = errorResponse.error {
                throw GeminiServiceError.apiError(error.message ?? "未知错误")
            }
            throw GeminiServiceError.httpError(httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            // 打印更多调试信息
            print("Gemini Response candidates: \(String(describing: geminiResponse.candidates))")
            throw GeminiServiceError.noContent
        }

        return text
    }

    // MARK: - 构建提示词
    private func buildTicketReplyPrompts(ticket: Ticket, replies: [TicketReply], currentInput: String) -> (systemPrompt: String, userPrompt: String) {

        let systemPrompt = """
        你是一个专业的客服人员，负责回复用户的工单。

        【要求】
        1. 回复要礼貌、专业、有同理心
        2. 直接给出解决方案或下一步建议
        3. 语言简洁明了，不要过于冗长
        4. 使用中文回复
        5. 只输出纯文本回复内容，不要包含任何标记或格式符号
        """

        var userPrompt = """
        【工单信息】
        标题: \(ticket.title)
        分类: \(ticket.categoryDisplayName)
        用户问题: \(ticket.content)

        """

        // 添加历史回复
        if !replies.isEmpty {
            userPrompt += "\n【历史回复】\n"
            for reply in replies.suffix(5) { // 只取最近5条
                let sender = reply.isAdmin ? "客服" : "用户"
                userPrompt += "\(sender): \(reply.content)\n"
            }
        }

        // 添加当前输入
        if !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userPrompt += "\n【客服草稿】\n\(currentInput)\n"
            userPrompt += "\n请基于上述草稿内容进行优化，使其更加专业和友好。"
        } else {
            userPrompt += "\n请根据工单内容和历史回复，生成一个合适的客服回复。"
        }

        return (systemPrompt, userPrompt)
    }
}

// MARK: - 错误类型
enum GeminiServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .apiError(let message):
            return "API 错误: \(message)"
        case .noContent:
            return "AI 未返回内容"
        }
    }
}
