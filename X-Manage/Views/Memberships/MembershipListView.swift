//
//  MembershipListView.swift
//  X-Manage
//
//  会员（订阅权益）列表 —— 查询 memberships 表，支持按等级/状态/来源/到期时间筛选

import SwiftUI

struct MembershipListView: View {
    @StateObject private var viewModel = MembershipListViewModel()
    @State private var searchUserId = ""
    @State private var selectedTier: MembershipTier?
    @State private var selectedStatus: MembershipStatus?
    @State private var selectedSource: MembershipSource?
    @State private var eventsTarget: MembershipEventsTarget?

    var body: some View {
        VStack(spacing: 0) {
            contentView
            paginationView
        }
        .task {
            await viewModel.loadMemberships()
        }
        .onChange(of: selectedTier) { _, newValue in
            viewModel.filterTier = newValue
            Task { await viewModel.loadMemberships() }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task { await viewModel.loadMemberships() }
        }
        .onChange(of: selectedSource) { _, newValue in
            viewModel.filterSource = newValue
            Task { await viewModel.loadMemberships() }
        }
        .sheet(item: $eventsTarget) { target in
            MembershipEventsSheet(
                username: "用户 #\(target.userId)",
                events: viewModel.events,
                isLoading: viewModel.isLoadingEvents,
                currentPage: viewModel.eventsCurrentPage,
                totalPages: viewModel.eventsTotalPages,
                onPageChange: { page in
                    Task { await viewModel.loadEvents(userId: target.userId, page: page) }
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    // 用户ID搜索
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("用户ID", text: $searchUserId)
                            .textFieldStyle(.plain)
                            .frame(width: 70)
                            .onSubmit { performSearch() }
                        if !searchUserId.isEmpty {
                            Button {
                                searchUserId = ""
                                viewModel.filterUserId = nil
                                Task { await viewModel.loadMemberships() }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // 等级筛选
                    Picker("等级", selection: $selectedTier) {
                        Text("全部等级").tag(MembershipTier?.none)
                        ForEach(MembershipTier.allCases, id: \.self) { tier in
                            Text(tier.displayName).tag(MembershipTier?.some(tier))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 110)

                    // 状态筛选
                    Picker("状态", selection: $selectedStatus) {
                        Text("全部状态").tag(MembershipStatus?.none)
                        ForEach(MembershipStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(MembershipStatus?.some(status))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 110)

                    // 来源筛选
                    Picker("来源", selection: $selectedSource) {
                        Text("全部来源").tag(MembershipSource?.none)
                        ForEach(MembershipSource.allCases, id: \.self) { source in
                            Text(source.displayName).tag(MembershipSource?.some(source))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadMemberships() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func performSearch() {
        viewModel.filterUserId = Int(searchUserId)
        Task { await viewModel.loadMemberships() }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.memberships.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.memberships.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "crown")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(hasFilters ? "未找到匹配的会员" : "暂无会员记录")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if hasFilters {
                    Button("清除筛选条件") {
                        clearFilters()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            MembershipTableView(
                memberships: viewModel.memberships,
                onViewEvents: { userId in
                    Task { await viewModel.loadEvents(userId: userId) }
                    eventsTarget = MembershipEventsTarget(userId: userId)
                }
            )
            .id(viewModel.currentPage)
        }
    }

    @ViewBuilder
    private var paginationView: some View {
        if !viewModel.memberships.isEmpty {
            Divider()
            PaginationView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { page in
                    Task { await viewModel.loadMemberships(page: page) }
                }
            )
            .padding()
        }
    }

    private var hasFilters: Bool {
        selectedTier != nil || selectedStatus != nil || selectedSource != nil || !searchUserId.isEmpty
    }

    private func clearFilters() {
        selectedTier = nil
        selectedStatus = nil
        selectedSource = nil
        searchUserId = ""
        viewModel.filterUserId = nil
        Task { await viewModel.loadMemberships() }
    }
}

// MARK: - 会员表格
struct MembershipTableView: View {
    let memberships: [Membership]
    let onViewEvents: (Int) -> Void
    @State private var selectedId: Membership.ID?

    var body: some View {
        Table(memberships, selection: $selectedId) {
            TableColumn("ID") { (m: Membership) in
                Text("\(m.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(50)

            TableColumn("用户ID") { (m: Membership) in
                Text("\(m.userId)")
                    .font(.caption)
            }
            .width(70)

            TableColumn("等级") { (m: Membership) in
                Text(m.tierDisplay)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((m.tierEnum?.color ?? .gray).opacity(0.15))
                    .foregroundStyle(m.tierEnum?.color ?? .gray)
                    .clipShape(Capsule())
            }
            .width(70)

            TableColumn("状态") { (m: Membership) in
                Text(m.statusDisplay)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((m.statusEnum?.color ?? .gray).opacity(0.15))
                    .foregroundStyle(m.statusEnum?.color ?? .gray)
                    .clipShape(Capsule())
            }
            .width(80)

            TableColumn("到期时间") { (m: Membership) in
                Text(formatDateTime(m.currentPeriodEnd))
                    .font(.caption)
                    .foregroundStyle(isExpiringSoon(m.currentPeriodEnd) ? .orange : .primary)
            }
            .width(140)

            TableColumn("来源") { (m: Membership) in
                Text(m.sourceDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(90)

            TableColumn("最近订单") { (m: Membership) in
                Text(m.lastOrderId?.isEmpty == false ? m.lastOrderId! : "-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            TableColumn("操作") { (m: Membership) in
                Button {
                    onViewEvents(m.userId)
                } label: {
                    Label("事件", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .width(70)
        }
    }

    private func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else {
            return String(dateString.prefix(16)).replacingOccurrences(of: "T", with: " ")
        }
        let display = DateFormatter()
        display.dateFormat = "yyyy-MM-dd HH:mm"
        return display.string(from: date)
    }

    private func isExpiringSoon(_ dateString: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else { return false }
        let days = date.timeIntervalSinceNow / 86400
        return days >= 0 && days <= 7
    }
}

// MARK: - ViewModel
@MainActor
class MembershipListViewModel: ObservableObject {
    @Published var memberships: [Membership] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    // 事件审计
    @Published var events: [MembershipEvent] = []
    @Published var isLoadingEvents = false
    @Published var eventsCurrentPage = 1
    @Published var eventsTotalPages = 1

    var filterUserId: Int?
    var filterTier: MembershipTier?
    var filterStatus: MembershipStatus?
    var filterSource: MembershipSource?

    private let service = MembershipService.shared

    func loadMemberships(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = MembershipListParams(page: page, pageSize: 25)
        params.userId = filterUserId
        params.tier = filterTier
        params.status = filterStatus
        params.source = filterSource

        do {
            let response = try await service.getList(params: params)
            memberships = response.memberships
            totalPages = max(response.pagination.totalPages, 1)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadEvents(userId: Int, page: Int = 1) async {
        isLoadingEvents = true
        eventsCurrentPage = page
        do {
            let response = try await service.getEvents(userId: userId, page: page)
            events = response.events
            eventsTotalPages = max(response.pagination.totalPages, 1)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingEvents = false
    }
}

// 会员事件弹窗目标（用于 .sheet(item:)）
struct MembershipEventsTarget: Identifiable {
    let userId: Int
    var id: Int { userId }
}
