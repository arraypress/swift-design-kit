//
//  OpenFonts.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The open fonts a design may name: found by family name, fetched on first
//  use through the services' `FontFetching` (the CLI fetches with CLIKit's
//  pinned download), registered for the process from the files fetched.
//

import Foundation

public enum OpenFonts {

    /// Every open font, in catalogue order.
    public static var all: [OpenFont] { list }

    /// The open font called `family` (case and spaces ignored: `playfair-display` works).
    public static func named(_ family: String) -> OpenFont? {
        let key = squash(family)
        return list.first { squash($0.family) == key || $0.folder == key }
    }

    static func squash(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

/// Fetches an open font's files (or finds them already fetched).
public protocol FontFetching: Sendable {

    /// The font's files on this machine — fetching them first if need be.
    func files(for font: OpenFont) async throws(DesignError) -> [URL]

    /// The files when already fetched; `nil` otherwise. Never fetches.
    func fetched(_ font: OpenFont) -> [URL]?
}
