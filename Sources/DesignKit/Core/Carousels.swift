//
//  Carousels.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A carousel made from its template, read and written as `"carousel": 1`,
//  and turned into one design per page: the shared background given its
//  `span` (this page of that many), the page's own layers on top. Each page
//  is drawn and checked as any design is.
//

import Foundation
import RecipeKit

/// Carousels made from their templates, read and written as recipes, and split into one design per page.
public enum Carousels {

    /// The recipe format.
    public static let format = RecipeFormat(versionKey: "carousel", version: Carousel.formatVersion,
                                            rootKeys: Carousel.CodingKeys.allCases.map(\.rawValue), sections: [], suggests: true)

    /// The pages most a carousel takes (Instagram's limit is 20).
    public static let maximumPages = 20

    /// A carousel from its recipe's bytes, read strictly.
    public static func decoded(_ data: Data) throws(RecipeError) -> Carousel {
        try RecipeJSON.decoded(data, as: Carousel.self, format: format)
    }

    /// The carousel as recipe bytes.
    public static func encoded(_ carousel: Carousel) throws(RecipeError) -> Data {
        try RecipeJSON.encoded(carousel)
    }

    /// The carousel in the recipe at `url`, its paths resolved against the file's folder.
    public static func load(_ url: URL) throws(RecipeFileError) -> Carousel {
        let carousel = try RecipeFiles.load(url) { data in try decoded(data) }
        let folder = url.deletingLastPathComponent()
        var moved = carousel
        moved.pages = carousel.pages.map { Recipes.relocated(Design(canvas: carousel.canvas, layers: $0), from: folder, to: nil).layers }
        moved.background = carousel.background.flatMap { Recipes.relocated(Design(canvas: carousel.canvas, layers: [$0]), from: folder, to: nil).layers.first }
        return moved
    }

    /// Writes the carousel to `url`, its paths made relative to the file's folder.
    public static func save(_ carousel: Carousel, to url: URL, overwrites: Bool) throws(RecipeFileError) {
        let folder = url.deletingLastPathComponent()
        var stored = carousel
        stored.pages = carousel.pages.map { Recipes.relative(Design(canvas: carousel.canvas, layers: $0), to: folder).layers }
        stored.background = carousel.background.flatMap { Recipes.relative(Design(canvas: carousel.canvas, layers: [$0]), to: folder).layers.first }
        try RecipeFiles.save(stored, to: url, overwrites: overwrites)
    }

    /// One design per page.
    public static func designs(_ carousel: Carousel) -> [Design] {
        let count = carousel.pages.count
        return carousel.pages.enumerated().map { index, layers in
            var all = layers
            if var background = carousel.background, case .background(var content) = background.content {
                content.span = [index, count]
                background.content = .background(content)
                all.insert(background, at: 0)
            }
            return Design(canvas: carousel.canvas, template: carousel.template, vars: carousel.vars, grid: carousel.grid,
                          fonts: carousel.fonts, palette: carousel.palette, googleFonts: carousel.googleFonts,
                          brand: carousel.brand, layers: all)
        }
    }

    /// `carousel` with its palette roles found once, in the whole background
    /// drawn across all the pages, and pinned — so `accent` is the same colour
    /// on every page rather than each page's own slice's.
    public static func sharedPalette(_ carousel: Carousel, services: DesignServices) async throws(DesignError) -> Carousel {
        guard let background = carousel.background, carousel.pages.count > 1 else { return carousel }
        let count = Double(carousel.pages.count)
        // The panorama, small: its aspect is what matters (a gradient is drawn for its shape).
        let scale = min(1, 2048 / (Double(carousel.canvas.width) * count))
        let width = max(16, Int(Double(carousel.canvas.width) * count * scale)), height = max(16, Int(Double(carousel.canvas.height) * scale))
        var strip = Design(canvas: CanvasSpec(width: width, height: height), vars: carousel.vars, palette: carousel.palette, layers: [background])
        strip.canvas.safe = Insets(uniform: 0)
        let roles = try await DesignEngine.render(strip, services: services).plan.palette
        var pinned = carousel
        var palette = carousel.palette ?? .standard
        if let roles {
            for role in ColorRole.allCases where palette.fixed[role] == nil { palette.fixed[role] = roles[role] }
        }
        pinned.palette = palette
        return pinned
    }

    /// The carousel `template` makes with `values`: a cover, a page per item, an end.
    public static func make(_ template: CarouselTemplate, values: [String: String], canvas: CanvasSpec? = nil,
                            pairing: String? = nil) throws(DesignError) -> Carousel {
        let (slotValues, faces) = TypeVars.split(values)
        let vars: [String: String]
        do { vars = try SlotFilling.resolved(slotValues, for: template.slots.map(\.styleSlot), style: template.name) } catch {
            throw .invalid(error.errorDescription ?? "\(error)")
        }
        let items = ListLayout.items(from: vars[template.repeats] ?? "").map(\.text)
        guard !items.isEmpty else { throw .invalid("--var \(template.repeats)= needs one item or more, split by |") }
        let pageCount = items.count + 1 + (template.end == nil ? 0 : 1)
        guard pageCount <= maximumPages else {
            throw .invalid("\(items.count) items make \(pageCount) pages; a carousel takes at most \(maximumPages)")
        }
        func layers(_ json: Data, extra: [String: String]) throws(DesignError) -> [Layer] {
            let page = Template(name: template.name, summary: template.summary, preset: template.preset,
                                slots: template.slots, layers: substituted(json, extra))
            return try Making.design(from: page, values: slotValues, canvas: canvas).layers
        }
        var pages = [try layers(template.cover, extra: ["count": String(items.count)])]
        for (index, item) in items.enumerated() {
            pages.append(try layers(template.each, extra: ["item": item, "n": String(index + 1), "count": String(items.count)]))
        }
        if let end = template.end { pages.append(try layers(end, extra: ["count": String(items.count)])) }
        var background: Layer?
        if let json = template.background {
            background = try layers(Data("[".utf8) + json + Data("]".utf8), extra: [:]).first
        }
        guard let page = canvas ?? Presets.named(template.preset).map(CanvasSpec.init(preset:)) else {
            throw .invalid("template \(template.name) names a preset that does not exist: \(template.preset)")
        }
        if let pairing, Pairings.named(pairing) == nil { throw .invalid(Pairings.refusal(pairing, at: "--pairing")) }
        let fonts = try TypeVars.applied(faces, to: (pairing ?? template.pairing).map { Typesetting(pairing: $0.lowercased()) })
        return Carousel(canvas: page, template: template.name, vars: vars, fonts: fonts, palette: template.palette,
                        background: background, pages: pages)
    }

    /// `json` with `{item}`, `{n}` and `{count}` written in (they are the page's, not slots).
    static func substituted(_ json: Data, _ extra: [String: String]) -> Data {
        var text = String(decoding: json, as: UTF8.self)
        for (name, value) in extra {
            let escaped = String(decoding: (try? JSONSerialization.data(withJSONObject: [value])) ?? Data(), as: UTF8.self)
                .dropFirst(2).dropLast(2)
            text = text.replacingOccurrences(of: "{\(name)}", with: String(escaped))
        }
        return Data(text.utf8)
    }
}
