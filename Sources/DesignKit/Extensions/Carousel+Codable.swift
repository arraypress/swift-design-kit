//
//  Carousel+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension Carousel: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case carousel, canvas, template, vars, grid, fonts, palette, brand, background, pages
        case googleFonts = "google_fonts"
    }

    struct Page: Codable {
        let layers: [Layer]
        enum CodingKeys: String, CodingKey, CaseIterable { case layers }
        init(layers: [Layer]) { self.layers = layers }
        init(from decoder: any Decoder) throws {
            try decoder.refuseUnknownKeys(CodingKeys.self, noun: "carousel page")
            layers = try decoder.container(keyedBy: CodingKeys.self).decode([Layer].self, forKey: .layers)
        }
    }

    /// Reads it as a carousel recipe writes it; an unknown key is refused with the close one.
    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "carousel")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pages = try c.decode([Page].self, forKey: .pages).map(\.layers)
        guard (1...Carousels.maximumPages).contains(pages.count) else {
            throw RecipeError("pages: a carousel has 1…\(Carousels.maximumPages) pages, not \(pages.count)")
        }
        let background = try c.decodeIfPresent(Layer.self, forKey: .background)
        if let background {
            guard case .background = background.content else { throw RecipeError("background is a background layer (\"type\": \"background\")") }
        }
        self.init(canvas: try c.decode(CanvasSpec.self, forKey: .canvas), template: try c.decodeIfPresent(String.self, forKey: .template),
                  vars: try c.value(.vars, or: [:]), grid: try c.value(.grid, or: .standard),
                  fonts: try c.decodeIfPresent(Typesetting.self, forKey: .fonts), palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  googleFonts: try c.decodeIfPresent(String.self, forKey: .googleFonts), brand: try c.decodeIfPresent(String.self, forKey: .brand),
                  background: background, pages: pages)
    }

    /// Writes it as a carousel recipe holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Carousel.formatVersion, forKey: .carousel)
        try c.encode(canvas, forKey: .canvas)
        try c.encodeIfPresent(template, forKey: .template)
        if !vars.isEmpty { try c.encode(vars, forKey: .vars) }
        if grid != .standard { try c.encode(grid, forKey: .grid) }
        try c.encodeIfPresent(fonts, forKey: .fonts)
        try c.encodeIfPresent(palette, forKey: .palette)
        try c.encodeIfPresent(googleFonts, forKey: .googleFonts)
        try c.encodeIfPresent(brand, forKey: .brand)
        try c.encodeIfPresent(background, forKey: .background)
        try c.encode(pages.map(Page.init(layers:)), forKey: .pages)
    }
}
