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
