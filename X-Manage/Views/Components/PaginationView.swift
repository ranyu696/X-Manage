//
//  PaginationView.swift
//  X-Manage
//
//  分页视图组件

import SwiftUI

struct PaginationView: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onPageChange(currentPage - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage <= 1)

            Text("第 \(currentPage) / \(totalPages) 页")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                onPageChange(currentPage + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage >= totalPages)
        }
    }
}

#Preview {
    PaginationView(
        currentPage: 1,
        totalPages: 10,
        onPageChange: { _ in }
    )
}
