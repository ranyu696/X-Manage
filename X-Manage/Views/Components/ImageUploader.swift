//
//  ImageUploader.swift
//  X-Manage
//
//  可复用的图片上传组件

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 图片上传器

struct ImageUploader: View {
    let title: String
    let maxFiles: Int
    let existingImages: [String]
    let onUpload: ([URL]) async throws -> Void

    @State private var selectedImages: [URL] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showFilePicker = false

    init(
        title: String = "上传图片",
        maxFiles: Int = 3,
        existingImages: [String] = [],
        onUpload: @escaping ([URL]) async throws -> Void
    ) {
        self.title = title
        self.maxFiles = maxFiles
        self.existingImages = existingImages
        self.onUpload = onUpload
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和操作按钮
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if !selectedImages.isEmpty {
                    Button("清除选择") {
                        selectedImages.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }

                Button {
                    selectImages()
                } label: {
                    Label("选择图片", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.bordered)
                .disabled(isUploading)
            }

            // 现有图片预览
            if !existingImages.isEmpty {
                Text("当前图片")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(existingImages, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.quaternary)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }

            // 选中的新图片预览
            if !selectedImages.isEmpty {
                Text("待上传图片 (\(selectedImages.count)/\(maxFiles))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedImages, id: \.self) { url in
                            ZStack(alignment: .topTrailing) {
                                if let image = NSImage(contentsOf: url) {
                                    Image(nsImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Rectangle()
                                        .fill(.quaternary)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                Button {
                                    selectedImages.removeAll { $0 == url }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(.red))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }

                // 上传按钮
                HStack {
                    if let error = uploadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("上传中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button("开始上传") {
                            uploadImages()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func selectImages() {
        let urls = UploadService.shared.selectImages(
            allowMultiple: maxFiles > 1,
            maxCount: maxFiles
        )
        if !urls.isEmpty {
            selectedImages = urls
            uploadError = nil
        }
    }

    private func uploadImages() {
        guard !selectedImages.isEmpty else { return }

        isUploading = true
        uploadError = nil

        Task {
            do {
                try await onUpload(selectedImages)
                selectedImages.removeAll()
            } catch {
                uploadError = error.localizedDescription
            }
            isUploading = false
        }
    }
}

// MARK: - 单图上传器

struct SingleImageUploader: View {
    let title: String
    let currentImage: String?
    let aspectRatio: CGFloat
    let onUpload: (URL) async throws -> Void

    @State private var selectedImage: URL?
    @State private var isUploading = false
    @State private var uploadError: String?

    init(
        title: String = "封面",
        currentImage: String? = nil,
        aspectRatio: CGFloat = 2/3,
        onUpload: @escaping (URL) async throws -> Void
    ) {
        self.title = title
        self.currentImage = currentImage
        self.aspectRatio = aspectRatio
        self.onUpload = onUpload
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                // 当前/预览图片
                Group {
                    if let selectedImage = selectedImage,
                       let nsImage = NSImage(contentsOf: selectedImage) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let currentImage = currentImage,
                              let url = URL(string: currentImage) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("暂无图片")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .frame(width: 120, height: 120 / aspectRatio)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                )

                // 操作区域
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        selectImage()
                    } label: {
                        Label("选择图片", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isUploading)

                    if selectedImage != nil {
                        HStack {
                            Button("取消") {
                                selectedImage = nil
                                uploadError = nil
                            }
                            .buttonStyle(.borderless)

                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Button("上传") {
                                    uploadImage()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    if let error = uploadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func selectImage() {
        let urls = UploadService.shared.selectImages(allowMultiple: false, maxCount: 1)
        if let url = urls.first {
            selectedImage = url
            uploadError = nil
        }
    }

    private func uploadImage() {
        guard let url = selectedImage else { return }

        isUploading = true
        uploadError = nil

        Task {
            do {
                try await onUpload(url)
                selectedImage = nil
            } catch {
                uploadError = error.localizedDescription
            }
            isUploading = false
        }
    }
}

// MARK: - 预览

#Preview("ImageUploader") {
    ImageUploader(
        title: "游戏封面",
        maxFiles: 3,
        existingImages: []
    ) { urls in
        print("Upload: \(urls)")
    }
    .frame(width: 400)
    .padding()
}

#Preview("SingleImageUploader") {
    SingleImageUploader(
        title: "小说封面",
        currentImage: nil
    ) { url in
        print("Upload: \(url)")
    }
    .frame(width: 400)
    .padding()
}
