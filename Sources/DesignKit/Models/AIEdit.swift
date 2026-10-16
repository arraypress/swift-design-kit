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
    public var model: String?
    /// The model's pinned commit — written when the design is made.
    public var revision: String?
    public var seed: UInt32?
    /// The shape the edit is drawn at — written when made.
    public var aspect: String?
    public var steps: Int?
    /// How far the picture may move, `0…1`: low keeps the layout and detail, 1 redraws it with the old one as a reference.
    public var strength: Double

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
