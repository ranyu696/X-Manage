//
//  DetailPlaceholderView.swift
//  X-Manage
//
//  详情占位视图组件

import SwiftUI

struct DetailPlaceholderView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DetailPlaceholderView(icon: "text.book.closed", message: "选择一个小说查看详情")
}
