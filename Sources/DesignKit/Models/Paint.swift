//
//  Paint.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

/// What something is painted with: a colour, a role from the design's
/// palette (`accent`, `dominant`…, taken from the art), or `auto` — for
/// words, picked from the picture under them for the most contrast.
public enum Paint: Codable, Equatable, Sendable {
    /// Picked per layer from the picture under it, for the most contrast.
    case auto
    /// A colour.
    case color(DesignColor)
    /// A role from the design's palette.
    case role(ColorRole)

    /// Reads `auto`, a palette role or a colour, refusing anything else.
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

    /// Writes `auto`, the role's name or the colour's hex.
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
