//
//  AppVersionDetailView.swift
//  X-Manage
//
//  应用版本详情视图

import SwiftUI
import CryptoKit

struct AppVersionDetailView: View {
    @State var version: AppVersion
    let onUpdate: ((AppVersion) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // 上传状态
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadStatus: String = ""
    @State private var errorMessage: String?

    private let versionService = AppVersionService.shared
    private let uploadService = UploadService.shared

    init(version: AppVersion, onUpdate: ((AppVersion) -> Void)? = nil) {
        self._version = State(initialValue: version)
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("版本详情")
                        .font(.headline)
                    Text("\(version.platformEnum?.displayName ?? version.platform) - \(version.version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: version.statusEnum ?? .draft)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // 版本信息
                    GroupBox("版本信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                            GridRow {
                                Text("ID")
                                    .foregroundStyle(.secondary)
                                Text("\(version.id)")
                                    .font(.body.monospaced())
                            }
                            GridRow {
                                Text("版本号")
                                    .foregroundStyle(.secondary)
                                Text(version.version)
                                    .font(.body.monospaced())
                            }
                            GridRow {
                                Text("Build号")
                                    .foregroundStyle(.secondary)
                                Text("\(version.buildNumber)")
                                    .font(.body.monospaced())
                            }
                            GridRow {
                                Text("平台")
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: version.platformEnum?.iconName ?? "questionmark")
                                    Text(version.platformEnum?.displayName ?? version.platform)
                                }
                            }
                            GridRow {
                                Text("更新类型")
                                    .foregroundStyle(.secondary)
                                Text(version.updateTypeEnum?.displayName ?? version.updateType)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(version.updateTypeEnum == .required ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .foregroundStyle(version.updateTypeEnum == .required ? .red : .blue)
                                    .clipShape(Capsule())
                            }
                            if let minVersion = version.minVersion, !minVersion.isEmpty {
                                GridRow {
                                    Text("最低版本")
                                        .foregroundStyle(.secondary)
                                    Text(minVersion)
                                        .font(.body.monospaced())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }

                    // 基本信息
                    GroupBox("基本信息") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("标题")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(version.title)
                            }

                            if let desc = version.description, !desc.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("更新说明")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(desc)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }

                    // 安装包上传
                    GroupBox("安装包") {
                        VStack(spacing: 12) {
                            if let url = version.downloadUrl, !url.isEmpty {
                                // 已上传状态
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("已上传")
                                            .font(.headline)
                                        Spacer()
                                        Button("重新上传") {
                                            selectAndUploadFile()
                                        }
                                        .disabled(isUploading)
                                    }

                                    Divider()

                                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                                        GridRow {
                                            Text("下载链接")
                                                .foregroundStyle(.secondary)
                                            Text(url)
                                                .font(.caption.monospaced())
                                                .textSelection(.enabled)
                                                .lineLimit(2)
                                        }
                                        GridRow {
                                            Text("文件大小")
                                                .foregroundStyle(.secondary)
                                            Text(version.formattedFileSize)
                                        }
                                        if let md5 = version.md5, !md5.isEmpty {
                                            GridRow {
                                                Text("MD5")
                                                    .foregroundStyle(.secondary)
                                                Text(md5)
                                                    .font(.caption.monospaced())
                                                    .textSelection(.enabled)
                                            }
                                        }
                                        if let updaterUrl = version.updaterUrl, !updaterUrl.isEmpty {
                                            GridRow {
                                                Text("自动更新产物")
                                                    .foregroundStyle(.secondary)
                                                Text(updaterUrl)
                                                    .font(.caption.monospaced())
                                                    .textSelection(.enabled)
                                                    .lineLimit(2)
                                            }
                                        }
                                        if let signature = version.signature, !signature.isEmpty {
                                            GridRow {
                                                Text("签名")
                                                    .foregroundStyle(.secondary)
                                                Text(signature)
                                                    .font(.caption.monospaced())
                                                    .textSelection(.enabled)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // 未上传状态
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.up.doc")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.secondary)

                                    Text("暂未上传安装包")
                                        .foregroundStyle(.secondary)

                                    Button {
                                        selectAndUploadFile()
                                    } label: {
                                        Label("选择并上传\(version.platformEnum == .android ? "APK" : "安装包")", systemImage: "plus.circle")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isUploading)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }

                            // 上传进度
                            if isUploading {
                                Divider()
                                VStack(spacing: 8) {
                                    ProgressView(value: uploadProgress)
                                    Text(uploadStatus)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // 错误信息
                            if let error = errorMessage {
                                Divider()
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }

                    // 自动更新 (Tauri) —— 仅桌面端
                    if isDesktopPlatform {
                        GroupBox("自动更新 (Tauri)") {
                            VStack(alignment: .leading, spacing: 12) {
                                // 更新产物 (.nsis.zip)
                                if let updaterUrl = version.updaterUrl, !updaterUrl.isEmpty {
                                    HStack(alignment: .top) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("更新产物已上传")
                                                .font(.subheadline)
                                            Text(updaterUrl)
                                                .font(.caption.monospaced())
                                                .textSelection(.enabled)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Button("替换") { selectAndUploadUpdater() }
                                            .disabled(isUploading)
                                    }
                                } else {
                                    HStack {
                                        Text("暂未上传更新产物 (.nsis.zip)")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Button {
                                            selectAndUploadUpdater()
                                        } label: {
                                            Label("上传 .nsis.zip", systemImage: "plus.circle")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(isUploading)
                                    }
                                }

                                Divider()

                                // 签名 (.sig)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("签名 (.sig)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let sig = version.signature, !sig.isEmpty {
                                            Text(sig)
                                                .font(.caption.monospaced())
                                                .textSelection(.enabled)
                                                .lineLimit(2)
                                        } else {
                                            Text("未设置")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button("选择 .sig 文件") { selectAndUploadSignature() }
                                        .disabled(isUploading)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                    }

                    // 时间信息
                    GroupBox("时间信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                            if let releaseTime = version.releaseTime {
                                GridRow {
                                    Text("发布时间")
                                        .foregroundStyle(.secondary)
                                    Text(formatDate(releaseTime))
                                }
                            }
                            if let createdAt = version.createdAt {
                                GridRow {
                                    Text("创建时间")
                                        .foregroundStyle(.secondary)
                                    Text(formatDate(createdAt))
                                }
                            }
                            if let updatedAt = version.updatedAt {
                                GridRow {
                                    Text("更新时间")
                                        .foregroundStyle(.secondary)
                                    Text(formatDate(updatedAt))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 700)
    }

    // MARK: - 上传逻辑

    private func selectAndUploadFile() {
        guard let platform = version.platformEnum else { return }

        // 选择文件
        guard let fileUrl = uploadService.selectAppPackage(platform: platform) else {
            return
        }

        Task {
            await uploadFile(fileUrl)
        }
    }

    private func uploadFile(_ fileUrl: URL) async {
        isUploading = true
        uploadProgress = 0
        uploadStatus = "准备上传..."
        errorMessage = nil

        do {
            // 读取文件信息
            let fileName = fileUrl.lastPathComponent
            let fileData = try Data(contentsOf: fileUrl)
            let fileSize = fileData.count

            // 计算 MD5
            uploadStatus = "计算文件校验值..."
            uploadProgress = 0.1
            let md5Hash = calculateMD5(data: fileData)

            // 获取上传URL
            uploadStatus = "获取上传地址..."
            uploadProgress = 0.2

            let contentType = version.platformEnum == .android
                ? "application/vnd.android.package-archive"
                : "application/octet-stream"

            let uploadUrlResponse = try await versionService.getUploadUrl(
                versionId: version.id,
                fileName: fileName,
                contentType: contentType,
                fileSize: fileSize
            )

            // 上传文件到预签名URL
            uploadStatus = "正在上传文件..."
            uploadProgress = 0.3

            try await uploadToPresignedUrl(
                uploadUrlResponse.uploadUrl,
                data: fileData,
                contentType: contentType
            )

            uploadProgress = 0.8

            // 确认上传
            uploadStatus = "确认上传..."
            let confirmRequest = ConfirmUploadRequest(
                downloadUrl: uploadUrlResponse.downloadUrl,
                fileSize: fileSize,
                md5: md5Hash
            )

            let updatedVersion = try await versionService.confirmUpload(
                versionId: version.id,
                request: confirmRequest
            )

            uploadProgress = 1.0
            uploadStatus = "上传完成"

            // 更新本地状态
            await MainActor.run {
                version = updatedVersion
                onUpdate?(updatedVersion)
                isUploading = false
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
            }
        }
    }

    // 是否桌面端（Tauri 自动更新仅适用于桌面）
    private var isDesktopPlatform: Bool {
        switch version.platformEnum {
        case .windows, .macos, .linux: return true
        default: return false
        }
    }

    // MARK: - 自动更新产物上传

    private func selectAndUploadUpdater() {
        guard let fileUrl = uploadService.selectUpdaterArtifact() else { return }
        Task { await uploadUpdater(fileUrl) }
    }

    private func uploadUpdater(_ fileUrl: URL) async {
        isUploading = true
        uploadProgress = 0
        uploadStatus = "准备上传更新产物..."
        errorMessage = nil

        do {
            let fileName = fileUrl.lastPathComponent
            let fileData = try Data(contentsOf: fileUrl)
            let fileSize = fileData.count
            let contentType = "application/zip"

            uploadStatus = "获取上传地址..."
            uploadProgress = 0.2
            let uploadUrlResponse = try await versionService.getUploadUrl(
                versionId: version.id,
                fileName: fileName,
                contentType: contentType,
                fileSize: fileSize
            )

            uploadStatus = "正在上传更新产物..."
            uploadProgress = 0.3
            try await uploadToPresignedUrl(uploadUrlResponse.uploadUrl, data: fileData, contentType: contentType)

            uploadProgress = 0.8
            uploadStatus = "保存更新地址..."
            // 将上传后的公开地址写入 updater_url（自动更新器下载此产物）
            let updated = try await versionService.update(
                id: version.id,
                request: UpdateAppVersionRequest(updaterUrl: uploadUrlResponse.downloadUrl)
            )

            uploadProgress = 1.0
            uploadStatus = "上传完成"
            await MainActor.run {
                version = updated
                onUpdate?(updated)
                isUploading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
            }
        }
    }

    private func selectAndUploadSignature() {
        guard let fileUrl = uploadService.selectSignatureFile() else { return }
        Task { await uploadSignature(fileUrl) }
    }

    private func uploadSignature(_ fileUrl: URL) async {
        isUploading = true
        uploadStatus = "读取签名文件..."
        errorMessage = nil

        do {
            let content = try String(contentsOf: fileUrl, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else {
                throw UploadError.invalidResponse
            }
            // .sig 文本内容即签名字符串，直接写入 signature
            let updated = try await versionService.update(
                id: version.id,
                request: UpdateAppVersionRequest(signature: content)
            )
            await MainActor.run {
                version = updated
                onUpdate?(updated)
                isUploading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
            }
        }
    }

    private func uploadToPresignedUrl(_ url: String, data: Data, contentType: String) async throws {
        guard let uploadUrl = URL(string: url) else {
            throw UploadError.invalidUrl
        }

        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw UploadError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }

    private func calculateMD5(data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        // 尝试不带毫秒的格式
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AppVersionDetailView(
        version: AppVersion(
            id: 1,
            version: "1.0.0",
            buildNumber: 100,
            platform: "IOS",
            status: "PUBLISHED",
            title: "首次发布",
            updateType: "OPTIONAL",
            description: "这是首个正式版本，包含以下功能：\n- 用户注册登录\n- 内容浏览\n- 个人中心",
            downloadUrl: "https://example.com/download/app-1.0.0.ipa",
            updaterUrl: nil,
            fileSize: 52428800,
            md5: "abc123def456",
            signature: nil,
            minVersion: nil,
            minOsVersion: "iOS 14.0",
            releaseTime: "2024-01-15T10:30:00Z",
            createdAt: "2024-01-10T08:00:00Z",
            updatedAt: "2024-01-15T10:30:00Z"
        )
    )
}
