//
//  ColorRoles.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A design's palette roles from its art, in OKLab (OKLCh: lightness,
//  chroma, hue): the art's colours by ImagePalette's k-means, the dominant
//  and secondary by share, the accent by a harmony rule round the hue
//  wheel, and the neutrals tinted with the dominant's hue. And the readable
//  variant of a role for words: the same hue and chroma, its lightness
//  moved until it reaches the contrast the words need.
//

import CoreGraphics
import Foundation
import ImagePalette
import Legibility

enum ColorRoles {

    /// A colour as lightness (0…1), chroma and hue (degrees).
    struct LCh: Equatable {
        var l: Double
        var c: Double
        var h: Double
    }

    /// The roles for `art` under `spec`.
    static func roles(from art: CGImage?, spec: PaletteSpec) -> PaletteRoles {
        let swatches = art.flatMap { try? PaletteExtractor.extract(from: $0, options: PaletteOptions(count: 6)) } ?? []
        return roles(swatches: swatches.map { (lch(hex: $0.hex), $0.share) }, spec: spec)
    }

    /// The roles for colours (as LCh) with their shares of the art.
    static func roles(swatches: [(LCh, Double)], spec: PaletteSpec) -> PaletteRoles {
        let byShare = swatches.sorted { $0.1 > $1.1 }
        let dominant = byShare.first?.0 ?? LCh(l: 0.3, c: 0.03, h: 250)
        let secondary = byShare.dropFirst().first { distance($0.0, dominant) > 0.08 }?.0
            ?? LCh(l: dominant.l > 0.5 ? dominant.l - 0.25 : dominant.l + 0.25, c: dominant.c, h: dominant.h)
        // The hue the harmony turns from: the dominant's, unless it is grey.
        let base = dominant.c >= 0.04 ? dominant : (byShare.map(\.0).max { $0.c < $1.c }.flatMap { $0.c >= 0.04 ? $0 : nil }
                                                     ?? LCh(l: dominant.l, c: 0.12, h: 40))
        var from = spec.harmony.rawValue
        var accent: LCh
        switch spec.harmony {
        case .auto:
            let candidates = byShare.dropFirst().map(\.0).filter { $0.c >= 0.08 && hueDistance($0.h, dominant.h) >= 60 }
            if let found = candidates.max(by: { $0.c < $1.c }) {
                accent = found
                from = "art"
            } else {
                accent = turned(base, by: 180)
                from = "complementary"
            }
        case .complementary: accent = turned(base, by: 180)
        case .split: accent = turned(base, by: 150)
        case .analogous: accent = turned(base, by: 30)
        case .mono: accent = LCh(l: base.l > 0.55 ? 0.35 : 0.8, c: max(0.08, base.c), h: base.h)
        }
        accent = inGamut(accent)
        let neutral = LCh(l: 0.62, c: min(0.02, dominant.c), h: dominant.h)
        let light = LCh(l: 0.965, c: min(0.012, dominant.c), h: dominant.h)
        let dark = LCh(l: 0.2, c: min(0.025, dominant.c), h: dominant.h)
        var roles = PaletteRoles(dominant: color(dominant), secondary: color(inGamut(secondary)), accent: color(accent),
                                 neutral: color(neutral), light: color(light), dark: color(dark), accentFrom: from)
        for (role, fixed) in spec.fixed {
            switch role {
            case .dominant: roles.dominant = fixed
            case .secondary: roles.secondary = fixed
            case .accent: roles.accent = fixed; roles.accentFrom = "fixed"
            case .neutral: roles.neutral = fixed
            case .light: roles.light = fixed
            case .dark: roles.dark = fixed
            }
        }
        return roles
    }

    /// The accent harmony would make from `base`: its hue turned, vivid enough to read as a colour.
    static func turned(_ base: LCh, by degrees: Double) -> LCh {
        // Light against a dark picture, deeper against a light one, and vivid either way.
        LCh(l: base.l < 0.55 ? 0.8 : 0.52, c: max(0.14, base.c), h: (base.h + degrees).truncatingRemainder(dividingBy: 360))
    }

