//
//  Plate+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A plate as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Plate: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case color, padding, radius
        case perLine = "per_line"
    }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.value(.color, or: .auto), padding: try c.number(.padding, in: 0...500, or: 24),
                  radius: try c.number(.radius, in: 0...500, or: 8), perLine: try c.value(.perLine, or: false))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(padding, forKey: .padding)
        try c.encode(radius, forKey: .radius)
        if perLine { try c.encode(perLine, forKey: .perLine) }
    }
}
