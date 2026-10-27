//
//  DesignChoice.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

/// A string-backed enum read from a design file by one of its words.
public protocol DesignChoice: RawRepresentable, CaseIterable, Codable, Sendable where RawValue == String {}

public extension DesignChoice {

    /// Reads one of the words, strictly: any other is refused with the list (or the close one).
    init(from decoder: any Decoder) throws {
        let word = try decoder.singleValueContainer().decode(String.self)
        guard let value = Self(rawValue: word) else {
            throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath),
                                              among: Self.allCases.map(\.rawValue)))
        }
        self = value
    }

    /// Writes it as its word.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The value for `word`, or a refusal naming the choices.
    static func named(_ word: String, field: String) throws(RecipeError) -> Self {
        guard let value = Self(rawValue: word.lowercased()) else {
            throw RecipeError(Choices.refusal(word, at: field, among: allCases.map(\.rawValue)))
        }
        return value
    }
}
