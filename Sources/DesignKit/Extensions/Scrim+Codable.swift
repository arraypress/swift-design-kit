//
//  Scrim+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A scrim as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Scrim: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case edge, strength }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(edge: try c.value(.edge, or: .auto), strength: try c.number(.strength, in: 0...1, or: 0.5))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(edge, forKey: .edge)
        try c.encode(strength, forKey: .strength)
    }
}
