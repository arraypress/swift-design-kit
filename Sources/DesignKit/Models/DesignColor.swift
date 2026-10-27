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

    /// Reads a colour from its text, refusing what is not one.
    public init(from decoder: any Decoder) throws {
        hex = try ColorParsing.decode(from: decoder)
    }

    /// Writes the normalised hex.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    /// `#FFFFFF`.
    public static let white = DesignColor("#FFFFFF")!
    /// `#000000`.
    public static let black = DesignColor("#000000")!
}

extension DesignColor {
    /// From an already-normalised hex.
    init(hex: String) { self.hex = hex }
}
