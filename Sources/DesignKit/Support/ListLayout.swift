//
//  ListLayout.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A list fitted into a box: the largest share of its sizes at which every
//  line fits the width and every line together fits the height. Inline
//  lists break each tier's run of items into the fewest lines, then even
//  them out (the longest line as short as it can be); line lists fill their
//  columns top to bottom. Items are never broken.
//

import CoreGraphics
import Foundation

enum ListLayout {

    /// One line to draw: its words, the tier it belongs to, its box (pixels,
    /// top-left, inside the list's frame), and a detail at its right end.
    struct Line: Equatable {
        var text: String
        var tier: Int
        var rect: CGRect
        var detail: String?
        var number: String?
    }

    struct Result: Equatable {
        var lines: [Line]
        /// The share of the sizes used.
        var scale: Double
        var fits: Bool
    }

    /// Splits written text into items: `|` or new lines between items,
    /// `||` (or a blank line) between tiers, `::` before a detail.
    static func items(from text: String) -> [ListItem] {
        let tiers = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n\n", with: "||").components(separatedBy: "||")
        var items: [ListItem] = []
        for (index, tier) in tiers.enumerated() {
            for part in tier.split(whereSeparator: { $0 == "|" || $0 == "\n" }) {
                let pieces = part.components(separatedBy: "::")
                let words = pieces[0].trimmingCharacters(in: .whitespaces)
                guard !words.isEmpty else { continue }
                let detail = pieces.count > 1 ? pieces[1...].joined(separator: "::").trimmingCharacters(in: .whitespaces) : nil
                items.append(ListItem(text: words, tier: index + 1, detail: detail?.isEmpty == true ? nil : detail))
            }
        }
        return items
    }

    /// The layout of `items` in a box `width`×`height` pixels. `measure`
    /// gives a line's width in pixels at a size in pixels (for the tier);
    /// `size` gives a tier's size in pixels at full scale.
    static func layout(_ items: [ListItem], list: ListContent, width: Double, height: Double,
                       size: (Int) -> Double, measure: (String, Int, Double) -> Double) -> Result {
        guard !items.isEmpty, width > 1, height > 1 else { return Result(lines: [], scale: 1, fits: items.isEmpty) }
        var scale = 1.0
        while true {
            if let lines = attempt(items, list: list, scale: scale, width: width, height: height, size: size, measure: measure) {
                return Result(lines: lines, scale: scale, fits: true)
            }
            if scale <= list.minScale {
                let lines = attempt(items, list: list, scale: scale, width: width, height: .infinity, size: size, measure: measure,
                                    overflowing: true) ?? []
                return Result(lines: placed(lines, list: list, height: height), scale: scale, fits: false)
            }
            scale = max(list.minScale, scale * 0.94)
        }
    }

    /// The lines at `scale`, or `nil` when they do not fit.
    static func attempt(_ items: [ListItem], list: ListContent, scale: Double, width: Double, height: Double,
                        size: (Int) -> Double, measure: (String, Int, Double) -> Double, overflowing: Bool = false) -> [Line]? {
        var lines: [Line] = []
        var y = 0.0
        switch list.flow {
        case .inline:
            let separator = " \(list.separator) "
            let tiers = Dictionary(grouping: items, by: \.tier).keys.sorted()
            for (position, tier) in tiers.enumerated() {
                let names = items.filter { $0.tier == tier }.map(\.text)
                let px = size(tier) * scale
                let widths = names.map { measure($0, tier, px) }
                let gap = measure(separator, tier, px)
                if !overflowing, widths.contains(where: { $0 > width }) { return nil }
                let rows = balanced(widths, gap: gap, width: width)
                if position > 0 { y += px * 0.35 }
                for row in rows {
                    let lineHeight = px * list.lineHeight
                    lines.append(Line(text: row.map { names[$0] }.joined(separator: separator), tier: tier,
                                      rect: CGRect(x: 0, y: y, width: width, height: lineHeight)))
                    y += lineHeight
                }
            }
        case .lines:
            let columns = max(1, min(list.columns, items.count))
            let gutter = width * 0.06
            let columnWidth = (width - gutter * Double(columns - 1)) / Double(columns)
            let perColumn = Int((Double(items.count) / Double(columns)).rounded(.up))
            let digits = String(items.count).count
            var columnHeights: [Double] = []
            for column in 0..<columns {
                var cy = 0.0
                for index in (column * perColumn)..<min(items.count, (column + 1) * perColumn) {
                    let item = items[index]
                    let px = size(item.tier) * scale
                    let number = list.numbered ? String(repeating: "0", count: max(0, max(2, digits) - String(index + 1).count)) + "\(index + 1)" : nil
                    var needed = measure(item.text, item.tier, px)
                    if let number { needed += measure(number + "  ", item.tier, px) }
                    if let detail = item.detail { needed += measure("   " + detail, item.tier, px) }
                    if !overflowing, needed > columnWidth { return nil }
                    let lineHeight = px * list.lineHeight
                    lines.append(Line(text: item.text, tier: item.tier,
                                      rect: CGRect(x: Double(column) * (columnWidth + gutter), y: cy, width: columnWidth, height: lineHeight),
                                      detail: item.detail, number: number))
                    cy += lineHeight
                }
                columnHeights.append(cy)
            }
            y = columnHeights.max() ?? 0
        }
        if !overflowing, y > height { return nil }
        return overflowing ? lines : placed(lines, list: list, height: height)
    }

    /// The block moved down its box by `valign`.
    static func placed(_ lines: [Line], list: ListContent, height: Double) -> [Line] {
        let used = lines.map(\.rect.maxY).max() ?? 0
        let shift: Double = switch list.valign {
        case .top: 0
        case .middle: (height - used) / 2
        case .bottom: height - used
        }
        return lines.map { var line = $0; line.rect.origin.y += shift; return line }
    }

    /// Item indices split into the fewest lines no wider than `width`, then
    /// evened out: the widest line made as narrow as it can be with that many lines.
    static func balanced(_ widths: [Double], gap: Double, width: Double) -> [[Int]] {
        guard !widths.isEmpty else { return [] }
        func lineWidth(_ from: Int, _ to: Int) -> Double {
            widths[from...to].reduce(0, +) + gap * Double(to - from)
        }
        // The fewest lines, greedily.
        var count = 1, current = 0.0
        for (index, item) in widths.enumerated() {
            let next = current == 0 ? item : current + gap + item
            if next > width, current > 0 { count += 1; current = item } else { current = next }
            _ = index
        }
        // Then the partition into `count` lines whose widest is narrowest (small n: dynamic programming).
        let n = widths.count
        var best = [[Double]](repeating: [Double](repeating: .infinity, count: count + 1), count: n + 1)
        var cut = [[Int]](repeating: [Int](repeating: 0, count: count + 1), count: n + 1)
        best[0][0] = 0
        for end in 1...n {
            for lines in 1...min(count, end) {
                for start in (lines - 1)..<end {
                    let candidate = max(best[start][lines - 1], lineWidth(start, end - 1))
                    if candidate < best[end][lines] { best[end][lines] = candidate; cut[end][lines] = start }
                }
            }
        }
        var rows: [[Int]] = []
        var end = n, lines = count
        while lines > 0 {
            let start = cut[end][lines]
            rows.insert(Array(start..<end), at: 0)
            end = start
            lines -= 1
        }
        return rows
    }
}
