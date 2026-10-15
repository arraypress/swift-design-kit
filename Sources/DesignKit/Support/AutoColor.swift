//
//  AutoColor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  `color: auto` — a text colour picked from the art. The picture's own
//  colours (ImagePalette, OKLab k-means) are tried first: of those that
//  reach WCAG 4.5:1 against what lies under the words, the most colourful
//  wins, so the type belongs to the picture. When none reads, white or
//  black, whichever stands out more. A plate set to `auto` is the least
//  black or white panel that lifts the words to 4.5:1, or none.
//

import CoreGraphics
import Foundation
import ImagePalette
import Legibility

enum AutoColor {

    /// The darkest and brightest of what lies under `rect` in `image` (its
    /// 10th and 90th percentile luminance; pixels of `image`, top-left). A
    /// colour has to read against both: words over a picture that is dark
    /// on one side and bright on the other are only as legible as their
    /// worst stretch.
    static func range(under rect: CGRect, in image: CGImage) -> (dark: Double, light: Double)? {
        let values = Contrast.luminances(in: image, rect: rect, grid: 48)
        guard let dark = Contrast.percentile(values, 0.1), let light = Contrast.percentile(values, 0.9) else { return nil }
        return (dark, light)
    }

    /// The contrast of `luminance` against the worst of `range`.
    static func worst(_ luminance: Double, over range: (dark: Double, light: Double)) -> Double {
        min(Contrast.ratio(luminance, range.dark), Contrast.ratio(luminance, range.light))
    }

    /// The colour to set words in over `range`, from `art`'s palette when one reads.
    static func pick(over range: (dark: Double, light: Double), art: CGImage) -> (color: DesignColor, note: String) {
        let swatches = (try? PaletteExtractor.extract(from: art, options: PaletteOptions(count: 8))) ?? []
        let readable = swatches.compactMap { swatch -> (DesignColor, Double, Double)? in
            guard let color = DesignColor(swatch.hex) else { return nil }
            let ratio = worst(color.luminance, over: range)
            return ratio >= Contrast.normalTextMinimum ? (color, ratio, swatch.chroma) : nil
        }
        if let best = readable.max(by: { ($0.2, $0.1) < ($1.2, $1.1) }) {
            return (best.0, "picked \(best.0.hex) from the art (at least \(format(best.1)):1 over what is behind it)")
        }
        let white = worst(1, over: range), black = worst(0, over: range)
        let color: DesignColor = white >= black ? .white : .black
        return (color, "no colour in the art reads there; \(color == .white ? "white" : "black") (at least \(format(max(white, black))):1)")
    }

    /// The plate for words of `text` luminance over `range`: `nil` when none is needed.
    static func plate(text: Double, over range: (dark: Double, light: Double)) -> DesignColor? {
        // Light words fight the brightest stretch; dark words the darkest.
        let background = Contrast.plateLuminance(forText: text) == 0 ? range.light : range.dark
        let alpha = Contrast.plateAlpha(text: text, background: background) ?? Contrast.maximumPlateAlpha
        guard alpha > 0 else { return nil }
        let base: DesignColor = Contrast.plateLuminance(forText: text) == 0 ? .black : .white
        return base.withAlpha(alpha)
    }

    static func format(_ value: Double) -> String { String(format: "%.1f", value) }
}
