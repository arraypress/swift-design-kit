//
//  Grid+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A grid as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Grid: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case columns, gutter }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try c.value(.columns, or: 12)
        guard (1...48).contains(columns) else { throw RecipeError("grid.columns is \(columns); it takes 1…48") }
        self.init(columns: columns, gutter: try c.number(.gutter, in: 0...0.2, or: 0.02))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(columns, forKey: .columns)
        try c.encode(gutter, forKey: .gutter)
    }
}
