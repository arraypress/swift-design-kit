//
//  Words.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The words a text layer draws: its `{slot}` markers filled from the
//  design's vars, then cased.
//

import Foundation
import RecipeKit

enum Words {

    /// `text` with every `{name}` the vars hold replaced; others left as written.
    static func filled(_ text: String, vars: [String: String]) -> String {
        guard text.contains("{") else { return text }
        return SlotFilling.filled(text, with: vars.keys.sorted().map { ($0, vars[$0] ?? "") })
    }

    /// The `{markers}` still in `text` once filled.
    static func unfilled(_ text: String) -> [String] {
        SlotFilling.markers(in: text)
    }

    /// `text` in `textCase`. Markup (`**`, `*`, `~`) survives every case.
    static func cased(_ text: String, _ textCase: TextCase) -> String {
        switch textCase {
        case .none: text
        case .upper: text.uppercased()
        case .lower: text.lowercased()
        case .title: text.capitalized
        }
    }

    /// The words as a reader sees them: markup removed.
    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "~", with: "")
    }
}
