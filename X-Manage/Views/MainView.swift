//
//  MainView.swift
//  X-Manage
//
//  主视图 - 侧边栏导航

import SwiftUI

// MARK: - 导航项
enum NavigationItem: String, Hashable, Identifiable {
    // 概览
    case dashboard = "仪表板"
    case backgroundUploads = "上传任务"

    // 漫画管理
    case comicList = "漫画列表"
    case comicPricing = "漫画定价"
    case comicOrders = "漫画订单"
    case comicTasks = "任务管理"

    // 游戏管理
    case gameList = "游戏列表"
    case gamePricing = "游戏定价"
    case gameOrders = "游戏订单"

    // 小说管理
    case novelList = "小说列表"
    case novelPricing = "小说定价"
    case novelOrders = "小说订单"

    // 动漫管理
    case animeList = "动漫列表"
    case animePricing = "动漫定价"
    case animeOrders = "动漫订单"
    case animeTranscode = "转码管理"

    // 系统管理
    case users = "用户管理"
    case memberships = "会员管理"
    case categories = "分类管理"
    case tags = "标签管理"

    // 运营管理
    case comments = "评论管理"
    case tickets = "工单管理"
    case faqKnowledge = "FAQ 知识库"
    case emails = "邮件管理"
    case payments = "支付订单"
    case paymentAppeals = "支付申诉"

    // 系统
    case appVersions = "版本列表"
    case appDevices = "设备列表"
    case appUpdateLogs = "更新日志"
    case systemConfig = "系统配置"
    case cdnManagement = "CDN管理"
    case settings = "系统设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .backgroundUploads: return "arrow.up.circle"
        case .comicList: return "book.closed"
        case .comicPricing: return "dollarsign.circle"
        case .comicOrders: return "list.clipboard"
        case .comicTasks: return "arrow.up.doc"
        case .gameList: return "gamecontroller"
        case .gamePricing: return "dollarsign.circle"
        case .gameOrders: return "list.clipboard"
        case .novelList: return "text.book.closed"
        case .novelPricing: return "dollarsign.circle"
        case .novelOrders: return "list.clipboard"
        case .animeList: return "play.tv"
        case .animePricing: return "dollarsign.circle"
        case .animeOrders: return "list.clipboard"
        case .animeTranscode: return "waveform"
        case .users: return "person.2.fill"
        case .memberships: return "crown.fill"
        case .categories: return "folder.fill"
        case .tags: return "tag.fill"
        case .comments: return "bubble.left.and.bubble.right.fill"
        case .tickets: return "ticket.fill"
        case .faqKnowledge: return "sparkles.rectangle.stack"
        case .emails: return "envelope.fill"
        case .payments: return "creditcard.fill"
        case .paymentAppeals: return "exclamationmark.bubble.fill"
        case .appVersions: return "app.badge"
        case .appDevices: return "iphone.gen3"
        case .appUpdateLogs: return "doc.text.magnifyingglass"
        case .systemConfig: return "server.rack"
        case .cdnManagement: return "cloud.fill"
        case .settings: return "gear"
        }
    }
}

// MARK: - 内容管理分组
enum ContentGroup: String, CaseIterable, Identifiable {
    case comics = "漫画管理"
    case games = "游戏管理"
    case novels = "小说管理"
    case anime = "动漫管理"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .comics: return "book.fill"
        case .games: return "gamecontroller.fill"
        case .novels: return "text.book.closed.fill"
        case .anime: return "play.tv.fill"
        }
    }

    var items: [NavigationItem] {
        switch self {
        case .comics: return [.comicList, .comicPricing, .comicOrders, .comicTasks]
        case .games: return [.gameList, .gamePricing, .gameOrders]
        case .novels: return [.novelList, .novelPricing, .novelOrders]
        case .anime: return [.animeList, .animePricing, .animeOrders, .animeTranscode]
        }
    }
}

// MARK: - 系统分组
enum SystemGroup: String, CaseIterable, Identifiable {
    case appVersion = "版本管理"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appVersion: return "app.badge.fill"
        }
    }

    var items: [NavigationItem] {
        switch self {
        case .appVersion: return [.appVersions, .appDevices, .appUpdateLogs]
        }
    }
}

