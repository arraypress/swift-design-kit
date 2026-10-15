//
//  ColorParsing.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation
import RecipeKit

enum ColorParsing {

    static let named = ["white": "#FFFFFF", "black": "#000000", "clear": "#00000000"]

    /// Uppercase `#RRGGBB` / `#RRGGBBAA` for a colour's text, shorthand
    /// expanded; `nil` when it is not a colour.
    static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let name = named[trimmed.lowercased()] { return name }
        var digits = Substring(trimmed.uppercased())
        if digits.hasPrefix("#") { digits = digits.dropFirst() }
        guard digits.allSatisfy(\.isHexDigit) else { return nil }
        switch digits.count {
        case 3, 4: return "#" + digits.map { "\($0)\($0)" }.joined()
        case 6, 8: return "#" + digits
        default: return nil
        }
    }

    /// The colour at the decoder's position, refused with its path.
    static func decode(from decoder: any Decoder) throws -> String {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let hex = normalized(text) else {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) is \"\(text)\", not a colour (#RRGGBB, #RRGGBBAA, white, black, clear)")
        }
        return hex
    }

    /// sRGB components of a normalised hex.
    static func components(_ hex: String) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let digits = String(hex.dropFirst())
        let bits = UInt64(digits, radix: 16) ?? 0
        let shift: UInt64 = digits.count == 8 ? 8 : 0
        return (Double((bits >> (16 + shift)) & 0xFF) / 255, Double((bits >> (8 + shift)) & 0xFF) / 255,
                Double((bits >> shift) & 0xFF) / 255, digits.count == 8 ? Double(bits & 0xFF) / 255 : 1)
    }

    /// The hex for components (alpha written only when below one).
    static func hex(red: Double, green: Double, blue: Double, alpha: Double = 1) -> String {
        func byte(_ value: Double) -> Int { Int((min(1, max(0, value)) * 255).rounded()) }
        let base = String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
        return alpha >= 1 ? base : base + String(format: "%02X", byte(alpha))
    }
}
