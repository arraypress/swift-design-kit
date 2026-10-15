//
//  DesignColor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

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

/// A text colour: a colour, or `auto` — picked from the picture under the
/// words for the most contrast, from the picture's own colours when one of
/// them reads.
public enum TextColor: Codable, Equatable, Sendable {
    case auto
    case color(DesignColor)

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        if text.lowercased() == "auto" { self = .auto; return }
        self = .color(DesignColor(hex: try ColorParsing.decode(from: decoder)))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto: try container.encode("auto")
        case .color(let color): try container.encode(color)
        }
    }
}

extension DesignColor {
    /// From an already-normalised hex.
    init(hex: String) { self.hex = hex }
}
