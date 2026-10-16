//
//  FontTraits.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What a face is, read from the font itself: its category from CoreText's
//  stylistic class (the OS/2 family class) and monospace bit, with the
//  name as a tiebreak where a font leaves its class unset; a few words for
//  its feel from width, weight range and category; and whether its OS/2
//  embedding bits let a PDF carry it.
//

import CoreText
import Foundation

enum FontTraits {

    /// The category of a face.
    static func category(of descriptor: CTFontDescriptor, family: String) -> FontCategory {
        let name = family.lowercased()
        let traits = CTFontDescriptorCopyAttribute(descriptor, kCTFontTraitsAttribute) as? [String: Any] ?? [:]
        let symbolic = (traits[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
        if symbolic & CTFontSymbolicTraits.traitMonoSpace.rawValue != 0 || name.contains("mono") || name.contains("courier") {
            return .mono
        }
        if ["emoji", "symbol", "dingbat", "braille", "webdings", "wingdings", "ornament"].contains(where: name.contains) {
            return .symbol
        }
        if ["script", "hand", "brush", "chancery", "signpainter", "savoye", "snell", "zapfino", "pacifico", "lobster",
            "party", "marker", "noteworthy", "chalk"].contains(where: name.contains) { return .script }
        let stylistic = CTFontStylisticClass(rawValue: symbolic & CTFontSymbolicTraits.traitClassMask.rawValue)
        switch stylistic {
        case .classScripts: return .script
        case .classOrnamentals: return .display
        case .classSymbolic: return .symbol
        case .classSansSerif: return .sans
        case .classOldStyleSerifs, .classTransitionalSerifs, .classModernSerifs, .classClarendonSerifs,
             .classSlabSerifs, .classFreeformSerifs: return .serif
        default: break
        }
        if ["impact", "black", "fatface", "display", "poster", "bungee", "monoton", "righteous", "shrikhand", "stencil",
            "copperplate", "papyrus", "luminari", "herculanum", "bebas", "anton"].contains(where: name.contains) { return .display }
        if ["serif", "garamond", "baskerville", "bodoni", "didot", "caslon", "georgia", "times", "palatino", "cochin",
            "hoefler", "charter", "lora", "playfair", "fraunces", "cormorant", "mincho", "song"].contains(where: name.contains) {
            return name.contains("sans") ? .sans : .serif
        }
        return .sans
    }

    /// A few words for a family's feel.
    static func mood(category: FontCategory, styles: [String], family: String) -> String {
        let all = (styles + [family]).joined(separator: " ").lowercased()
        var words: [String] = []
        switch category {
        case .serif: words.append(all.contains("display") || family.lowercased().contains("didot") || family.lowercased().contains("bodoni") ? "elegant" : "classic")
        case .sans: words.append("clean")
        case .mono: words.append("technical")
        case .display: words.append("loud")
        case .script: words.append("personal")
        case .symbol: words.append("symbols")
        }
        if all.contains("condensed") || all.contains("compressed") || all.contains("narrow") { words.append("compact") }
        if all.contains("extended") || all.contains("expanded") || all.contains("wide") { words.append("wide") }
        if all.contains("black") || all.contains("heavy") || all.contains("ultra") || all.contains("extrabold") { words.append("bold weights") }
        if all.contains("thin") || all.contains("light") || all.contains("hairline") { words.append("light weights") }
        if styles.count == 1 { words.append("one style") }
        return words.joined(separator: ", ")
    }

    /// Whether a font's OS/2 `fsType` lets a document embed it: installable
    /// (0), print-and-preview (bit 2) or editable (bit 3), and not
    /// bitmap-only. A restricted font (bit 1 alone) or one with no OS/2
    /// table is not embedded.
    static func embeddable(_ font: CTFont) -> Bool {
        guard let table = CTFontCopyTable(font, CTFontTableTag(kCTFontTableOS2), []) as Data?, table.count >= 10 else {
            return false
        }
        let fsType = UInt16(table[table.startIndex + 8]) << 8 | UInt16(table[table.startIndex + 9])
        return embeddable(fsType: fsType)
    }

    static func embeddable(fsType: UInt16) -> Bool {
        if fsType & 0x0200 != 0 { return false }
        if fsType & 0x000F == 0 { return true }
        return fsType & 0x000C != 0
    }
}
