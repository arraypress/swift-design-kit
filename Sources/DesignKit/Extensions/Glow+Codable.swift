//
//  Glow+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A glow as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Glow: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, radius }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.decode(Paint.self, forKey: .color), radius: try c.number(.radius, in: 0...500, or: 20))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(radius, forKey: .radius)
    }
}
