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

extension CarouselTemplate: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name, summary, preset, slots, pairing, palette, background, cover, each, end
        case repeats = "repeat"
    }

    public init(from decoder: any Decoder) throws {
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "carousel template")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func raw(_ key: CodingKeys) throws -> Data? {
            guard let value = try c.decodeIfPresent(AnyJSON.self, forKey: key) else { return nil }
            return try JSONSerialization.data(withJSONObject: value.value, options: [.sortedKeys, .fragmentsAllowed])
        }
        guard let cover = try raw(.cover), let each = try raw(.each) else { throw RecipeError("a carousel template needs cover and each pages") }
        self.init(name: try c.decode(String.self, forKey: .name), summary: try c.decode(String.self, forKey: .summary),
                  preset: try c.decode(String.self, forKey: .preset), slots: try c.value(.slots, or: []),
                  pairing: try c.decodeIfPresent(String.self, forKey: .pairing), palette: try c.decodeIfPresent(PaletteSpec.self, forKey: .palette),
                  repeats: try c.decode(String.self, forKey: .repeats), background: try raw(.background), cover: cover, each: each,
                  end: try raw(.end))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(summary, forKey: .summary)
        try c.encode(preset, forKey: .preset)
        try c.encode(slots, forKey: .slots)
        try c.encodeIfPresent(pairing, forKey: .pairing)
        try c.encode(repeats, forKey: .repeats)
        for (key, data) in [(CodingKeys.background, background), (.cover, cover), (.each, each), (.end, end)] {
            if let data { try c.encode(try JSONDecoder().decode(JSONFragment.self, from: data), forKey: key) }
        }
    }
}
