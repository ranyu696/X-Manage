//
//  CollapsibleDetailPanel.swift
//  X-Manage
//
//  可折叠的详情面板包装组件

import SwiftUI

struct CollapsibleDetailPanel<Content: View>: View {
    @Binding var isVisible: Bool
    let minWidthToClose: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var currentWidth: CGFloat = 400

    var body: some View {
        GeometryReader { geometry in
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: geometry.size.width) { _, newWidth in
                    currentWidth = newWidth
                    if newWidth < minWidthToClose {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isVisible = false
                        }
                    }
                }
        }
    }
}

// MARK: - 带侧边详情面板的列表视图容器
struct ListWithDetailPanel<ListContent: View, DetailContent: View>: View {
    @Binding var selectedId: Int?
    let listMinWidth: CGFloat
    let detailMinWidth: CGFloat
    let detailIdealWidth: CGFloat
    let closeThreshold: CGFloat
    let placeholderIcon: String
    let placeholderMessage: String
    @ViewBuilder let listContent: () -> ListContent
    @ViewBuilder let detailContent: (Int) -> DetailContent

    init(
        selectedId: Binding<Int?>,
        listMinWidth: CGFloat = 600,
        detailMinWidth: CGFloat = 300,
        detailIdealWidth: CGFloat = 450,
        closeThreshold: CGFloat = 150,
        placeholderIcon: String,
        placeholderMessage: String,
        @ViewBuilder listContent: @escaping () -> ListContent,
        @ViewBuilder detailContent: @escaping (Int) -> DetailContent
    ) {
        self._selectedId = selectedId
        self.listMinWidth = listMinWidth
        self.detailMinWidth = detailMinWidth
        self.detailIdealWidth = detailIdealWidth
        self.closeThreshold = closeThreshold
        self.placeholderIcon = placeholderIcon
        self.placeholderMessage = placeholderMessage
        self.listContent = listContent
        self.detailContent = detailContent
    }

    var body: some View {
        HSplitView {
            listContent()
                .frame(minWidth: listMinWidth)

            if let id = selectedId {
                GeometryReader { geometry in
                    detailContent(id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: geometry.size.width) { _, newWidth in
                            if newWidth < closeThreshold {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedId = nil
                                }
                            }
                        }
                }
                .id(id)
                .frame(minWidth: detailMinWidth, idealWidth: detailIdealWidth)
            }
        }
    }
}
