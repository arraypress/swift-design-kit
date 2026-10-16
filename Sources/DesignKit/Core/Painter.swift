//
//  Painter.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Drawing a prepared design into any CoreGraphics context — a bitmap or a
//  PDF page — so the picture and the print file come from one path, and the
//  PDF keeps its words as vector text. Each layer is turned about its
//  frame's centre, and when it fades, blends, casts a shadow or glows, it is
//  drawn into a transparency layer first so those apply to all of it at
//  once (a stroked word is two passes; faded separately they would show the
//  seam).
//
//  The context's user space is the design's pixels in CoreGraphics
//  orientation (origin bottom-left); `deviceScale` is how many device pixels
//  one of those is, because CoreGraphics does not scale shadows with the CTM.
//

import CanvasKit
import CoreGraphics
import Foundation

enum Painter {

    /// What to draw: everything, or one layer alone (its groups' fades and
    /// turns kept), as finished art or as bare letters (the mask the
    /// contrast check measures).
    struct Filter {
        var only: String?
        var lettersOnly = false
        /// Top-level layers before this index only.
        var before: Int?
        /// The art alone: backgrounds and pictures, no words, shapes or codes
        /// — what a subject is looked for in.
        var artOnly = false
        /// Shapes and codes alone, drawn before the layer at this path —
        /// what hides the art from words laid over it (a label strip, a
        /// starburst).
        var coversBefore: String?
        /// Only what is drawn before the layer at this path (the groups it is in, their earlier children).
        var drawnBefore: String?
        /// With `only`: that layer and its groups drawn without their
        /// opacity or blend (a fade stays: it is part of the pixels) — a layer's own pixels, as a
        /// layered file holds them beside its opacity and blend mode.
        var plain = false
        /// Text layers drawn as pictures rather than as words (a PDF whose
        /// font may not be embedded).
        var textAsPictures: Set<String> = []

        static let all = Filter()

        func includes(_ path: String) -> Bool {
            if let coversBefore, !Painter.drawn(path, before: coversBefore) { return false }
            if let drawnBefore, !Painter.drawn(path, before: drawnBefore) { return false }
            guard let only else { return true }
            // The layer, the groups it is in, and — for a group — everything in it.
            return path == only || only.hasPrefix(path + ".") || path.hasPrefix(only + ".")
        }

        func includes(_ layer: Layer) -> Bool {
            switch layer.content {
            case .group, .list: return true
            case .background, .image: return coversBefore == nil
            case .shape, .qr, .texture: return !artOnly
            case .text: return !artOnly && coversBefore == nil
            }
        }
    }

    /// Whether the layer at `path` is drawn before the one at `other` (a
    /// group counts as drawn before its children, so they can be drawn).
    static func drawn(_ path: String, before other: String) -> Bool {
        if other.hasPrefix(path + ".") { return true }
        let a = path.split(separator: ".").compactMap { Int($0) }, b = other.split(separator: ".").compactMap { Int($0) }
        for (x, y) in zip(a, b) where x != y { return x < y }
        return false
    }

    static func draw(_ prepared: PreparedDesign, plan: Plan, in context: CGContext, deviceScale: Double,
                     filter: Filter = .all) {
        for (index, layer) in prepared.design.layers.enumerated() {
            if let before = filter.before, index >= before { break }
            draw(layer, path: String(index), prepared: prepared, plan: plan, context: context,
                 deviceScale: deviceScale, filter: filter)
        }
    }

