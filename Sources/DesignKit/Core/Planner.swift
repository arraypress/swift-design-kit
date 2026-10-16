//
//  Planner.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  One pass over the design, bottom to top, at a measuring size, deciding
//  what can only be decided by looking at what is already drawn: a text
//  layer's `auto` colour, its `auto` plate, and — when it avoids faces or
//  the subject — the placement that keeps it off them. The pass ends with
//  the finished picture at that size, which the checks then measure.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility

enum Planner {

    /// The longest side the measuring pass draws at.
    static let measuringSide = 2000.0

    /// At most this share of a text layer's lines over what it avoids counts as clear.
    static let clear = 0.01

    /// The frame widths tried, widest first, when no anchor clears at full width.
    static let narrower = [0.8, 0.6, 0.45, 0.35]

    /// The scale the measuring pass draws at.
    static func measuringScale(_ geometry: CanvasGeometry) -> Double {
        min(1, measuringSide / Double(max(geometry.pixelWidth, geometry.pixelHeight)))
    }

    /// The plan, and the finished picture at the measuring scale.
    static func plan(_ prepared: PreparedDesign) -> (plan: Plan, composite: CGImage?) {
        let geometry = prepared.geometry
        let scale = measuringScale(geometry)
        var moves: [String: TextMove] = [:]
        var placed = Layouter.place(prepared.design, geometry: geometry, faces: prepared.faces)
        var plan = Plan(frames: placed.frames, fits: placed.fits, text: [:])
        // The palette roles, from the art alone.
        let art = Checker.render(prepared, plan: plan, scale: min(scale, 512 / Double(max(geometry.pixelWidth, geometry.pixelHeight))),
                                 filter: Painter.Filter(artOnly: true))
        plan.palette = ColorRoles.roles(from: art, spec: prepared.design.palette ?? .standard)

        let width = Int((Double(geometry.pixelWidth) * scale).rounded()), height = Int((Double(geometry.pixelHeight) * scale).rounded())
        guard let context = Bitmaps.context(width: width, height: height) else { return (plan, nil) }
        context.scaleBy(x: scale, y: scale)

        let entries = Layouter.entries(prepared.design.layers)
        for (index, layer) in prepared.design.layers.enumerated() {
            let path = String(index)
            let texts = entries.filter { ($0.path == path || $0.path.hasPrefix(path + ".")) && isText($0.layer) }
            if !texts.isEmpty, let snapshot = context.makeImage() {
                for entry in texts {
                    guard case .text(let text) = entry.layer.content else { continue }
                    if !text.avoid.isEmpty {
                        let looked = look(at: index, for: text.avoid, prepared: prepared, plan: &plan)
                        let obstacles = obstacles(text.avoid, look: looked, prepared: prepared, plan: plan, before: index,
                                                  path: entry.path)
                        var decision = TextDecision(color: .white)
                        if let moved = move(entry, obstacles: obstacles, prepared: prepared, moves: moves, plan: plan) {
                            if let move = moved.move {
                                moves[entry.path] = move
                                placed = Layouter.place(prepared.design, geometry: geometry, faces: prepared.faces, moves: moves)
                                plan.frames = placed.frames
                                plan.fits = placed.fits
                                decision.move = move
                            }
                            decision.note = moved.note
                        }
                        if text.avoid.contains(.subject), looked.subject == .failed {
                            decision.note = [decision.note, "the subject could not be looked for (Vision could not run)"]
                                .compactMap { $0 }.joined(separator: "; ")
                        }
                        plan.text[entry.path] = decision
                    }
                    // Words inside a group read against the group's earlier layers too (a label strip).
                    var under = snapshot
                    if entry.path != path, let nested = Bitmaps.context(width: width, height: height) {
                        nested.draw(snapshot, in: CGRect(x: 0, y: 0, width: width, height: height))
                        nested.scaleBy(x: scale, y: scale)
                        Painter.draw(layer, path: path, prepared: prepared, plan: plan, context: nested, deviceScale: scale,
                                     filter: Painter.Filter(drawnBefore: entry.path))
                        under = nested.makeImage() ?? snapshot
                    }
                    decideColors(text, path: entry.path, snapshot: under, scale: scale, geometry: geometry, plan: &plan)
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
        case .role(let role):
            // The role's hue, lightened or darkened until the words read over
            // what is under them — unless a plate will carry them.
            let base = plan.palette?[role] ?? .white
            if text.plate != nil {
                decision.color = base
            } else {
                let units = (plan.fits[path]?.pointSize ?? text.size * geometry.unit) / geometry.unit
                let target = units >= Checker.largeTextUnits ? Contrast.largeTextMinimum : Contrast.normalTextMinimum
                decision.color = ColorRoles.readable(base, role: role, palette: plan.palette, over: range, target: target)
                if decision.color != base {
                    decision.note = [decision.note, "\(role.rawValue) \(base.hex) set as \(decision.color.hex) to read over the art"]
                        .compactMap { $0 }.joined(separator: "; ")
                }
            }
        }
        if let plate = text.plate {
            switch plate.color {
            case .color(let color): decision.plate = color
            case .role(let role): decision.plate = plan.palette?[role]
            case .auto: decision.plate = AutoColor.plate(text: decision.color.luminance, over: range)
            }
        }
        plan.text[path] = decision
    }

    // MARK: What lies under the words

    /// Which art layers lie under top-level layer `index`, as a key; `nil` when none.
    static func artKey(before index: Int, in design: Design) -> String? {
        let below = design.layers.prefix(index).enumerated().filter { hasArt($0.element) }.map { String($0.offset) }
        return below.isEmpty ? nil : below.joined(separator: ",")
    }

    static func hasArt(_ layer: Layer) -> Bool {
        switch layer.content {
        case .background, .image: true
        case .group(let children): children.contains(where: hasArt)
        case .text, .shape, .qr, .texture, .list: false
        }
    }

    /// The art under top-level layer `index`, looked at for `kinds` — once per
    /// set of art layers, kept in the plan for the checks.
    static func look(at index: Int, for kinds: [Avoid], prepared: PreparedDesign, plan: inout Plan) -> ArtLook {
        guard let key = artKey(before: index, in: prepared.design) else { return ArtLook(faces: [], subject: .nothing) }
        var look = plan.art[key] ?? ArtLook()
        let wantsFaces = kinds.contains(.faces) && look.faces == nil
        let wantsSubject = kinds.contains(.subject) && look.subject == nil
        guard wantsFaces || wantsSubject,
              let art = Checker.render(prepared, plan: plan, scale: measuringScale(prepared.geometry),
                                       filter: Painter.Filter(before: index, artOnly: true)) else { return look }
        if wantsFaces { look.faces = Faces.find(in: art) }
        if wantsSubject { look.subject = Subjects.find(in: art) }
        plan.art[key] = look
        return look
    }

    /// What a text layer avoids, as one mask: the lifted subject, faces, and
    /// cut-out pictures drawn before it.
    static func obstacles(_ kinds: [Avoid], look: ArtLook, prepared: PreparedDesign, plan: Plan, before index: Int,
                          path: String) -> Obstacles {
        let geometry = prepared.geometry
        let scale = measuringScale(geometry)
        let width = Int((Double(geometry.pixelWidth) * scale).rounded()), height = Int((Double(geometry.pixelHeight) * scale).rounded())
        var rects: [CGRect] = []
        if kinds.contains(.faces) {
            rects += (look.faces ?? []).map { CGRect(x: $0.minX / scale, y: $0.minY / scale, width: $0.width / scale, height: $0.height / scale) }
        }
        var mask: [Bool]?
        if kinds.contains(.subject) {
            if case .found(let found) = look.subject { mask = visible(found, under: path, prepared: prepared, plan: plan) }
            for entry in Layouter.entries(prepared.design.layers) {
                guard let top = Int(entry.path.split(separator: ".").first ?? ""), top < index,
                      case .image(let image) = entry.layer.content, image.cutout,
                      let frame = plan.frames[entry.path], let picture = prepared.pictures[entry.path] else { continue }
                let height = Double(geometry.pixelHeight)
                let drawn = Bitmaps.placement(of: picture.image, in: Layout.flipped(frame, height: height), mode: image.fit,
                                              focus: image.focus, flippedY: true)
                rects.append(Layout.flipped(drawn.intersection(Layout.flipped(frame, height: height)), height: height))
            }
        }
        return Obstacles(mask: mask, rects: rects, width: width, height: height, scale: scale)
    }

    /// The part of `subject` (measuring pixels) still seen at the text layer
    /// at `path`: shapes and codes drawn before it — a label strip, a
    /// starburst — hide what is under them, and words on them are not on it.
    static func visible(_ subject: [Bool], under path: String, prepared: PreparedDesign, plan: Plan) -> [Bool] {
        guard let covers = Checker.render(prepared, plan: plan, scale: measuringScale(prepared.geometry),
                                          filter: Painter.Filter(coversBefore: path)) else { return subject }
        let hidden = Pixels.mask(of: covers)
        guard hidden.count == subject.count else { return subject }
        return zip(subject, hidden).map { $0 && !$1 }
    }

    // MARK: Moving

    /// Each line of a text layer, full-size pixels, top-left.
    static func lines(_ path: String, fits: [String: TextFit], frames: [String: CGRect], height: Double) -> [CGRect] {
        if let rects = fits[path]?.lineRects, !rects.isEmpty { return rects.map { Layout.flipped($0, height: height) } }
        return frames[path].map { [$0] } ?? []
    }

    /// How much of a layer's lines sit on other text layers' lines, square pixels.
    static func clash(_ path: String, fits: [String: TextFit], frames: [String: CGRect], height: Double) -> Double {
        let mine = lines(path, fits: fits, frames: frames, height: height)
        let others = fits.keys.filter { $0 != path && !$0.hasPrefix(path + ".") && !path.hasPrefix($0 + ".") }
            .flatMap { lines($0, fits: fits, frames: frames, height: height) }
        return mine.reduce(0) { $0 + Layout.overlap($1, others) }
    }

    /// Where a text layer goes to keep its lines off `obstacles`, and why;
    /// `nil` when it is already clear.
    ///
    /// The rule: every other anchor, at the full width, first; the first that
    /// clears wins, else the one that covers least, if it covers less than
    /// where it was. Only when no anchor clears is the frame narrowed —
    /// widest first, each anchor in turn — and a narrower frame is taken only
    /// when it clears, never to cover a little less. No place is taken that
    /// does not fit, or that puts the words on other words.
    static func move(_ entry: Layouter.Entry, obstacles: Obstacles, prepared: PreparedDesign,
                     moves: [String: TextMove], plan: Plan) -> (move: TextMove?, note: String)? {
        guard !obstacles.isEmpty, case .text(let text) = entry.layer.content else { return nil }
        let height = Double(prepared.geometry.pixelHeight)
        let path = entry.path
        let current = lines(path, fits: plan.fits, frames: plan.frames, height: height)
        guard !current.isEmpty else { return nil }
        let covered = obstacles.share(of: current)
        guard covered > clear else { return nil }
        let crowded = clash(path, fits: plan.fits, frames: plan.frames, height: height)
        let fitted = plan.fits[path]?.fits ?? true
        let declared = entry.layer.frame.anchor

        func trial(_ anchor: Anchor, width: Double) -> (TextMove, Double)? {
            var trial = moves
            let move = Moves.move(text, declared: declared, to: anchor, width: width)
            trial[path] = move
            let placed = Layouter.place(prepared.design, geometry: prepared.geometry, faces: prepared.faces, moves: trial)
            guard placed.fits[path]?.fits ?? true || !fitted,
                  clash(path, fits: placed.fits, frames: placed.frames, height: height) <= crowded + 1 else { return nil }
            let rects = lines(path, fits: placed.fits, frames: placed.frames, height: height)
            return rects.isEmpty ? nil : (move, obstacles.share(of: rects))
        }

        var best: (TextMove, Double)?
        var taken: (TextMove, Double)?
        for anchor in Layout.alternatives(to: declared).dropFirst() {
            guard let tried = trial(anchor, width: 1) else { continue }
            if best == nil || tried.1 < best!.1 { best = tried }
            if tried.1 <= clear { taken = tried; break }
        }
        if taken == nil {
            search: for width in narrower {
                for anchor in Layout.alternatives(to: declared) {
                    if let tried = trial(anchor, width: width), tried.1 <= clear { taken = tried; break search }
                }
            }
        }
        if taken == nil, let best, best.1 < covered { taken = best }

        let percent = Int((covered * 100).rounded())
        guard let (move, share) = taken else {
            return (nil, "covers \(percent)% of its lines with what it avoids; no placement clears it")
        }
        var place = move.anchor == declared ? "narrowed at \(declared.rawValue)" : "moved from \(declared.rawValue) to \(move.anchor.rawValue)"
        if move.width < 1 { place += (move.anchor == declared ? " to" : " at") + " \(Int((move.width * 100).rounded()))% of its width" }
        return (move, "\(place): it covered \(percent)% of its lines with what it avoids"
                + (share > clear ? " (still \(Int((share * 100).rounded()))%)" : ""))
    }
}
