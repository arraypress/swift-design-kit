//
//  CanvasSpec+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

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

    /// Writes it as a design file holds it.
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
