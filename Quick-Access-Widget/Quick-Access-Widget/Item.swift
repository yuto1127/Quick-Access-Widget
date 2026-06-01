//
//  Item.swift
//  Quick-Access-Widget
//
//  Created by 赤石優斗 on R 8/06/01.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
