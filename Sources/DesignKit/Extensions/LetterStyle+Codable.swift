//
//  LetterStyle+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension LetterStyle: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case range, word, match, color, size, weight, baseline, tracking }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
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

    /// Writes it as a design file holds it.
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