// MARK: - 主视图
struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject private var uploadManager = BackgroundUploadManager.shared
    @State private var selectedItem: NavigationItem = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var expandedGroups: Set<ContentGroup> = []
    @State private var expandedSystemGroups: Set<SystemGroup> = []

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            List(selection: $selectedItem) {
                // 概览
                Section("概览") {
                    NavigationLink(value: NavigationItem.dashboard) {
                        Label("仪表板", systemImage: "chart.pie.fill")
                    }
                    NavigationLink(value: NavigationItem.backgroundUploads) {
                        HStack {
                            Label("上传任务", systemImage: "arrow.up.circle")
                            Spacer()
                            if uploadManager.activeCount > 0 {
                                Text("\(uploadManager.activeCount)")
                                    .font(.caption2.monospacedDigit())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.blue, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                // 内容管理（带子菜单）
                Section("内容管理") {
                    ForEach(ContentGroup.allCases) { group in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedGroups.contains(group) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedGroups.insert(group)
                                    } else {
                                        expandedGroups.remove(group)
                                    }
                                }
                            )
                        ) {
                            ForEach(group.items) { item in
                                NavigationLink(value: item) {
                                    Label(item.rawValue, systemImage: item.icon)
                                }
                            }
                        } label: {
                            Label(group.rawValue, systemImage: group.icon)
                        }
                    }
                }

                // 系统管理
                Section("系统管理") {
                    NavigationLink(value: NavigationItem.users) {
                        Label("用户管理", systemImage: "person.2.fill")
                    }
                    NavigationLink(value: NavigationItem.memberships) {
                        Label("会员管理", systemImage: "crown.fill")
                    }
                    NavigationLink(value: NavigationItem.categories) {
                        Label("分类管理", systemImage: "folder.fill")
                    }
                    NavigationLink(value: NavigationItem.tags) {
                        Label("标签管理", systemImage: "tag.fill")
                    }
                }

                // 运营管理
                Section("运营管理") {
                    NavigationLink(value: NavigationItem.comments) {
                        Label("评论管理", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    NavigationLink(value: NavigationItem.tickets) {
                        Label("工单管理", systemImage: "ticket.fill")
                    }
                    NavigationLink(value: NavigationItem.faqKnowledge) {
                        Label("FAQ 知识库", systemImage: "sparkles.rectangle.stack")
                    }
                    NavigationLink(value: NavigationItem.emails) {
                        Label("邮件管理", systemImage: "envelope.fill")
                    }
                    NavigationLink(value: NavigationItem.payments) {
                        Label("支付订单", systemImage: "creditcard.fill")
                    }
                    NavigationLink(value: NavigationItem.paymentAppeals) {
                        Label("支付申诉", systemImage: "exclamationmark.bubble.fill")
                    }
                }

                // 系统
                Section("系统") {
                    ForEach(SystemGroup.allCases) { group in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSystemGroups.contains(group) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedSystemGroups.insert(group)
                                    } else {
                                        expandedSystemGroups.remove(group)
                                    }
                                }
                            )
                        ) {
                            ForEach(group.items) { item in
                                NavigationLink(value: item) {
                                    Label(item.rawValue, systemImage: item.icon)
                                }
                            }
                        } label: {
                            Label(group.rawValue, systemImage: group.icon)
                        }
                    }

                    NavigationLink(value: NavigationItem.systemConfig) {
                        Label("系统配置", systemImage: "server.rack")
                    }
                    NavigationLink(value: NavigationItem.cdnManagement) {
                        Label("CDN管理", systemImage: "cloud.fill")
                    }
                    NavigationLink(value: NavigationItem.settings) {
                        Label("系统设置", systemImage: "gear")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .toolbar {
                ToolbarItem {
                    Button {
                        authManager.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .help("退出登录")
                }
            }
        } detail: {
            // 详情视图
            contentView(for: selectedItem)
        }
        .navigationTitle(selectedItem.rawValue)
    }

    @ViewBuilder
    private func contentView(for item: NavigationItem) -> some View {
        switch item {
        case .dashboard:
            DashboardView()
        case .backgroundUploads:
            BackgroundUploadTasksView()

        // 漫画
        case .comicList:
            ComicListContentView()
        case .comicPricing:
            ComicPricingListView()
        case .comicOrders:
            ComicOrderListView()
        case .comicTasks:
            ComicUploadTasksView()

        // 游戏
        case .gameList:
            GameListContentView()
        case .gamePricing:
            GamePricingListView()
        case .gameOrders:
            GameOrderListView()

        // 小说
        case .novelList:
            NovelListContentView()
        case .novelPricing:
            NovelPricingListView()
        case .novelOrders:
            NovelOrderListView()

        // 动漫
        case .animeList:
            AnimeListContentView()
        case .animePricing:
            AnimePricingListView()
        case .animeOrders:
            AnimeOrderListView()
        case .animeTranscode:
            AnimeTranscodeView()

        // 其他
        case .users:
            UserListView()
        case .memberships:
            MembershipListView()
        case .categories:
            CategoryListView()
        case .tags:
            TagListView()
        case .comments:
            CommentListView()
        case .tickets:
            TicketListView()
        case .faqKnowledge:
            FAQGeneratorView()
        case .emails:
            EmailListView()
        case .payments:
            PaymentListView()
        case .paymentAppeals:
            PaymentAppealListView()
        case .appVersions:
            AppVersionListView()
        case .appDevices:
            DeviceListView()
        case .appUpdateLogs:
            UpdateLogListView()
        case .systemConfig:
            SystemConfigView()
        case .cdnManagement:
            CDNManagementView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainView()
}
