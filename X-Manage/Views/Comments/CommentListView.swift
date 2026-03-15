//
//  CommentListView.swift
//  X-Manage
//
//  评论列表视图

import SwiftUI

// MARK: - 评论类型
enum CommentType: String, CaseIterable {
    case comic = "漫画"
    case game = "游戏"
    case novel = "小说"
    case anime = "动漫"

    var icon: String {
        switch self {
        case .comic: return "book"
        case .game: return "gamecontroller"
        case .novel: return "text.book.closed"
        case .anime: return "play.tv"
        }
    }
}

// MARK: - 评论列表视图
struct CommentListView: View {
    @State private var selectedType: CommentType = .comic
    @State private var searchText = ""
    @State private var selectedStatus: String?

    var body: some View {
        // 内容区域
        Group {
            switch selectedType {
            case .comic:
                ComicCommentListView(searchText: $searchText, selectedStatus: $selectedStatus)
            case .game:
                GameCommentListView(searchText: $searchText, selectedStatus: $selectedStatus)
            case .novel:
                NovelCommentListView(searchText: $searchText, selectedStatus: $selectedStatus)
            case .anime:
                AnimeCommentListView(searchText: $searchText, selectedStatus: $selectedStatus)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                // 类型选择器
                HStack(spacing: 2) {
                    ForEach(CommentType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.caption)
                                Text(type.rawValue)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedType == type ? Color.accentColor : Color.clear)
                            .foregroundStyle(selectedType == type ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            ToolbarItem(placement: .automatic) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索评论...", text: $searchText)
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

            ToolbarItem(placement: .automatic) {
                // 状态筛选
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as String?)
                    Text("待审核").tag("COMMENT_PENDING" as String?)
                    Text("已通过").tag("COMMENT_APPROVED" as String?)
                    Text("已拒绝").tag("COMMENT_REJECTED" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
    }
}

// MARK: - 漫画评论列表
struct ComicCommentListView: View {
    @StateObject private var viewModel = ComicCommentListViewModel()
    @Binding var searchText: String
    @Binding var selectedStatus: String?
    @State private var selectedComments: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            // 批量操作栏
            if selectedComments.count > 0 {
                batchActionBar
                Divider()
            }

            // 内容
            if viewModel.isLoading && viewModel.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                ContentUnavailableView(
                    "暂无评论",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("暂无符合条件的评论")
                )
            } else {
                List(viewModel.comments, selection: $selectedComments) { comment in
                    ComicCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveComment(comment) },
                        onReject: { viewModel.rejectComment(comment) },
                        onDelete: { viewModel.deleteComment(comment) },
                        onToggleTop: { viewModel.toggleTop(comment) }
                    )
                    .tag(comment.id)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // 分页
            if !viewModel.comments.isEmpty {
                Divider()
                HStack {
                    Button {
                        Task { await viewModel.loadComments(page: viewModel.currentPage) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()

                    PaginationView(
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadComments(page: page) }
                        }
                    )
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.keyword = newValue
            Task { await viewModel.loadComments() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadComments() }
        }
    }

    private var batchActionBar: some View {
        HStack(spacing: 12) {
            Text("已选择 \(selectedComments.count) 条")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("批量通过") {
                viewModel.batchApprove(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button("批量拒绝") {
                viewModel.batchReject(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("批量删除") {
                viewModel.batchDelete(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button("取消选择") {
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.05))
    }
}

// MARK: - 漫画评论行
struct ComicCommentRow: View {
    let comment: ComicComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void
    let onToggleTop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部信息
            HStack {
                // 用户信息
                HStack(spacing: 8) {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String((comment.username ?? "U").prefix(1)).uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            if let role = comment.userRole {
                                RoleBadge(role: role)
                            }
                        }
                        if let title = comment.comicTitle {
                            Text("评论了 \(title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("漫画ID: \(comment.comicId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // 状态和时间
                HStack(spacing: 8) {
                    if comment.isTop == true {
                        Label("置顶", systemImage: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    CommentStatusBadge(status: comment.status)
                    Text(formatDateTime(comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 评论内容
            Text(comment.content)
                .font(.body)
                .lineLimit(3)

            // 统计信息
            HStack(spacing: 16) {
                Label("\(comment.likeCount ?? 0)", systemImage: "heart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(comment.replyCount ?? 0)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // 操作按钮
                commentActionButtons(
                    status: comment.status,
                    isTop: comment.isTop ?? false,
                    onApprove: onApprove,
                    onReject: onReject,
                    onDelete: onDelete,
                    onToggleTop: onToggleTop
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 游戏评论列表
struct GameCommentListView: View {
    @StateObject private var viewModel = GameCommentListViewModel()
    @Binding var searchText: String
    @Binding var selectedStatus: String?
    @State private var selectedComments: Set<Int> = []
    @State private var editingComment: GameComment?
    @State private var replyingComment: GameComment?

    var body: some View {
        VStack(spacing: 0) {
            // 批量操作栏
            if selectedComments.count > 0 {
                batchActionBar
                Divider()
            }

            // 内容
            if viewModel.isLoading && viewModel.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                ContentUnavailableView(
                    "暂无评论",
                    systemImage: "gamecontroller",
                    description: Text("暂无符合条件的评论")
                )
            } else {
                List(viewModel.comments, selection: $selectedComments) { comment in
                    GameCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveComment(comment) },
                        onReject: { viewModel.rejectComment(comment) },
                        onDelete: { viewModel.deleteComment(comment) },
                        onToggleTop: { viewModel.toggleTop(comment) },
                        onEdit: { editingComment = comment },
                        onReply: { replyingComment = comment }
                    )
                    .tag(comment.id)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // 分页
            if !viewModel.comments.isEmpty {
                Divider()
                HStack {
                    Button {
                        Task { await viewModel.loadComments(page: viewModel.currentPage) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()

                    PaginationView(
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadComments(page: page) }
                        }
                    )
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.keyword = newValue
            Task { await viewModel.loadComments() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadComments() }
        }
        .sheet(item: $editingComment) { comment in
            GameCommentEditSheet(comment: comment) { newContent in
                viewModel.editComment(comment, content: newContent)
            }
        }
        .sheet(item: $replyingComment) { comment in
            GameCommentReplySheet(comment: comment) { content in
                viewModel.replyComment(comment, content: content)
            }
        }
    }

    private var batchActionBar: some View {
        HStack(spacing: 12) {
            Text("已选择 \(selectedComments.count) 条")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("批量通过") {
                viewModel.batchApprove(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button("批量拒绝") {
                viewModel.batchReject(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("批量删除") {
                viewModel.batchDelete(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button("取消选择") {
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.05))
    }
}

// MARK: - 游戏评论编辑弹窗
struct GameCommentEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let comment: GameComment
    let onSave: (String) -> Void

    @State private var content: String

    init(comment: GameComment, onSave: @escaping (String) -> Void) {
        self.comment = comment
        self.onSave = onSave
        _content = State(initialValue: comment.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑评论")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("评论内容")
                    .font(.headline)

                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("原始内容: \(comment.content)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                Button("保存") {
                    onSave(content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - 游戏评论回复弹窗
struct GameCommentReplySheet: View {
    @Environment(\.dismiss) private var dismiss
    let comment: GameComment
    let onReply: (String) -> Void

    @State private var content = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("回复评论")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                GroupBox("原评论") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formatDateTime(comment.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(comment.content)
                            .font(.callout)
                    }
                    .padding()
                }

                Text("回复内容")
                    .font(.headline)

                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                Button("发送回复") {
                    onReply(content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - 游戏评论行
struct GameCommentRow: View {
    let comment: GameComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void
    let onToggleTop: () -> Void
    let onEdit: () -> Void
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部信息
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String((comment.username ?? "U").prefix(1)).uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            if let role = comment.userRole {
                                RoleBadge(role: role)
                            }
                        }
                        Text("评论了 \(comment.gameTitle ?? "游戏#\(comment.gameId)")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if comment.isTop == true {
                        Label("置顶", systemImage: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    CommentStatusBadge(status: comment.status)
                    Text(formatDateTime(comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 回复信息
            if let replyTo = comment.replyTo {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                    Text("回复 @\(replyTo.user?.username ?? "用户"):")
                        .font(.caption)
                    Text(replyTo.content)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(comment.content)
                .font(.body)
                .lineLimit(3)

            HStack(spacing: 16) {
                Label("\(comment.likeCount ?? 0)", systemImage: "heart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(comment.replyCount ?? 0)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // 操作按钮
                gameCommentActionButtons(
                    status: comment.status,
                    isTop: comment.isTop ?? false,
                    onApprove: onApprove,
                    onReject: onReject,
                    onDelete: onDelete,
                    onToggleTop: onToggleTop,
                    onEdit: onEdit,
                    onReply: onReply
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 游戏评论操作按钮
@ViewBuilder
private func gameCommentActionButtons(
    status: String,
    isTop: Bool,
    onApprove: @escaping () -> Void,
    onReject: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onToggleTop: @escaping () -> Void,
    onEdit: @escaping () -> Void,
    onReply: @escaping () -> Void
) -> some View {
    HStack(spacing: 8) {
        if status == "PENDING" {
            Button {
                onApprove()
            } label: {
                Image(systemName: "checkmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.green)
            .help("通过")

            Button {
                onReject()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.orange)
            .help("拒绝")
        }

        Button {
            onToggleTop()
        } label: {
            Image(systemName: isTop ? "pin.slash" : "pin")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isTop ? .orange : .secondary)
        .help(isTop ? "取消置顶" : "置顶")

        Button {
            onEdit()
        } label: {
            Image(systemName: "pencil")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.blue)
        .help("编辑")

        Button {
            onReply()
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.purple)
        .help("回复")

        Button {
            onDelete()
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.red)
        .help("删除")
    }
}

// MARK: - 小说评论列表
struct NovelCommentListView: View {
    @StateObject private var viewModel = NovelCommentListViewModel()
    @Binding var searchText: String
    @Binding var selectedStatus: String?

    var body: some View {
        VStack(spacing: 0) {
            // 内容
            if viewModel.isLoading && viewModel.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                ContentUnavailableView(
                    "暂无评论",
                    systemImage: "text.book.closed",
                    description: Text("暂无符合条件的评论")
                )
            } else {
                List(viewModel.comments) { comment in
                    NovelCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveComment(comment) },
                        onReject: { viewModel.rejectComment(comment) },
                        onDelete: { viewModel.deleteComment(comment) }
                    )
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // 分页
            if !viewModel.comments.isEmpty {
                Divider()
                HStack {
                    Button {
                        Task { await viewModel.loadComments(page: viewModel.currentPage) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()

                    PaginationView(
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadComments(page: page) }
                        }
                    )
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.keyword = newValue
            Task { await viewModel.loadComments() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadComments() }
        }
    }
}

// MARK: - 小说评论行
struct NovelCommentRow: View {
    let comment: NovelComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.cyan.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String((comment.username ?? "U").prefix(1)).uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            if let role = comment.userRole {
                                RoleBadge(role: role)
                            }
                        }
                        Text("评论了 \(comment.novelTitle ?? "小说#\(comment.novelId)")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if comment.isTop == true {
                        Label("置顶", systemImage: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    CommentStatusBadge(status: comment.status)
                    Text(formatDateTime(comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(comment.content)
                .font(.body)
                .lineLimit(3)

            HStack(spacing: 16) {
                if let likes = comment.likeCount {
                    Label("\(likes)", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let replies = comment.replyCount {
                    Label("\(replies)", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                commentActionButtons(
                    status: comment.status,
                    isTop: comment.isTop ?? false,
                    onApprove: onApprove,
                    onReject: onReject,
                    onDelete: onDelete,
                    onToggleTop: nil
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 动漫评论列表
struct AnimeCommentListView: View {
    @StateObject private var viewModel = AnimeCommentListViewModel()
    @Binding var searchText: String
    @Binding var selectedStatus: String?
    @State private var selectedComments: Set<Int> = []
    @State private var editingComment: AnimeComment?
    @State private var replyingComment: AnimeComment?

    var body: some View {
        VStack(spacing: 0) {
            // 批量操作栏
            if selectedComments.count > 0 {
                batchActionBar
                Divider()
            }

            // 内容
            if viewModel.isLoading && viewModel.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                ContentUnavailableView(
                    "暂无评论",
                    systemImage: "play.tv",
                    description: Text("暂无符合条件的评论")
                )
            } else {
                List(viewModel.comments, selection: $selectedComments) { comment in
                    AnimeCommentRow(
                        comment: comment,
                        onApprove: { viewModel.approveComment(comment) },
                        onReject: { viewModel.rejectComment(comment) },
                        onDelete: { viewModel.deleteComment(comment) },
                        onToggleTop: { viewModel.toggleTop(comment) },
                        onEdit: { editingComment = comment },
                        onReply: { replyingComment = comment }
                    )
                    .tag(comment.id)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // 分页
            if !viewModel.comments.isEmpty {
                Divider()
                HStack {
                    Button {
                        Task { await viewModel.loadComments(page: viewModel.currentPage) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()

                    PaginationView(
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onPageChange: { page in
                            Task { await viewModel.loadComments(page: page) }
                        }
                    )
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.keyword = newValue
            Task { await viewModel.loadComments() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadComments() }
        }
        .sheet(item: $editingComment) { comment in
            AnimeCommentEditSheet(comment: comment) { newContent in
                viewModel.editComment(comment, content: newContent)
            }
        }
        .sheet(item: $replyingComment) { comment in
            AnimeCommentReplySheet(comment: comment) { content in
                viewModel.replyComment(comment, content: content)
            }
        }
    }

    private var batchActionBar: some View {
        HStack(spacing: 12) {
            Text("已选择 \(selectedComments.count) 条")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("批量通过") {
                viewModel.batchApprove(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button("批量拒绝") {
                viewModel.batchReject(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Button("批量删除") {
                viewModel.batchDelete(ids: Array(selectedComments))
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button("取消选择") {
                selectedComments.removeAll()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.05))
    }
}

// MARK: - 动漫评论行
struct AnimeCommentRow: View {
    let comment: AnimeComment
    let onApprove: () -> Void
    let onReject: () -> Void
    let onDelete: () -> Void
    let onToggleTop: () -> Void
    let onEdit: () -> Void
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.purple.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String((comment.username ?? "U").prefix(1)).uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            if let role = comment.userRole {
                                RoleBadge(role: role)
                            }
                        }
                        if let title = comment.animeTitle {
                            Text("评论了 \(title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("动漫ID: \(comment.animeId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if comment.isTop == true {
                        Label("置顶", systemImage: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    CommentStatusBadge(status: comment.status)
                    Text(formatDateTime(comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 回复信息
            if let replyToUsername = comment.replyToUsername {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                    Text("回复 @\(replyToUsername)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Text(comment.content)
                .font(.body)
                .lineLimit(3)

            HStack(spacing: 16) {
                Label("\(comment.likeCount ?? 0)", systemImage: "heart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(comment.replyCount ?? 0)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
                    .help("编辑")

                    Button {
                        onReply()
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
                    .help("回复")

                    commentActionButtons(
                        status: comment.status,
                        isTop: comment.isTop ?? false,
                        onApprove: onApprove,
                        onReject: onReject,
                        onDelete: onDelete,
                        onToggleTop: onToggleTop
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 动漫评论编辑弹窗
struct AnimeCommentEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let comment: AnimeComment
    let onSave: (String) -> Void

    @State private var content: String

    init(comment: AnimeComment, onSave: @escaping (String) -> Void) {
        self.comment = comment
        self.onSave = onSave
        _content = State(initialValue: comment.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑评论")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("评论内容")
                    .font(.headline)

                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("原始内容: \(comment.content)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                Button("保存") {
                    onSave(content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - 动漫评论回复弹窗
struct AnimeCommentReplySheet: View {
    @Environment(\.dismiss) private var dismiss
    let comment: AnimeComment
    let onReply: (String) -> Void

    @State private var content = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("回复评论")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                GroupBox("原评论") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(comment.username ?? "用户\(comment.userId)")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formatDateTime(comment.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(comment.content)
                            .font(.callout)
                    }
                    .padding()
                }

                Text("回复内容")
                    .font(.headline)

                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                Button("发送回复") {
                    onReply(content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - 通用操作按钮
@ViewBuilder
private func commentActionButtons(
    status: String,
    isTop: Bool,
    onApprove: @escaping () -> Void,
    onReject: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onToggleTop: (() -> Void)?
) -> some View {
    HStack(spacing: 8) {
        if status == "COMMENT_PENDING" {
            Button {
                onApprove()
            } label: {
                Image(systemName: "checkmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.green)
            .help("通过")

            Button {
                onReject()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.orange)
            .help("拒绝")
        }

        if let onToggleTop = onToggleTop {
            Button {
                onToggleTop()
            } label: {
                Image(systemName: isTop ? "pin.slash" : "pin")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(isTop ? .orange : .secondary)
            .help(isTop ? "取消置顶" : "置顶")
        }

        Button {
            onDelete()
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.red)
        .help("删除")
    }
}

// MARK: - 评论状态徽章
struct CommentStatusBadge: View {
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
        case "COMMENT_PENDING": return "待审核"
        case "COMMENT_APPROVED": return "已通过"
        case "COMMENT_REJECTED": return "已拒绝"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "COMMENT_PENDING": return .orange
        case "COMMENT_APPROVED": return .green
        case "COMMENT_REJECTED": return .red
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 辅助方法
private func formatDateTime(_ dateString: String) -> String {
    guard !dateString.isEmpty else { return "-" }
    return dateString
        .replacingOccurrences(of: "T", with: " ")
        .replacingOccurrences(of: "Z", with: "")
        .prefix(16)
        .description
}

// MARK: - 漫画评论 ViewModel
@MainActor
class ComicCommentListViewModel: ObservableObject {
    @Published var comments: [ComicComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var keyword = ""
    var filterStatus: String?

    private let service = CommentService.shared

    func loadComments(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = CommentListParams(page: page, pageSize: 25)
        params.keyword = keyword.isEmpty ? nil : keyword
        params.status = filterStatus

        do {
            let response = try await service.getComicComments(params: params)
            comments = response.comments
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func approveComment(_ comment: ComicComment) {
        Task {
            do {
                try await service.approveComicComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComment(_ comment: ComicComment) {
        Task {
            do {
                try await service.rejectComicComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComment(_ comment: ComicComment) {
        Task {
            do {
                try await service.deleteComicComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ comment: ComicComment) {
        Task {
            do {
                try await service.setComicCommentTop(id: comment.id, isTop: !(comment.isTop ?? false))
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchApprove(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchApproveComicComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchReject(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchRejectComicComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchDelete(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchDeleteComicComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 游戏评论 ViewModel
@MainActor
class GameCommentListViewModel: ObservableObject {
    @Published var comments: [GameComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var keyword = ""
    var filterStatus: String?

    private let service = CommentService.shared

    func loadComments(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = CommentListParams(page: page, pageSize: 25)
        params.keyword = keyword.isEmpty ? nil : keyword
        params.status = filterStatus

        do {
            let response = try await service.getGameComments(params: params)
            comments = response.comments
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func approveComment(_ comment: GameComment) {
        Task {
            do {
                try await service.approveGameComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComment(_ comment: GameComment) {
        Task {
            do {
                try await service.rejectGameComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComment(_ comment: GameComment) {
        Task {
            do {
                try await service.deleteGameComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchApprove(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchApproveGameComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchReject(ids: [Int], reason: String? = nil) {
        Task {
            do {
                _ = try await service.batchRejectGameComments(ids: ids, reason: reason)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchDelete(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchDeleteGameComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ comment: GameComment) {
        Task {
            do {
                _ = try await service.setGameCommentTop(id: comment.id, isTop: !(comment.isTop ?? false))
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func editComment(_ comment: GameComment, content: String) {
        Task {
            do {
                _ = try await service.editGameComment(id: comment.id, content: content)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func replyComment(_ comment: GameComment, content: String) {
        Task {
            do {
                _ = try await service.replyGameComment(id: comment.id, content: content)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 小说评论 ViewModel
@MainActor
class NovelCommentListViewModel: ObservableObject {
    @Published var comments: [NovelComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var keyword = ""
    var filterStatus: String?

    private let service = CommentService.shared

    func loadComments(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = CommentListParams(page: page, pageSize: 25)
        params.keyword = keyword.isEmpty ? nil : keyword
        params.status = filterStatus

        do {
            let response = try await service.getNovelComments(params: params)
            comments = response.comments
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func approveComment(_ comment: NovelComment) {
        Task {
            do {
                try await service.approveNovelComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComment(_ comment: NovelComment) {
        Task {
            do {
                try await service.rejectNovelComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComment(_ comment: NovelComment) {
        Task {
            do {
                try await service.deleteNovelComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 动漫评论 ViewModel
@MainActor
class AnimeCommentListViewModel: ObservableObject {
    @Published var comments: [AnimeComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var keyword = ""
    var filterStatus: String?

    private let service = CommentService.shared

    func loadComments(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = CommentListParams(page: page, pageSize: 25)
        params.keyword = keyword.isEmpty ? nil : keyword
        params.status = filterStatus

        do {
            let response = try await service.getAnimeComments(params: params)
            comments = response.comments
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func approveComment(_ comment: AnimeComment) {
        Task {
            do {
                try await service.approveAnimeComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func rejectComment(_ comment: AnimeComment) {
        Task {
            do {
                try await service.rejectAnimeComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteComment(_ comment: AnimeComment) {
        Task {
            do {
                try await service.deleteAnimeComment(id: comment.id)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleTop(_ comment: AnimeComment) {
        Task {
            do {
                try await service.setAnimeCommentTop(id: comment.id, isTop: !(comment.isTop ?? false))
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func editComment(_ comment: AnimeComment, content: String) {
        Task {
            do {
                _ = try await service.editAnimeComment(id: comment.id, content: content)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func replyComment(_ comment: AnimeComment, content: String) {
        Task {
            do {
                _ = try await service.replyAnimeComment(id: comment.id, content: content)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchApprove(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchApproveAnimeComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchReject(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchRejectAnimeComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func batchDelete(ids: [Int]) {
        Task {
            do {
                _ = try await service.batchDeleteAnimeComments(ids: ids)
                await loadComments(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    CommentListView()
}
