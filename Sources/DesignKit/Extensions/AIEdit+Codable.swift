//
//  AIEdit+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

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

    /// Writes it as a design file holds it.
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
