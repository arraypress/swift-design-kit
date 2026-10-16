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

        static let all = Filter()

        func includes(_ path: String) -> Bool {
            if let coversBefore, !Painter.drawn(path, before: coversBefore) { return false }
            guard let only else { return true }
            return path == only || only.hasPrefix(path + ".")
        }

        func includes(_ layer: Layer) -> Bool {
            switch layer.content {
            case .group: return true
            case .background, .image: return coversBefore == nil
            case .shape, .qr: return !artOnly
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
        let isolated = !bare && (layer.opacity < 1 || layer.blend != .normal || shadow != nil || glow != nil || group)
        if !bare {
            context.setAlpha(layer.opacity)
            context.setBlendMode(layer.blend.cgBlendMode)
        }
        if let shadow {
            context.setShadow(offset: CGSize(width: shadow.x * unit * deviceScale, height: -shadow.y * unit * deviceScale),
                              blur: shadow.blur * unit * deviceScale, color: shadow.color.cgColor)
        } else if let glow {
            context.setShadow(offset: .zero, blur: glow.radius * unit * deviceScale, color: glow.color.cgColor)
        }
        if isolated { context.beginTransparencyLayer(auxiliaryInfo: nil) }
        // A glow under a shadow: its own layer inside the shadowed one.
        let nestedGlow = shadow != nil && glow != nil
        if nestedGlow, let glow {
            context.setShadow(offset: .zero, blur: glow.radius * unit * deviceScale, color: glow.color.cgColor)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
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
            drawText(text, path: path, prepared: prepared, plan: plan, in: box, lettersOnly: bare, context: context)
        case .shape(let shape):
            if !bare { drawShape(shape, in: box, unit: unit, context: context) }
        case .qr:
            if !bare, let picture = prepared.pictures[path] {
                let side = min(box.width, box.height)
                context.interpolationQuality = .none
                context.draw(picture.image, in: CGRect(x: box.midX - side / 2, y: box.midY - side / 2, width: side, height: side))
                context.interpolationQuality = .high
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
            context.setStrokeColor(stroke.color.cgColor)
            context.setLineWidth(stroke.width * unit)
            context.setLineJoin(.round)
            context.strokePath()
        }
    }

    static func drawShape(_ shape: ShapeContent, in box: CGRect, unit: Double, context: CGContext) {
        let path = Shapes.path(shape, in: box, unit: unit)
        if shape.shape == .line {
            let stroke = shape.stroke ?? Stroke(color: shape.fill ?? .white, width: 4)
            context.addPath(path)
            context.setStrokeColor(stroke.color.cgColor)
            context.setLineWidth(stroke.width * unit)
            context.setLineCap(.round)
            context.strokePath()
            return
        }
        if let gradient = shape.gradient {
            context.saveGState()
            context.addPath(path)
            context.clip()
            Shapes.linear(gradient, angle: shape.angle, in: path.boundingBox, context: context)
            context.restoreGState()
        } else if let fill = shape.fill {
            context.addPath(path)
            context.setFillColor(fill.cgColor)
            context.fillPath()
        }
        if let stroke = shape.stroke, stroke.width > 0 {
            context.addPath(path)
            context.setStrokeColor(stroke.color.cgColor)
            context.setLineWidth(stroke.width * unit)
            context.setLineJoin(.round)
            context.strokePath()
        }
    }

    static func drawText(_ text: TextContent, path: String, prepared: PreparedDesign, plan: Plan, in box: CGRect,
                         lettersOnly: Bool, context: CGContext) {
        let unit = prepared.geometry.unit
        let decision = plan.text[path]
        let text = decision?.move.map { Moves.applied($0, to: text) } ?? text
        let color = decision?.color ?? { if case .color(let c) = text.color { return c }; return .white }()
        var style = TextStyles.style(text, family: prepared.families[path], color: color, lettersOnly: lettersOnly)
        let words = Words.cased(Words.filled(text.text, vars: prepared.design.vars), text.textCase)

        if !lettersOnly, let plate = text.plate, let fill = decision?.plate {
            if plate.perLine {
                style.linePill = fill.slide
            } else if let lines = plan.fits[path]?.linesBounds {
                let padding = plate.padding * unit
                context.addPath(Shapes.rounded(lines.insetBy(dx: -padding, dy: -padding), radius: plate.radius * unit))
                context.setFillColor(fill.cgColor)
                context.fillPath()
            }
        } else if text.plate?.perLine == true {
            style.linePill = nil
        }
        TextDrawer.draw(text: words, style: style, in: box, verticalAlignment: TextStyles.vertical(text.valign),
                        context: context, scale: unit)
    }
}
