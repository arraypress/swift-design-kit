//
//  Template+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Template: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case name, summary, preset, slots, grid, pairing, palette, layers }

    /// Reads it as the catalogue writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "template")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pairing = try c.decodeIfPresent(String.self, forKey: .pairing)
        if let pairing, Pairings.named(pairing) == nil { throw RecipeError(Pairings.refusal(pairing, at: "pairing")) }
        self.init(name: try c.decode(String.self, forKey: .name), summary: try c.decode(String.self, forKey: .summary),
                  preset: try c.decode(String.self, forKey: .preset), slots: try c.value(.slots, or: []),
                  grid: try c.value(.grid, or: .standard), pairing: pairing,
                  palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  layers: try JSONSerialization.data(withJSONObject: c.decode(AnyJSON.self, forKey: .layers).value, options: [.sortedKeys]))
    }

    /// Writes it as the catalogue holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(summary, forKey: .summary)
        try c.encode(preset, forKey: .preset)
        try c.encode(slots, forKey: .slots)
        if grid != .standard { try c.encode(grid, forKey: .grid) }
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encodeIfPresent(palette, forKey: .palette)
        try c.encode(try JSONDecoder().decode(JSONFragment.self, from: layers), forKey: .layers)
    }
}
