//
//  ShelfItem.swift
//  Quick-Access-Widget
//

import Foundation

struct ShelfItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var displayName: String {
        url.lastPathComponent
    }

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.url == rhs.url
    }
}
