//
//  CDNNodeCreateView.swift
//  X-Manage
//
//  CDN 节点创建/编辑视图

import SwiftUI

struct CDNNodeCreateView: View {
    let node: CDNNode?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var errorMessage: String?

    // 基础信息
    @State private var name = ""
    @State private var url = ""
    @State private var token = ""
    @State private var description = ""
    @State private var region = ""
    @State private var enabled = true

    // R2 凭证
    @State private var r2AccountId = ""
    @State private var r2AccessKeyId = ""
    @State private var r2SecretAccessKey = ""
    @State private var r2Region = "auto"

    // R2 存储桶
    @State private var animeR2BucketName = ""
    @State private var gameR2BucketName = ""
    @State private var comicR2BucketName = ""
    @State private var novelR2BucketName = ""
    @State private var downloadR2BucketName = ""

    // HMAC
    @State private var signSecret = ""

    // 缓存
    @State private var cacheDir = "/data/cdn-cache"
    @State private var cacheMaxSizeStr = "0"

    // 限流
    @State private var rateLimitEnabled = true
    @State private var rateLimitPerIpStr = "10"
    @State private var segmentRateLimitPerIpStr = "60"
    @State private var imageRateLimitPerIpStr = "30"
    @State private var bandwidthLimitMbpsStr = "0"

    // 日志
    @State private var logLevel = "info"
    @State private var metricsEnabled = true

    // TLS
    @State private var autoCertEmail = ""
    @State private var httpPort = "80"
    @State private var httpsPort = "443"

