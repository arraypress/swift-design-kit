//
//  Brand+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Brand: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name, logo, colors, pairing, display, text, corner
        case logoWidth = "logo_width"
    }

    /// Reads it as a brand file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "brand")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let named = try c.decodeIfPresent([String: DesignColor].self, forKey: .colors) ?? [:]
        var colors: [ColorRole: DesignColor] = [:]
        for (role, color) in named {
            guard let parsed = ColorRole(rawValue: role) else {
                throw RecipeError(Choices.refusal(role, at: "colors", among: ColorRole.allCases.map(\.rawValue)))
            }
            colors[parsed] = color
        }
        let pairing = try c.decodeIfPresent(String.self, forKey: .pairing)
        if let pairing, Pairings.named(pairing) == nil { throw RecipeError(Pairings.refusal(pairing, at: "pairing")) }
        self.init(name: try c.decode(String.self, forKey: .name), logo: try c.decodeIfPresent(String.self, forKey: .logo), colors: colors,
                  pairing: pairing, display: try c.decodeIfPresent(Face.self, forKey: .display),
                  text: try c.decodeIfPresent(Face.self, forKey: .text), corner: try c.decodeIfPresent(Anchor.self, forKey: .corner),
                  logoWidth: try c.number(.logoWidth, in: 0.03...0.6, or: 0.14))
    }

    /// Writes it as a brand file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(logo, forKey: .logo)
        try c.encode(Dictionary(uniqueKeysWithValues: colors.map { ($0.key.rawValue, $0.value) }), forKey: .colors)
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encodeIfPresent(display, forKey: .display)
        try c.encodeIfPresent(text, forKey: .text)
        try c.encodeIfPresent(corner, forKey: .corner)
        try c.encode(logoWidth, forKey: .logoWidth)
    }
}
