//
//  Lists.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A list layer laid out into its lines once its frame is known: the items
//  filled from the vars and split, the face resolved, every line measured by
//  the text engine at each trial size, and the lines handed back as text
//  layers placed in the list's frame — drawn, and checked, like any words.
//

import CanvasKit
import CoreGraphics
import Foundation

enum Lists {

    /// Whether any layer is a list.
    static func any(_ layers: [Layer]) -> Bool {
        Layouter.entries(layers).contains { if case .list = $0.layer.content { return true }; return false }
    }

    /// `layers` with every list laid out into its lines, using the frames
    /// already placed (`frames`, by path).
    static func expanded(_ layers: [Layer], prefix: String = "", frames: [String: CGRect], design: Design, geometry: CanvasGeometry,
                         services: DesignServices) async throws(DesignError) -> [Layer] {
        var result: [Layer] = []
        for (index, layer) in layers.enumerated() {
            let path = prefix.isEmpty ? String(index) : "\(prefix).\(index)"
            var layer = layer
            switch layer.content {
            case .group(let children):
                layer.content = .group(try await expanded(children, prefix: path, frames: frames, design: design,
                                                          geometry: geometry, services: services))
            case .list(var list):
                if let frame = frames[path] {
                    try await layOut(&list, id: layer.id, frame: frame, design: design, geometry: geometry, services: services)
                }
                layer.content = .list(list)
            default:
                break
            }
            result.append(layer)
        }
        return result
    }

    /// The items a list holds, slots filled and cased.
    static func items(_ list: ListContent, vars: [String: String]) -> [ListItem] {
        let raw: [ListItem] = switch list.items {
        case .text(let text): ListLayout.items(from: Words.filled(text, vars: vars))
        case .items(let items): items.map {
            ListItem(text: Words.filled($0.text, vars: vars), tier: $0.tier, detail: $0.detail.map { Words.filled($0, vars: vars) })
        }
        }
        return raw.map { ListItem(text: Words.cased($0.text, list.textCase), tier: $0.tier, detail: $0.detail) }
    }

    static func layOut(_ list: inout ListContent, id: String?, frame: CGRect, design: Design, geometry: CanvasGeometry,
                       services: DesignServices) async throws(DesignError) {
        let unit = geometry.unit
        let items = items(list, vars: design.vars)
        let weights = list.weights ?? []
        func weight(_ tier: Int) -> String { weights.isEmpty ? "bold" : weights[min(tier, weights.count) - 1] }
        func units(_ tier: Int) -> Double { list.sizes[min(tier, list.sizes.count) - 1] }
        let face = try await Fonts.face(for: TextContent(text: "", font: list.font, weight: weight(1), size: units(1)),
                                         typesetting: design.fonts, folder: services.folder, fetcher: services.fonts)
        let family = face.family
        let roleWeight = list.weights == nil ? face.weight : nil
        func measure(_ text: String, _ tier: Int, _ px: Double) -> Double {
            let style = TextStyle(fontFamily: family, weight: roleWeight ?? weight(tier), size: px, kerning: list.tracking / 1000 * px,
                                  autoShrink: false)
            return Double(TextDrawer.line(text: text, style: style, pointSize: px)?.lines.first?.width ?? 0)
        }
        let laid = ListLayout.layout(items, list: list, width: frame.width, height: frame.height,
                                     size: { units($0) * unit }, measure: measure)
        let separator = list.separator.trimmingCharacters(in: .whitespaces)
        var lines: [Layer] = []
        for (number, line) in laid.lines.enumerated() {
            let size = units(line.tier) * laid.scale
            let placement = Placement(anchor: .topLeft, width: line.rect.width / frame.width, height: line.rect.height / frame.height,
                                      x: line.rect.minX / frame.width, y: line.rect.minY / frame.height)
            var words = line.text
            if list.flow == .inline, !separator.isEmpty, list.separatorColor != nil {
                words = words.replacingOccurrences(of: " \(separator) ", with: " ~\(separator)~ ")
            }
            if let prefix = line.number { words = (list.separatorColor != nil ? "~\(prefix)~" : prefix) + "  " + words }
            let lineID = id.map { "\($0)-\(number + 1)" }
            func text(_ words: String, align: TextAlign, color: Paint) -> TextContent {
                TextContent(text: words, font: list.font, weight: roleWeight ?? weight(line.tier), size: size, minSize: size * 0.85,
                            maxLines: 1, fit: .shrink, tracking: list.tracking, align: align, valign: .middle, color: color,
                            muted: list.separatorColor)
            }
            let align: TextAlign = line.detail != nil && list.align == .center ? .left : list.align
            lines.append(Layer(id: lineID, frame: placement, content: .text(text(words, align: align, color: list.color))))
            if let detail = line.detail {
                lines.append(Layer(id: lineID.map { "\($0)-detail" }, frame: placement,
                                   content: .text(text(detail, align: .right, color: list.detailColor ?? list.color))))
            }
        }
        list.lines = lines
        list.fitted = laid.fits
    }
}
