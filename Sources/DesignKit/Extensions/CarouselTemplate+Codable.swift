//
//  CarouselTemplate+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension CarouselTemplate: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name, summary, preset, slots, pairing, palette, background, cover, each, end
        case repeats = "repeat"
    }

    /// Reads it as the catalogue writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "carousel template")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func raw(_ key: CodingKeys) throws -> Data? {
            guard let value = try c.decodeIfPresent(AnyJSON.self, forKey: key) else { return nil }
            return try JSONSerialization.data(withJSONObject: value.value, options: [.sortedKeys, .fragmentsAllowed])
        }
        guard let cover = try raw(.cover), let each = try raw(.each) else { throw RecipeError("a carousel template needs cover and each pages") }
        self.init(name: try c.decode(String.self, forKey: .name), summary: try c.decode(String.self, forKey: .summary),
                  preset: try c.decode(String.self, forKey: .preset), slots: try c.value(.slots, or: []),
                  pairing: try c.decodeIfPresent(String.self, forKey: .pairing), palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  repeats: try c.decode(String.self, forKey: .repeats), background: try raw(.background), cover: cover, each: each,
                  end: try raw(.end))
    }

    /// Writes it as the catalogue holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(summary, forKey: .summary)
        try c.encode(preset, forKey: .preset)
        try c.encode(slots, forKey: .slots)
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encode(repeats, forKey: .repeats)
        for (key, data) in [(CodingKeys.background, background), (.cover, cover), (.each, each), (.end, end)] {
            if let data { try c.encode(try JSONDecoder().decode(JSONFragment.self, from: data), forKey: key) }
        }
    }
}
