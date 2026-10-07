import SwiftUI

/// SF Symbol names for the Material icons used in the mockups.
enum PiIcon {
    static let back = "arrow.left"
    static let close = "xmark"
    static let search = "magnifyingglass"
    static let notifications = "bell"
    static let insights = "chart.bar"
    static let settings = "gearshape"
    static let sync = "arrow.triangle.2.circlepath"
    static let add = "plus"
    static let remove = "minus"
    static let transfer = "arrow.left.arrow.right"
    static let history = "list.bullet.rectangle.portrait"
    static let ask = "bubble.left.and.bubble.right"
    static let goals = "target"
    static let lock = "lock"
    static let check = "checkmark"
    static let info = "info.circle"
    static let error = "exclamationmark.circle"
    static let edit = "pencil"
    static let chevron = "chevron.right"
    static let send = "arrow.up"
    static let backspace = "delete.left"
    static let bank = "building.columns"
    static let sparkle = "sparkles"
    static let credit = "arrow.down"
    static let withdrawal = "arrow.up"
    static let delete = "trash"
    static let schedule = "clock"
    static let stepOne = "1.circle"
    static let stepTwo = "2.circle"
    static let stepThree = "3.circle"

    /// Picks a goal icon from its name, as the mockups do (`gi()`).
    static func goal(named name: String) -> String {
        let lowered = name.lowercased()
        let table: [(keyword: String, symbol: String)] = [
            ("car", "car"),
            ("emergency", "cross.case"),
            ("vacation", "airplane"),
            ("trip", "airplane"),
            ("travel", "airplane"),
            ("home", "house"),
            ("house", "house"),
            ("bike", "bicycle"),
            ("wedding", "heart"),
            ("education", "graduationcap"),
            ("college", "graduationcap"),
            ("phone", "iphone"),
            ("laptop", "laptopcomputer"),
        ]
        return table.first { lowered.contains($0.keyword) }?.symbol ?? "indianrupeesign.circle"
    }
}
