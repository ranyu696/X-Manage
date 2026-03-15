//
//  UserListView.swift
//  X-Manage
//
//  用户列表视图

import SwiftUI

struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()
    @State private var searchText = ""
    @State private var userIdText = ""
    @State private var publicIdText = ""
    @State private var selectedRole: UserRole?
    @State private var selectedStatus: UserStatus?
    @State private var selectedUser: User?
    @State private var selectedUserId: User.ID?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.users.isEmpty {
                ContentUnavailableView(
                    "暂无用户",
                    systemImage: "person.2",
                    description: Text("暂无符合条件的用户")
                )
            } else {
                Table(viewModel.users, selection: $selectedUserId) {
                    TableColumn("ID") { (user: User) in
                        Text(String(user.id))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .width(60)

                    TableColumn("用户") { (user: User) in
                        HStack(spacing: 8) {
                            // 头像
                            UserAvatarView(username: user.username, role: user.role, avatar: user.avatar, size: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .fontWeight(.medium)
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .width(min: 180, ideal: 220)

                    TableColumn("角色") { user in
                        RoleBadge(role: user.role)
                    }
                    .width(80)

                    TableColumn("状态") { user in
                        UserStatusBadge(status: user.status)
                    }
                    .width(80)

                    TableColumn("余额") { user in
                        Text("¥\(user.balance ?? "0")")
                    }
                    .width(80)

                    TableColumn("注册时间") { user in
                        Text(formatDate(user.createdAt ?? ""))
                    }
                    .width(120)

                    TableColumn("操作") { (user: User) in
                        HStack(spacing: 8) {
                            Button {
                                selectedUser = user
                            } label: {
                                Image(systemName: "eye")
                            }
                            .buttonStyle(.borderless)
                            .help("查看详情")

                            if user.status == "ACTIVE" {
                                Button {
                                    viewModel.banUser(user)
                                } label: {
                                    Image(systemName: "lock")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                                .help("封禁用户")
                            } else if user.status == "BANNED" {
                                Button {
                                    viewModel.unbanUser(user)
                                } label: {
                                    Image(systemName: "lock.open")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.borderless)
                                .help("解除封禁")
                            }
                        }
                    }
                    .width(80)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .id(viewModel.currentPage) // 页面变化时重置滚动位置
            }

            if !viewModel.users.isEmpty {
                Divider()
                PaginationView(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageChange: { page in
                        Task {
                            await viewModel.loadUsers(page: page)
                        }
                    }
                )
                .padding()
            }
        }
        .task {
            await viewModel.loadUsers()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchKeyword = newValue
            Task {
                await viewModel.loadUsers()
            }
        }
        .onChange(of: selectedRole) { _, newValue in
            viewModel.filterRole = newValue
            Task {
                await viewModel.loadUsers()
            }
        }
        .onChange(of: selectedStatus) { _, newValue in
            viewModel.filterStatus = newValue
            Task {
                await viewModel.loadUsers()
            }
        }
        .onChange(of: userIdText) { _, newValue in
            viewModel.filterUserId = Int(newValue)
            Task {
                await viewModel.loadUsers()
            }
        }
        .onChange(of: publicIdText) { _, newValue in
            viewModel.filterPublicId = newValue
            Task {
                await viewModel.loadUsers()
            }
        }
        .onChange(of: selectedUserId) { _, newValue in
            if let userId = newValue,
               let user = viewModel.users.first(where: { $0.id == userId }) {
                selectedUser = user
                selectedUserId = nil // 重置选择，允许再次点击同一行
            }
        }
        .sheet(item: $selectedUser) { user in
            UserDetailView(user: user)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    // 用户名搜索
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索用户名...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 100)
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

                    // 用户 ID 搜索
                    HStack {
                        Text("ID:")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("用户ID", text: $userIdText)
                            .textFieldStyle(.plain)
                            .frame(width: 60)
                        if !userIdText.isEmpty {
                            Button {
                                userIdText = ""
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

                    // 公共 ID 搜索
                    HStack {
                        Text("公共ID:")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("公共ID", text: $publicIdText)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                        if !publicIdText.isEmpty {
                            Button {
                                publicIdText = ""
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
                Picker("角色", selection: $selectedRole) {
                    Text("全部角色").tag(nil as UserRole?)
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.displayName).tag(role as UserRole?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                Picker("状态", selection: $selectedStatus) {
                    Text("全部状态").tag(nil as UserStatus?)
                    ForEach(UserStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as UserStatus?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 90)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await viewModel.loadUsers()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        if let index = dateString.firstIndex(of: "T") {
            return String(dateString[..<index])
        }
        return dateString
    }
}

// MARK: - 角色徽章
struct RoleBadge: View {
    let role: String

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
        switch role {
        case "MEMBER": return "普通会员"
        case "VIP": return "VIP"
        case "SVIP": return "SVIP"
        case "ADMIN": return "管理员"
        case "SUPER_ADMIN": return "超级管理员"
        default: return role
        }
    }

    private var textColor: Color {
        switch role {
        case "MEMBER": return .gray
        case "VIP": return .orange
        case "SVIP": return .purple
        case "ADMIN": return .blue
        case "SUPER_ADMIN": return .red
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

// MARK: - 用户状态徽章
struct UserStatusBadge: View {
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
        case "ACTIVE": return "正常"
        case "BANNED": return "已封禁"
        case "DELETED": return "已删除"
        case "PENDING_VERIFICATION": return "待验证"
        default: return status
        }
    }

    private var textColor: Color {
        switch status {
        case "ACTIVE": return .green
        case "BANNED": return .red
        case "DELETED": return .gray
        case "PENDING_VERIFICATION": return .orange
        default: return .gray
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

@MainActor
class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var totalPages = 1

    var searchKeyword = ""
    var filterUserId: Int?
    var filterPublicId = ""
    var filterRole: UserRole?
    var filterStatus: UserStatus?

    private let service = UserService.shared

    func loadUsers(page: Int = 1) async {
        isLoading = true
        currentPage = page

        var params = UserListParams(page: page, pageSize: 25)
        params.keyword = searchKeyword.isEmpty ? nil : searchKeyword
        params.userId = filterUserId
        params.publicId = filterPublicId.isEmpty ? nil : filterPublicId
        params.role = filterRole
        params.status = filterStatus

        do {
            let response = try await service.getList(params: params)
            users = response.users
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func banUser(_ user: User) {
        Task {
            do {
                try await service.banUser(id: user.id)
                await loadUsers(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func unbanUser(_ user: User) {
        Task {
            do {
                try await service.unbanUser(id: user.id)
                await loadUsers(page: currentPage)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 用户头像视图
struct UserAvatarView: View {
    let username: String
    let role: String
    var avatar: String? = nil
    var size: CGFloat = 32

    var body: some View {
        if let avatarUrl = avatar, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure(_):
                    fallbackAvatar
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(roleGradient)
                .frame(width: size, height: size)
            Text(String(username.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var roleGradient: LinearGradient {
        let colors: [Color] = {
            switch role {
            case "SVIP": return [.purple, .pink]
            case "VIP": return [.orange, .yellow]
            case "ADMIN", "SUPER_ADMIN": return [.blue, .cyan]
            default: return [.gray, .gray.opacity(0.7)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    UserListView()
}
