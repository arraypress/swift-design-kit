//
//  DesignColor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

/// A colour as a design file writes it: `#RRGGBB`, `#RRGGBBAA`, CSS shorthand
/// (`#FC6`), or `white` / `black` / `clear`. Always held as uppercase
/// `#RRGGBB` or `#RRGGBBAA`.
public struct DesignColor: Codable, Equatable, Hashable, Sendable {

    /// The normalised hex.
    public let hex: String

    /// A colour from its text; `nil` when it is not one.
    public init?(_ text: String) {
        guard let hex = ColorParsing.normalized(text) else { return nil }
        self.hex = hex
    }

    public init(from decoder: any Decoder) throws {
        hex = try ColorParsing.decode(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    public static let white = DesignColor("#FFFFFF")!
    public static let black = DesignColor("#000000")!
}

/// What something is painted with: a colour, a role from the design's
/// palette (`accent`, `dominant`…, taken from the art), or `auto` — for
/// words, picked from the picture under them for the most contrast.
public enum Paint: Codable, Equatable, Sendable {
    case auto
    case color(DesignColor)
    case role(ColorRole)

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        let word = text.trimmingCharacters(in: .whitespaces).lowercased()
        if word == "auto" { self = .auto; return }
        if let role = ColorRole(rawValue: word) { self = .role(role); return }
        guard let hex = ColorParsing.normalized(text) else {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) is \"\(text)\", not a colour (#RRGGBB, #RRGGBBAA, white, black, clear), "
                              + "a palette role (\(ColorRole.allCases.map(\.rawValue).joined(separator: ", "))) or auto")
        }
        self = .color(DesignColor(hex: hex))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto: try container.encode("auto")
        case .color(let color): try container.encode(color)
        case .role(let role): try container.encode(role.rawValue)
        }
    }

    /// The colour, when it is one already.
    public var fixed: DesignColor? {
        if case .color(let color) = self { return color }
        return nil
    }
}

extension DesignColor {
    /// From an already-normalised hex.
    init(hex: String) { self.hex = hex }
}
