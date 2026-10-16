//
//  Design+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Insets: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case top, bottom, left, right }

    /// An object of four fractions, or one number: the same fraction of the
    /// shorter side on every edge (made per-edge when the canvas is known).
    public init(from decoder: any Decoder) throws {
        if let uniform = try? decoder.singleValueContainer().decode(Double.self) {
            guard (0...0.45).contains(uniform) else {
                throw RecipeError("\(RecipeJSON.path(decoder.codingPath)) is \(uniform); it takes 0…0.45")
            }
            self.init(uniform: uniform)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(top: try c.number(.top, in: 0...0.45, or: 0), bottom: try c.number(.bottom, in: 0...0.45, or: 0),
                  left: try c.number(.left, in: 0...0.45, or: 0), right: try c.number(.right, in: 0...0.45, or: 0))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(top, forKey: .top)
        try c.encode(bottom, forKey: .bottom)
        try c.encode(left, forKey: .left)
        try c.encode(right, forKey: .right)
    }
}

extension CanvasSpec: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case preset, width, height, dpi, bleed, safe
        case cropMarks = "crop_marks"
    }

    /// A preset alone fills in everything; numbers given beside it win.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let path = RecipeJSON.path(decoder.codingPath)
        let presetName = try c.decodeIfPresent(String.self, forKey: .preset)
        var base: CanvasSpec?
        if let presetName {
            guard let preset = Presets.named(presetName) else {
                throw RecipeError(Choices.refusal(presetName, at: path + ".preset", among: Presets.all.map(\.name)))
            }
            base = Canvases.spec(for: preset)
        }
        guard let width = try c.decodeIfPresent(Int.self, forKey: .width) ?? base?.width,
              let height = try c.decodeIfPresent(Int.self, forKey: .height) ?? base?.height else {
            throw RecipeError("\(path) needs a preset, or a width and a height in pixels")
        }
        guard (16...20000).contains(width), (16...20000).contains(height) else {
            throw RecipeError("\(path) is \(width)×\(height); each side takes 16…20000 pixels")
        }
        let dpi = try c.number(.dpi, in: 36...2400) ?? base?.dpi
        let bleed = try c.decodeIfPresent(Int.self, forKey: .bleed) ?? base?.bleed ?? 0
        guard (0...2000).contains(bleed) else { throw RecipeError("\(path).bleed is \(bleed); it takes 0…2000 pixels") }
        var safe = try c.decodeIfPresent(Insets.self, forKey: .safe) ?? base?.safe ?? Insets(uniform: 0.06)
        if let uniform = try? c.decode(Double.self, forKey: .safe) {
            safe = Canvases.uniformSafe(uniform, width: width, height: height)
        }
        self.init(preset: presetName, width: width, height: height, dpi: dpi, bleed: bleed, safe: safe,
                  cropMarks: try c.decodeIfPresent(Bool.self, forKey: .cropMarks) ?? base?.cropMarks ?? false)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(preset, forKey: .preset)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encodeIfPresent(dpi, forKey: .dpi)
        if bleed != 0 { try c.encode(bleed, forKey: .bleed) }
        try c.encode(safe, forKey: .safe)
        if cropMarks { try c.encode(cropMarks, forKey: .cropMarks) }
    }
}

extension Design: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case design, canvas, template, vars, grid, fonts, palette, brand, layers
        case googleFonts = "google_fonts"
    }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(canvas: try c.decode(CanvasSpec.self, forKey: .canvas),
                  template: try c.decodeIfPresent(String.self, forKey: .template),
                  vars: try c.value(.vars, or: [:]), grid: try c.value(.grid, or: .standard),
                  fonts: try c.decodeIfPresent(Typesetting.self, forKey: .fonts),
                  palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  googleFonts: try c.decodeIfPresent(String.self, forKey: .googleFonts),
                  brand: try c.decodeIfPresent(String.self, forKey: .brand),
                  layers: try c.decode([Layer].self, forKey: .layers))
        if let commit = googleFonts, commit.count != 40 || !commit.allSatisfy(\.isHexDigit) {
            throw RecipeError("google_fonts is \"\(commit)\"; it is a google/fonts commit, 40 hex digits")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Design.formatVersion, forKey: .design)
        try c.encode(canvas, forKey: .canvas)
        try c.encodeIfPresent(template, forKey: .template)
        if !vars.isEmpty { try c.encode(vars, forKey: .vars) }
        if grid != .standard { try c.encode(grid, forKey: .grid) }
        try c.encodeIfPresent(fonts, forKey: .fonts)
        try c.encodeIfPresent(palette, forKey: .palette)
        try c.encodeIfPresent(googleFonts, forKey: .googleFonts)
        try c.encodeIfPresent(brand, forKey: .brand)
        try c.encode(layers, forKey: .layers)
    }
}

