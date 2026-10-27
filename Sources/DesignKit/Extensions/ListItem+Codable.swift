//
//  ListItem+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension ListItem: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case text, tier, detail }

    /// An object, or the words alone (tier 1).
    public init(from decoder: any Decoder) throws {
        if let words = try? decoder.singleValueContainer().decode(String.self) {
            self.init(text: words)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tier = try c.value(.tier, or: 1)
        guard (1...20).contains(tier) else { throw RecipeError("\(RecipeJSON.path(decoder.codingPath)).tier is \(tier); billing runs 1…20") }
        self.init(text: try c.decode(String.self, forKey: .text), tier: tier, detail: try c.decodeIfPresent(String.self, forKey: .detail))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        if tier == 1, detail == nil {
            var c = encoder.singleValueContainer()
            try c.encode(text)
            return
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text)
        try c.encode(tier, forKey: .tier)
        try c.encodeIfPresent(detail, forKey: .detail)
    }
}
