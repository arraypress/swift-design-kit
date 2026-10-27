//
//  TextPaths.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Words set along a line: an arc bowed up or down, a circle, a wave. The
//  words are laid out on one line by the text engine, then each glyph is
//  moved to its place along the curve and turned to its slope. The curve is
//  sampled as a polyline and walked by arc length, so every shape is placed
//  the same way. Too long for the curve, the words shrink (to the layer's
//  min size); still too long, they do not fit and the check says so.
//

import CanvasKit
import CoreGraphics
import Foundation

enum TextPaths {

    /// How much of a circle words may go round, and of an open curve's length.
    static let circleShare = 0.94
    static let openShare = 0.98

    /// `words` along `path` in `box` (CoreGraphics space), at the largest size
    /// up to the style's that fits.
    static func layout(_ words: String, style: TextStyle, path: TextPath, in box: CGRect, scale: Double) -> TextOutlines? {
        guard box.width > 1, box.height > 1 else { return nil }
        var size = style.size * scale
        let minimum = min(size, style.minimumSize * scale)
        while true {
            guard let line = TextDrawer.line(text: words, style: style, pointSize: size), let first = line.lines.first else { return nil }
            let curve = polyline(path, in: box, ascent: first.ascent, descent: first.descent)
            let room = curve.length * (path.shape == .circle ? circleShare : openShare)
            let fits = first.width <= room
            if fits || !style.autoShrink || size <= minimum {
                return placed(line, along: curve, size: size, fits: fits, box: box)
            }
            size = max(minimum, size * 0.94)
        }
    }

    /// The glyphs of `line` moved onto `curve`, centred on its middle.
    static func placed(_ line: TextOutlines, along curve: Polyline, size: Double, fits: Bool, box: CGRect) -> TextOutlines {
        let width = line.lines.first?.width ?? 0
        let offset = (curve.length - width) / 2
        var glyphs: [GlyphOutline] = []
        var bounds = CGRect.null
        for glyph in line.glyphs {
            let along = offset + glyph.origin.x + glyph.advance / 2
            let (point, angle) = curve.point(at: along)
            var transform = CGAffineTransform(translationX: point.x, y: point.y)
                .rotated(by: angle)
                .translatedBy(x: -glyph.advance / 2, y: glyph.origin.y)
            guard let moved = glyph.path.copy(using: &transform) else { continue }
            glyphs.append(GlyphOutline(path: moved, origin: .zero, advance: glyph.advance, color: glyph.color, character: glyph.character))
            if !moved.isEmpty { bounds = bounds.union(moved.boundingBoxOfPath) }
        }
        let rects = bounds.isNull ? [] : [bounds]
        let fit = TextFit(pointSize: size, fits: fits, lineCount: 1, frame: box, lineRects: rects)
        return TextOutlines(fit: fit, glyphs: glyphs, lines: line.lines, text: line.text)
    }

    /// The baseline the words run along, inside `box` with room for the letters' ascent and descent.
    static func polyline(_ path: TextPath, in box: CGRect, ascent: CGFloat, descent: CGFloat) -> Polyline {
        let samples = 720
        var points: [CGPoint] = []
        switch path.shape {
        case .circle:
            // Clockwise from the top, the words outside the baseline, centred at `start`.
            let radius = max(1, min(box.width, box.height) / 2 - ascent)
            let start = path.start * .pi / 180
            for index in 0...samples {
                let theta = start - .pi + 2 * .pi * Double(index) / Double(samples)
                points.append(CGPoint(x: box.midX + radius * sin(theta), y: box.midY + radius * cos(theta)))
            }
        case .arc:
            // A circular arc across the frame; its depth `bend` of the room left after the letters.
            let room = max(0, box.height - ascent - descent)
            let sagitta = max(0.5, abs(path.bend) * room)
            let chord = box.width
            let radius = (chord * chord / 4 + sagitta * sagitta) / (2 * sagitta)
            let half = asin(min(1, chord / 2 / radius))
            let up = path.bend > 0
            // Rainbow: the top of the letters at the frame's top; smile: their feet at its bottom.
            let apex = up ? box.maxY - ascent : box.minY + descent
            let centre = CGPoint(x: box.midX, y: up ? apex - radius : apex + radius)
            for index in 0...samples {
                let theta = -half + 2 * half * Double(index) / Double(samples)
                points.append(up ? CGPoint(x: centre.x + radius * sin(theta), y: centre.y + radius * cos(theta))
                                 : CGPoint(x: centre.x + radius * sin(theta), y: centre.y - radius * cos(theta)))
            }
        case .wave:
            let amplitude = max(0, path.amplitude * (box.height - ascent - descent) / 2)
            let middle = box.midY - (ascent - descent) / 2
            for index in 0...samples {
                let t = Double(index) / Double(samples)
                points.append(CGPoint(x: box.minX + box.width * t, y: middle + amplitude * sin(2 * .pi * path.waves * t)))
            }
        }
        return Polyline(points)
    }
}
