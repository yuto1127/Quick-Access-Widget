//
//  FileShelfSectionView.swift
//  Quick-Access-Widget
//

import SwiftUI
import UniformTypeIdentifiers

struct FileShelfSectionView: View {
    @State private var items: [ShelfItem] = []
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shelf")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(isTargeted ? 0.06 : 0.03))
                    )

                if items.isEmpty {
                    Text("ドロップ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(8)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 52, maximum: 64), spacing: 8)],
                            spacing: 8
                        ) {
                            ForEach(items) { item in
                                shelfItemView(item)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func shelfItemView(_ item: ShelfItem) -> some View {
        VStack(spacing: 2) {
            Image(systemName: item.url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                .font(.body)
                .foregroundStyle(.secondary)

            Text(item.displayName)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 52, height: 52)
        .contextMenu {
            Button("削除", role: .destructive) {
                removeItem(item)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                removeItem(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .offset(x: 2, y: -2)
        }
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    addItem(url: url)
                }
            }
        }
        return true
    }

    private func addItem(url: URL) {
        guard !items.contains(where: { $0.url == url }) else { return }
        items.append(ShelfItem(url: url))
    }

    private func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }
}
