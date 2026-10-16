//
//  OpenFonts.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The open fonts a design may name: every family in google/fonts at a
//  pinned commit (OFL, Apache and Ubuntu licences — see
//  GoogleFontIndex.swift), found by name, fetched on first use through the
//  services' `FontFetching` (the CLI fetches with CLIKit's pinned
//  download, each file checked against the SHA-256 recorded here),
//  registered for the process from the files fetched, the licence file kept
//  beside them.
//

import Foundation

public enum OpenFonts {

    /// Every open font, by name.
    public static var all: [OpenFont] { list }

    /// The few dozen chosen for pairings and listed by `design fonts`
    /// without `--google`: their folders.
    public static let curated: Set<String> = [
        "playfairdisplay", "dmserifdisplay", "fraunces", "bodonimoda", "cormorantgaramond", "instrumentserif", "youngserif",
        "abrilfatface", "bebasneue", "anton", "archivoblack", "oswald", "spacegrotesk", "syne", "unbounded",
        "bricolagegrotesque", "dmsans", "worksans", "manrope", "instrumentsans", "ebgaramond", "lora", "librebaskerville",
        "spacemono", "dmmono", "righteous", "shrikhand", "rubikmonoone", "bungee", "monoton", "pacifico",
    ]

    /// The open font called `family` (case, spaces and hyphens ignored:
    /// `playfair-display` works), by its Google Fonts name first, then by
    /// the name CoreText reads from its files.
    public static func named(_ family: String) -> OpenFont? {
        let key = squash(family)
        guard !key.isEmpty else { return nil }
        return byName[key] ?? byDrawnName[key]
    }

    /// Families whose name contains `query` (case and spaces ignored), the
    /// closest first: an exact name, then names starting with it.
    public static func search(_ query: String) -> [OpenFont] {
        let key = squash(query)
        guard !key.isEmpty else { return list }
        func rank(_ font: OpenFont) -> Int {
            let name = squash(font.family)
            return name == key ? 0 : name.hasPrefix(key) ? 1 : 2
        }
        return list.filter { squash($0.family).contains(key) || squash($0.drawnFamily).contains(key) }
            .sorted { rank($0) == rank($1) ? $0.family < $1.family : rank($0) < rank($1) }
    }

    static func squash(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// The index, read once.
    static let list: [OpenFont] = index.split(separator: "\n").compactMap { OpenFont(indexLine: $0) }

    private static let byName: [String: OpenFont] = Dictionary(list.map { (squash($0.family), $0) }) { first, _ in first }

    private static let byDrawnName: [String: OpenFont] = Dictionary(list.map { (squash($0.drawnFamily), $0) }) { first, _ in first }
}

/// Fetches an open font's files (or finds them already fetched).
public protocol FontFetching: Sendable {

    /// The font's files on this machine — fetching them first if need be.
    func files(for font: OpenFont) async throws(DesignError) -> [URL]

    /// The files when already fetched; `nil` otherwise. Never fetches.
    func fetched(_ font: OpenFont) -> [URL]?
}

extension OpenFont {

    /// One line of the index: name, folder, licence folder, category, axes, files, CoreText's name.
    init?(indexLine line: Substring) {
        let fields = line.trimmingCharacters(in: .whitespaces).split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 6, let category = FontCategory(rawValue: fields[3]) else { return nil }
        let axes = fields[4].split(separator: ",").compactMap { part -> Axis? in
            let bits = part.split(separator: ":")
            guard bits.count == 3, let low = Double(bits[1]), let high = Double(bits[2]) else { return nil }
            return Axis(tag: String(bits[0]), minimum: low, maximum: high)
        }
        let files = fields[5].split(separator: ";").compactMap { part -> File? in
            let bits = part.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            guard bits.count >= 3, let bytes = Int(bits[2]) else { return nil }
            return File(name: bits[0], sha256: bits[1], bytes: bytes,
                        italic: bits.count >= 5 ? bits[3] == "i" : nil, weight: bits.count >= 5 ? Int(bits[4]) : nil)
        }
        guard !files.isEmpty else { return nil }
        let drawn = fields.count >= 7 && !fields[6].isEmpty ? fields[6] : fields[0]
        self.init(family: fields[0], drawnFamily: drawn, folder: fields[1], licenceFolder: fields[2], category: category,
                  axes: axes, files: files)
    }
}
