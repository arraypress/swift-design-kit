//
//  Placement+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Frames, grids and effects as a design file writes them: snake_case,
//  every key optional, an unknown one refused with the close one.
//

import Foundation
import RecipeKit

extension Placement: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case area, anchor, width, height, aspect, margin, x, y, columns, below, above, gap
    }

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

extension Shadow: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, blur, x, y }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = Shadow()
        self.init(color: try c.value(.color, or: base.color), blur: try c.number(.blur, in: 0...500, or: base.blur),
                  x: try c.number(.x, in: -500...500, or: base.x), y: try c.number(.y, in: -500...500, or: base.y))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(blur, forKey: .blur)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
    }
}

extension Glow: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, radius }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.decode(Paint.self, forKey: .color), radius: try c.number(.radius, in: 0...500, or: 20))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(radius, forKey: .radius)
    }
}

extension Stroke: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, width, style, dash }

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

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(width, forKey: .width)
        try c.encode(style, forKey: .style)
        try c.encodeIfPresent(dash, forKey: .dash)
    }
}

extension Plate: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case color, padding, radius
        case perLine = "per_line"
    }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.value(.color, or: .auto), padding: try c.number(.padding, in: 0...500, or: 24),
                  radius: try c.number(.radius, in: 0...500, or: 8), perLine: try c.value(.perLine, or: false))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(padding, forKey: .padding)
        try c.encode(radius, forKey: .radius)
        if perLine { try c.encode(perLine, forKey: .perLine) }
    }
}

extension Fade: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case edge, start, end }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(edge: try c.value(.edge, or: .bottom), start: try c.number(.start, in: 0...1, or: 0.5),
                  end: try c.number(.end, in: 0...1, or: 1))
        guard end > start else {
            throw RecipeError("\(RecipeJSON.path(decoder.codingPath)): end (\(end)) must lie past start (\(start))")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(edge, forKey: .edge)
        try c.encode(start, forKey: .start)
        try c.encode(end, forKey: .end)
    }
}

extension Scrim: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case edge, strength }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(edge: try c.value(.edge, or: .auto), strength: try c.number(.strength, in: 0...1, or: 0.5))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(edge, forKey: .edge)
        try c.encode(strength, forKey: .strength)
    }
}

extension Mask: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case shape, radius, points }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(shape: try c.decode(MaskShape.self, forKey: .shape), radius: try c.number(.radius, in: 0...1000, or: 40),
                  points: try c.decodeIfPresent([[Double]].self, forKey: .points))
        try Points.check(points, at: RecipeJSON.path(decoder.codingPath + [CodingKeys.points]), needed: shape == .polygon ? 3 : 0)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shape, forKey: .shape)
        try c.encode(radius, forKey: .radius)
        try c.encodeIfPresent(points, forKey: .points)
    }
}

extension Grid: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case columns, gutter }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let columns = try c.value(.columns, or: 12)
        guard (1...48).contains(columns) else { throw RecipeError("grid.columns is \(columns); it takes 1…48") }
        self.init(columns: columns, gutter: try c.number(.gutter, in: 0...0.2, or: 0.02))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(columns, forKey: .columns)
        try c.encode(gutter, forKey: .gutter)
    }
}

enum Points {
    /// Each point a pair of finite numbers; at least `needed` of them.
    static func check(_ points: [[Double]]?, at path: String, needed: Int) throws(RecipeError) {
        guard let points else {
            if needed > 0 { throw RecipeError("\(path) is missing: at least \(needed) points, [[x, y], …] as fractions of the frame") }
            return
        }
        guard points.count >= needed, points.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isFinite) }) else {
            throw RecipeError("\(path) is [[x, y], …] as fractions of the frame, at least \(max(needed, 1)) of them")
        }
    }
}