    static func draw(_ layer: Layer, path: String, prepared: PreparedDesign, plan: Plan, context: CGContext,
                     deviceScale: Double, filter: Filter) {
        guard filter.includes(path), filter.includes(layer), let frame = plan.frames[path] else { return }
        let height = Double(prepared.geometry.pixelHeight)
        let box = Layout.flipped(frame, height: height)
        let unit = prepared.geometry.unit
        let bare = filter.lettersOnly

        context.saveGState()
        defer { context.restoreGState() }
        if layer.rotation != 0 {
            context.translateBy(x: box.midX, y: box.midY)
            context.rotate(by: -layer.rotation * .pi / 180)
            context.translateBy(x: -box.midX, y: -box.midY)
        }
        var group = false
        if case .group = layer.content { group = true }
        let shadow = bare ? nil : layer.shadow
        let glow = bare ? nil : layer.glow
        let glowColor = (plan.color(glow?.color) ?? .white).cgColor
        // A layer's own pixels for a layered file: no fade, opacity or blend.
        // Only the layer itself and the groups it is in; what is inside a group keeps its own look.
        let plain = filter.plain && filter.only.map { path == $0 || $0.hasPrefix(path + ".") } == true
        let opacity = plain ? 1 : layer.opacity
        let blend = plain ? BlendMode.normal : layer.blend
        let fade = bare ? nil : layer.fade
        let isolated = !bare && (opacity < 1 || blend != .normal || shadow != nil || glow != nil || group || fade != nil)
        if !bare {
            context.setAlpha(opacity)
            context.setBlendMode(blend.cgBlendMode)
        }
        if let shadow {
            context.setShadow(offset: CGSize(width: shadow.x * unit * deviceScale, height: -shadow.y * unit * deviceScale),
                              blur: shadow.blur * unit * deviceScale, color: shadow.color.cgColor)
        } else if glow != nil {
            context.setShadow(offset: .zero, blur: (glow?.radius ?? 0) * unit * deviceScale, color: glowColor)
        }
        if isolated { context.beginTransparencyLayer(auxiliaryInfo: nil) }
        // A glow under a shadow: its own layer inside the shadowed one.
        let nestedGlow = shadow != nil && glow != nil
        if nestedGlow, let glow {
            context.setShadow(offset: .zero, blur: glow.radius * unit * deviceScale, color: glowColor)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
        }
        if let fade, let mask = Fades.mask(fade, frame: box) {
            context.clip(to: mask.rect, mask: mask.image)
        }
        if isolated {
            // Inside the layer everything draws plainly; the fade, blend and
            // shadow apply when it is composited.
            context.setAlpha(1)
            context.setBlendMode(.normal)
            context.setShadow(offset: .zero, blur: 0, color: nil)
        }

        switch layer.content {
        case .background:
            if !bare, let picture = prepared.pictures[path] { context.draw(picture.image, in: box) }
        case .image(let image):
            if !bare { drawImage(image, picture: prepared.pictures[path], in: box, unit: unit, context: context) }
        case .text(let text):
            if !bare, filter.textAsPictures.contains(path) {
                drawTextAsPicture(text, path: path, prepared: prepared, plan: plan, in: box, context: context)
            } else {
                drawText(text, path: path, prepared: prepared, plan: plan, in: box, lettersOnly: bare, context: context)
            }
        case .shape(let shape):
            if !bare { drawShape(shape, in: box, unit: unit, plan: plan, context: context) }
        case .texture:
            if !bare, let picture = prepared.pictures[path] { context.draw(picture.image, in: box) }
        case .qr:
            if !bare, let picture = prepared.pictures[path] {
                let side = min(box.width, box.height)
                context.interpolationQuality = .none
                context.draw(picture.image, in: CGRect(x: box.midX - side / 2, y: box.midY - side / 2, width: side, height: side))
                context.interpolationQuality = .high
            }
        case .list(let list):
            for (index, child) in list.lines.enumerated() {
                draw(child, path: "\(path).\(index)", prepared: prepared, plan: plan, context: context,
                     deviceScale: deviceScale, filter: filter)
            }
        case .group(let children):
            for (index, child) in children.enumerated() {
                draw(child, path: "\(path).\(index)", prepared: prepared, plan: plan, context: context,
                     deviceScale: deviceScale, filter: filter)
            }
        }

        if nestedGlow { context.endTransparencyLayer() }
        if isolated { context.endTransparencyLayer() }
    }

    // MARK: Kinds

    static func drawImage(_ content: ImageContent, picture: PreparedPicture?, in box: CGRect, unit: Double, context: CGContext) {
        guard let picture else { return }
        let rect = Bitmaps.placement(of: picture.image, in: box, mode: content.fit, focus: content.focus, flippedY: true)
        let clip: CGPath? = content.mask.map { Shapes.path($0, in: box, unit: unit) }
            ?? (content.fit == .fill ? CGPath(rect: box, transform: nil) : nil)
        context.saveGState()
        if let clip {
            context.addPath(clip)
            context.clip()
        }
        if let outline = picture.outline {
            let scale = rect.width / Double(picture.image.width)
            context.draw(outline, in: rect.insetBy(dx: -picture.pad * scale, dy: -picture.pad * scale))
        }
        context.draw(picture.image, in: rect)
        context.restoreGState()

        // A stroke follows the mask, or the picture's edge; a cut-out's is its outline (above).
        if let stroke = content.stroke, stroke.width > 0, picture.outline == nil, !(content.cutout && content.mask == nil) {
            context.addPath(clip ?? CGPath(rect: rect, transform: nil))
            context.setStrokeColor((stroke.color.fixed ?? .white).cgColor)
            context.setLineWidth(stroke.width * unit)
            context.setLineJoin(.round)
            context.strokePath()
        }
    }

