//
//  Layer+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A layer as a design file writes it: `type`, the keys every layer takes,
//  and its kind's own keys beside them — one flat object, read strictly
//  against the keys that kind allows.
//

import Foundation
import ObjectCutout
import RecipeKit

extension Layer: Codable {

    enum Keys: String, CodingKey, CaseIterable {
        // Every layer.
        case type, id, frame, opacity, blend, rotation, shadow, glow, fade
        // Background.
        case fill, fit, blur, darken, scrim, grade, duotone, grain, vignette, upscale
        case gradientMap = "gradient_map"
        // Text.
        case text, font, weight, size
        case minSize = "min_size"
        case maxLines = "max_lines"
        case tracking
        case lineHeight = "line_height"
        case textCase = "case"
        case align, valign, color, accent, muted, gradient, stroke, plate, avoid
        // Image.
        case source, cutout, edge, choke, focus, mask
        // Shape.
        case shape, angle, radius, points, count, inner, inset, gap, length
        // Texture.
        case kind, scale, density, seed
        // QR.
        case background, level
        // Group.
        case layers
    }

    static let types = ["background", "text", "image", "shape", "qr", "texture", "group"]

    static let common: [Keys] = [.type, .id, .frame, .opacity, .blend, .rotation, .shadow, .glow, .fade]

    /// The keys a layer of `type` takes.
    static func keys(for type: String) -> [Keys] {
        common + {
            switch type {
            case "background": [.fill, .fit, .blur, .darken, .scrim, .grade, .duotone, .gradientMap, .grain, .vignette, .upscale]
            case "text": [.text, .font, .weight, .size, .minSize, .maxLines, .fit, .tracking, .lineHeight, .textCase,
                          .align, .valign, .color, .accent, .muted, .gradient, .stroke, .plate, .avoid]
            case "image": [.source, .cutout, .edge, .choke, .fit, .focus, .mask, .stroke, .upscale]
            case "shape": [.shape, .fill, .gradient, .angle, .stroke, .radius, .points, .count, .inner, .inset, .gap, .length]
            case "qr": [.text, .color, .background, .level]
            case "texture": [.kind, .color, .scale, .density, .angle, .seed]
            default: [.layers]
            }
        }()
    }


    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let path = RecipeJSON.path(decoder.codingPath)
        let type = try c.decode(String.self, forKey: .type)
        guard Self.types.contains(type) else { throw RecipeError(Choices.refusal(type, at: path + ".type", among: Self.types)) }
        try decoder.refuseUnknownKeys(Self.keys(for: type).map(\.rawValue), noun: "\(type) layer")

