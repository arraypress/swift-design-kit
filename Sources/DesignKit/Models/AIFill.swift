//
//  AIFill.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A background drawn from words, pinned so a replay draws the same picture.
public struct AIFill: Equatable, Sendable {
    /// What to draw.
    public var prompt: String
    /// `flux2-klein-4b` (default) or `sana-sprint-1.6b`.
    public var model: String?
    /// The model's pinned commit — written when the design is made.
    public var revision: String?
    /// The seed — written when the design is made.
    public var seed: UInt32?
    /// The shape drawn (`1:1`, `9:16`…) — written when the design is made,
    /// from the shapes installed, nearest the canvas.
    public var aspect: String?
    /// Steps; `nil` for the model's own.
    public var steps: Int?
    /// Words added after the prompt — a look kept apart from the subject.
    public var style: String?

    /// A background from `prompt`; the rest is pinned when the design is made.
    public init(prompt: String, model: String? = nil, revision: String? = nil, seed: UInt32? = nil,
                aspect: String? = nil, steps: Int? = nil, style: String? = nil) {
        self.prompt = prompt
        self.model = model
        self.revision = revision
        self.seed = seed
        self.aspect = aspect
        self.steps = steps
        self.style = style
    }
}
