//
//  VectorExport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The design as SVG: shapes as paths, words as text a person can still
//  edit (each line and run where CoreText set it, in its face, size, weight
//  and colour), pictures embedded as PNG. What SVG cannot say is said in
//  pixels or approximated: backgrounds, pictures, textures and codes are
//  embedded pictures of the layer as drawn; words on a path, extruded or
//  inlined become outlines; a group with a shadow, glow or fade is one
//  picture; linear dodge and burn have no SVG blend and draw normally.
//  Google faces are embedded (@font-face; their licences allow it); a
//  Mac's own faces are named only, and a viewer without one substitutes.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility

public enum VectorExport {

    /// What an SVG keeps and loses, for the notes `design` prints.
    public static func notes(_ prepared: PreparedDesign) -> [String] {
        var notes = ["Google faces are embedded; this Mac's own faces are named only, and a viewer without one substitutes another"]
        let entries = Layouter.entries(prepared.design.layers)
        if entries.contains(where: { if case .text(let text) = $0.layer.content { return text.path != nil || text.extrude != nil || text.inline != nil }; return false }) {
            notes.append("words on a path, extruded or inlined are outlines in the SVG, not text")
        }
        if entries.contains(where: { [.linearBurn, .linearDodge].contains($0.layer.blend) }) {
            notes.append("linear dodge and linear burn have no SVG blend mode: those layers draw normally")
        }
        if entries.contains(where: { if case .group = $0.layer.content { return LayeredExport.flattened($0.layer) }; return false }) {
            notes.append("a group with a shadow, glow or fade is one picture in the SVG")
        }
        return notes
    }

