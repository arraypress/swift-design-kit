//
//  Typography+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension TextPath: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case shape, bend, start, waves, amplitude }

    /// An object, or a shape's name alone (`"path": "circle"`).
    public init(from decoder: any Decoder) throws {
        if let word = try? decoder.singleValueContainer().decode(String.self) {
            guard let shape = TextPathShape(rawValue: word.lowercased()) else {
                throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath), among: TextPathShape.allCases.map(\.rawValue)))
            }
            self.init(shape: shape)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(shape: try c.decode(TextPathShape.self, forKey: .shape), bend: try c.number(.bend, in: -1...1, or: 0.5),
                  start: try c.number(.start, in: -360...360, or: 0), waves: try c.number(.waves, in: 0.25...12, or: 1.5),
                  amplitude: try c.number(.amplitude, in: 0...1, or: 0.25))
        if shape == .arc, bend == 0 { throw RecipeError("\(RecipeJSON.path(decoder.codingPath)).bend is 0, a straight line; leave out path, or bend it") }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shape, forKey: .shape)
        switch shape {
        case .arc: try c.encode(bend, forKey: .bend)
        case .circle: try c.encode(start, forKey: .start)
        case .wave:
            try c.encode(waves, forKey: .waves)
            try c.encode(amplitude, forKey: .amplitude)
        }
    }
}

extension Extrude: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case depth, angle, color, shade }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(depth: try c.number(.depth, in: 1...400, or: 24), angle: try c.number(.angle, in: -360...360, or: 135),
                  color: try c.value(.color, or: .auto), shade: try c.number(.shade, in: 0...1, or: 0.5))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(depth, forKey: .depth)
        try c.encode(angle, forKey: .angle)
        try c.encode(color, forKey: .color)
        try c.encode(shade, forKey: .shade)
    }
}

extension Inline: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case color, width, inset }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(color: try c.value(.color, or: .color(.white)), width: try c.number(.width, in: 0.2...100, or: 3),
                  inset: try c.number(.inset, in: 0...200, or: 4))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encode(width, forKey: .width)
        try c.encode(inset, forKey: .inset)
    }
}

extension LetterStyle: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case range, word, match, color, size, weight, baseline, tracking }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let path = RecipeJSON.path(decoder.codingPath)
        let range = try c.decodeIfPresent([Int].self, forKey: .range)
        let word = try c.decodeIfPresent(Int.self, forKey: .word)
        let match = try c.decodeIfPresent(String.self, forKey: .match)
        guard [range != nil, word != nil, match != nil].filter({ $0 }).count == 1 else {
            throw RecipeError("\(path) picks its letters one way: range [from, to), word N, or match \"words\"")
        }
        if let range, range.count != 2 || range[0] < 0 || range[1] <= range[0] {
            throw RecipeError("\(path).range is [from, to): characters from 0, to past from")
        }
        if word == 0 { throw RecipeError("\(path).word counts from 1 (or from the end: -1 is the last)") }
        if let match, match.isEmpty { throw RecipeError("\(path).match is empty") }
        let weight = try c.decodeIfPresent(String.self, forKey: .weight)
        if let weight, !Fonts.weights.contains(weight) {
            throw RecipeError(Choices.refusal(weight, at: path + ".weight", among: Fonts.weights))
        }
        self.init(range: range, word: word, match: match, color: try c.decodeIfPresent(Paint.self, forKey: .color),
                  size: try c.number(.size, in: 0.1...10), weight: weight, baseline: try c.number(.baseline, in: -2...2),
                  tracking: try c.number(.tracking, in: -300...2000))
        if color == nil, size == nil, weight == nil, baseline == nil, tracking == nil {
            throw RecipeError("\(path) changes nothing: give it a color, size, weight, baseline or tracking")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(range, forKey: .range)
        try c.encodeIfPresent(word, forKey: .word)
        try c.encodeIfPresent(match, forKey: .match)
        try c.encodeIfPresent(color, forKey: .color)
        try c.encodeIfPresent(size, forKey: .size)
        try c.encodeIfPresent(weight, forKey: .weight)
        try c.encodeIfPresent(baseline, forKey: .baseline)
        try c.encodeIfPresent(tracking, forKey: .tracking)
    }
}

extension AIEdit: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case prompt, model, revision, seed, aspect, steps, strength }

    /// An object, or the words alone (`"edit": "make it night"`).
    public init(from decoder: any Decoder) throws {
        if let words = try? decoder.singleValueContainer().decode(String.self) {
            guard !words.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) is empty; say what to change")
            }
            self.init(prompt: words)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(prompt: try c.decode(String.self, forKey: .prompt), model: try c.decodeIfPresent(String.self, forKey: .model),
                  revision: try c.decodeIfPresent(String.self, forKey: .revision), seed: try c.decodeIfPresent(UInt32.self, forKey: .seed),
                  aspect: try c.decodeIfPresent(String.self, forKey: .aspect), steps: try c.decodeIfPresent(Int.self, forKey: .steps),
                  strength: try c.number(.strength, in: 0.05...1, or: 0.75))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(prompt, forKey: .prompt)
        try c.encodeIfPresent(model, forKey: .model)
        try c.encodeIfPresent(revision, forKey: .revision)
        try c.encodeIfPresent(seed, forKey: .seed)
        try c.encodeIfPresent(aspect, forKey: .aspect)
        try c.encodeIfPresent(steps, forKey: .steps)
        try c.encode(strength, forKey: .strength)
    }
}

extension MotionSpec: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case kind, seconds, fps, amount, leaks, particles, grain, seed
        case depthModel = "depth_model"
        case fillModel = "fill_model"
    }

    /// An object, or a kind alone (`"motion": "parallax"`).
    public init(from decoder: any Decoder) throws {
        if let word = try? decoder.singleValueContainer().decode(String.self) {
            guard let kind = MotionKind(rawValue: word.lowercased()) else {
                throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath), among: MotionKind.allCases.map(\.rawValue)))
            }
            self.init(kind: kind)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fps = try c.value(.fps, or: 30)
        guard [24, 25, 30, 60].contains(fps) else { throw RecipeError("motion.fps is \(fps); it takes 24, 25, 30 or 60") }
        let particles = try c.value(.particles, or: 0)
        guard (0...400).contains(particles) else { throw RecipeError("motion.particles is \(particles); it takes 0…400") }
        self.init(kind: try c.value(.kind, or: .zoom), seconds: try c.number(.seconds, in: 3...8, or: 6), fps: fps,
                  amount: try c.number(.amount, in: 0.01...0.2, or: 0.06), leaks: try c.number(.leaks, in: 0...1, or: 0),
                  particles: particles, grain: try c.number(.grain, in: 0...1, or: 0.04), seed: try c.value(.seed, or: 1),
                  depthModel: try c.decodeIfPresent(String.self, forKey: .depthModel), fillModel: try c.decodeIfPresent(String.self, forKey: .fillModel))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kind, forKey: .kind)
        try c.encode(seconds, forKey: .seconds)
        try c.encode(fps, forKey: .fps)
        try c.encode(amount, forKey: .amount)
        if leaks > 0 { try c.encode(leaks, forKey: .leaks) }
        if particles > 0 { try c.encode(particles, forKey: .particles) }
        try c.encode(grain, forKey: .grain)
        try c.encode(seed, forKey: .seed)
        try c.encodeIfPresent(depthModel, forKey: .depthModel)
        try c.encodeIfPresent(fillModel, forKey: .fillModel)
    }
}
