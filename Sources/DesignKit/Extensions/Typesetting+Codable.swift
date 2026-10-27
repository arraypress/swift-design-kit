//
//  Typesetting+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Typesetting: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case pairing, display, text, scale, base }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pairing = try c.decodeIfPresent(String.self, forKey: .pairing)
        if let pairing, Pairings.named(pairing) == nil {
            throw RecipeError(Pairings.refusal(pairing, at: RecipeJSON.path(decoder.codingPath + [CodingKeys.pairing])))
        }
        self.init(pairing: pairing?.lowercased(), display: try Self.face(c, .display), text: try Self.face(c, .text),
                  scale: try c.number(.scale, in: 1...3), base: try c.number(.base, in: 4...400))
    }

    /// A face: `{"family": …, "weight": …}`, or a family name alone.
    static func face(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> Face? {
        if let family = try? c.decodeIfPresent(String.self, forKey: key) { return Face(family: family) }
        guard let face = try c.decodeIfPresent(Face.self, forKey: key) else { return nil }
        guard Fonts.weights.contains(face.weight) else {
            throw RecipeError(Choices.refusal(face.weight, at: "fonts.\(key.rawValue).weight", among: Fonts.weights))
        }
        return face
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encodeIfPresent(display, forKey: .display)
        try c.encodeIfPresent(text, forKey: .text)
        try c.encodeIfPresent(scale, forKey: .scale)
        try c.encodeIfPresent(base, forKey: .base)
    }
}
