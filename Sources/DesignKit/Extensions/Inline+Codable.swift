//
//  Inline+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Inline: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, width, inset }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.value(.color, or: .color(.white)), width: try c.number(.width, in: 0.2...100, or: 3),
                  inset: try c.number(.inset, in: 0...200, or: 4))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(width, forKey: .width)
        try c.encode(inset, forKey: .inset)
    }
}
