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
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primary.opacity(isTargeted ? 0.06 : 0.03))
                    )

                if items.isEmpty {
                    Text("ファイルやフォルダをここにドロップ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(items) { item in
                                shelfItemView(item)
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .frame(minHeight: 100, maxHeight: 140)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        }
    }

    @ViewBuilder
    private func shelfItemView(_ item: ShelfItem) -> some View {
        VStack(spacing: 4) {
            Image(systemName: item.url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(item.displayName)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 72, height: 72)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
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