        let content: Content
        switch type {
        case "background":
            let grain = try c.number(.grain, in: 0...1, or: 0)
            content = .background(BackgroundContent(
                fill: try c.decode(Fill.self, forKey: .fill), fit: try c.value(.fit, or: .fill),
                blur: try c.number(.blur, in: 0...500, or: 0), darken: try c.number(.darken, in: 0...1, or: 0),
                scrim: try c.decodeIfPresent(Scrim.self, forKey: .scrim), grade: try c.decodeIfPresent(LookReference.self, forKey: .grade),
                duotone: try Self.pair(c, .duotone, path: path), gradientMap: try Self.colors(c, .gradientMap, path: path), grain: grain,
                vignette: try c.number(.vignette, in: 0...1, or: 0), upscale: try c.decodeIfPresent(Bool.self, forKey: .upscale)))
        case "text":
            let weight = try c.decodeIfPresent(String.self, forKey: .weight)
            if let weight, !Fonts.weights.contains(weight) {
                throw RecipeError(Choices.refusal(weight, at: path + ".weight", among: Fonts.weights))
            }
            // A size is design units, or a step of the type scale by name.
            var step: SizeStep?
            var typedSize: Double?
            if let word = try? c.decodeIfPresent(String.self, forKey: .size) {
                // `--set title.size=120` writes the number as words.
                if let number = Double(word.trimmingCharacters(in: .whitespaces)), number.isFinite, (1...2000).contains(number) {
                    typedSize = number
                } else {
                    step = try SizeStep.named(word, field: path + ".size")
                }
            }
            let maxLines = try c.decodeIfPresent(Int.self, forKey: .maxLines)
            if let maxLines, !(1...40).contains(maxLines) { throw RecipeError("\(path).max_lines is \(maxLines); it takes 1…40") }
            content = .text(TextContent(
                text: try c.decode(String.self, forKey: .text), font: try c.decodeIfPresent(String.self, forKey: .font),
                weight: weight, size: try typedSize ?? (step == nil ? c.number(.size, in: 1...2000, or: 80) : 80), step: step,
                minSize: try c.number(.minSize, in: 1...2000), maxLines: maxLines, fit: try c.value(.fit, or: .shrink),
                tracking: try c.number(.tracking, in: -300...2000, or: 0), lineHeight: try c.number(.lineHeight, in: 0.4...4, or: 1),
                textCase: try c.value(.textCase, or: .none), align: try c.value(.align, or: .center),
                valign: try c.value(.valign, or: .middle), color: try c.value(.color, or: .color(.white)),
                accent: try c.decodeIfPresent(Paint.self, forKey: .accent), muted: try c.decodeIfPresent(Paint.self, forKey: .muted),
                gradient: try Self.colors(c, .gradient, path: path), stroke: try c.decodeIfPresent(Stroke.self, forKey: .stroke),
                plate: try c.decodeIfPresent(Plate.self, forKey: .plate), avoid: try c.value(.avoid, or: [])))
        case "image":
            let focus = try c.decodeIfPresent([Double].self, forKey: .focus)
            if let focus, focus.count != 2 || !focus.allSatisfy({ (0...1).contains($0) }) {
                throw RecipeError("\(path).focus is [x, y], each 0…1")
            }
            var edge = CutoutEdge.crisp
            if let word = try c.decodeIfPresent(String.self, forKey: .edge) {
                guard let parsed = CutoutEdge(word) else {
                    throw RecipeError("\(path).edge is \"\(word)\"; it takes \(CutoutEdge.forms)")
                }
                edge = parsed
            }
            content = .image(ImageContent(
                source: try c.decode(String.self, forKey: .source), cutout: try c.value(.cutout, or: false),
                edge: edge, choke: try c.number(.choke, in: 0...50, or: 0),
                fit: try c.value(.fit, or: .fill), focus: focus, mask: try c.decodeIfPresent(Mask.self, forKey: .mask),
                stroke: try c.decodeIfPresent(Stroke.self, forKey: .stroke), upscale: try c.decodeIfPresent(Bool.self, forKey: .upscale)))
        case "shape":
            let shape = try c.decode(ShapeKind.self, forKey: .shape)
            let points = try c.decodeIfPresent([[Double]].self, forKey: .points)
            try Points.check(points, at: path + ".points", needed: shape == .polygon ? 3 : 0)
            if let count = try c.decodeIfPresent(Int.self, forKey: .count), !(2...96).contains(count) {
                throw RecipeError("\(path).count is \(count); it takes 2…96")
            }
            let framed = [ShapeKind.frame, .doubleFrame, .brackets, .filmStrip].contains(shape)
            let defaultCount = shape == .filmStrip ? 8 : shape == .burst ? 24 : shape == .badge ? 20 : 5
            let defaultInner = shape == .burst ? 0.84 : shape == .ring ? 0.7 : shape == .badge ? 0.9 : 0.45
            content = .shape(ShapeContent(
                shape: shape, fill: try c.decodeIfPresent(Paint.self, forKey: .fill),
                gradient: try Self.colors(c, .gradient, path: path), angle: try c.number(.angle, in: -360...360, or: 180),
                stroke: try c.decodeIfPresent(Stroke.self, forKey: .stroke),
                radius: try c.number(.radius, in: 0...1000, or: framed ? 0 : 40),
                points: points, count: try c.decodeIfPresent(Int.self, forKey: .count) ?? defaultCount,
                inner: try c.number(.inner, in: 0.05...0.98, or: defaultInner),
                inset: try c.number(.inset, in: 0...1000, or: 0), gap: try c.number(.gap, in: 0...500, or: 12),
                length: try c.number(.length, in: 0.01...0.5, or: 0.18)))
        case "qr":
            let text = try c.decode(String.self, forKey: .text)
            guard !text.isEmpty else { throw RecipeError("\(path).text is empty; a QR code needs a link or words") }
            content = .qr(QRContent(text: text, color: try c.value(.color, or: .black),
                                    background: try c.value(.background, or: .white), level: try c.value(.level, or: .medium)))
        case "texture":
            let kind = try c.decode(TextureKind.self, forKey: .kind)
            content = .texture(TextureContent(
                kind: kind, color: try c.value(.color, or: .black), scale: try c.number(.scale, in: 0.2...500),
                density: try c.number(.density, in: 0...1, or: 0.5), angle: try c.number(.angle, in: -360...360, or: 180),
                seed: try c.value(.seed, or: 1)))
        default:
            content = .group(try c.decode([Layer].self, forKey: .layers))
        }

