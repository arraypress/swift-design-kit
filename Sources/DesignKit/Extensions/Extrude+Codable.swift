//
//  Extrude+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Extrude: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case depth, angle, color, shade }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(depth: try c.number(.depth, in: 1...400, or: 24), angle: try c.number(.angle, in: -360...360, or: 135),
                  color: try c.value(.color, or: .auto), shade: try c.number(.shade, in: 0...1, or: 0.5))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(depth, forKey: .depth)
        try c.encode(angle, forKey: .angle)
        try c.encode(color, forKey: .color)
        try c.encode(shade, forKey: .shade)
    }
}
