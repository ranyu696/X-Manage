//
//  PaymentAppealDetailView.swift
//  X-Manage
//
//  支付申诉审核详情视图

import SwiftUI

struct PaymentAppealDetailView: View {
    let appeal: PaymentAppeal
    var onResolved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // 处理表单状态
    @State private var decision = "approved"
    @State private var adminNote = ""
    @State private var currentStatus: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // 图片预览状态
    @State private var selectedImageURL: String?

    init(appeal: PaymentAppeal, onResolved: (() -> Void)? = nil) {
        self.appeal = appeal
        self.onResolved = onResolved
        self._currentStatus = State(initialValue: appeal.status)
    }

    private var isActionable: Bool {
        currentStatus == AppealStatus.pending.rawValue || currentStatus == AppealStatus.needMoreInfo.rawValue
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    appealInfoSection
                    orderInfoSection
                    ocrSection
                    if !appeal.images.isEmpty {
                        screenshotsSection
                    }
                    descriptionSection
                    resolveSection
                }
                .padding()
            }
        }
        .frame(width: 780, height: 680)
        .overlay {
            if let imageURL = selectedImageURL {
                ImagePreviewOverlay(imageURL: imageURL) {
                    selectedImageURL = nil
                }
            }
        }
    }

    // MARK: - 标题栏
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("支付申诉审核")
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(appeal.publicId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AppealTypeBadge(type: appeal.type)
                    AppealStatusBadge(status: currentStatus)
                }
            }
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
    }

    // MARK: - 申诉信息
    private var appealInfoSection: some View {
        GroupBox("申诉信息") {
            VStack(spacing: 0) {
                InfoRow(title: "申诉ID", value: appeal.publicId)
                Divider()
                InfoRow(title: "用户ID", value: "\(appeal.userId)")
                Divider()
                InfoRow(title: "申诉类型", value: appeal.typeDisplayName)
                Divider()
                InfoRow(title: "创建时间", value: formatDateTime(appeal.createdAt))
                if !appeal.updatedAt.isEmpty {
                    Divider()
                    InfoRow(title: "更新时间", value: formatDateTime(appeal.updatedAt))
                }
            }
        }
    }

    // MARK: - 关联订单
    private var orderInfoSection: some View {
        GroupBox("关联订单") {
            VStack(spacing: 0) {
                InfoRow(title: "商户订单号", value: appeal.outTradeNo.isEmpty ? "-" : appeal.outTradeNo)
                Divider()
                InfoRow(title: "订单金额", value: appeal.orderAmount.isEmpty ? "-" : "¥\(appeal.orderAmount)")
                Divider()
                InfoRow(title: "订单状态", value: appeal.orderStatus.isEmpty ? "-" : appeal.orderStatus)
                Divider()
                InfoRow(title: "订单类型", value: appeal.orderPayType.isEmpty ? "-" : appeal.orderPayType)
            }
        }
    }

    // MARK: - OCR 识别结果
    private var ocrSection: some View {
        GroupBox("OCR 识别结果") {
            VStack(spacing: 0) {
                HStack {
                    Text("预审结果")
                        .foregroundStyle(.secondary)
                    Spacer()
                    AppealOCRBadge(passed: appeal.ocrPassed, platform: appeal.ocrPlatform)
                }
                .padding(.vertical, 8)
                Divider()
                InfoRow(title: "识别平台", value: appeal.ocrPlatformDisplayName)
                Divider()
                InfoRow(title: "识别金额", value: appeal.ocrAmount.isEmpty ? "-" : "¥\(appeal.ocrAmount)")
                Divider()
                InfoRow(title: "识别交易号", value: appeal.ocrTradeNo.isEmpty ? "-" : appeal.ocrTradeNo)
                Divider()
                InfoRow(title: "识别支付时间", value: appeal.ocrPaidAt.isEmpty ? "-" : formatDateTime(appeal.ocrPaidAt))
            }
        }
    }

    // MARK: - 用户截图
    private var screenshotsSection: some View {
        GroupBox("支付截图 (\(appeal.images.count))") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appeal.images, id: \.self) { imagePath in
                        let fullURL = imagePath.hasPrefix("http") ? imagePath : "https://game.xyou.me/\(imagePath)"
                        AsyncImage(url: URL(string: fullURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                        }
                        .frame(width: 140, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            selectedImageURL = fullURL
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 用户描述
    private var descriptionSection: some View {
        GroupBox("用户描述") {
            Text(appeal.description.isEmpty ? "（用户未填写描述）" : appeal.description)
                .font(.body)
                .textSelection(.enabled)
                .foregroundStyle(appeal.description.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
    }

    // MARK: - 处理区域
    @ViewBuilder
    private var resolveSection: some View {
        if isActionable {
            GroupBox("处理申诉") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("处理决定", selection: $decision) {
                        Text("批准（已核实，标记已解决）").tag("approved")
                        Text("驳回").tag("rejected")
                        Text("需补充材料").tag("need_more_info")
                    }
                    .pickerStyle(.radioGroup)

                    Text(noteHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $adminNote)
                        .font(.body)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Text("处理后将自动向用户发送对应邮件通知")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            submit()
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                                Text("提交中...")
                            } else {
                                Label("提交处理", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(decisionTint)
                        .disabled(isSubmitting || (decision != "approved" && adminNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            GroupBox("处理结果") {
                VStack(spacing: 0) {
                    HStack {
                        Text("处理状态")
                            .foregroundStyle(.secondary)
                        Spacer()
                        AppealStatusBadge(status: currentStatus)
                    }
                    .padding(.vertical, 8)
                    if !appeal.adminNote.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("处理说明")
                                .foregroundStyle(.secondary)
                            Text(appeal.adminNote)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                    }
                    if !appeal.resolvedAt.isEmpty {
                        Divider()
                        InfoRow(title: "处理时间", value: formatDateTime(appeal.resolvedAt))
                    }
                }
            }
        }
    }

    private var noteHint: String {
        switch decision {
        case "rejected": return "请填写驳回原因（将通过邮件告知用户）"
        case "need_more_info": return "请说明需要用户补充的材料（将通过邮件告知用户）"
        default: return "处理说明（可选，将通过邮件告知用户）"
        }
    }

    private var decisionTint: Color {
        switch decision {
        case "approved": return .green
        case "rejected": return .red
        default: return .blue
        }
    }

    // MARK: - 提交处理
    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                let updated = try await PaymentAppealService.shared.resolve(
                    publicId: appeal.publicId,
                    decision: decision,
                    adminNote: adminNote
                )
                currentStatus = updated.status
                onResolved?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    // MARK: - 格式化日期时间
    private func formatDateTime(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "-" }
        return dateString
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

#Preview {
    PaymentAppealDetailView(appeal: PaymentAppeal.preview)
}

// MARK: - Preview 数据
extension PaymentAppeal {
    static var preview: PaymentAppeal {
        let json = """
        {
          "id": 1,
          "public_id": "PA-12ab34cd",
          "user_id": 12345,
          "payment_id": 88,
          "out_trade_no": "20240102ABC",
          "type": "paid_not_received",
          "status": "pending",
          "description": "我已用微信支付30元，但VIP没有到账。",
          "images": [],
          "ocr_passed": true,
          "ocr_platform": "wechat",
          "ocr_amount": "30.00",
          "ocr_trade_no": "4200001234",
          "ocr_paid_at": "2024-01-02T15:04:05",
          "admin_note": "",
          "resolved_at": "",
          "created_at": "2024-01-02T15:10:00",
          "updated_at": "2024-01-02T15:10:00",
          "order_amount": "30.00",
          "order_status": "TIMEOUT",
          "order_pay_type": "PAYMENT_VIP"
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(PaymentAppeal.self, from: json)
    }
}
