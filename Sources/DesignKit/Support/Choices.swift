//
//  Choices.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A word from a fixed list, read strictly: a value the list does not have
//  is refused with the list (or the close one), never mapped to a default.
//

import Foundation
import RecipeKit

/// A string-backed enum read from a design file by one of its words.
public protocol DesignChoice: RawRepresentable, CaseIterable, Codable, Sendable where RawValue == String {}

public extension DesignChoice {

    init(from decoder: any Decoder) throws {
        let word = try decoder.singleValueContainer().decode(String.self)
        guard let value = Self(rawValue: word) else {
            throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath),
                                              among: Self.allCases.map(\.rawValue)))
        }
        self = value
    }

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

enum Choices {

    /// `frame.anchor is "middle"; one of: top-left, top, …` — or the close one.
    static func refusal(_ word: String, at path: String, among names: [String]) -> String {
        let field = path.isEmpty ? "the value" : path
        if let close = FieldPaths.closest(word, among: names) {
            return "\(field) is \"\(word)\" — did you mean \(close)?"
        }
        return "\(field) is \"\(word)\"; one of: \(names.joined(separator: ", "))"
    }
}
