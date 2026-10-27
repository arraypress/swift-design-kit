//
//  Insets+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Insets: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case top, bottom, left, right }

    /// An object of four fractions, or one number: the same fraction of the
    /// shorter side on every edge (made per-edge when the canvas is known).
    public init(from decoder: any Decoder) throws {
        if let uniform = try? decoder.singleValueContainer().decode(Double.self) {
            guard (0...0.45).contains(uniform) else {
                throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) is \(uniform); it takes 0…0.45")
            }
            self.init(uniform: uniform)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(top: try c.number(.top, in: 0...0.45, or: 0), bottom: try c.number(.bottom, in: 0...0.45, or: 0),
                  left: try c.number(.left, in: 0...0.45, or: 0), right: try c.number(.right, in: 0...0.45, or: 0))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(top, forKey: .top)
        try c.encode(bottom, forKey: .bottom)
        try c.encode(left, forKey: .left)
        try c.encode(right, forKey: .right)
    }
}
