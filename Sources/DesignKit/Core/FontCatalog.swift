//
//  FontCatalog.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Every face a design can name, listed: each family installed on this Mac
//  (read once from CoreText's collection of available fonts, grouped by
//  family) with its styles, a category and a few words for its feel; the
//  bundled faces; and the open fonts, with whether they are fetched yet.
//

import CoreText
import Foundation

/// Every face a design can name, listed with its styles, category and feel.
public enum FontCatalog {

    /// Installed families (hidden system faces left out), bundled faces and
    /// open fonts, each once — an open font installed on this Mac is listed as installed.
    public static func families(fetcher: (any FontFetching)? = nil) -> [FontFamily] {
        // A bundled face registered for this process shows up as installed: list it once, as bundled.
        let bundledFamilies = Set(Fonts.bundled.map(\.family))
        var rows = installed().filter { !bundledFamilies.contains($0.family) }
        let installedNames = Set(rows.map { $0.family.lowercased() })
        for entry in Fonts.bundled {
            rows.append(FontFamily(family: entry.family, name: entry.name, source: "bundled",
                                   styles: entry.files.map { String($0.split(separator: "-").last ?? "") },
                                   category: entry.name == "jetbrains-mono" ? .mono : entry.name == "inter" ? .sans : .serif,
                                   mood: entry.name == "jetbrains-mono" ? "technical" : entry.name == "inter" ? "clean, neutral" : "classic, readable",
                                   embeddable: true, licence: "OFL-1.1", fetched: nil))
        }
        for font in OpenFonts.all where font.isCurated && !installedNames.contains(font.family.lowercased()) {
            rows.append(row(font, fetcher: fetcher))
        }
        return rows
    }

    /// Every Google Fonts family whose name contains `query` (all ~2,000
    /// with none), closest first — what `design fonts --google` lists.
    public static func google(_ query: String?, fetcher: (any FontFetching)? = nil) -> [FontFamily] {
        OpenFonts.search(query ?? "").map { row($0, fetcher: fetcher) }
    }

    /// An open font as a listing row.
    static func row(_ font: OpenFont, fetcher: (any FontFetching)?) -> FontFamily {
        let styles = font.styles
        return FontFamily(family: font.family, name: font.family, source: "open", styles: styles, category: font.category,
                          // A weight axis is every weight, not one style.
                          mood: FontTraits.mood(category: font.category, styles: font.axes.contains { $0.tag == "wght" } ? ["Regular", "Bold"] : styles,
                                                family: font.family),
                          embeddable: nil, licence: font.licence, fetched: fetcher?.fetched(font) != nil,
                          axes: font.axes.isEmpty ? nil : font.axes.map { "\($0.tag) \(Decoding.text($0.minimum))–\(Decoding.text($0.maximum))" })
    }

    /// Every family installed on this Mac.
    public static func installed() -> [FontFamily] {
        let collection = CTFontCollectionCreateFromAvailableFonts(nil)
        let descriptors = CTFontCollectionCreateMatchingFontDescriptors(collection) as? [CTFontDescriptor] ?? []
        var byFamily: [String: [CTFontDescriptor]] = [:]
        for descriptor in descriptors {
            guard let family = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String,
                  !family.hasPrefix(".") else { continue }
            byFamily[family, default: []].append(descriptor)
        }
        return byFamily.keys.sorted().map { family in
            let members = byFamily[family] ?? []
            let styles = members.compactMap { CTFontDescriptorCopyAttribute($0, kCTFontStyleNameAttribute) as? String }
            let ordered = styles.sorted { weight(of: $0) == weight(of: $1) ? $0 < $1 : weight(of: $0) < weight(of: $1) }
            let regular = members.first { (CTFontDescriptorCopyAttribute($0, kCTFontStyleNameAttribute) as? String)
                .map { ["regular", "roman", "book", "plain", "medium"].contains($0.lowercased()) } ?? false } ?? members[0]
            let category = FontTraits.category(of: regular, family: family)
            let font = CTFontCreateWithFontDescriptor(regular, 12, nil)
            return FontFamily(family: family, name: family, source: "installed", styles: ordered, category: category,
                              mood: FontTraits.mood(category: category, styles: styles, family: family),
                              embeddable: FontTraits.embeddable(font), licence: nil, fetched: nil)
        }
    }

    /// A rough weight for ordering style names, lightest first.
    static func weight(of style: String) -> Int {
        let s = style.lowercased()
        let ranks: [(String, Int)] = [("hairline", 0), ("ultralight", 1), ("ultra light", 1), ("extralight", 1), ("thin", 2),
                                      ("light", 3), ("book", 4), ("regular", 4), ("roman", 4), ("plain", 4), ("medium", 5),
                                      ("demi", 6), ("semibold", 6), ("extrabold", 8), ("ultrabold", 8), ("bold", 7),
                                      ("heavy", 9), ("black", 10), ("extrablack", 11)]
        return ranks.first { s.contains($0.0) }?.1 ?? 4
    }
}
