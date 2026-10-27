//
//  TemplateSlot.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One value a template takes.
public struct TemplateSlot: Equatable, Sendable, Codable {
    /// Lowercase: `title`.
    public var name: String
    /// What it fills, in a few words.
    public var summary: String
    /// Used when no value is given.
    public var defaultValue: String

    /// A slot called `name`.
    public init(name: String, summary: String, defaultValue: String) {
        self.name = name
        self.summary = summary
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name, summary
        case defaultValue = "default"
    }
}
