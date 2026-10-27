//
//  Fade+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A fade as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Fade: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case edge, start, end }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(edge: try c.value(.edge, or: .bottom), start: try c.number(.start, in: 0...1, or: 0.5),
                  end: try c.number(.end, in: 0...1, or: 1))
        guard end > start else {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath)): end (\(end)) must lie past start (\(start))")
        }
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(edge, forKey: .edge)
        try c.encode(start, forKey: .start)
        try c.encode(end, forKey: .end)
    }
}
