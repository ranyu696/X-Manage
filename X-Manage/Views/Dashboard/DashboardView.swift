//
//  DashboardView.swift
//  X-Manage
//
//  仪表板视图

import SwiftUI
import Charts

// MARK: - 仪表板视图
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 统计卡片
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "用户总数",
                        value: "\(viewModel.stats.totalUsers)",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    StatCard(
                        title: "漫画总数",
                        value: "\(viewModel.stats.totalComics)",
                        icon: "book.fill",
                        color: .purple
                    )
                    StatCard(
                        title: "游戏总数",
                        value: "\(viewModel.stats.totalGames)",
                        icon: "gamecontroller.fill",
                        color: .green
                    )
                    StatCard(
                        title: "小说总数",
                        value: "\(viewModel.stats.totalNovels)",
                        icon: "text.book.closed.fill",
                        color: .orange
                    )
                }

                // 第二行卡片
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "动漫总数",
                        value: "\(viewModel.stats.totalAnime)",
                        icon: "play.tv.fill",
                        color: .pink
                    )
                    StatCard(
                        title: "今日订单",
                        value: "\(viewModel.stats.todayOrders)",
                        icon: "creditcard.fill",
                        color: .cyan
                    )
                    StatCard(
                        title: "待处理工单",
                        value: "\(viewModel.stats.pendingTickets)",
                        icon: "ticket.fill",
                        color: .red
                    )
                    StatCard(
                        title: "今日收入",
                        value: "¥\(viewModel.stats.todayRevenue)",
                        icon: "yensign.circle.fill",
                        color: .yellow
                    )
                }

                // 收入趋势图 - 全宽
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("收入趋势（近15天）")
                            .font(.headline)

                        Spacer()

                        // 图例
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("成功收入")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text("创建收入")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if viewModel.paymentTrendData.isEmpty {
                        ContentUnavailableView("暂无数据", systemImage: "chart.line.uptrend.xyaxis")
                            .frame(height: 250)
                    } else {
                        PaymentTrendChart(
                            data: viewModel.paymentTrendData,
                            selectedDate: $viewModel.selectedDate
                        )
                        .frame(height: 250)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 最近活动
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近活动")
                        .font(.headline)

                    if viewModel.recentActivities.isEmpty {
                        ContentUnavailableView("暂无活动", systemImage: "clock")
                    } else {
                        ForEach(viewModel.recentActivities) { activity in
                            HStack(spacing: 12) {
                                Image(systemName: activity.icon)
                                    .foregroundStyle(activity.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.title)
                                        .font(.subheadline)
                                    Text(activity.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(activity.time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)

                            if activity.id != viewModel.recentActivities.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
}

// MARK: - 支付趋势图表
struct PaymentTrendChart: View {
    let data: [PaymentChartDataPoint]
    @Binding var selectedDate: String?

    // 缓存日期数组避免重复计算
    private var dates: [String] {
        data.map { $0.date }
    }

    var body: some View {
        Chart {
            // 成功收入线
            ForEach(data, id: \.date) { item in
                LineMark(
                    x: .value("日期", item.date),
                    y: .value("金额", item.successValue),
                    series: .value("类型", "成功收入")
                )
                .foregroundStyle(.green)
                .symbol(Circle())
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("日期", item.date),
                    y: .value("金额", item.successValue),
                    series: .value("类型", "成功收入")
                )
                .foregroundStyle(.green.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }

            // 创建收入线
            ForEach(data, id: \.date) { item in
                LineMark(
                    x: .value("日期", item.date),
                    y: .value("金额", item.createdValue),
                    series: .value("类型", "创建收入")
                )
                .foregroundStyle(.blue)
                .symbol(Circle())
                .interpolationMethod(.catmullRom)
            }

            // 选中指示点
            if let selectedDate = selectedDate,
               let dataPoint = data.first(where: { $0.date == selectedDate }) {
                PointMark(
                    x: .value("日期", selectedDate),
                    y: .value("金额", dataPoint.successValue)
                )
                .foregroundStyle(.green)
                .symbolSize(100)

                PointMark(
                    x: .value("日期", selectedDate),
                    y: .value("金额", dataPoint.createdValue)
                )
                .foregroundStyle(.blue)
                .symbolSize(100)
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 2000)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("¥\(Int(doubleValue))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: dates) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let dateStr = value.as(String.self) {
                        Text(formatChartDateLabel(dateStr))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .overlay(alignment: .topLeading) {
            if let selectedDate = selectedDate,
               let dataPoint = data.first(where: { $0.date == selectedDate }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatChartDateLabel(selectedDate))
                        .font(.caption)
                        .fontWeight(.semibold)
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("成功: ¥\(Int(dataPoint.successValue))")
                            .font(.caption2)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.blue).frame(width: 6, height: 6)
                        Text("创建: ¥\(Int(dataPoint.createdValue))")
                            .font(.caption2)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 2)
                .padding(8)
            }
        }
    }

    private func formatChartDateLabel(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM/dd"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 活动项
struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
    let time: String
}

// MARK: - 仪表板统计数据
struct DashboardStats {
    var totalUsers: Int = 0
    var totalComics: Int = 0
    var totalGames: Int = 0
    var totalNovels: Int = 0
    var totalAnime: Int = 0
    var todayOrders: Int = 0
    var pendingTickets: Int = 0
    var todayRevenue: String = "0.00"
}

// MARK: - 仪表板视图模型
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stats = DashboardStats()
    @Published var paymentTrendData: [PaymentChartDataPoint] = []
    @Published var recentActivities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var selectedDate: String?

    private let paymentService = PaymentService.shared

    func loadData() async {
        isLoading = true

        // 并行加载数据
        async let statsTask: () = loadStats()
        async let trendTask: () = loadPaymentTrend()
        async let activitiesTask: () = loadRecentActivities()

        _ = await (statsTask, trendTask, activitiesTask)

        isLoading = false
    }

    private func loadStats() async {
        // TODO: 从 API 加载真实数据
        // 暂时使用模拟数据
        stats = DashboardStats(
            totalUsers: 12580,
            totalComics: 3240,
            totalGames: 856,
            totalNovels: 1420,
            totalAnime: 320,
            todayOrders: 156,
            pendingTickets: 23,
            todayRevenue: "8,520.50"
        )
    }

    private func loadPaymentTrend() async {
        // 计算15天前的日期
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -14, to: endDate) else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startStr = dateFormatter.string(from: startDate)
        let endStr = dateFormatter.string(from: endDate)

        do {
            let data = try await paymentService.getTrendStats(startDate: startStr, endDate: endStr)
            paymentTrendData = data
        } catch {
            // 如果API失败，使用模拟数据作为回退
            paymentTrendData = generateMockTrendData()
        }
    }

    private func generateMockTrendData() -> [PaymentChartDataPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var data: [PaymentChartDataPoint] = []
        for i in (0..<15).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dateStr = dateFormatter.string(from: date)
                let created = Double.random(in: 5000...15000)
                let success = created * Double.random(in: 0.7...0.95)
                data.append(PaymentChartDataPoint(
                    date: dateStr,
                    createdAmount: String(format: "%.2f", created),
                    successAmount: String(format: "%.2f", success)
                ))
            }
        }
        return data
    }

    private func loadRecentActivities() async {
        recentActivities = [
            ActivityItem(
                icon: "person.fill.badge.plus",
                color: .green,
                title: "新用户注册",
                description: "用户 user123 完成注册",
                time: "2分钟前"
            ),
            ActivityItem(
                icon: "book.fill",
                color: .purple,
                title: "漫画上传",
                description: "《测试漫画》更新了第10章",
                time: "15分钟前"
            ),
            ActivityItem(
                icon: "creditcard.fill",
                color: .blue,
                title: "订单支付",
                description: "用户 vip_member 购买了游戏",
                time: "32分钟前"
            ),
            ActivityItem(
                icon: "ticket.fill",
                color: .red,
                title: "新工单",
                description: "用户提交了问题反馈",
                time: "1小时前"
            ),
            ActivityItem(
                icon: "bubble.left.fill",
                color: .orange,
                title: "新评论",
                description: "《热门漫画》收到5条新评论",
                time: "2小时前"
            )
        ]
    }
}

// MARK: - 日期格式化辅助函数
private func formatDateLabel(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd"

    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "MM/dd"

    if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    return dateString
}

#Preview {
    DashboardView()
}
