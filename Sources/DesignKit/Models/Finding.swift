//
//  Finding.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One thing a check found.
public struct Finding: Codable, Equatable, Sendable {

    /// How much a finding matters.
    public enum Level: String, Codable, Sendable, Comparable {
        /// `fail` blocks the design; `warn` is worth a look.
        case fail, warn
        /// Failures sort first.
        public static func < (a: Level, b: Level) -> Bool { a == .fail && b == .warn }
    }

    /// `contrast`, `read-back`, `clipped`, `safe-area`, `fit`, `print-size`,
    /// `resolution`, `bleed`, `platform`, `unfilled`, `avoid`, `subject`,
    /// `families`, `colors`, `embedding`.
    public var check: String
    /// Whether it fails the design or warns.
    public var level: Level
    /// The layer's path and id, when it is about one.
    public var layer: String?
    /// The layer's id, when it has one.
    public var id: String?
    /// What was found, in a sentence.
    public var message: String
    /// What would fix it, as a change to the design.
    public var fix: String?

    /// A finding by `check`.
    public init(check: String, level: Level, layer: String? = nil, id: String? = nil, message: String, fix: String? = nil) {
        self.check = check
        self.level = level
        self.layer = layer
        self.id = id
        self.message = message
        self.fix = fix
    }
}
