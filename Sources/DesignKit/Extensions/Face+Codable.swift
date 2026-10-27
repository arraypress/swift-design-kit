//
//  Face+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Face {

    enum CodingKeys: String, CodingKey, CaseIterable { case family, weight }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(family: try c.decode(String.self, forKey: .family), weight: try c.value(.weight, or: "regular"))
    }
}
