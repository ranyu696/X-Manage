//
//  PaymentDetailView.swift
//  X-Manage
//
//  支付订单详情视图

import SwiftUI

struct PaymentDetailView: View {
    let payment: Payment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("支付订单详情")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            // 内容
            ScrollView {
                VStack(spacing: 20) {
                    // 头部信息
                    headerSection

                    // 基本信息
                    basicInfoSection

                    // 支付信息
                    paymentInfoSection

                    // 订单信息
                    orderInfoSection

                    // 设备信息
                    deviceInfoSection

                    // 错误信息（如有）
                    if let errorMessage = payment.errorMessage, !errorMessage.isEmpty {
                        errorSection(errorMessage)
                    }

                    if let failReason = payment.failReason, !failReason.isEmpty {
                        failReasonSection(failReason)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 650)
    }

    // MARK: - 头部信息
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 金额
            Text("¥\(payment.amount)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.green)

            // 状态
            PaymentStatusBadge(status: payment.status)

            // 支付类型
            Text(payment.payTypeDisplayName)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 基本信息
    private var basicInfoSection: some View {
        GroupBox("基本信息") {
            VStack(spacing: 0) {
                DetailRow(title: "支付ID", value: "\(payment.id)")
                Divider()
                DetailRow(title: "用户ID", value: "\(payment.userId)")
                Divider()
                DetailRow(title: "创建时间", value: formatDateTime(payment.createdAt))
                if let updatedAt = payment.updatedAt, !updatedAt.isEmpty {
                    Divider()
                    DetailRow(title: "更新时间", value: formatDateTime(updatedAt))
                }
            }
        }
    }

    // MARK: - 支付信息
    private var paymentInfoSection: some View {
        GroupBox("支付信息") {
            VStack(spacing: 0) {
                HStack {
                    Text("支付方式")
                        .foregroundStyle(.secondary)
                    Spacer()
                    PaymentMethodBadge(method: payment.method)
                }
                .padding(.vertical, 8)

                Divider()

                DetailRow(title: "支付类型", value: payment.payTypeDisplayName)

                if let paidAt = payment.paidAt, !paidAt.isEmpty {
                    Divider()
                    DetailRow(title: "支付时间", value: formatDateTime(paidAt))
                }
            }
        }
    }

    // MARK: - 订单信息
    private var orderInfoSection: some View {
        GroupBox("订单信息") {
            VStack(spacing: 0) {
                if let outTradeNo = payment.outTradeNo, !outTradeNo.isEmpty {
                    DetailRow(title: "外部订单号", value: outTradeNo, canCopy: true)
                    Divider()
                }

                if let tradeNo = payment.tradeNo, !tradeNo.isEmpty {
                    DetailRow(title: "交易号", value: tradeNo, canCopy: true)
                    Divider()
                }

                if let payUrl = payment.payUrl, !payUrl.isEmpty {
                    DetailRow(title: "支付链接", value: payUrl, canCopy: true)
                    Divider()
                }

                if let param = payment.param, !param.isEmpty {
                    DetailRow(title: "参数", value: param)
                }
            }
        }
    }

    // MARK: - 设备信息
    private var deviceInfoSection: some View {
        GroupBox("设备信息") {
            VStack(spacing: 0) {
                HStack {
                    Text("客户端")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(payment.clientTypeDisplayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 8)

                if let ip = payment.ip, !ip.isEmpty {
                    Divider()
                    DetailRow(title: "IP 地址", value: ip)
                }

                if let userAgent = payment.userAgent, !userAgent.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Agent")
                            .foregroundStyle(.secondary)
                        Text(userAgent)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - 错误信息
    private func errorSection(_ message: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("错误信息", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 失败原因
    private func failReasonSection(_ reason: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("失败原因", systemImage: "xmark.circle")
                    .foregroundStyle(.red)
                    .font(.headline)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 格式化日期时间
    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        // 简单格式化：2024-01-01T12:00:00Z -> 2024-01-01 12:00:00
        return dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

// MARK: - 详情行
struct DetailRow: View {
    let title: String
    let value: String
    var canCopy: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            if canCopy {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                } label: {
                    HStack(spacing: 4) {
                        Text(value)
                            .lineLimit(1)
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            } else {
                Text(value)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PaymentDetailView(payment: Payment(
        id: 1,
        userId: 12345,
        amount: "99.00",
        method: "ALIPAY",
        status: "PAID",
        payType: "PAYMENT_VIP",
        param: nil,
        tradeNo: "2024010112345678",
        outTradeNo: "OUT2024010112345678",
        errorMessage: nil,
        failReason: nil,
        payUrl: nil,
        clientType: "IOS",
        ip: "192.168.1.1",
        userAgent: "Mozilla/5.0",
        paidAt: "2024-01-01T12:00:00Z",
        createdAt: "2024-01-01T11:55:00Z",
        updatedAt: "2024-01-01T12:00:00Z"
    ))
}