    var isEdit: Bool { node != nil }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(isEdit ? "编辑节点：\(node?.name ?? "")" : "新建 CDN 节点")
                    .font(.headline)
                Spacer()
                Button("取消") { dismiss() }
            }
            .padding()

            Divider()

            // 表单
            ScrollView {
                VStack(spacing: 0) {
                    Form {
                        // 基础信息
                        Section("基础信息") {
                            TextField("节点名称", text: $name)
                            TextField("cdn-proxy admin 地址（如 http://1.2.3.4:8080）", text: $url)
                            SecureField("Admin Token", text: $token)
                            TextField("备注说明", text: $description)
                            TextField("地区（如 jp、cn、us）", text: $region)
                            Toggle("启用", isOn: $enabled)
                        }

                        // R2 凭证
                        Section("Cloudflare R2 凭证") {
                            TextField("Account ID", text: $r2AccountId)
                            TextField("Access Key ID", text: $r2AccessKeyId)
                            SecureField("Secret Access Key", text: $r2SecretAccessKey)
                            TextField("R2 区域（默认 auto）", text: $r2Region)
                        }

                        // R2 存储桶
                        Section("R2 存储桶") {
                            TextField("动漫视频分片桶（/s/）", text: $animeR2BucketName)
                            TextField("游戏文件桶", text: $gameR2BucketName)
                            TextField("漫画/图片桶（/i/）", text: $comicR2BucketName)
                            TextField("小说资源桶", text: $novelR2BucketName)
                            TextField("付费内容下载桶（/d/）", text: $downloadR2BucketName)
                        }

                        // 安全
                        Section("URL 签名") {
                            SecureField("HMAC 签名密钥", text: $signSecret)
                        }

                        // 磁盘缓存
                        Section("磁盘缓存") {
                            TextField("缓存目录", text: $cacheDir)
                            TextField("最大缓存字节数（0=节点默认）", text: $cacheMaxSizeStr)
                                .onReceive(cacheMaxSizeStr.publisher) { _ in
                                    cacheMaxSizeStr = cacheMaxSizeStr.filter { $0.isNumber }
                                }
                        }

                        // 限流
                        Section("限流配置") {
                            Toggle("启用限流", isOn: $rateLimitEnabled)
                            HStack {
                                Text("下载限流 (req/s/IP)")
                                Spacer()
                                TextField("10", text: $rateLimitPerIpStr)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                            HStack {
                                Text("分片限流 (req/s/IP)")
                                Spacer()
                                TextField("60", text: $segmentRateLimitPerIpStr)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                            HStack {
                                Text("图片限流 (req/s/IP)")
                                Spacer()
                                TextField("30", text: $imageRateLimitPerIpStr)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                            HStack {
                                Text("带宽上限 (MB/s, 0=不限)")
                                Spacer()
                                TextField("0", text: $bandwidthLimitMbpsStr)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                        }

                        // 日志
                        Section("日志与监控") {
                            Picker("日志级别", selection: $logLevel) {
                                Text("debug").tag("debug")
                                Text("info").tag("info")
                                Text("warn").tag("warn")
                                Text("error").tag("error")
                            }
                            Toggle("暴露 /metrics", isOn: $metricsEnabled)
                        }

                        // TLS
                        Section("HTTPS / Let's Encrypt") {
                            TextField("ACME 邮箱（非空时启用 HTTPS）", text: $autoCertEmail)
                            TextField("HTTP 端口（默认 80）", text: $httpPort)
                            TextField("HTTPS 端口（默认 443）", text: $httpsPort)
                        }
                    }
                    .formStyle(.grouped)
                }
            }

            Divider()

            // 底部操作栏
            HStack {
                if let err = errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()
                if isSaving {
                    ProgressView().scaleEffect(0.8)
                }
                Button("保存") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty || isSaving)
            }
            .padding()
        }
        .frame(width: 540, height: 720)
        .onAppear { populateFromNode() }
    }

    private func populateFromNode() {
        guard let node else { return }
        name = node.name
        url = node.url
        description = node.description
        region = node.region
        enabled = node.enabled
        r2AccountId = node.r2AccountId ?? ""
        r2Region = node.r2Region ?? "auto"
        animeR2BucketName = node.animeR2BucketName ?? ""
        gameR2BucketName = node.gameR2BucketName ?? ""
        comicR2BucketName = node.comicR2BucketName ?? ""
        novelR2BucketName = node.novelR2BucketName ?? ""
        downloadR2BucketName = node.downloadR2BucketName ?? ""
        cacheDir = node.cacheDir ?? "/data/cdn-cache"
        cacheMaxSizeStr = "\(node.cacheMaxSize)"
        rateLimitEnabled = node.rateLimitEnabled
        rateLimitPerIpStr = "\(node.rateLimitPerIp)"
        segmentRateLimitPerIpStr = "\(node.segmentRateLimitPerIp)"
        imageRateLimitPerIpStr = "\(node.imageRateLimitPerIp)"
        bandwidthLimitMbpsStr = "\(node.bandwidthLimitMbps)"
        logLevel = node.logLevel
        metricsEnabled = node.metricsEnabled
        autoCertEmail = node.autoCertEmail ?? ""
        httpPort = node.httpPort
        httpsPort = node.httpsPort
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let req = CDNNodeCreateRequest(
            name: name,
            url: url,
            token: token,
            description: description,
            region: region,
            enabled: enabled,
            r2AccountId: r2AccountId,
            r2AccessKeyId: r2AccessKeyId,
            r2SecretAccessKey: r2SecretAccessKey,
            r2Region: r2Region.isEmpty ? "auto" : r2Region,
            animeR2BucketName: animeR2BucketName,
            gameR2BucketName: gameR2BucketName,
            comicR2BucketName: comicR2BucketName,
            novelR2BucketName: novelR2BucketName,
            downloadR2BucketName: downloadR2BucketName,
            signSecret: signSecret,
            cacheDir: cacheDir.isEmpty ? "/data/cdn-cache" : cacheDir,
            cacheMaxSize: Int64(cacheMaxSizeStr) ?? 0,
            rateLimitEnabled: rateLimitEnabled,
            rateLimitPerIp: Int(rateLimitPerIpStr) ?? 10,
            segmentRateLimitPerIp: Int(segmentRateLimitPerIpStr) ?? 60,
            imageRateLimitPerIp: Int(imageRateLimitPerIpStr) ?? 30,
            bandwidthLimitMbps: Int(bandwidthLimitMbpsStr) ?? 0,
            logLevel: logLevel,
            metricsEnabled: metricsEnabled,
            autoCertEmail: autoCertEmail,
            httpPort: httpPort.isEmpty ? "80" : httpPort,
            httpsPort: httpsPort.isEmpty ? "443" : httpsPort
        )
        do {
            if let node {
                _ = try await CDNService.shared.updateNode(node.id, req)
            } else {
                _ = try await CDNService.shared.createNode(req)
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
