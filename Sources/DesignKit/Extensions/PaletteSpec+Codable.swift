//
//  PaletteSpec+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension PaletteSpec: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case harmony, dominant, secondary, accent, neutral, light, dark }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var fixed: [ColorRole: DesignColor] = [:]
        for role in ColorRole.allCases {
            guard let key = CodingKeys(rawValue: role.rawValue) else { continue }
            if let color = try c.decodeIfPresent(DesignColor.self, forKey: key) { fixed[role] = color }
        }
        self.init(harmony: try c.value(.harmony, or: .auto), fixed: fixed)
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(harmony, forKey: .harmony)
        for role in ColorRole.allCases {
            if let color = fixed[role], let key = CodingKeys(rawValue: role.rawValue) { try c.encode(color, forKey: key) }
        }
    }
}
