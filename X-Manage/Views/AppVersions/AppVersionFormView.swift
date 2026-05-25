//
//  AppVersionFormView.swift
//  X-Manage
//
//  应用版本表单视图

import SwiftUI

struct AppVersionFormView: View {
    enum Mode {
        case create
        case edit(AppVersion)

        var isCreate: Bool {
            if case .create = self { return true }
            return false
        }

        var title: String {
            isCreate ? "新建版本" : "编辑版本"
        }
    }

    let mode: Mode
    let onSave: (AppVersion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    // 表单字段
    @State private var version = ""
    @State private var buildNumber = ""
    @State private var platform: AppPlatform = .ios
    @State private var title = ""
    @State private var description = ""
    @State private var minVersion = ""
    @State private var minOsVersion = ""
    @State private var updateType: AppUpdateType = .optional
    // 编辑模式下使用的字段（自动更新产物 / 签名 改为在详情页上传，不在表单手填）
    @State private var downloadUrl = ""
    @State private var fileSize = ""
    @State private var md5 = ""

    private let service = AppVersionService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text(mode.title)
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // 表单
            Form {
                Section("版本信息") {
                    HStack {
                        TextField("版本号", text: $version, prompt: Text("例如: 1.0.0"))
                            .disabled(!mode.isCreate)
                        TextField("Build号", text: $buildNumber, prompt: Text("例如: 100"))
                            .disabled(!mode.isCreate)
                            .frame(width: 100)
                    }

                    if mode.isCreate {
                        Picker("平台", selection: $platform) {
                            ForEach(AppPlatform.allCases, id: \.self) { p in
                                Label(p.displayName, systemImage: p.iconName)
                                    .tag(p)
                            }
                        }
                    } else {
                        LabeledContent("平台") {
                            if case .edit(let ver) = mode {
                                Label(
                                    ver.platformEnum?.displayName ?? ver.platform,
                                    systemImage: ver.platformEnum?.iconName ?? "questionmark"
                                )
                            }
                        }
                    }

                    Picker("更新类型", selection: $updateType) {
                        ForEach(AppUpdateType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("基本信息") {
                    TextField("标题", text: $title, prompt: Text("版本更新标题"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("更新说明")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .font(.body)
                    }
                }

                Section("其他设置") {
                    if mode.isCreate {
                        TextField("最低支持版本", text: $minVersion, prompt: Text("可选，例如: 1.0.0"))
                        TextField("最低系统版本", text: $minOsVersion, prompt: Text("可选，例如: Android 8.0 / iOS 14.0"))
                    } else if case .edit(let ver) = mode {
                        LabeledContent("最低支持版本") {
                            Text(ver.minVersion ?? "-")
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("最低系统版本") {
                            Text(ver.minOsVersion ?? "-")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 编辑模式下显示下载信息（自动更新产物 .nsis.zip 与签名在「详情页」上传，不在此手填）
                if !mode.isCreate {
                    Section("下载信息") {
                        TextField("下载链接", text: $downloadUrl, prompt: Text("完整安装包，Windows 为 .exe"))
                            .textContentType(.URL)

                        HStack {
                            TextField("文件大小 (字节)", text: $fileSize, prompt: Text("可选"))
                                .frame(maxWidth: .infinity)
                            TextField("MD5", text: $md5, prompt: Text("可选"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // 底部按钮
            HStack {
                if !mode.isCreate {
                    if case .edit(let ver) = mode {
                        Text("ID: \(ver.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid || isLoading)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(width: 500, height: mode.isCreate ? 480 : 580)
        .onAppear {
            loadExistingData()
        }
    }

    private var isValid: Bool {
        if mode.isCreate {
            return !version.isEmpty && !buildNumber.isEmpty && !title.isEmpty
        } else {
            return !title.isEmpty
        }
    }

    private func loadExistingData() {
        if case .edit(let ver) = mode {
            version = ver.version
            buildNumber = String(ver.buildNumber)
            platform = ver.platformEnum ?? .ios
            title = ver.title
            description = ver.description ?? ""
            downloadUrl = ver.downloadUrl ?? ""
            fileSize = ver.fileSize.map { String($0) } ?? ""
            md5 = ver.md5 ?? ""
            minVersion = ver.minVersion ?? ""
            minOsVersion = ver.minOsVersion ?? ""
            updateType = ver.updateTypeEnum ?? .optional
        }
    }

    private func save() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let savedVersion: AppVersion

                if mode.isCreate {
                    let request = CreateAppVersionRequest(
                        version: version,
                        buildNumber: Int(buildNumber) ?? 1,
                        platform: platform,
                        title: title,
                        updateType: updateType,
                        description: description.isEmpty ? nil : description,
                        downloadUrl: nil,
                        fileSize: nil,
                        md5: nil,
                        signature: nil,
                        minVersion: minVersion.isEmpty ? nil : minVersion,
                        minOsVersion: minOsVersion.isEmpty ? nil : minOsVersion
                    )
                    savedVersion = try await service.create(request: request)
                } else if case .edit(let ver) = mode {
                    let request = UpdateAppVersionRequest(
                        title: title,
                        description: description.isEmpty ? nil : description,
                        downloadUrl: downloadUrl.isEmpty ? nil : downloadUrl,
                        fileSize: Int(fileSize),
                        md5: md5.isEmpty ? nil : md5,
                        updateType: updateType
                    )
                    savedVersion = try await service.update(id: ver.id, request: request)
                } else {
                    return
                }

                await MainActor.run {
                    onSave(savedVersion)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview("Create") {
    AppVersionFormView(mode: .create) { _ in }
}
