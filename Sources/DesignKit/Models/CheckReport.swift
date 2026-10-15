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

    /// No failures (warnings allowed).
    public var passed: Bool { !findings.contains { $0.level == .fail } }

    public init(findings: [Finding], text: [TextMeasure], sources: [SourceNote]) {
        self.findings = findings
        self.text = text
        self.sources = sources
    }
}

/// One thing a check found.
public struct Finding: Codable, Equatable, Sendable {

    public enum Level: String, Codable, Sendable, Comparable {
        case fail, warn
        public static func < (a: Level, b: Level) -> Bool { a == .fail && b == .warn }
    }

    /// `contrast`, `read-back`, `clipped`, `safe-area`, `fit`, `print-size`,
    /// `resolution`, `bleed`, `platform`, `unfilled`, `faces`.
    public var check: String
    public var level: Level
    /// The layer's path and id, when it is about one.
    public var layer: String?
    public var id: String?
    public var message: String
    /// What would fix it, as a change to the design.
    public var fix: String?

    public init(check: String, level: Level, layer: String? = nil, id: String? = nil, message: String, fix: String? = nil) {
        self.check = check
        self.level = level
        self.layer = layer
        self.id = id
        self.message = message
        self.fix = fix
    }
}

/// One text layer, measured on the drawn pixels.
public struct TextMeasure: Codable, Equatable, Sendable {
    public var layer: String
    public var id: String?
    /// The words as drawn (markup removed).
    public var words: String
    /// The size drawn, after any shrinking: pixels, and design units.
    public var sizePixels: Double
    public var sizeUnits: Double
    /// Points on paper, for print.
    public var sizePoints: Double?
    public var lines: Int
    public var fits: Bool
    /// Where the ink is, pixels, top-left: `[x, y, width, height]`.
    public var ink: [Double]?
    public var insideSafe: Bool
    public var insideTrim: Bool
    /// WCAG ratio of the letters against the ring of pixels round them.
    public var contrast: Double?
    /// The ratio it needs: 3 for large type, 4.5 otherwise.
    public var contrastNeeded: Double
    /// Share of the words on-device text recognition reads back; `nil` when
    /// recognition could not run.
    public var readBack: Double?
    public var color: String
    public var plate: String?
    public var movedTo: String?
    public var note: String?
}
