//
//  CheckReport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What the blind checks measured on the finished picture.
public struct CheckReport: Codable, Equatable, Sendable {

    /// Every finding, failures first.
    public var findings: [Finding]

    /// Each text layer, as measured.
    public var text: [TextMeasure]

    /// Each picture, and how far it is enlarged.
    public var sources: [SourceNote]

    /// The palette roles found in the art.
    public var palette: PaletteRoles?

    /// The faces the words are set in (`family weight`), and the pairing they came from.
    public var fonts: [String]
    /// The pairing the faces came from.
    public var pairing: String?

    /// The colours words and shapes are drawn in, besides the art's own.
    public var colors: [String]

    /// No failures (warnings allowed).
    public var passed: Bool { !findings.contains { $0.level == .fail } }

    /// A report of these findings and measures.
    public init(findings: [Finding], text: [TextMeasure], sources: [SourceNote], palette: PaletteRoles? = nil,
                fonts: [String] = [], pairing: String? = nil, colors: [String] = []) {
        self.findings = findings
        self.text = text
        self.sources = sources
        self.palette = palette
        self.fonts = fonts
        self.pairing = pairing
        self.colors = colors
    }
}