    /// The SVG's bytes.
    static func svg(_ rendered: Rendered) throws(DesignError) -> Data {
        var writer = SVGWriter(rendered: rendered)
        for (index, layer) in rendered.prepared.design.layers.enumerated() {
            writer.body.append(writer.element(layer, path: String(index), turns: []))
        }
        let geometry = rendered.prepared.geometry
        let width = geometry.pixelWidth, height = geometry.pixelHeight
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">

        """
        // Google faces travel with the file (their licences allow embedding); a Mac's own faces are only named.
        let embedded = Set(rendered.prepared.faces.values.compactMap(\.family)).filter(Fonts.isFetched).sorted()
        var faces: [String] = []
        for family in embedded {
            for file in Fonts.fetchedFiles(family) {
                guard let data = try? Data(contentsOf: file) else { continue }
                let italic = file.lastPathComponent.lowercased().contains("italic")
                let format = file.pathExtension.lowercased() == "otf" ? "opentype" : "truetype"
                faces.append("@font-face{font-family:'\(SVGWriter.escape(family))';font-style:\(italic ? "italic" : "normal");"
                             + "src:url(data:font/\(file.pathExtension.lowercased());base64,\(data.base64EncodedString())) format('\(format)');}")
            }
        }
        if !faces.isEmpty { writer.defs.insert("<style>\(faces.joined(separator: "\n"))</style>", at: 0) }
        if !writer.defs.isEmpty { svg += "<defs>\n" + writer.defs.joined(separator: "\n") + "\n</defs>\n" }
        svg += writer.body.filter { !$0.isEmpty }.joined(separator: "\n") + "\n</svg>\n"
        return Data(svg.utf8)
    }
}

/// One SVG being written: definitions and elements.
struct SVGWriter {
    let rendered: Rendered
    var defs: [String] = []
    var body: [String] = []
    private var next = 0

    init(rendered: Rendered) { self.rendered = rendered }

    var prepared: PreparedDesign { rendered.prepared }
    var plan: Plan { rendered.plan }
    var height: Double { Double(prepared.geometry.pixelHeight) }
    var unit: Double { prepared.geometry.unit }

    mutating func id(_ prefix: String) -> String {
        next += 1
        return "\(prefix)\(next)"
    }

    /// One layer: its look (opacity, blend, shadow, fade) round its content.
    /// `turns` are the rotations of the groups it is in, outermost first.
    mutating func element(_ layer: Layer, path: String, turns: [String]) -> String {
        guard let frame = plan.frames[path] else { return "" }
        var look: [String] = []
        if layer.opacity < 1 { look.append("opacity=\"\(n(layer.opacity))\"") }
        if let blend = Self.blend(layer.blend) { look.append("style=\"mix-blend-mode:\(blend)\"") }
        let raster = Self.isRaster(layer)
        // A raster layer is a picture of itself as drawn: turned, shadowed and faded already.
        var own = turns
        if !raster {
            if layer.rotation != 0 { own.append("rotate(\(n(layer.rotation)) \(n(frame.midX)) \(n(frame.midY)))") }
            if layer.shadow != nil || layer.glow != nil { look.append("filter=\"url(#\(shadow(layer)))\"") }
            if let fade = layer.fade { look.append("mask=\"url(#\(mask(fade, frame: frame)))\"") }
        }
        let content: String
        if raster {
            content = picture(path)
        } else {
            switch layer.content {
            case .shape(let shape): content = self.shape(shape, frame: frame, transform: own)
            case .text(let text): content = self.text(text, path: path, frame: frame, transform: own)
            case .group(let children):
                content = children.enumerated().map { element($0.element, path: "\(path).\($0.offset)", turns: own) }.joined(separator: "\n")
            case .list(let list):
                content = list.lines.enumerated().map { element($0.element, path: "\(path).\($0.offset)", turns: own) }.joined(separator: "\n")
            case .background, .image, .qr, .texture: content = picture(path)
            }
        }
        guard !content.isEmpty else { return "" }
        let label = layer.id.map { " id=\"\(Self.escape($0))\"" } ?? ""
        return "<g\(label)\(look.isEmpty ? "" : " " + look.joined(separator: " "))>\n\(content)\n</g>"
    }

    /// Drawn as a picture: backgrounds, pictures, codes, textures, and groups whose shadow or fade must apply as one.
    static func isRaster(_ layer: Layer) -> Bool {
        switch layer.content {
        case .background, .image, .qr, .texture: true
        case .group: LayeredExport.flattened(layer)
        case .text, .shape, .list: false
        }
    }

    /// The layer alone as drawn (no opacity or blend: the SVG applies those), cropped to its ink, embedded.
    func picture(_ path: String) -> String {
        var filter = Painter.Filter(only: path)
        filter.plain = true
        guard let image = Checker.render(prepared, plan: plan, scale: 1, filter: filter),
              let ink = InkBox.bounds(of: image, alphaFloor: 0),
              let cropped = image.cropping(to: ink.integral) else { return "" }
        // Opaque pictures go in as JPEG (a tenth of the size: an A3 background as PNG passes the
        // 10 MB attribute limit some SVG readers keep); anything with transparency as PNG.
        let opaque = Pixels.rgba(of: cropped).map { bytes in stride(from: 3, to: bytes.count, by: 4).allSatisfy { bytes[$0] == 255 } } ?? false
        guard let data = opaque ? try? Exporter.jpeg(cropped, quality: 0.92) : try? Exporter.png(cropped) else { return "" }
        let rect = ink.integral
        return "<image x=\"\(n(rect.minX))\" y=\"\(n(rect.minY))\" width=\"\(n(rect.width))\" height=\"\(n(rect.height))\" "
            + "preserveAspectRatio=\"none\" href=\"data:image/\(opaque ? "jpeg" : "png");base64,\(data.base64EncodedString())\"/>"
    }

    // MARK: Shapes

    mutating func shape(_ shape: ShapeContent, frame: CGRect, transform: [String]) -> String {
        let box = Layout.flipped(frame, height: height)
        let path = Shapes.path(shape, in: box, unit: unit)
        let fill = plan.color(shape.fill)
        let ink = plan.color(shape.stroke?.color) ?? fill ?? .white
        let moves = transform.isEmpty ? "" : " transform=\"\(transform.joined(separator: " "))\""
        var parts: [String] = []
        if Shapes.isLines(shape.shape) {
            let cap = shape.shape == .brackets ? "square" : "round"
            parts.append("<path d=\"\(d(path))\" fill=\"none\" \(stroke(ink, width: Shapes.lineWidth(shape, unit: unit), dash: shape.stroke?.dash, join: shape.shape == .brackets ? "miter" : "round")) stroke-linecap=\"\(cap)\"/>")
            if shape.shape == .arrow {
                let ends = (shape.points ?? [[0, 0.5], [1, 0.5]]).map { Shapes.point($0, in: box) }
                if ends.count >= 2 {
                    let size = max(Shapes.lineWidth(shape, unit: unit) * 3, min(box.width, box.height, hypot(box.width, box.height)) * shape.length)
                    parts.append("<path d=\"\(d(Shapes.arrowHead(from: ends[ends.count - 2], to: ends[ends.count - 1], size: size)))\" \(paint(ink))/>")
                }
            } else if shape.shape == .divider {
                parts.append("<path d=\"\(d(Shapes.diamond(in: box)))\" \(paint(ink))/>")
            }
        } else {
            let rule = Shapes.isEvenOdd(shape.shape) ? " fill-rule=\"evenodd\"" : ""
            var fillAttribute = "fill=\"none\""
            if let colors = shape.gradient {
                fillAttribute = "fill=\"url(#\(linear(colors, angle: shape.angle, in: path.boundingBox)))\""
            } else if let color = fill ?? (shape.stroke == nil ? .white : nil) {
                fillAttribute = paint(color)
            }
            var strokeAttribute = ""
            if let line = shape.stroke, line.width > 0 {
                strokeAttribute = " " + stroke(ink, width: line.width * unit, dash: line.dash, join: "round")
            }
            parts.append("<path d=\"\(d(path))\" \(fillAttribute)\(rule)\(strokeAttribute)/>")
        }
        return "<g\(moves)>" + parts.joined() + "</g>"
    }

    // MARK: Words

    mutating func text(_ content: TextContent, path: String, frame: CGRect, transform: [String]) -> String {
        let decision = plan.text[path]
        let text = decision?.move.map { Moves.applied($0, to: content) } ?? content
        let color = decision?.color ?? plan.color(text.color) ?? .white
        var style = TextStyles.style(text, face: prepared.faces[path], color: color, plan: plan,
                                     words: TextStyles.drawn(text, vars: prepared.design.vars))
        let words = Words.cased(Words.filled(text.text, vars: prepared.design.vars), text.textCase)
        let box = Layout.flipped(frame, height: height)
        let moves = transform.isEmpty ? "" : " transform=\"\(transform.joined(separator: " "))\""
        var parts: [String] = []
        let vertical = TextStyles.vertical(text.valign)
        if text.plate?.perLine == true { style.linePill = nil }
        let outlines = text.path.map { TextPaths.layout(words, style: style, path: $0, in: box, scale: unit) }
            ?? TextDrawer.outlines(text: words, style: style, in: box, verticalAlignment: vertical, scale: unit)
        guard let outlines else { return "" }
        if let plate = text.plate, let fill = decision?.plate {
            if plate.perLine, text.path == nil {
                for line in outlines.lines where line.width > 1 {
                    let rect = CGRect(x: line.origin.x - 18 * unit, y: line.origin.y - line.descent - 8 * unit,
                                      width: line.width + 36 * unit, height: line.ascent + line.descent + 16 * unit)
                    parts.append(rectangle(rect, radius: min(12 * unit, rect.height / 2), color: fill))
                }
            } else if let lines = outlines.fit.linesBounds {
                parts.append(rectangle(lines.insetBy(dx: -plate.padding * unit, dy: -plate.padding * unit), radius: plate.radius * unit, color: fill))
            }
        }
        if let extrude = text.extrude {
            let solid = outlines.path.normalized(using: .winding)
            let depth = extrude.depth * unit, angle = extrude.angle * .pi / 180
            let side = plan.color(extrude.color) ?? color.darkened(0.35)
            let steps = max(1, min(LetterEffects.extrudeSteps, Int(depth.rounded(.up))))
            for step in stride(from: steps, through: 1, by: -1) {
                let t = Double(step) / Double(steps)
                var move = CGAffineTransform(translationX: sin(angle) * depth * t, y: cos(angle) * depth * t)
                if let copy = solid.copy(using: &move) { parts.append("<path d=\"\(d(copy))\" \(paint(side.darkened(extrude.shade * t)))/>") }
            }
        }
        if text.path != nil || text.extrude != nil || text.inline != nil {
            parts.append(glyphs(outlines, style: style))
        } else {
            parts.append(lines(outlines, style: style, text: text))
        }
        if let inline = text.inline {
            parts.append("<path d=\"\(d(LetterEffects.inlineBand(outlines, inline, unit: unit)))\" \(paint(plan.color(inline.color) ?? .white))/>")
        }
        return "<g\(moves)>\n" + parts.joined(separator: "\n") + "\n</g>"
    }

    /// The words as text: a `<text>` per line, a `<tspan>` per run.
    mutating func lines(_ outlines: TextOutlines, style: TextStyle, text: TextContent) -> String {
        var gradientFill: String?
        if let colors = style.gradientColors, colors.count >= 2, let bounds = outlines.fit.linesBounds {
            let gradient = id("grad")
            let top = height - bounds.maxY, bottom = height - bounds.minY
            defs.append("<linearGradient id=\"\(gradient)\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"\(n(top))\" x2=\"0\" y2=\"\(n(bottom))\">"
                        + stops(colors.map { DesignColor($0.hex) ?? .white }) + "</linearGradient>")
            gradientFill = "url(#\(gradient))"
        }
        let size = outlines.fit.pointSize
        let strokeWidth = style.strokeWidth / 100 * size
        var common: [String] = []
        if let variations = style.variations, !variations.isEmpty {
            common.append("font-variation-settings:" + variations.keys.sorted().map { "'\($0)' \(n(variations[$0] ?? 0))" }.joined(separator: ","))
        }
        if let features = style.features, !features.isEmpty {
            common.append("font-feature-settings:" + features.keys.sorted().map { "'\($0)' \(features[$0] ?? 1)" }.joined(separator: ","))
        }
        var result: [String] = []
        for line in outlines.lines where !line.runs.isEmpty {
            var spans: [String] = []
            for (index, run) in line.runs.enumerated() {
                let color = DesignColor.from(run.color)
                // Only the line's start is placed: later runs follow on, so a substituted face does not pile runs up.
                var attributes = [index == 0 ? "x=\"\(n(line.origin.x + run.x))\"" : "", "font-family=\"\(Self.escape(run.family))\"",
                                  "font-size=\"\(n(run.size))\"", "font-weight=\"\(Self.cssWeight(run.weight))\""]
                if run.italic { attributes.append("font-style=\"italic\"") }
                if run.rise != 0 { attributes.append("dy=\"\(n(-run.rise))\"") }
                if run.tracking != 0 { attributes.append("letter-spacing=\"\(n(run.tracking))\"") }
                if style.strokeStyle == .hollow, strokeWidth > 0 {
                    attributes.append("fill=\"none\" " + stroke(DesignColor((style.strokeColor ?? style.color ?? .white).hex) ?? .white,
                                                                width: strokeWidth, dash: nil, join: "round"))
                } else {
                    attributes.append(gradientFill.map { "fill=\"\($0)\"" } ?? paint(color))
                    if style.strokeStyle == .outlined, strokeWidth > 0 {
                        attributes.append("paint-order=\"stroke\" " + stroke(DesignColor((style.strokeColor ?? .black).hex) ?? .black,
                                                                             width: strokeWidth * 2, dash: nil, join: "round"))
                    }
                }
                spans.append("<tspan \(attributes.filter { !$0.isEmpty }.joined(separator: " "))>\(Self.escape(run.text))</tspan>")
            }
            let css = common.isEmpty ? "" : " style=\"\(common.joined(separator: ";"))\""
            result.append("<text y=\"\(n(height - line.origin.y))\" xml:space=\"preserve\"\(css)>\(spans.joined())</text>")
        }
        return result.joined(separator: "\n")
    }

    /// The words as glyph outlines, each in its colour (or the layer's blend, or a stroke).
    mutating func glyphs(_ outlines: TextOutlines, style: TextStyle) -> String {
        let size = outlines.fit.pointSize
        let strokeWidth = style.strokeWidth / 100 * size
        if style.strokeStyle == .hollow, strokeWidth > 0 {
            return "<path d=\"\(d(outlines.path.normalized(using: .winding)))\" fill=\"none\" "
                + stroke(DesignColor((style.strokeColor ?? style.color ?? .white).hex) ?? .white, width: strokeWidth, dash: nil, join: "round") + "/>"
        }
        var parts: [String] = []
        if style.strokeStyle == .outlined, strokeWidth > 0 {
            parts.append("<path d=\"\(d(outlines.path.normalized(using: .winding)))\" fill=\"none\" "
                         + stroke(DesignColor((style.strokeColor ?? .black).hex) ?? .black, width: strokeWidth * 2, dash: nil, join: "round") + "/>")
        }
        if let colors = style.gradientColors, colors.count >= 2, let bounds = outlines.fit.linesBounds {
            let gradient = id("grad")
            defs.append("<linearGradient id=\"\(gradient)\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"\(n(height - bounds.maxY))\" x2=\"0\" y2=\"\(n(height - bounds.minY))\">"
                        + stops(colors.map { DesignColor($0.hex) ?? .white }) + "</linearGradient>")
            parts.append("<path d=\"\(d(outlines.path))\" fill=\"url(#\(gradient))\"/>")
        } else {
            for glyph in outlines.glyphs { parts.append("<path d=\"\(d(glyph.placed))\" \(paint(DesignColor.from(glyph.color)))/>") }
        }
        return parts.joined(separator: "\n")
    }

    // MARK: Pieces

    mutating func shadow(_ layer: Layer) -> String {
        let name = id("shadow")
        var effects: [String] = []
        if let glow = layer.glow {
            let color = plan.color(glow.color) ?? .white
            effects.append("<feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"\(n(glow.radius * unit / 2))\" flood-color=\"\(color.rgbHex)\" flood-opacity=\"\(n(color.components.alpha))\"/>")
        }
        if let shadow = layer.shadow {
            effects.append("<feDropShadow dx=\"\(n(shadow.x * unit))\" dy=\"\(n(shadow.y * unit))\" stdDeviation=\"\(n(shadow.blur * unit / 2))\" "
                           + "flood-color=\"\(shadow.color.rgbHex)\" flood-opacity=\"\(n(shadow.color.components.alpha))\"/>")
        }
        defs.append("<filter id=\"\(name)\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">\(effects.joined())</filter>")
        return name
    }

    mutating func mask(_ fade: Fade, frame: CGRect) -> String {
        let name = id("fade"), gradient = id("fadeg")
        let stops = "<stop offset=\"\(n(fade.start))\" stop-color=\"white\"/><stop offset=\"\(n(fade.end))\" stop-color=\"black\"/>"
        switch fade.edge {
        case .radial:
            defs.append("<radialGradient id=\"\(gradient)\" cx=\"0.5\" cy=\"0.5\" r=\"0.71\">\(stops)</radialGradient>")
        default:
            let (x1, y1, x2, y2): (Int, Int, Int, Int) = switch fade.edge {
            case .bottom: (0, 0, 0, 1)
            case .top: (0, 1, 0, 0)
            case .right: (0, 0, 1, 0)
            default: (1, 0, 0, 0)
            }
            defs.append("<linearGradient id=\"\(gradient)\" x1=\"\(x1)\" y1=\"\(y1)\" x2=\"\(x2)\" y2=\"\(y2)\">\(stops)</linearGradient>")
        }
        defs.append("<mask id=\"\(name)\" maskUnits=\"userSpaceOnUse\"><rect x=\"\(n(frame.minX))\" y=\"\(n(frame.minY))\" width=\"\(n(frame.width))\" height=\"\(n(frame.height))\" fill=\"url(#\(gradient))\"/></mask>")
        return name
    }

    /// A blend like ``Shapes/linear`` over `rect` (CoreGraphics space).
    mutating func linear(_ colors: [DesignColor], angle: Double, in rect: CGRect) -> String {
        let name = id("grad")
        let radians = (90 - angle) * .pi / 180
        let dx = cos(radians), dy = sin(radians)
        let reach = (abs(rect.width * dx) + abs(rect.height * dy)) / 2
        let start = CGPoint(x: rect.midX - dx * reach, y: height - (rect.midY - dy * reach))
        let end = CGPoint(x: rect.midX + dx * reach, y: height - (rect.midY + dy * reach))
        defs.append("<linearGradient id=\"\(name)\" gradientUnits=\"userSpaceOnUse\" x1=\"\(n(start.x))\" y1=\"\(n(start.y))\" x2=\"\(n(end.x))\" y2=\"\(n(end.y))\">\(stops(colors))</linearGradient>")
        return name
    }

    func stops(_ colors: [DesignColor]) -> String {
        colors.enumerated().map { index, color in
            "<stop offset=\"\(n(colors.count > 1 ? Double(index) / Double(colors.count - 1) : 0))\" stop-color=\"\(color.rgbHex)\""
                + (color.components.alpha < 1 ? " stop-opacity=\"\(n(color.components.alpha))\"" : "") + "/>"
        }.joined()
    }

    func rectangle(_ rect: CGRect, radius: Double, color: DesignColor) -> String {
        "<rect x=\"\(n(rect.minX))\" y=\"\(n(height - rect.maxY))\" width=\"\(n(rect.width))\" height=\"\(n(rect.height))\" rx=\"\(n(radius))\" \(paint(color))/>"
    }

    func paint(_ color: DesignColor) -> String {
        let alpha = color.components.alpha
        return "fill=\"\(color.rgbHex)\"" + (alpha < 1 ? " fill-opacity=\"\(n(alpha))\"" : "")
    }

    func stroke(_ color: DesignColor, width: Double, dash: [Double]?, join: String) -> String {
        let alpha = color.components.alpha
        var text = "stroke=\"\(color.rgbHex)\" stroke-width=\"\(n(width))\" stroke-linejoin=\"\(join)\""
        if alpha < 1 { text += " stroke-opacity=\"\(n(alpha))\"" }
        if let dash { text += " stroke-dasharray=\"\(dash.map { n($0 * unit) }.joined(separator: " "))\"" }
        return text
    }

    /// Path data, flipped from CoreGraphics' bottom-left space.
    func d(_ path: CGPath) -> String {
        var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: height)
        let flipped = path.copy(using: &flip) ?? path
        var parts: [String] = []
        flipped.applyWithBlock { pointer in
            let element = pointer.pointee
            let p = element.points
            switch element.type {
            case .moveToPoint: parts.append("M\(n(p[0].x)) \(n(p[0].y))")
            case .addLineToPoint: parts.append("L\(n(p[0].x)) \(n(p[0].y))")
            case .addQuadCurveToPoint: parts.append("Q\(n(p[0].x)) \(n(p[0].y)) \(n(p[1].x)) \(n(p[1].y))")
            case .addCurveToPoint: parts.append("C\(n(p[0].x)) \(n(p[0].y)) \(n(p[1].x)) \(n(p[1].y)) \(n(p[2].x)) \(n(p[2].y))")
            case .closeSubpath: parts.append("Z")
            @unknown default: break
            }
        }
        return parts.joined()
    }

    /// A number written short: two decimals at most.
    func n(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    }

    static func blend(_ mode: BlendMode) -> String? {
        switch mode {
        case .normal, .linearBurn, .linearDodge: nil
        case .colorDodge: "color-dodge"
        case .colorBurn: "color-burn"
        case .softLight: "soft-light"
        case .hardLight: "hard-light"
        default: mode.rawValue
        }
    }

    /// CoreText's weight trait (−1…1) as a CSS weight.
    static func cssWeight(_ trait: Double) -> Int {
        let steps: [(Double, Int)] = [(-0.7, 100), (-0.5, 200), (-0.2, 300), (0.1, 400), (0.26, 500), (0.35, 600), (0.48, 700), (0.59, 800)]
        return steps.first { trait < $0.0 }?.1 ?? 900
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}

extension DesignColor {
    /// `#RRGGBB`, alpha dropped (SVG takes opacity separately).
    var rgbHex: String { String(hex.prefix(7)) }

    /// A CoreGraphics colour back as a design colour (sRGB).
    static func from(_ color: CGColor) -> DesignColor {
        let srgb = color.converted(to: Bitmaps.sRGB, intent: .defaultIntent, options: nil) ?? color
        let c = srgb.components ?? [1, 1, 1, 1]
        let rgb = c.count >= 3 ? (c[0], c[1], c[2]) : (c[0], c[0], c[0])
        return DesignColor(hex: ColorParsing.hex(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: c.last ?? 1))
    }
}
