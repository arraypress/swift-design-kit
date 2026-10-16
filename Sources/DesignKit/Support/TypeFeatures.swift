//
//  TypeFeatures.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Words for OpenType features and variable axes, to the tags CoreText
//  takes: `small-caps` is `smcp` on, `no-ligatures` is `liga` and `clig`
//  off, `oldstyle` is `onum`; `weight` is the `wght` axis. A four-letter tag
//  works as itself (`ss03`, `cv11`), and `-tag` turns it off.
//

import CoreText
import Foundation
import RecipeKit

enum TypeFeatures {

    /// Feature words and the tags (and values) they set.
    static let words: [String: [String: Int]] = [
        "small-caps": ["smcp": 1],
        "all-small-caps": ["smcp": 1, "c2sc": 1],
        "caps-to-small-caps": ["c2sc": 1],
        "ligatures": ["liga": 1],
        "no-ligatures": ["liga": 0, "clig": 0],
        "discretionary-ligatures": ["dlig": 1],
        "no-contextual": ["calt": 0],
        "tabular": ["tnum": 1],
        "proportional": ["pnum": 1],
        "oldstyle": ["onum": 1],
        "lining": ["lnum": 1],
        "slashed-zero": ["zero": 1],
        "fractions": ["frac": 1],
        "ordinals": ["ordn": 1],
        "superscript": ["sups": 1],
        "subscript": ["subs": 1],
        "swash": ["swsh": 1],
        "titling": ["titl": 1],
        "case-forms": ["case": 1],
        "alternates": ["salt": 1],
    ]

    /// Axis words and their tags.
    static let axes: [String: String] = [
        "weight": "wght", "width": "wdth", "slant": "slnt", "italic": "ital", "optical-size": "opsz", "optical": "opsz",
    ]

    /// The tags `features` asks for; an unknown word refused with the list.
    static func tags(_ features: [String], at path: String) throws(RecipeError) -> [String: Int] {
        var tags: [String: Int] = [:]
        for feature in features {
            let word = feature.trimmingCharacters(in: .whitespaces)
            if let set = words[word.lowercased()] {
                tags.merge(set) { _, new in new }
            } else if isTag(word) {
                tags[word] = 1
            } else if word.hasPrefix("-"), isTag(String(word.dropFirst())) {
                tags[String(word.dropFirst())] = 0
            } else {
                throw RecipeError(Choices.refusal(word, at: path, among: words.keys.sorted() + ["ss01…ss20", "a four-letter OpenType tag", "-tag (off)"]))
            }
        }
        return tags
    }

    /// The axis tag for a word or tag; refused when it is neither.
    static func axisTag(_ name: String, at path: String) throws(RecipeError) -> String {
        if let tag = axes[name.lowercased()] { return tag }
        if isTag(name) { return name }
        throw RecipeError("\(path) has \"\(name)\"; axes are weight, width, slant, italic, optical-size, or a four-letter tag (wght, SOFT)")
    }

    /// Four printable ASCII characters, no spaces.
    static func isTag(_ text: String) -> Bool {
        text.utf8.count == 4 && text.utf8.allSatisfy { $0 > 32 && $0 < 127 }
    }

    /// The features in `tags` that change nothing in `font` for `text` —
    /// measured by laying the words out with and without each and comparing
    /// the glyphs drawn. A face without a feature ignores it silently.
    static func ineffective(_ tags: [String: Int], text: String, font: CTFont) -> [String] {
        guard !text.isEmpty else { return [] }
        func glyphs(_ face: CTFont) -> [CGGlyph] {
            let line = CTLineCreateWithAttributedString(
                CFAttributedStringCreate(nil, text as CFString, [kCTFontAttributeName: face] as CFDictionary))
            return ((CTLineGetGlyphRuns(line) as? [CTRun]) ?? []).flatMap { run -> [CGGlyph] in
                var ids = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &ids)
                return ids
            }
        }
        let plain = glyphs(font)
        return tags.keys.sorted().filter { tag in
            let attributes = [kCTFontFeatureSettingsAttribute: [[kCTFontOpenTypeFeatureTag: tag, kCTFontOpenTypeFeatureValue: tags[tag] ?? 1]]]
            let featured = CTFontCreateCopyWithAttributes(font, CTFontGetSize(font), nil,
                                                          CTFontDescriptorCreateWithAttributes(attributes as CFDictionary))
            return glyphs(featured) == plain
        }
    }
}
