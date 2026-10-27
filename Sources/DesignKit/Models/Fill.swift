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