extension Typesetting: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case pairing, display, text, scale, base }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pairing = try c.decodeIfPresent(String.self, forKey: .pairing)
        if let pairing, Pairings.named(pairing) == nil {
            throw RecipeError(Pairings.refusal(pairing, at: RecipeJSON.path(decoder.codingPath + [CodingKeys.pairing])))
        }
        self.init(pairing: pairing?.lowercased(), display: try Self.face(c, .display), text: try Self.face(c, .text),
                  scale: try c.number(.scale, in: 1...3), base: try c.number(.base, in: 4...400))
    }

    /// A face: `{"family": …, "weight": …}`, or a family name alone.
    static func face(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> Face? {
        if let family = try? c.decodeIfPresent(String.self, forKey: key) { return Face(family: family) }
        guard let face = try c.decodeIfPresent(Face.self, forKey: key) else { return nil }
        guard Fonts.weights.contains(face.weight) else {
            throw RecipeError(Choices.refusal(face.weight, at: "fonts.\(key.rawValue).weight", among: Fonts.weights))
        }
        return face
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encodeIfPresent(display, forKey: .display)
        try c.encodeIfPresent(text, forKey: .text)
        try c.encodeIfPresent(scale, forKey: .scale)
        try c.encodeIfPresent(base, forKey: .base)
    }
}

extension Face {

    enum CodingKeys: String, CodingKey, CaseIterable { case family, weight }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(family: try c.decode(String.self, forKey: .family), weight: try c.value(.weight, or: "regular"))
    }
}

extension PaletteSpec: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case harmony, dominant, secondary, accent, neutral, light, dark }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var fixed: [ColorRole: DesignColor] = [:]
        for role in ColorRole.allCases {
            guard let key = CodingKeys(rawValue: role.rawValue) else { continue }
            if let color = try c.decodeIfPresent(DesignColor.self, forKey: key) { fixed[role] = color }
        }
        self.init(harmony: try c.value(.harmony, or: .auto), fixed: fixed)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(harmony, forKey: .harmony)
        for role in ColorRole.allCases {
            if let color = fixed[role], let key = CodingKeys(rawValue: role.rawValue) { try c.encode(color, forKey: key) }
        }
    }
}

extension Template: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case name, summary, preset, slots, grid, pairing, palette, layers }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "template")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pairing = try c.decodeIfPresent(String.self, forKey: .pairing)
        if let pairing, Pairings.named(pairing) == nil { throw RecipeError(Pairings.refusal(pairing, at: "pairing")) }
        self.init(name: try c.decode(String.self, forKey: .name), summary: try c.decode(String.self, forKey: .summary),
                  preset: try c.decode(String.self, forKey: .preset), slots: try c.value(.slots, or: []),
                  grid: try c.value(.grid, or: .standard), pairing: pairing,
                  palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  layers: try JSONSerialization.data(withJSONObject: c.decode(AnyJSON.self, forKey: .layers).value, options: [.sortedKeys]))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(summary, forKey: .summary)
        try c.encode(preset, forKey: .preset)
        try c.encode(slots, forKey: .slots)
        if grid != .standard { try c.encode(grid, forKey: .grid) }
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encodeIfPresent(palette, forKey: .palette)
        try c.encode(try JSONDecoder().decode(JSONFragment.self, from: layers), forKey: .layers)
    }
}

/// JSON carried through an encoder unchanged.
struct JSONFragment: Codable {
    let value: Any

    init(from decoder: any Decoder) throws { value = try AnyJSON(from: decoder).value }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as NSNull: _ = v; try c.encodeNil()
        case let v as Bool: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [Any]: try c.encode(v.map { JSONFragment(raw: $0) })
        case let v as [String: Any]: try c.encode(v.mapValues { JSONFragment(raw: $0) })
        default: try c.encodeNil()
        }
    }

    init(raw: Any) { value = raw }
}
