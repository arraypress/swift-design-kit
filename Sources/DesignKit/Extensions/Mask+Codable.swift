//
//  Mask+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A mask as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Mask: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case shape, radius, points }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(shape: try c.decode(MaskShape.self, forKey: .shape), radius: try c.number(.radius, in: 0...1000, or: 40),
                  points: try c.decodeIfPresent([[Double]].self, forKey: .points))
        try Points.check(points, at: RecipeJSON.path(decoder.codingPath + [CodingKeys.points]), needed: shape == .polygon ? 3 : 0)
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shape, forKey: .shape)
        try c.encode(radius, forKey: .radius)
        try c.encodeIfPresent(points, forKey: .points)
    }
}
