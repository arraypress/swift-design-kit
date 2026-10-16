//
//  TextStyles.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A text layer as the text engine (CanvasKit's TextDrawer) takes it.
//  Sizes there are points times a scale; here the scale is pixels per design
//  unit, so a size of 80 is 8% of the canvas's shorter side.
//

import CanvasKit
import Foundation

enum TextStyles {

    /// The engine's style for `text`, set in `face` (the system face, bold,
    /// at its own size when `nil`) and drawn in `color` (already decided
    /// when the layer asked for `auto` or a role); `plan` resolves the
    /// colours its spans, stroke and plate name. `lettersOnly` strips
    /// everything but the letters' fill — the mask the contrast check measures.
    static func style(_ text: TextContent, face: ResolvedFace?, color: DesignColor, plan: Plan? = nil,
                      lettersOnly: Bool = false) -> TextStyle {
        let size = face?.size ?? text.size
        var style = TextStyle(
            fontFamily: face?.family,
            weight: face?.weight ?? text.weight ?? "bold",
            size: size,
            color: lettersOnly ? .white : color.slide,
            accentColor: lettersOnly ? .white : plan?.color(text.accent)?.slide,
            mutedColor: lettersOnly ? .white : plan?.color(text.muted)?.slide,
            alignment: text.align.rawValue,
            lineHeight: text.lineHeight,
            kerning: text.tracking / 1000 * size,
            uppercased: false,
            autoShrink: text.fit == .shrink,
            minimumSize: text.minSize ?? min(size, max(8, size * 0.35)),
            maxLines: text.maxLines,
            keepsWordsWhole: true)
        if !lettersOnly {
            if let gradient = text.gradient { style.gradientColors = gradient.map(\.slide) }
            if let stroke = text.stroke, stroke.width > 0 {
                // The engine's stroke is a percentage of the point size.
                style.strokeWidth = stroke.width / size * 100
                style.strokeStyle = stroke.style == .hollow ? .hollow : .outlined
                style.strokeColor = (plan?.color(stroke.color) ?? .black).slide
            }
            if let plate = text.plate, plate.perLine, let fill = plan?.color(plate.color) {
                style.linePill = fill.slide
            }
        } else if text.stroke?.style == .hollow, let stroke = text.stroke {
            // Hollow letters have no fill: their outline is the ink.
            style.strokeWidth = stroke.width / size * 100
            style.strokeStyle = .hollow
            style.strokeColor = .white
        }
        return style
    }

    /// The vertical alignment word the engine takes.
    static func vertical(_ valign: VerticalAlign) -> String { valign.rawValue }
}
