//
//  ReleaseKit.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  One design as a matched set — cover, square post, portrait post, story,
//  video thumbnail, header — each a new page laid out by the design's own
//  rules, never a stretched picture. Layout is already by rule (frames are
//  fractions of the area, sizes thousandths of the shorter side), so a
//  design moves to another page as itself; on a wide page, where the
//  shorter side is short, its words are set larger (by the square root of
//  the page's width over its height, at most 1.5×) and left to shrink to
//  their frames. (Growing the frames too was tried: it broke stacks built
//  with `above`/`below` — a host line climbed off its band.) A made picture is the same picture on every page, cropped
//  to fill; a gradient is drawn for each page.
//

import Foundation

/// One design laid out again as a matched set of pages.
public enum ReleaseKit {

    /// The sizes a set is made in, by short name, and the preset each is.
    public static let sizes: [(name: String, preset: String)] = [
        ("cover", "cover"), ("square", "ig-post"), ("portrait", "ig-portrait"), ("story", "story"),
        ("youtube", "youtube-thumbnail"), ("banner", "x-header"), ("podcast", "podcast-cover"),
    ]

    /// The set made when none is named.
    public static let defaultSizes = ["cover", "square", "portrait", "story", "youtube", "banner"]

    /// Words grow by at most this on a wide page.
    public static let widestGrowth = 1.5

    /// The preset a size name (or any preset's own name) stands for.
    public static func preset(for size: String) -> Preset? {
        let key = size.lowercased().trimmingCharacters(in: .whitespaces)
        if let entry = sizes.first(where: { $0.name == key }) { return Presets.named(entry.preset) }
        return Presets.named(key)
    }

    /// The names `text` lists (`cover,story,a4`), each checked.
    public static func sizeList(_ text: String) throws(DesignError) -> [String] {
        let names = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        guard !names.isEmpty else { throw .invalid("--sizes names one size or more: \(defaultSizes.joined(separator: ","))") }
        for name in names where preset(for: name) == nil {
            throw .invalid(Choices.refusal(name, at: "--sizes", among: sizes.map(\.name) + Presets.all.map(\.name)))
        }
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }

    /// `design` on the page `size` names, its words grown on a wide page.
    public static func adapted(_ design: Design, to size: String) throws(DesignError) -> Design {
        guard let preset = preset(for: size) else {
            throw .invalid(Choices.refusal(size, at: "size", among: sizes.map(\.name) + Presets.all.map(\.name)))
        }
        var adapted = design
        adapted.canvas = CanvasSpec(preset: preset)
        let growth = growth(width: Double(adapted.canvas.width), height: Double(adapted.canvas.height))
        if growth > 1 { adapted.layers = adapted.layers.map { grown($0, by: growth) } }
        return adapted
    }

    /// How much words grow on a page `width`×`height`: 1 unless it is wide.
    public static func growth(width: Double, height: Double) -> Double {
        let aspect = width / height
        return aspect > 1 ? min(widestGrowth, aspect.squareRoot()) : 1
    }

    /// A top-level text or list layer with its sizes multiplied (a named size step is left to the scale).
    static func grown(_ layer: Layer, by factor: Double) -> Layer {
        var layer = layer
        switch layer.content {
        case .text(var text) where text.step == nil:
            text.size *= factor
            text.minSize = text.minSize.map { $0 * factor }
            layer.content = .text(text)
        case .list(var list):
            list.sizes = list.sizes.map { $0 * factor }
            layer.content = .list(list)
        default:
            break
        }
        return layer
    }
}
