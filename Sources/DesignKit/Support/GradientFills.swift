//
//  GradientFills.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A GradientKit wallpaper as a background, chosen the way the `gradients`
//  tool chooses: the same seed, palette and motif draw the same picture in
//  both. A palette is named by its slug (`sea-glass`) or name; `dark` and
//  `light` are made from the seed; none is one of the soft palettes picked
//  by the seed, and no motif one of the featured motifs.
//

import CoreGraphics
import Foundation
import GradientKit

enum GradientFills {

    /// Every palette a design can name, soft ones first.
    static var palettes: [Palette] { Palette.soft + Palette.builtIn }

    /// `Sea Glass` → `sea-glass`.
    static func slug(_ name: String) -> String {
        name.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: "-")
    }

    /// Every palette's slug, for listings and refusals.
    static var paletteNames: [String] { palettes.map { slug($0.name) } + ["dark", "light"] }

    /// Every motif's name.
    static var motifNames: [String] { Motif.allCases.map(\.rawValue) }

    /// The palette and motif a spec names, refused when unknown.
    static func choices(_ spec: GradientFill) throws(DesignError) -> (palette: Palette, motif: Motif) {
        let palette: Palette
        switch spec.palette.map(slug) {
        case nil: palette = Palette.soft[Int(spec.seed % UInt64(Palette.soft.count))]
        case "dark"?: palette = Palette.generate(mood: .dark, seed: spec.seed)
        case "light"?: palette = Palette.generate(mood: .light, seed: spec.seed)
        case let wanted?:
            guard let found = palettes.first(where: { slug($0.name) == wanted }) else {
                throw .invalid(Choices.refusal(spec.palette ?? "", at: "gradient palette", among: paletteNames))
            }
            palette = found
        }
        let motif: Motif
        if let name = spec.motif {
            guard let found = Motif(rawValue: name.lowercased()) else {
                throw .invalid(Choices.refusal(name, at: "gradient motif", among: motifNames))
            }
            motif = found
        } else {
            motif = Motif.featured[Int(spec.seed % UInt64(Motif.featured.count))]
        }
        return (palette, motif)
    }

    /// The wallpaper, `width`×`height` pixels. Needs a Metal device.
    static func render(_ spec: GradientFill, width: Int, height: Int) throws(DesignError) -> CGImage {
        let (palette, motif) = try choices(spec)
        let wallpaper = Wallpaper.generate(motif, palette: palette, seed: spec.seed, aspect: Double(width) / Double(height))
        do {
            let renderer = try WallpaperRenderer()
            return try renderer.render(wallpaper, width: width, height: height, options: .init(bitDepth: .eight))
        } catch {
            throw .failed("the gradient could not be drawn: \(error)")
        }
    }
}
