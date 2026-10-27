//
//  FontFetching.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Fetches an open font's files (or finds them already fetched).
public protocol FontFetching: Sendable {

    /// The font's files on this machine — fetching them first if need be.
    func files(for font: OpenFont) async throws(DesignError) -> [URL]

    /// The files when already fetched; `nil` otherwise. Never fetches.
    func fetched(_ font: OpenFont) -> [URL]?
}
