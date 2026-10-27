//
//  TextDecision.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What was decided for one text layer.
public struct TextDecision: Codable, Equatable, Sendable {
    /// The letters' colour, as decided.
    public var color: DesignColor
    /// The plate's colour, when one is drawn.
    public var plate: DesignColor?
    /// Where `avoid` moved the words, when it did.
    public var move: TextMove?
    /// Why it moved, or how much of what it avoids it still covers.
    public var note: String?
}
