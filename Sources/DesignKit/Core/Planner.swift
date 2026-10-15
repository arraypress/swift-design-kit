//
//  Planner.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  One pass over the design, bottom to top, at a measuring size, deciding
//  what can only be decided by looking at what is already drawn: a text
//  layer's `auto` colour, its `auto` plate, and — when it avoids faces or a
//  cut-out subject — the anchor that keeps it off them. The pass ends with
//  the finished picture at that size, which the checks then measure.
//

import CanvasKit
import CoreGraphics
import Foundation

enum Planner {

    /// The longest side the measuring pass draws at.
    static let measuringSide = 2000.0

    /// The scale the measuring pass draws at.
    static func measuringScale(_ geometry: CanvasGeometry) -> Double {
        min(1, measuringSide / Double(max(geometry.pixelWidth, geometry.pixelHeight)))
    }

    /// The plan, and the finished picture at the measuring scale.
    static func plan(_ prepared: PreparedDesign) -> (plan: Plan, composite: CGImage?) {
        let geometry = prepared.geometry
        let scale = measuringScale(geometry)
        var anchors: [String: Anchor] = [:]
        var placed = Layouter.place(prepared.design, geometry: geometry, families: prepared.families)
        var plan = Plan(frames: placed.frames, fits: placed.fits, text: [:])

        let width = Int((Double(geometry.pixelWidth) * scale).rounded()), height = Int((Double(geometry.pixelHeight) * scale).rounded())
        guard let context = Bitmaps.context(width: width, height: height) else { return (plan, nil) }
        context.scaleBy(x: scale, y: scale)

        let entries = Layouter.entries(prepared.design.layers)
        for (index, layer) in prepared.design.layers.enumerated() {
            let path = String(index)
            let texts = entries.filter { ($0.path == path || $0.path.hasPrefix(path + ".")) && isText($0.layer) }
            if !texts.isEmpty, let snapshot = context.makeImage() {
                var faces: [CGRect]?
                for entry in texts {
                    guard case .text(let text) = entry.layer.content else { continue }
                    if !text.avoid.isEmpty {
                        let obstacles = avoided(text.avoid, snapshot: snapshot, scale: scale, faces: &faces,
                                                prepared: prepared, plan: plan, before: index)
                        if let moved = move(entry, obstacles: obstacles, prepared: prepared, anchors: anchors, plan: plan) {
                            anchors[entry.path] = moved.anchor
                            placed = Layouter.place(prepared.design, geometry: geometry, families: prepared.families, anchors: anchors)
                            plan.frames = placed.frames
                            plan.fits = placed.fits
                            plan.text[entry.path] = TextDecision(color: .white, movedTo: moved.anchor, note: moved.note)
                        } else if !obstacles.isEmpty {
                            plan.text[entry.path] = TextDecision(color: .white, note: "clear of what it avoids")
                        }
                    }
                    decideColors(text, path: entry.path, snapshot: snapshot, scale: scale, geometry: geometry, plan: &plan)
                }
            }
            Painter.draw(layer, path: path, prepared: prepared, plan: plan, context: context, deviceScale: scale, filter: .all)
        }
        return (plan, context.makeImage())
    }

    static func isText(_ layer: Layer) -> Bool {
        if case .text = layer.content { return true }
        return false
    }

    /// The ink and plate colours of one text layer.
    static func decideColors(_ text: TextContent, path: String, snapshot: CGImage, scale: Double,
                             geometry: CanvasGeometry, plan: inout Plan) {
        var decision = plan.text[path] ?? TextDecision(color: .white)
        let lines = plan.fits[path]?.linesBounds.map { Layout.flipped($0, height: Double(geometry.pixelHeight)) }
            ?? plan.frames[path] ?? .zero
        let under = CGRect(x: lines.minX * scale, y: lines.minY * scale, width: lines.width * scale, height: lines.height * scale)
        let range = AutoColor.range(under: under, in: snapshot) ?? (0, 0)
        switch text.color {
        case .color(let color): decision.color = color
        case .auto:
            let picked = AutoColor.pick(over: range, art: snapshot)
            decision.color = picked.color
            decision.note = [decision.note, picked.note].compactMap { $0 }.joined(separator: "; ")
        }
        if let plate = text.plate {
            switch plate.color {
            case .color(let color): decision.plate = color
            case .auto: decision.plate = AutoColor.plate(text: decision.color.luminance, over: range)
            }
        }
        plan.text[path] = decision
    }

    /// What a text layer avoids, in full-size pixels (top-left): faces in
    /// what is drawn so far, cut-out subjects drawn so far.
    static func avoided(_ kinds: [Avoid], snapshot: CGImage, scale: Double, faces: inout [CGRect]?,
                        prepared: PreparedDesign, plan: Plan, before index: Int) -> [CGRect] {
        var obstacles: [CGRect] = []
        if kinds.contains(.faces) {
            if faces == nil { faces = Faces.find(in: snapshot) }
            obstacles += (faces ?? []).map { CGRect(x: $0.minX / scale, y: $0.minY / scale, width: $0.width / scale, height: $0.height / scale) }
        }
        if kinds.contains(.subject) {
            for entry in Layouter.entries(prepared.design.layers) {
                guard let top = Int(entry.path.split(separator: ".").first ?? ""), top < index,
                      case .image(let image) = entry.layer.content, image.cutout,
                      let frame = plan.frames[entry.path], let picture = prepared.pictures[entry.path] else { continue }
                let height = Double(prepared.geometry.pixelHeight)
                let drawn = Bitmaps.placement(of: picture.image, in: Layout.flipped(frame, height: height), mode: image.fit,
                                              focus: image.focus, flippedY: true)
                obstacles.append(Layout.flipped(drawn.intersection(Layout.flipped(frame, height: height)), height: height))
            }
        }
        return obstacles
    }

    /// The anchor that keeps a text layer's lines off `obstacles`, when its
    /// own does not; `nil` when it is already clear or nothing is better.
    static func move(_ entry: Layouter.Entry, obstacles: [CGRect], prepared: PreparedDesign,
                     anchors: [String: Anchor], plan: Plan) -> (anchor: Anchor, note: String)? {
        let height = Double(prepared.geometry.pixelHeight)
        func lines(_ fits: [String: TextFit], _ frames: [String: CGRect]) -> CGRect? {
            fits[entry.path]?.linesBounds.map { Layout.flipped($0, height: height) } ?? frames[entry.path]
        }
        guard let current = lines(plan.fits, plan.frames), !obstacles.isEmpty else { return nil }
        let area = max(1, current.width * current.height)
        let covered = Layout.overlap(current, obstacles) / area
        guard covered > 0.01 else { return nil }
        let declared = anchors[entry.path] ?? entry.layer.frame.anchor
        var best: (Anchor, Double)?
        for anchor in Layout.alternatives(to: declared).dropFirst() {
            var trial = anchors
            trial[entry.path] = anchor
            let placed = Layouter.place(prepared.design, geometry: prepared.geometry, families: prepared.families, anchors: trial)
            guard let rect = lines(placed.fits, placed.frames) else { continue }
            let share = Layout.overlap(rect, obstacles) / max(1, rect.width * rect.height)
            if best == nil || share < best!.1 { best = (anchor, share) }
            if share <= 0.01 { break }
        }
        guard let best, best.1 < covered else { return nil }
        let percent = Int((covered * 100).rounded())
        return (best.0, "moved from \(declared.rawValue) to \(best.0.rawValue): it covered \(percent)% of its lines with what it avoids"
                + (best.1 > 0.01 ? " (still \(Int((best.1 * 100).rounded()))%)" : ""))
    }
}
