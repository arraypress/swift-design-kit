//
//  Layout.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A frame from its rule. Pixels, origin top-left.
//

import CoreGraphics
import Foundation

enum Layout {

    /// The frame `placement` gives inside `area`: size as fractions of the
    /// area, the anchored edges held `margin` in, a column span when given,
    /// under or over `reference` when given, then the nudge.
    static func frame(_ placement: Placement, in area: CGRect, grid: Grid, anchor: Anchor? = nil,
                      reference: CGRect? = nil) -> CGRect {
        let anchor = anchor ?? placement.anchor
        var width = placement.width * area.width
        var height = placement.height * area.height
        if let aspect = placement.aspect { height = width / aspect }
        let margin = placement.margin * min(area.width, area.height)

        var x: Double
        switch anchor.horizontal {
        case 0: x = area.minX + margin
        case 1: x = area.maxX - margin - width
        default: x = area.midX - width / 2
        }
        if let columns = placement.columns, columns.count == 2 {
            let span = column(start: columns[0], count: columns[1], in: area, grid: grid)
            x = span.x
            width = span.width
            if placement.aspect != nil, let aspect = placement.aspect { height = width / aspect }
        }

        var y: Double
        switch anchor.vertical {
        case 0: y = area.minY + margin
        case 1: y = area.maxY - margin - height
        default: y = area.midY - height / 2
        }
        if let reference {
            if placement.below != nil { y = reference.maxY + placement.gap * area.height }
            if placement.above != nil { y = reference.minY - placement.gap * area.height - height }
        }
        return CGRect(x: x + placement.x * area.width, y: y + placement.y * area.height, width: width, height: height)
    }

    /// The left edge and width of `count` columns from `start` (1-based).
    static func column(start: Int, count: Int, in area: CGRect, grid: Grid) -> (x: Double, width: Double) {
        let columns = max(1, grid.columns)
        let gutter = grid.gutter * area.width
        let columnWidth = (area.width - gutter * Double(columns - 1)) / Double(columns)
        let first = min(max(1, start), columns)
        let span = min(max(1, count), columns - first + 1)
        return (area.minX + Double(first - 1) * (columnWidth + gutter), Double(span) * columnWidth + Double(span - 1) * gutter)
    }

    /// A top-left rect in a bottom-left (CoreGraphics) space `height` tall, and back.
    static func flipped(_ rect: CGRect, height: Double) -> CGRect {
        CGRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// How much of `rect` the `obstacles` cover, in square pixels.
    static func overlap(_ rect: CGRect, _ obstacles: [CGRect]) -> Double {
        obstacles.reduce(0) { total, obstacle in
            let shared = rect.intersection(obstacle)
            return shared.isNull ? total : total + shared.width * shared.height
        }
    }

    /// The anchors tried, in order, when the declared one covers what a layer avoids.
    static func alternatives(to anchor: Anchor) -> [Anchor] {
        var tried: [Anchor] = [anchor, anchor.flippedVertically, anchor.flippedHorizontally,
                               anchor.flippedVertically.flippedHorizontally, .top, .bottom, .center]
        var seen = Set<String>()
        tried = tried.filter { seen.insert($0.rawValue).inserted }
        return tried
    }
}