        self.init(id: try c.decodeIfPresent(String.self, forKey: .id), frame: try c.value(.frame, or: .full),
                  opacity: try c.number(.opacity, in: 0...1, or: 1), blend: try c.value(.blend, or: .normal),
                  rotation: try c.number(.rotation, in: -360...360, or: 0),
                  shadow: try c.decodeIfPresent(Shadow.self, forKey: .shadow), glow: try c.decodeIfPresent(Glow.self, forKey: .glow),
                  fade: try c.decodeIfPresent(Fade.self, forKey: .fade), content: content)
        if let id, !SlotFilling.isName(id) {
            throw RecipeError("\(path).id is \"\(id)\"; ids are kebab-case words (title, artist-name)")
        }
    }

    /// Two colours or more, or nothing.
    static func colors(_ c: KeyedDecodingContainer<Keys>, _ key: Keys, path: String) throws -> [DesignColor]? {
        guard let colors = try c.decodeIfPresent([DesignColor].self, forKey: key) else { return nil }
        guard colors.count >= 2 else { throw RecipeError("\(path).\(key.rawValue) takes two colours or more") }
        return colors
    }

    /// Exactly two colours, or nothing.
    static func pair(_ c: KeyedDecodingContainer<Keys>, _ key: Keys, path: String) throws -> [DesignColor]? {
        guard let colors = try c.decodeIfPresent([DesignColor].self, forKey: key) else { return nil }
        guard colors.count == 2 else { throw RecipeError("\(path).\(key.rawValue) takes two colours: dark, then light") }
        return colors
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(frame, forKey: .frame)
        if opacity != 1 { try c.encode(opacity, forKey: .opacity) }
        if blend != .normal { try c.encode(blend, forKey: .blend) }
        if rotation != 0 { try c.encode(rotation, forKey: .rotation) }
        try c.encodeIfPresent(shadow, forKey: .shadow)
        try c.encodeIfPresent(glow, forKey: .glow)
        try c.encodeIfPresent(fade, forKey: .fade)
        switch content {
        case .background(let b):
            try c.encode("background", forKey: .type)
            try c.encode(b.fill, forKey: .fill)
            try c.encode(b.fit, forKey: .fit)
            if b.blur != 0 { try c.encode(b.blur, forKey: .blur) }
            if b.darken != 0 { try c.encode(b.darken, forKey: .darken) }
            try c.encodeIfPresent(b.scrim, forKey: .scrim)
            try c.encodeIfPresent(b.grade, forKey: .grade)
            try c.encodeIfPresent(b.duotone, forKey: .duotone)
            try c.encodeIfPresent(b.gradientMap, forKey: .gradientMap)
            if b.grain != 0 { try c.encode(b.grain, forKey: .grain) }
            if b.vignette != 0 { try c.encode(b.vignette, forKey: .vignette) }
            try c.encodeIfPresent(b.upscale, forKey: .upscale)
        case .text(let t):
            try c.encode("text", forKey: .type)
            try c.encode(t.text, forKey: .text)
            try c.encodeIfPresent(t.font, forKey: .font)
            try c.encodeIfPresent(t.weight, forKey: .weight)
            if let step = t.step { try c.encode(step, forKey: .size) } else { try c.encode(t.size, forKey: .size) }
            try c.encodeIfPresent(t.minSize, forKey: .minSize)
            try c.encodeIfPresent(t.maxLines, forKey: .maxLines)
            try c.encode(t.fit, forKey: .fit)
            if t.tracking != 0 { try c.encode(t.tracking, forKey: .tracking) }
            if t.lineHeight != 1 { try c.encode(t.lineHeight, forKey: .lineHeight) }
            if t.textCase != .none { try c.encode(t.textCase, forKey: .textCase) }
            try c.encode(t.align, forKey: .align)
            try c.encode(t.valign, forKey: .valign)
            try c.encode(t.color, forKey: .color)
            try c.encodeIfPresent(t.accent, forKey: .accent)
            try c.encodeIfPresent(t.muted, forKey: .muted)
            try c.encodeIfPresent(t.gradient, forKey: .gradient)
            try c.encodeIfPresent(t.stroke, forKey: .stroke)
            try c.encodeIfPresent(t.plate, forKey: .plate)
            if !t.avoid.isEmpty { try c.encode(t.avoid, forKey: .avoid) }
        case .image(let i):
            try c.encode("image", forKey: .type)
            try c.encode(i.source, forKey: .source)
            if i.cutout {
                try c.encode(true, forKey: .cutout)
                try c.encode(i.edge.description, forKey: .edge)
                if i.choke != 0 { try c.encode(i.choke, forKey: .choke) }
            }
            try c.encode(i.fit, forKey: .fit)
            try c.encodeIfPresent(i.focus, forKey: .focus)
            try c.encodeIfPresent(i.mask, forKey: .mask)
            try c.encodeIfPresent(i.stroke, forKey: .stroke)
            try c.encodeIfPresent(i.upscale, forKey: .upscale)
        case .shape(let s):
            try c.encode("shape", forKey: .type)
            try c.encode(s.shape, forKey: .shape)
            try c.encodeIfPresent(s.fill, forKey: .fill)
            try c.encodeIfPresent(s.gradient, forKey: .gradient)
            if s.gradient != nil { try c.encode(s.angle, forKey: .angle) }
            try c.encodeIfPresent(s.stroke, forKey: .stroke)
            if [.rounded, .frame, .doubleFrame].contains(s.shape) { try c.encode(s.radius, forKey: .radius) }
            try c.encodeIfPresent(s.points, forKey: .points)
            if [.star, .burst, .badge, .filmStrip].contains(s.shape) { try c.encode(s.count, forKey: .count) }
            if [.star, .burst, .ring, .badge].contains(s.shape) { try c.encode(s.inner, forKey: .inner) }
            if [.frame, .doubleFrame, .brackets].contains(s.shape) { try c.encode(s.inset, forKey: .inset) }
            if s.shape == .doubleFrame { try c.encode(s.gap, forKey: .gap) }
            if [.brackets, .arrow].contains(s.shape) { try c.encode(s.length, forKey: .length) }
        case .qr(let q):
            try c.encode("qr", forKey: .type)
            try c.encode(q.text, forKey: .text)
            try c.encode(q.color, forKey: .color)
            try c.encode(q.background, forKey: .background)
            try c.encode(q.level, forKey: .level)
        case .texture(let t):
            try c.encode("texture", forKey: .type)
            try c.encode(t.kind, forKey: .kind)
            try c.encode(t.color, forKey: .color)
            try c.encode(t.scale, forKey: .scale)
            try c.encode(t.density, forKey: .density)
            try c.encode(t.angle, forKey: .angle)
            try c.encode(t.seed, forKey: .seed)
        case .group(let layers):
            try c.encode("group", forKey: .type)
            try c.encode(layers, forKey: .layers)
        }
    }
}
