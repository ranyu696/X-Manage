//
//  FAQGeneratorView.swift
//  X-Manage
//
//  从历史工单归纳 FAQ 知识库 —— 产物直接作为 AI 助手的系统提示词

import SwiftUI

@MainActor
final class FAQGeneratorViewModel: ObservableObject {
    @Published var progress = ""
    @Published var faq = ""
    @Published var isRunning = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // ponytail: Gemini 调用串行，2000 条工单约 3 分钟。要更快就把归纳阶段换成 TaskGroup，
    // 但要先确认 Gemini 的 RPM 配额撑得住并发。
    private let batchSize = 150

    // ponytail: 只取最近 2000 条。工单总量 5000+，但全量拉取会把 ticket-service 打挂（gRPC EOF），
    // 而且更老的工单答案多半已经过时——FAQ 要的是当下高频问题，不是历史全集。
    private let maxTickets = 2000

    /// 载入已保存的 FAQ，让运营看到当前线上生效的版本，而不是每次都从空白开始
    func load() async {
        faq = (try? await ConfigService.shared.getAssistantFAQ()) ?? ""
    }

    /// 保存后各端助手下一轮对话即生效
    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await ConfigService.shared.updateAssistantFAQ(faq)
            progress = "已保存，各端助手下一轮对话生效"
            errorMessage = nil
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    func generate() async {
        isRunning = true
        errorMessage = nil
        faq = ""
        defer { isRunning = false }

        do {
            let tickets = try await fetchRecent()
            guard !tickets.isEmpty else {
                errorMessage = "没有拉到任何工单"
                return
            }

            var summaries: [String] = []
            let batches = stride(from: 0, to: tickets.count, by: batchSize).map {
                Array(tickets[$0..<min($0 + batchSize, tickets.count)])
            }
            for (index, batch) in batches.enumerated() {
                progress = "归纳中 \(index + 1)/\(batches.count) 批…"
                // 单批失败就跳过：别让整轮归纳卡在一次 API 抖动上
                summaries += (try? await summarize(batch)) ?? []
            }
            guard !summaries.isEmpty else {
                errorMessage = "所有批次归纳都失败了，检查 Gemini API Key"
                return
            }

            progress = "汇总 \(summaries.count) 条摘要，生成 FAQ…"
            faq = try await cluster(summaries)
            progress = "完成：\(tickets.count) 条工单 → \(faq.count) 字 FAQ"
        } catch {
            errorMessage = error.localizedDescription
            progress = ""
        }
    }

    /// 分页拉取最近的工单（不过滤状态：未解决的问题同样是真实高频问题）
    private func fetchRecent() async throws -> [Ticket] {
        var all: [Ticket] = []
        var page = 1
        while all.count < maxTickets {
            do {
                let response = try await TicketService.shared.getList(
                    params: TicketListParams(page: page, pageSize: 100)
                )
                all += response.tickets
                progress = "拉取工单 \(all.count)/\(min(maxTickets, response.pagination.total))"
                guard response.pagination.hasNext, !response.tickets.isEmpty else { break }
                page += 1
                try await Task.sleep(nanoseconds: 300_000_000) // 别把 ticket-service 打挂
            } catch {
                // 中途失败不整批作废：已经拉到的工单照样能归纳出 FAQ
                guard !all.isEmpty else { throw error }
                progress = "第 \(page) 页拉取中断，用已拉到的 \(all.count) 条继续"
                break
            }
        }
        return all
    }

    /// 把一批工单压成每条一行的问题摘要
    private func summarize(_ batch: [Ticket]) async throws -> [String] {
        let list = batch.map { ticket in
            "[\(ticket.categoryDisplayName)] \(ticket.title) —— \(ticket.content.prefix(200))"
        }.joined(separator: "\n")

        let text = try await GeminiService.shared.generateContent(
            systemPrompt: """
            你在归纳客服工单。对输入的每一条工单，输出一行「问题类型 | 一句话问题描述」。
            输出行数必须与输入条数一致，不要编号、不要空行、不要任何解释。
            """,
            userPrompt: list,
            maxOutputTokens: 8192
        )

        return text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// 把全部摘要聚类成 FAQ 文档
    private func cluster(_ summaries: [String]) async throws -> String {
        let system = """
        你在把客服工单摘要归纳成一份 FAQ 知识库。这份文档会原样作为 AI 客服助手的系统提示词，
        所以它必须准确、可直接照着回答，不能有含糊其辞的套话。

        要求：
        1. 按出现频次从高到低排列，合并同义问题
        2. 每条格式：
           ### 问题标题
           - 频次：约 N 次（占比 X%）
           - 常见问法：最多 3 种
           - 标准答案：能从工单内容推断出来就写具体答案，推断不出就写「待补充」
           - 处理方式：[AI可直接回答] 或 [需转人工]
        3. 只保留出现 3 次以上的问题；长尾统一放到末尾「零散问题」一节，仅列标题
        4. 文档开头先写一段【摘要】：共归纳出多少类问题、标记为 [AI可直接回答] 的问题合计覆盖多少比例的工单
        5. 输出纯 Markdown，不要用代码块包裹整篇文档
        """

        return try await GeminiService.shared.generateContent(
            systemPrompt: system,
            userPrompt: summaries.joined(separator: "\n"),
            maxOutputTokens: 32768
        )
    }
}

struct FAQGeneratorView: View {
    @StateObject private var viewModel = FAQGeneratorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    Task { await viewModel.generate() }
                } label: {
                    Label(viewModel.isRunning ? "生成中…" : "从历史工单生成 FAQ", systemImage: "sparkles")
                }
                .disabled(viewModel.isRunning)

                if viewModel.isRunning {
                    ProgressView().controlSize(.small)
                }

                Text(viewModel.progress)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.faq, forType: .string)
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.faq.isEmpty)

                Button {
                    Task { await viewModel.save() }
                } label: {
                    Label("保存并生效", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.faq.isEmpty || viewModel.isSaving || viewModel.isRunning)
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            TextEditor(text: $viewModel.faq)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if viewModel.faq.isEmpty && !viewModel.isRunning {
                        Text("点击上方按钮，拉取最近 2000 条工单并归纳成 FAQ。生成后可在此直接编辑，再复制到系统提示词。")
                            .foregroundStyle(.tertiary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding()
        .navigationTitle("FAQ 知识库")
        .task { await viewModel.load() }
    }
}
