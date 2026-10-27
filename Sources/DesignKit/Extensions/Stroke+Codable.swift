//
//  Stroke+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A stroke as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Stroke: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, width, style, dash }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let dash = try c.decodeIfPresent([Double].self, forKey: .dash)
        if let dash, dash.isEmpty || !dash.allSatisfy({ $0.isFinite && $0 > 0 }) {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath + [CodingKeys.dash])) is dash and gap lengths, each above 0: [12, 8]")
        }
        self.init(color: try c.decode(Paint.self, forKey: .color), width: try c.number(.width, in: 0...200, or: 4),
                  style: try c.value(.style, or: .outline), dash: dash)
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(width, forKey: .width)
        try c.encode(style, forKey: .style)
        try c.encodeIfPresent(dash, forKey: .dash)
    }
}