    /// `color` as words over `range` should be: its own hue, lightened or
    /// darkened until it reaches `target` against the worst of the range.
    /// A role's colour for words: the neutrals (`light`, `dark`) stay at
    /// their end of the scale — when one does not read, the other is taken
    /// (never a mid grey); a hued role keeps its hue and moves its lightness.
    /// The target carries a 15% margin: the checks measure the letters'
    /// own ring, which is harsher than the spread under the line box.
    static func readable(_ color: DesignColor, role: ColorRole, palette: PaletteRoles?,
                         over range: (dark: Double, light: Double), target: Double) -> DesignColor {
        let target = target * 1.15
        func worst(_ c: DesignColor) -> Double { min(Contrast.ratio(c.luminance, range.dark), Contrast.ratio(c.luminance, range.light)) }
        guard role == .light || role == .dark, let palette else { return readable(color, over: range, target: target) }
        let other = role == .light ? palette.dark : palette.light
        let extremes: [DesignColor] = role == .light ? [color, .white, other, .black] : [color, .black, other, .white]
        return extremes.first { worst($0) >= target } ?? extremes.max { worst($0) < worst($1) } ?? color
    }

    static func readable(_ color: DesignColor, over range: (dark: Double, light: Double), target: Double) -> DesignColor {
        func worst(_ c: DesignColor) -> Double { min(Contrast.ratio(c.luminance, range.dark), Contrast.ratio(c.luminance, range.light)) }
        guard worst(color) < target else { return color }
        let start = lch(hex: color.hex)
        var reached: (DesignColor, Double)?      // the first to reach the target, and how far it moved
        var strongest = (color, worst(color))
        for direction in [1.0, -1.0] {
            for step in 1...100 {
                let l = start.l + direction * Double(step) * 0.01
                guard (0...1).contains(l) else { break }
                let candidate = self.color(inGamut(LCh(l: l, c: start.c, h: start.h)))
                let ratio = worst(candidate)
                if ratio > strongest.1 { strongest = (candidate, ratio) }
                if ratio >= target {
                    if reached == nil || Double(step) < reached!.1 { reached = (candidate, Double(step)) }
                    break
                }
            }
        }
        let picked = reached?.0 ?? strongest.0
        return color.components.alpha < 1 ? picked.withAlpha(color.components.alpha) : picked
    }

    // MARK: OKLab

    static func hueDistance(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    static func distance(_ a: LCh, _ b: LCh) -> Double {
        let (aa, ab) = (a.c * cos(a.h * .pi / 180), a.c * sin(a.h * .pi / 180))
        let (ba, bb) = (b.c * cos(b.h * .pi / 180), b.c * sin(b.h * .pi / 180))
        return ((a.l - b.l) * (a.l - b.l) + (aa - ba) * (aa - ba) + (ab - bb) * (ab - bb)).squareRoot()
    }

    static func lch(hex: String) -> LCh {
        let c = ColorParsing.components(hex)
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let r = linear(c.red), g = linear(c.green), b = linear(c.blue)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        let L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        var h = atan2(B, A) * 180 / .pi
        if h < 0 { h += 360 }
        return LCh(l: L, c: (A * A + B * B).squareRoot(), h: h)
    }

    /// Linear sRGB for an LCh, unclamped.
    static func linearRGB(_ v: LCh) -> (Double, Double, Double) {
        let A = v.c * cos(v.h * .pi / 180), B = v.c * sin(v.h * .pi / 180)
        let l = pow(v.l + 0.3963377774 * A + 0.2158037573 * B, 3)
        let m = pow(v.l - 0.1055613458 * A - 0.0638541728 * B, 3)
        let s = pow(v.l - 0.0894841775 * A - 1.2914855480 * B, 3)
        return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
    }

    /// The same lightness and hue with chroma cut until it is a colour sRGB can show.
    static func inGamut(_ v: LCh) -> LCh {
        var v = LCh(l: min(1, max(0, v.l)), c: max(0, v.c), h: v.h)
        for _ in 0..<60 {
            let (r, g, b) = linearRGB(v)
            if [r, g, b].allSatisfy({ $0 >= -0.0005 && $0 <= 1.0005 }) { return v }
            v.c *= 0.94
        }
        v.c = 0
        return v
    }

    static func color(_ v: LCh) -> DesignColor {
        let (r, g, b) = linearRGB(v)
        func encoded(_ x: Double) -> Double {
            let x = min(1, max(0, x))
            return x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1 / 2.4) - 0.055
        }
        return DesignColor(hex: ColorParsing.hex(red: encoded(r), green: encoded(g), blue: encoded(b)))
    }
}
