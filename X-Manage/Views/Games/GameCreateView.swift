//
//  GameCreateView.swift
//  X-Manage
//
//  游戏创建视图 - YAML 编辑器

import SwiftUI

struct GameCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GameCreateViewModel()
    let onSuccess: () -> Void

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("新建游戏")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // 主内容
            HSplitView {
                // 左侧 - YAML 编辑器
                VStack(spacing: 0) {
                    // 工具栏
                    HStack {
                        Text("YAML 编辑器")
                            .font(.headline)

                        Spacer()

                        Button {
                            viewModel.yamlContent = gameYamlTemplate
                        } label: {
                            Label("加载模板", systemImage: "doc.text")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            viewModel.parseYaml()
                        } label: {
                            Label("解析预览", systemImage: "eye")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()

                    Divider()

                    // YAML 文本编辑器
                    TextEditor(text: $viewModel.yamlContent)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(minWidth: 400)

                // 右侧 - 预览和参考
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("验证信息").tag(0)
                        Text("数据预览").tag(1)
                        Text("枚举参考").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    Divider()

                    switch selectedTab {
                    case 0:
                        validationInfoView
                    case 1:
                        dataPreviewView
                    case 2:
                        enumReferenceView
                    default:
                        EmptyView()
                    }
                }
                .frame(minWidth: 300)
            }

            Divider()

            // 底部操作栏
            HStack {
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Spacer()

                Button("创建游戏") {
                    Task {
                        if await viewModel.createGame() {
                            onSuccess()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.yamlContent.isEmpty || viewModel.isCreating)
            }
            .padding()
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - 验证信息视图
    private var validationInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.validationMessages.isEmpty {
                    ContentUnavailableView(
                        "点击「解析预览」查看验证结果",
                        systemImage: "checkmark.circle",
                        description: Text("验证您的 YAML 配置")
                    )
                } else {
                    ForEach(viewModel.validationMessages, id: \.self) { message in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: message.hasPrefix("✓") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(message.hasPrefix("✓") ? .green : .orange)

                            Text(message)
                                .font(.callout)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - 数据预览视图
    private var dataPreviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.parsedPreview.isEmpty {
                    ContentUnavailableView(
                        "点击「解析预览」查看数据",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("预览解析后的游戏数据")
                    )
                } else {
                    Text(viewModel.parsedPreview)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
    }

    // MARK: - 枚举参考视图
    private var enumReferenceView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                enumSection(title: "区域 (region)", items: GameRegion.allCases.map { ($0.rawValue, $0.displayName) })
                enumSection(title: "语言 (language)", items: GameLanguage.allCases.map { ($0.rawValue, $0.displayName) })
                enumSection(title: "画质 (quality)", items: GameQuality.allCases.map { ($0.rawValue, $0.displayName) })
                enumSection(title: "类型 (types)", items: GameType.allCases.map { ($0.rawValue, $0.displayName) })
                enumSection(title: "分类 (category_slug)", items: GameCategory.allCases.map { ($0.rawValue, $0.displayName) })
            }
            .padding()
        }
    }

    private func enumSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(item.1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class GameCreateViewModel: ObservableObject {
    @Published var yamlContent = ""
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var validationMessages: [String] = []
    @Published var parsedPreview = ""

    private let service = GameService.shared

    func parseYaml() {
        validationMessages = []
        parsedPreview = ""

        guard !yamlContent.isEmpty else {
            validationMessages.append("YAML 内容不能为空")
            return
        }

        // 基本验证
        if yamlContent.contains("game:") {
            validationMessages.append("✓ 找到 game 配置块")
        } else {
            validationMessages.append("缺少 game 配置块")
        }

        if yamlContent.contains("title:") {
            validationMessages.append("✓ 找到 title 字段")
        } else {
            validationMessages.append("缺少必填字段: title")
        }

        if yamlContent.contains("name:") {
            validationMessages.append("✓ 找到 name 字段")
        } else {
            validationMessages.append("缺少必填字段: name")
        }

        if yamlContent.contains("author:") {
            validationMessages.append("✓ 找到 author 字段")
        } else {
            validationMessages.append("缺少必填字段: author")
        }

        if yamlContent.contains("category_slug:") {
            validationMessages.append("✓ 找到 category_slug 字段")
        } else {
            validationMessages.append("缺少必填字段: category_slug")
        }

        if yamlContent.contains("version:") {
            validationMessages.append("✓ 找到 version 配置块")
        }

        // 显示预览
        parsedPreview = yamlContent
    }

    func createGame() async -> Bool {
        isCreating = true
        errorMessage = nil

        do {
            _ = try await service.createFromYaml(yaml: yamlContent)
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
            return false
        }
    }
}

// MARK: - YAML 模板
let gameYamlTemplate = """
game:
  title: "游戏标题"
  name: "游戏名称"
  original: "原名"
  author: "开发商"
  category_slug: "rpg"
  tags: "标签1,标签2"
  region: "japan"
  language: "ai"
  quality: "anime"
  types:
    - pc
    - mobile
  is_translated: true
  description: "游戏简介"
  content: |
    ## 游戏介绍

    这里是游戏的详细介绍，支持 Markdown 格式。
  update: |
    ## 更新日志

    - 版本更新内容
  update_time: "2024-01-15"

version:
  version: "1.0"
  description: "初始版本"
  size: 2.5
  is_latest: true
  baidu_url: "https://pan.baidu.com/s/xxx"
  baidu_password: "xxxx"
  cloud_url: ""
  cloud_password: ""
  storage_path: ""
  unzip_codes: "解压密码"
  cheat_codes:
    - code: "作弊码"
      description: "作弊码说明"
  pricing_id: 1
"""

#Preview {
    GameCreateView(onSuccess: {})
}