    static func drawShape(_ shape: ShapeContent, in box: CGRect, unit: Double, plan: Plan, context: CGContext) {
        let path = Shapes.path(shape, in: box, unit: unit)
        let fill = plan.color(shape.fill)
        let ink = plan.color(shape.stroke?.color) ?? fill ?? .white
        func stroke(_ path: CGPath, width: Double) {
            context.addPath(path)
            context.setStrokeColor(ink.cgColor)
            context.setLineWidth(width)
            context.setLineJoin(shape.shape == .brackets ? .miter : .round)
            if let dash = shape.stroke?.dash { context.setLineDash(phase: 0, lengths: dash.map { $0 * unit }) }
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }
        if Shapes.isLines(shape.shape) {
            context.setLineCap(shape.shape == .brackets ? .square : .round)
            stroke(path, width: Shapes.lineWidth(shape, unit: unit))
            context.setFillColor(ink.cgColor)
            if shape.shape == .arrow {
                let ends = (shape.points ?? [[0, 0.5], [1, 0.5]]).map { Shapes.point($0, in: box) }
                if ends.count >= 2 {
                    let size = max(Shapes.lineWidth(shape, unit: unit) * 3, min(box.width, box.height, hypot(box.width, box.height)) * shape.length)
                    context.addPath(Shapes.arrowHead(from: ends[ends.count - 2], to: ends[ends.count - 1], size: size))
                    context.fillPath()
                }
            } else if shape.shape == .divider {
                context.addPath(Shapes.diamond(in: box))
                context.fillPath()
            }
            return
        }
        let rule: CGPathFillRule = Shapes.isEvenOdd(shape.shape) ? .evenOdd : .winding
        if let gradient = shape.gradient {
            context.saveGState()
            context.addPath(path)
            context.clip(using: rule)
            Shapes.linear(gradient, angle: shape.angle, in: path.boundingBox, context: context)
            context.restoreGState()
        } else if let fill = fill ?? (shape.stroke == nil ? .white : nil) {
            context.addPath(path)
            context.setFillColor(fill.cgColor)
            context.fillPath(using: rule)
        }
        if let line = shape.stroke, line.width > 0 { stroke(path, width: line.width * unit) }
    }

    /// A text layer drawn into a picture first, then the picture placed —
    /// for a PDF whose font's licence does not allow embedding it.
    static func drawTextAsPicture(_ text: TextContent, path: String, prepared: PreparedDesign, plan: Plan, in box: CGRect,
                                  context: CGContext) {
        let unit = prepared.geometry.unit
        let size = (prepared.faces[path]?.size ?? text.size) * unit
        let pad = size * 0.6 + (text.plate?.padding ?? 0) * unit + (text.stroke?.width ?? 0) * unit
        var region = box
        if let lines = plan.fits[path]?.linesBounds { region = region.union(lines) }
        region = region.insetBy(dx: -pad, dy: -pad).integral
        guard let picture = Bitmaps.image(width: Int(region.width), height: Int(region.height), { offscreen in
            offscreen.translateBy(x: -region.minX, y: -region.minY)
            drawText(text, path: path, prepared: prepared, plan: plan, in: box, lettersOnly: false, context: offscreen)
        }) else { return }
        // In a CMYK print file the picture is converted like every other.
        context.draw(Inks.space != nil ? PrintColor.converted(picture) ?? picture : picture, in: region)
    }

    static func drawText(_ text: TextContent, path: String, prepared: PreparedDesign, plan: Plan, in box: CGRect,
                         lettersOnly: Bool, context: CGContext) {
        let unit = prepared.geometry.unit
        let decision = plan.text[path]
        let text = decision?.move.map { Moves.applied($0, to: text) } ?? text
        let color = decision?.color ?? plan.color(text.color) ?? .white
        var style = TextStyles.style(text, face: prepared.faces[path], color: color, plan: plan, lettersOnly: lettersOnly,
                                     words: TextStyles.drawn(text, vars: prepared.design.vars))
        let words = Words.cased(Words.filled(text.text, vars: prepared.design.vars), text.textCase)

        if !lettersOnly, let plate = text.plate, let fill = decision?.plate {
            if plate.perLine, text.path == nil {
                style.linePill = fill.slide
            } else if let lines = plan.fits[path]?.linesBounds {
                let padding = plate.padding * unit
                context.addPath(Shapes.rounded(lines.insetBy(dx: -padding, dy: -padding), radius: plate.radius * unit))
                context.setFillColor(Inks.converted(fill.cgColor))
                context.fillPath()
            }
        } else if text.plate?.perLine == true {
            style.linePill = nil
        }
        let vertical = TextStyles.vertical(text.valign)
        // The letters as outlines, when something is drawn from their shapes.
        let needsOutlines = text.path != nil || (!lettersOnly && (text.extrude != nil || text.inline != nil))
        let outlines: TextOutlines? = needsOutlines
            ? (text.path.map { TextPaths.layout(words, style: style, path: $0, in: box, scale: unit) }
                ?? TextDrawer.outlines(text: words, style: style, in: box, verticalAlignment: vertical, scale: unit))
            : nil
        if !lettersOnly, let extrude = text.extrude, let outlines {
            LetterEffects.extrude(outlines, extrude, face: color, plan: plan, unit: unit, context: context)
        }
        if text.path != nil, let outlines {
            LetterEffects.fill(outlines, style: style, lettersOnly: lettersOnly, context: context)
        } else {
            TextDrawer.draw(text: words, style: style, in: box, verticalAlignment: vertical, context: context, scale: unit)
        }
        if !lettersOnly, let inline = text.inline, let outlines {
            LetterEffects.inline(outlines, inline, plan: plan, unit: unit, context: context)
        }
    }
}
