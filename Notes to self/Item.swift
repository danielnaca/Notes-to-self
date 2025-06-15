//
//  Item.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/14/25.
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
