//
//  BackgroundUploadTasksView.swift
//  X-Manage
//
//  显示客户端正在进行中的分块上传任务（动漫视频 / 漫画 ZIP）
//

import SwiftUI

struct BackgroundUploadTasksView: View {
    @ObservedObject private var manager = BackgroundUploadManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("上传任务")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(manager.activeCount) 个进行中，共 \(manager.jobs.count) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    manager.clearFinished()
                } label: {
                    Label("清理已完成", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(!manager.jobs.contains { $0.status != .running })
            }
            .padding()

            Divider()

            // 列表
            if manager.jobs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(manager.jobs.reversed()) { job in
                            UploadJobCard(job: job)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("当前没有上传任务")
                .font(.headline)
            Text("开始上传后可在此查看进度")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 任务卡片
private struct UploadJobCard: View {
    let job: UploadJob
    @ObservedObject private var manager = BackgroundUploadManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: job.kind == .anime ? "play.tv" : "book.closed")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if let sub = job.subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                statusBadge
            }

            // 进度条（仅进行中显示）
            if job.status == .running {
                ProgressView(value: job.percentage, total: 100)
                HStack {
                    Text("\(Int(job.percentage))%")
                        .font(.caption.monospacedDigit())
                    if job.totalChunks > 0 {
                        Text("· 分块 \(job.uploadedChunks)/\(job.totalChunks)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if job.totalBytes > 0 {
                        Text("· \(formatBytes(job.uploadedBytes))/\(formatBytes(job.totalBytes))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("取消") {
                        manager.cancel(job.id)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }
            } else {
                HStack {
                    if let err = job.error {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    } else if let taskId = job.resultTaskId {
                        Text("服务端任务 ID: \(taskId)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("移除") {
                        manager.dismiss(job.id)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder private var statusBadge: some View {
        switch job.status {
        case .running:
            Label("上传中", systemImage: "arrow.up.circle")
                .font(.caption)
                .foregroundStyle(.blue)
        case .completed:
            Label("已完成", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed:
            Label("失败", systemImage: "xmark.octagon.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .cancelled:
            Label("已取消", systemImage: "minus.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    BackgroundUploadTasksView()
        .frame(width: 800, height: 600)
}
