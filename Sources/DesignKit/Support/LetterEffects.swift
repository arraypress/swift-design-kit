//
//  LetterEffects.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What is drawn from the letters' outlines: words along a path (filled,
//  stroked or graded from their glyph shapes), depth stacked behind them,
//  and a line inside them.
//

import CanvasKit
import CoreGraphics
import Foundation

enum LetterEffects {

    /// The most copies an extrusion stacks: past this, steps are spaced out.
    static let extrudeSteps = 200

    /// Glyph outlines drawn as the text engine would draw the words: filled
    /// in their colours, graded, stroked round, or hollow. Bare letters are white.
    static func fill(_ outlines: TextOutlines, style: TextStyle, lettersOnly: Bool, context: CGContext) {
        let path = style.strokeWidth > 0 ? solid(outlines) : outlines.path
        let size = outlines.fit.pointSize
        let strokeWidth = style.strokeWidth / 100 * size
        context.saveGState()
        defer { context.restoreGState() }
        if style.strokeStyle == .hollow, strokeWidth > 0 {
            context.addPath(path)
            context.setStrokeColor(lettersOnly ? CGColor(gray: 1, alpha: 1) : Inks.converted((style.strokeColor ?? style.color ?? .white).cgColor))
            context.setLineWidth(strokeWidth)
            context.setLineJoin(.round)
            context.strokePath()
            return
        }
        if lettersOnly {
            context.addPath(path)
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fillPath()
            return
        }
        if style.strokeStyle == .outlined, strokeWidth > 0 {
            context.addPath(path)
            context.setStrokeColor(Inks.converted((style.strokeColor ?? .black).cgColor))
            context.setLineWidth(strokeWidth * 2)
            context.setLineJoin(.round)
            context.strokePath()
        }
        if let colors = style.gradientColors, colors.count >= 2, let bounds = outlines.fit.linesBounds,
           let gradient = CGGradient(colorsSpace: Inks.space ?? CGColorSpace(name: CGColorSpace.sRGB),
                                     colors: colors.map { Inks.converted($0.cgColor) } as CFArray, locations: nil) {
            context.saveGState()
            context.addPath(path)
            context.clip()
            context.drawLinearGradient(gradient, start: CGPoint(x: bounds.midX, y: bounds.maxY),
                                       end: CGPoint(x: bounds.midX, y: bounds.minY), options: [])
            context.restoreGState()
            return
        }
        for glyph in outlines.glyphs {
            context.addPath(glyph.placed)
            context.setFillColor(glyph.color)
            context.fillPath()
        }
    }

    /// Copies of the letters stacked back from the face along `extrude.angle`,
    /// the nearest in the side colour, the furthest `shade` darker.
    static func extrude(_ outlines: TextOutlines, _ extrude: Extrude, face: DesignColor, plan: Plan, unit: Double, context: CGContext) {
        let path = solid(outlines)
        let depth = extrude.depth * unit
        let angle = extrude.angle * .pi / 180
        // Clockwise from up, in a space whose y runs up.
        let dx = sin(angle) * depth, dy = cos(angle) * depth
        let side = plan.color(extrude.color) ?? face.darkened(0.35)
        let steps = max(1, min(extrudeSteps, Int(depth.rounded(.up))))
        context.saveGState()
        defer { context.restoreGState() }
        for step in stride(from: steps, through: 1, by: -1) {
            let t = Double(step) / Double(steps)
            var move = CGAffineTransform(translationX: dx * t, y: dy * t)
            guard let copy = path.copy(using: &move) else { continue }
            context.addPath(copy)
            context.setFillColor(side.darkened(extrude.shade * t).cgColor)
            context.fillPath()
        }
    }

    /// The letters as one outline with no overlaps: a glyph drawn from
    /// overlapping contours (the bowl of a P across its stem) would show its
    /// seams in a stroke.
    static func solid(_ outlines: TextOutlines) -> CGPath {
        outlines.path.normalized(using: .winding)
    }

    /// A line `inline.width` thick running `inline.inset` inside the letters' edge.
    static func inline(_ outlines: TextOutlines, _ inline: Inline, plan: Plan, unit: Double, context: CGContext) {
        let band = inlineBand(outlines, inline, unit: unit)
        context.saveGState()
        defer { context.restoreGState() }
        context.addPath(band)
        context.setFillColor((plan.color(inline.color) ?? .white).cgColor)
        context.fillPath()
    }

    /// The inline as a shape: the letters' outline stroked `inset + width` in,
    /// less the part `inset` in, kept inside the letters. A filled shape, not
    /// a stroke through a transparency layer, so a PDF draws it in its own
    /// colours and an SVG writes it as one path.
    static func inlineBand(_ outlines: TextOutlines, _ inline: Inline, unit: Double) -> CGPath {
        let letters = solid(outlines)
        let inset = inline.inset * unit, width = inline.width * unit
        let outer = letters.copy(strokingWithWidth: 2 * (inset + width), lineCap: .round, lineJoin: .round, miterLimit: 10)
        var band = outer.intersection(letters, using: .winding)
        if inset > 0 {
            let inner = letters.copy(strokingWithWidth: 2 * inset, lineCap: .round, lineJoin: .round, miterLimit: 10)
            band = band.subtracting(inner, using: .winding)
        }
        return band
    }
}
