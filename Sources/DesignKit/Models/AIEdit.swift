//
//  AIEdit.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A background changed in place by words — "make it night", "add falling
/// snow" — on this machine (FLUX.2 Klein 4B's edit path). Pinned like a made
/// picture: model, revision, shape, seed.
public struct AIEdit: Equatable, Sendable {
    /// What to change.
    public var prompt: String
    /// The model that makes the edit — written when the design is made.
    public var model: String?
    /// The model's pinned commit — written when the design is made.
    public var revision: String?
    /// The seed — written when made.
    public var seed: UInt32?
    /// The shape the edit is drawn at — written when made.
    public var aspect: String?
    /// Steps; `nil` for the model's own.
    public var steps: Int?
    /// How far the picture may move, `0…1`: low keeps the layout and detail, 1 redraws it with the old one as a reference.
    public var strength: Double

    /// An edit by `prompt`; the rest is pinned when the design is made.
    public init(prompt: String, model: String? = nil, revision: String? = nil, seed: UInt32? = nil, aspect: String? = nil,
                steps: Int? = nil, strength: Double = 0.75) {
        self.prompt = prompt
        self.model = model
        self.revision = revision
        self.seed = seed
        self.aspect = aspect
        self.steps = steps
        self.strength = strength
    }
}
