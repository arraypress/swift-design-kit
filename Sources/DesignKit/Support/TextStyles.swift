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

    /// The engine's style for `text`, drawn in `color` (already decided when
    /// the layer asked for `auto`). `lettersOnly` strips everything but the
    /// letters' fill — the mask the contrast check measures.
    static func style(_ text: TextContent, family: String?, color: DesignColor, lettersOnly: Bool = false) -> TextStyle {
        var style = TextStyle(
            fontFamily: family,
            weight: text.weight,
            size: text.size,
            color: lettersOnly ? .white : color.slide,
            accentColor: lettersOnly ? .white : text.accent?.slide,
            mutedColor: lettersOnly ? .white : text.muted?.slide,
            alignment: text.align.rawValue,
            lineHeight: text.lineHeight,
            kerning: text.tracking / 1000 * text.size,
            uppercased: false,
            autoShrink: text.fit == .shrink,
            minimumSize: text.minSize ?? min(text.size, max(8, text.size * 0.35)),
            maxLines: text.maxLines,
            keepsWordsWhole: true)
        if !lettersOnly {
            if let gradient = text.gradient { style.gradientColors = gradient.map(\.slide) }
            if let stroke = text.stroke, stroke.width > 0 {
                // The engine's stroke is a percentage of the point size.
                style.strokeWidth = stroke.width / text.size * 100
                style.strokeStyle = stroke.style == .hollow ? .hollow : .outlined
                style.strokeColor = stroke.color.slide
            }
            if let plate = text.plate, plate.perLine, case .color(let fill) = plate.color {
                style.linePill = fill.slide
            }
        } else if text.stroke?.style == .hollow, let stroke = text.stroke {
            // Hollow letters have no fill: their outline is the ink.
            style.strokeWidth = stroke.width / text.size * 100
            style.strokeStyle = .hollow
            style.strokeColor = .white
        }
        return style
    }

    /// The vertical alignment word the engine takes.
    static func vertical(_ valign: VerticalAlign) -> String { valign.rawValue }
}
