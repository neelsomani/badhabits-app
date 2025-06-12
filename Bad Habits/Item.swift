//
//  Item.swift
//  Bad Habits
//
//  Created by Neel Somani on 6/12/25.
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
