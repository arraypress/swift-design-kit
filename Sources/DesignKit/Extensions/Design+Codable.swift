//
//  Design+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Design: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case design, canvas, template, vars, grid, fonts, palette, brand, motion, layers
        case googleFonts = "google_fonts"
    }

    /// Reads it as a design file writes it; an unknown key is refused with the close one.
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
        motion = try c.decodeIfPresent(MotionSpec.self, forKey: .motion)
        if let commit = googleFonts, commit.count != 40 || !commit.allSatisfy(\.isHexDigit) {
            throw RecipeError("google_fonts is \"\(commit)\"; it is a google/fonts commit, 40 hex digits")
        }
    }

    /// Writes it as a design file holds it.
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
        try c.encodeIfPresent(motion, forKey: .motion)
        try c.encode(layers, forKey: .layers)
    }
}
