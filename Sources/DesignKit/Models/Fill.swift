//
//  Fill.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a background is made of.
///
/// Written as an object (`{"kind": "ai", "prompt": …}`) or, in a template or
/// `--var`, as a short string: `#1B2A4A`, `linear:#FF9A8B,#FF6A88,angle=160`,
/// `radial:#FDE68A,#B45309`, `gradient:seed=42,palette=lagoon,motif=flow`,
/// `imagine:neon city at night, rain`, `image:cover.jpg`. A design saved as a
/// recipe always holds the object, with everything pinned.
public enum Fill: Equatable, Sendable {

    /// One colour.
    case color(DesignColor)

    /// A straight blend; `angle` in degrees, 0 pointing up, clockwise.
    case linear(colors: [DesignColor], angle: Double)

    /// A blend from the centre out.
    case radial(colors: [DesignColor])

    /// A gradient wallpaper from GradientKit, by seed.
    case gradient(GradientFill)

    /// A picture file.
    case image(path: String)

    /// A picture made on this machine from words.
    case ai(AIFill)
}

/// A GradientKit wallpaper: the same seed, palette and motif draw the same picture.
public struct GradientFill: Equatable, Sendable {
    public var seed: UInt64
    /// A palette's name (`lagoon`, `sea-glass`), `dark` / `light` (made from
    /// the seed), or `nil` for one of the soft palettes picked by the seed.
    public var palette: String?
    /// A motif's name (`flow`, `mesh`, `aurora`…), or `nil` for one of the
    /// featured motifs picked by the seed.
    public var motif: String?

    public init(seed: UInt64, palette: String? = nil, motif: String? = nil) {
        self.seed = seed
        self.palette = palette
        self.motif = motif
    }
}

/// A background drawn from words, pinned so a replay draws the same picture.
public struct AIFill: Equatable, Sendable {
    public var prompt: String
    /// `flux2-klein-4b` (default) or `sana-sprint-1.6b`.
    public var model: String?
    /// The model's pinned commit — written when the design is made.
    public var revision: String?
    public var seed: UInt32?
    /// The shape drawn (`1:1`, `9:16`…) — written when the design is made,
    /// from the shapes installed, nearest the canvas.
    public var aspect: String?
    /// Steps; `nil` for the model's own.
    public var steps: Int?
    /// Words added after the prompt — a look kept apart from the subject.
    public var style: String?

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
