//
//  MembershipEventsView.swift
//  X-Manage
//
//  会员事件审计（追加写日志）—— 按用户查看会员生命周期溯源

import SwiftUI

// MARK: - 会员事件审计弹窗
struct MembershipEventsSheet: View {
    let username: String
    let events: [MembershipEvent]
    let isLoading: Bool
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("会员事件审计")
                        .font(.headline)
                    Text(username)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            Divider()

            // 内容
            if isLoading && events.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("暂无会员事件记录")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            MembershipEventRow(event: event)
                            Divider()
                        }
                    }
                }
            }

            // 分页
            if !events.isEmpty {
                Divider()
                PaginationView(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPageChange: onPageChange
                )
                .padding()
            }
        }
        .frame(minWidth: 560, minHeight: 480)
        .frame(idealWidth: 640, idealHeight: 560)
    }
}

// MARK: - 会员事件行
struct MembershipEventRow: View {
    let event: MembershipEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(event.eventTypeDisplay)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((event.eventTypeEnum?.color ?? .gray).opacity(0.15))
                    .foregroundStyle(event.eventTypeEnum?.color ?? .gray)
                    .clipShape(Capsule())

                if let before = event.tierBefore, let after = event.tierAfter,
                   !before.isEmpty, before != after {
                    Text("\(before.uppercased()) → \(after.uppercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let after = event.tierAfter, !after.isEmpty {
                    Text(after.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatDateTime(event.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 到期时间变化
            if let after = event.periodEndAfter, !after.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let before = event.periodEndBefore, !before.isEmpty, before != after {
                        Text("到期 \(formatDateTime(before)) → \(formatDateTime(after))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("到期 \(formatDateTime(after))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 操作者 / 来源 / 订单
            HStack(spacing: 12) {
                if let op = event.operatorName, !op.isEmpty {
                    metaItem(icon: "person.crop.circle", text: op)
                }
                if let source = event.source, !source.isEmpty {
                    metaItem(icon: "tag", text: source)
                }
                if let order = event.orderId, !order.isEmpty {
                    metaItem(icon: "doc.text", text: order)
                }
            }

            if let reason = event.reason, !reason.isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    private func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else {
            // 退化：截断 T 之后
            return String(dateString.prefix(16)).replacingOccurrences(of: "T", with: " ")
        }
        let display = DateFormatter()
        display.dateFormat = "yyyy-MM-dd HH:mm"
        return display.string(from: date)
    }
}
