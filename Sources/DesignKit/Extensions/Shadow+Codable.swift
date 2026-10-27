//
//  Shadow+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A shadow as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Shadow: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, blur, x, y }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = Shadow()
        self.init(color: try c.value(.color, or: base.color), blur: try c.number(.blur, in: 0...500, or: base.blur),
                  x: try c.number(.x, in: -500...500, or: base.x), y: try c.number(.y, in: -500...500, or: base.y))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(blur, forKey: .blur)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
    }
}
