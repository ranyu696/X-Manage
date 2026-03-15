//
//  TicketListView.swift
//  X-Manage
//
//  工单列表视图

import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel = TicketListViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: String?
    @State private var selectedCategory: String?
    @State private var selectedTicket: Ticket?

    var body: some View {
        VStack(spacing: 0) {
            contentView
            paginationView
        }
        .task {
            await viewModel.loadTickets()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task { await viewModel.loadTickets() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadTickets() }
        }
        .onChange(of: selectedCategory) { _, newValue in
            viewModel.filterCategory = newValue
            Task { await viewModel.loadTickets() }
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailView(ticket: ticket)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索工单...", text: $searchText)
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
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as String?)
                    Text("待处理").tag("OPEN" as String?)
                    Text("处理中").tag("PENDING" as String?)
                    Text("已解决").tag("RESOLVED" as String?)
                    Text("已关闭").tag("CLOSED" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Picker("分类", selection: $selectedCategory) {
                    Text("全部分类").tag(nil as String?)
                    Text("游戏").tag("GAME" as String?)
                    Text("漫画").tag("COMIC" as String?)
                    Text("小说").tag("NOVEL" as String?)
                    Text("动漫").tag("ANIME" as String?)
                    Text("其他").tag("OTHER" as String?)
                }
                .pickerStyle(.menu)
                .frame(width: 90)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadTickets() }
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
        if viewModel.isLoading && viewModel.tickets.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tickets.isEmpty {
            ContentUnavailableView(
                "暂无工单",
                systemImage: "ticket",
                description: Text("暂无待处理的工单")
            )
        } else {
            List(viewModel.tickets) { ticket in
                TicketRowView(ticket: ticket)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTicket = ticket
                    }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: - 分页
    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.tickets.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadTickets(page: page) }
                }
            )
            .padding()
        }
    }
}

// MARK: - 工单行视图
struct TicketRowView: View {
    let ticket: Ticket

    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .frame(width: 24)

            // 工单信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ticket.title)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    TicketStatusBadge(status: ticket.status)
                }

                Text(ticket.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // 分类和来源
            VStack(alignment: .trailing, spacing: 4) {
                TicketCategoryBadge(category: ticket.category)

                Text(ticket.sourceDisplayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // 回复数和时间
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    Text("\(ticket.replyCount ?? 0)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Text(formatDate(ticket.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        switch ticket.status {
        case "OPEN", "TICKET_OPEN": return "clock"
        case "PENDING", "TICKET_PENDING": return "arrow.triangle.2.circlepath"
        case "RESOLVED", "TICKET_RESOLVED": return "checkmark.circle"
        case "CLOSED", "TICKET_CLOSED": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch ticket.status {
        case "OPEN", "TICKET_OPEN": return .orange
        case "PENDING", "TICKET_PENDING": return .blue
        case "RESOLVED", "TICKET_RESOLVED": return .green
        case "CLOSED", "TICKET_CLOSED": return .gray
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }
}

// MARK: - 工单状态徽章
struct TicketStatusBadge: View {
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
        case "OPEN", "TICKET_OPEN": return "待处理"
        case "PENDING", "TICKET_PENDING": return "处理中"
        case "RESOLVED", "TICKET_RESOLVED": return "已解决"
        case "CLOSED", "TICKET_CLOSED": return "已关闭"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "OPEN", "TICKET_OPEN": return .orange
        case "PENDING", "TICKET_PENDING": return .blue
        case "RESOLVED", "TICKET_RESOLVED": return .green
        case "CLOSED", "TICKET_CLOSED": return .gray
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 工单分类徽章
struct TicketCategoryBadge: View {
    let category: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .foregroundStyle(textColor)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var displayName: String {
        switch category {
        case "GAME": return "游戏"
        case "COMIC": return "漫画"
        case "NOVEL": return "小说"
        case "ANIME": return "动漫"
        case "OTHER": return "其他"
        default: return category
        }
    }

    private var iconName: String {
        switch category {
        case "GAME": return "gamecontroller"
        case "COMIC": return "book"
        case "NOVEL": return "text.book.closed"
        case "ANIME": return "play.tv"
        case "OTHER": return "ellipsis"
        default: return "questionmark"
        }
    }

    private var textColor: Color {
        switch category {
        case "GAME": return .blue
        case "COMIC": return .orange
        case "NOVEL": return .cyan
        case "ANIME": return .purple
        case "OTHER": return .gray
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 工单列表视图模型
@MainActor
class TicketListViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterStatus: String?
    var filterCategory: String?

    private let service = TicketService.shared

    func loadTickets(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = TicketListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.status = filterStatus
        params.category = filterCategory

        do {
            let response = try await service.getList(params: params)
            tickets = response.tickets
            totalPages = response.pagination.totalPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    TicketListView()
}
