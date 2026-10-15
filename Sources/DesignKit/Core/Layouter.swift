//
//  Layouter.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Every layer's frame, in order: each placed by its rule in its area (a
//  group's children in the group's frame), `below` / `above` measured off
//  an earlier layer's drawn extent — a text layer's lines, not its box.
//

import CanvasKit
import CoreGraphics
import Foundation

enum Layouter {

    /// One layer and where it sits in the tree.
    struct Entry {
        let path: String
        let layer: Layer
        let parent: String?
    }

    /// Every layer, depth first, in drawing order.
    static func entries(_ layers: [Layer], prefix: String = "", parent: String? = nil) -> [Entry] {
        layers.enumerated().flatMap { index, layer -> [Entry] in
            let path = prefix.isEmpty ? String(index) : "\(prefix).\(index)"
            var found = [Entry(path: path, layer: layer, parent: parent)]
            if case .group(let children) = layer.content { found += entries(children, prefix: path, parent: path) }
            return found
        }
    }

    /// Frames and text fits for every layer; `anchors` replaces a layer's
    /// declared anchor (what `avoid` decided).
    static func place(_ design: Design, geometry: CanvasGeometry, families: [String: String],
                      anchors: [String: Anchor] = [:]) -> (frames: [String: CGRect], fits: [String: TextFit]) {
        var frames: [String: CGRect] = [:]
        var fits: [String: TextFit] = [:]
        var extents: [String: CGRect] = [:]
        for entry in entries(design.layers) {
            let area: CGRect
            if let parent = entry.parent, let parentFrame = frames[parent] {
                area = parentFrame
            } else {
                area = geometry.rect(entry.layer.frame.area ?? defaultArea(entry.layer))
            }
            let referenceID = entry.layer.frame.below ?? entry.layer.frame.above
            let frame = Layout.frame(entry.layer.frame, in: area, grid: design.grid, anchor: anchors[entry.path],
                                     reference: referenceID.flatMap { extents[$0] })
            frames[entry.path] = frame
            var extent = frame
            if case .text(let text) = entry.layer.content,
               let fit = layout(text, vars: design.vars, family: families[entry.path], frame: frame, geometry: geometry) {
                fits[entry.path] = fit
                if let lines = fit.linesBounds { extent = Layout.flipped(lines, height: Double(geometry.pixelHeight)) }
            }
            if let id = entry.layer.id { extents[id] = extent }
        }
        return (frames, fits)
    }

    /// Backgrounds reach the bleed; everything else stays in the safe area.
    static func defaultArea(_ layer: Layer) -> Area {
        if case .background = layer.content { return .bleed }
        return .safe
    }

    /// The text laid out in `frame` (top-left) — sizes, lines, fit.
    static func layout(_ text: TextContent, vars: [String: String], family: String?, frame: CGRect,
                       geometry: CanvasGeometry) -> TextFit? {
        let words = Words.cased(Words.filled(text.text, vars: vars), text.textCase)
        let style = TextStyles.style(text, family: family, color: .white)
        return TextDrawer.layout(text: words, style: style, in: Layout.flipped(frame, height: Double(geometry.pixelHeight)),
                                 verticalAlignment: TextStyles.vertical(text.valign), scale: geometry.unit)
    }
}
