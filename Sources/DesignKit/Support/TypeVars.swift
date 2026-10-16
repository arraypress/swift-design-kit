//
//  TypeVars.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The type by name from the command line: `--var font="Space Mono"` sets
//  the whole design in one family (both roles), `display-font=` and
//  `text-font=` one role each — any installed family, a bundled face, any
//  Google Fonts family (fetched on first use) or a .ttf/.otf path. The
//  weights stay the pairing's, so a title stays heavier than its credits.
//

import Foundation
import RecipeKit

enum TypeVars {

    /// The names that set faces rather than fill slots.
    static let names = ["font", "display-font", "text-font"]

    /// `values` without the face names, and the faces they set.
    static func split(_ values: [String: String]) -> (slots: [String: String], faces: [String: String]) {
        var slots = values, faces: [String: String] = [:]
        for name in names {
            if let value = slots.removeValue(forKey: name) { faces[name] = value.trimmingCharacters(in: .whitespaces) }
        }
        return (slots, faces)
    }

    /// `typesetting` with the faces `faces` names set (the pairing it falls
    /// back on gives the weights); unknown families refused with the close one.
    static func applied(_ faces: [String: String], to typesetting: Typesetting?) throws(DesignError) -> Typesetting? {
        guard !faces.isEmpty else { return typesetting }
        var type = typesetting ?? Typesetting(pairing: Pairings.fallback)
        let pairing = Pairings.named(type.pairing ?? Pairings.fallback) ?? Pairings.named(Pairings.fallback)
        let displayWeight = type.display?.weight ?? pairing?.display.first?.weight ?? "bold"
        let textWeight = type.text?.weight ?? pairing?.text.first?.weight ?? "regular"
        for (name, family) in faces.sorted(by: { $0.key < $1.key }) {
            try known(family, field: name)
            if name != "text-font" { type.display = Face(family: family, weight: displayWeight) }
            if name != "display-font" { type.text = Face(family: family, weight: textWeight) }
        }
        if type.scale == nil { type.scale = pairing?.scale }
        if type.base == nil { type.base = pairing?.base }
        return type
    }

    /// Refuses a family that is nowhere: not installed, bundled, in Google Fonts, or a font file.
    static func known(_ family: String, field: String) throws(DesignError) {
        if family.isEmpty { throw .invalid("--var \(field) is empty; it takes a family: \(field)=\"Space Mono\"") }
        if ["ttf", "otf", "ttc"].contains((family as NSString).pathExtension.lowercased()) { return }
        if Fonts.isLocal(family) || OpenFonts.named(family) != nil { return }
        let close = FieldPaths.closest(family, among: Fonts.installedFamilies() + OpenFonts.all.map(\.family))
        throw .missing("no font family \"\(family)\" on this machine or in Google Fonts for \(field)"
                       + (close.map { " — did you mean \($0)?" } ?? "") + "; `design fonts --google NAME` searches")
    }
}
