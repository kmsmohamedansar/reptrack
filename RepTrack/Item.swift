//
//  Item.swift
//  RepTrack
//
//  Created by ANSAR on 2026-03-13.
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
