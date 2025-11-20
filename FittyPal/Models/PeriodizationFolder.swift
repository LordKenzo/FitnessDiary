//
//  PeriodizationFolder.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PeriodizationFolder: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String // colore del folder in formato hex
    var order: Int

    init(name: String, colorHex: String = "#007AFF", order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.order = order
    }

    // Helper per convertire hex in Color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
