//
//  LetterRanges.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Which characters a letter style picks out of the words as drawn: a range,
//  the nth word, or every place some words appear.
//

import Foundation

enum LetterRanges {

    /// The `[start, start + length)` character spans `style` picks in `words`.
    static func spans(_ style: LetterStyle, in words: String) -> [(start: Int, length: Int)] {
        let characters = Array(words)
        if let range = style.range {
            let start = min(range[0], characters.count), end = min(range[1], characters.count)
            return end > start ? [(start, end - start)] : []
        }
        if let word = style.word {
            let found = wordSpans(characters)
            let index = word > 0 ? word - 1 : found.count + word
            return found.indices.contains(index) ? [found[index]] : []
        }
        if let match = style.match {
            let needle = Array(match.lowercased()), haystack = characters.map { Character($0.lowercased()) }
            guard !needle.isEmpty, needle.count <= haystack.count else { return [] }
            var spans: [(Int, Int)] = []
            var index = 0
            while index + needle.count <= haystack.count {
                if Array(haystack[index..<index + needle.count]) == needle {
                    spans.append((index, needle.count))
                    index += needle.count
                } else {
                    index += 1
                }
            }
            return spans
        }
        return []
    }

    /// Each run of non-space characters.
    static func wordSpans(_ characters: [Character]) -> [(start: Int, length: Int)] {
        var spans: [(Int, Int)] = []
        var start: Int?
        for (index, character) in characters.enumerated() {
            if character.isWhitespace {
                if let begun = start { spans.append((begun, index - begun)); start = nil }
            } else if start == nil {
                start = index
            }
        }
        if let begun = start { spans.append((begun, characters.count - begun)) }
        return spans
    }
}
