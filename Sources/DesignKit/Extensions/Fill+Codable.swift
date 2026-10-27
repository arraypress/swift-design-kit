//
//  Fill+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Fill: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case kind, color, colors, angle, seed, palette, motif, path, prompt, model, revision, aspect, steps, style
    }

    static let kinds = ["color", "linear", "radial", "gradient", "image", "ai"]

    /// The keys each kind takes.
    static func keys(for kind: String) -> [CodingKeys] {
        switch kind {
        case "color": [.kind, .color]
        case "linear": [.kind, .colors, .angle]
        case "radial": [.kind, .colors]
        case "gradient": [.kind, .seed, .palette, .motif]
        case "image": [.kind, .path]
        default: [.kind, .prompt, .model, .revision, .seed, .aspect, .steps, .style]
        }
    }

    /// An object by its `kind`, or the short string a template or `--var` writes.
    public init(from decoder: any Decoder) throws {
        let path = RecipeJSON.path(decoder.codingPath)
        if let text = try? decoder.singleValueContainer().decode(String.self) {
            self = try FillShorthand.parse(text, field: path)
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(String.self, forKey: .kind)
        guard Self.kinds.contains(kind) else { throw RecipeError(Choices.refusal(kind, at: path + ".kind", among: Self.kinds)) }
        try decoder.refuseUnknownKeys(Self.keys(for: kind).map(\.rawValue), noun: "design")
        switch kind {
        case "color":
            self = .color(try c.decode(DesignColor.self, forKey: .color))
        case "linear", "radial":
            let colors = try c.decode([DesignColor].self, forKey: .colors)
            guard colors.count >= 2 else { throw RecipeError("\(path).colors takes two colours or more") }
            self = kind == "linear" ? .linear(colors: colors, angle: try c.number(.angle, in: -360...360, or: 180)) : .radial(colors: colors)
        case "gradient":
            self = .gradient(GradientFill(seed: try c.value(.seed, or: 1), palette: try c.decodeIfPresent(String.self, forKey: .palette),
                                          motif: try c.decodeIfPresent(String.self, forKey: .motif)))
        case "image":
            self = .image(path: try c.decode(String.self, forKey: .path))
        default:
            let steps = try c.decodeIfPresent(Int.self, forKey: .steps)
            if let steps, !(1...28).contains(steps) { throw RecipeError("\(path).steps is \(steps); it takes 1…28") }
            self = .ai(AIFill(prompt: try c.decode(String.self, forKey: .prompt), model: try c.decodeIfPresent(String.self, forKey: .model),
                              revision: try c.decodeIfPresent(String.self, forKey: .revision),
                              seed: try c.decodeIfPresent(UInt32.self, forKey: .seed),
                              aspect: try c.decodeIfPresent(String.self, forKey: .aspect), steps: steps,
                              style: try c.decodeIfPresent(String.self, forKey: .style)))
        }
    }

    /// Writes the object, with everything pinned.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .color(let color):
            try c.encode("color", forKey: .kind)
            try c.encode(color, forKey: .color)
        case .linear(let colors, let angle):
            try c.encode("linear", forKey: .kind)
            try c.encode(colors, forKey: .colors)
            try c.encode(angle, forKey: .angle)
        case .radial(let colors):
            try c.encode("radial", forKey: .kind)
            try c.encode(colors, forKey: .colors)
        case .gradient(let spec):
            try c.encode("gradient", forKey: .kind)
            try c.encode(spec.seed, forKey: .seed)
            try c.encodeIfPresent(spec.palette, forKey: .palette)
            try c.encodeIfPresent(spec.motif, forKey: .motif)
        case .image(let path):
            try c.encode("image", forKey: .kind)
            try c.encode(path, forKey: .path)
        case .ai(let spec):
            try c.encode("ai", forKey: .kind)
            try c.encode(spec.prompt, forKey: .prompt)
            try c.encodeIfPresent(spec.model, forKey: .model)
            try c.encodeIfPresent(spec.revision, forKey: .revision)
            try c.encodeIfPresent(spec.seed, forKey: .seed)
            try c.encodeIfPresent(spec.aspect, forKey: .aspect)
            try c.encodeIfPresent(spec.steps, forKey: .steps)
            try c.encodeIfPresent(spec.style, forKey: .style)
        }
    }
}
