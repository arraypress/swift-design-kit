//
//  Placement+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A frame as a design file writes it: snake_case, every key optional,
//  an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Placement: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case area, anchor, width, height, aspect, margin, x, y, columns, below, above, gap
    }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            area: try c.decodeIfPresent(Area.self, forKey: .area),
            anchor: try c.value(.anchor, or: .center),
            width: try c.number(.width, in: 0...4, or: 1),
            height: try c.number(.height, in: 0...4, or: 1),
            aspect: try c.number(.aspect, in: 0.01...100),
            margin: try c.number(.margin, in: 0...0.5, or: 0),
            x: try c.number(.x, in: -2...2, or: 0),
            y: try c.number(.y, in: -2...2, or: 0),
            columns: try c.decodeIfPresent([Int].self, forKey: .columns),
            below: try c.decodeIfPresent(String.self, forKey: .below),
            above: try c.decodeIfPresent(String.self, forKey: .above),
            gap: try c.number(.gap, in: -1...1, or: 0))
        if let columns, columns.count != 2 || columns[0] < 1 || columns[1] < 1 {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath + [CodingKeys.columns])) is [first, count], each from 1")
        }
        if below != nil, above != nil {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) has both below and above; one place at a time")
        }
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(area, forKey: .area)
        try c.encode(anchor, forKey: .anchor)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encodeIfPresent(aspect, forKey: .aspect)
        if margin != 0 { try c.encode(margin, forKey: .margin) }
        if x != 0 { try c.encode(x, forKey: .x) }
        if y != 0 { try c.encode(y, forKey: .y) }
        try c.encodeIfPresent(columns, forKey: .columns)
        try c.encodeIfPresent(below, forKey: .below)
        try c.encodeIfPresent(above, forKey: .above)
        if gap != 0 { try c.encode(gap, forKey: .gap) }
    }
}
