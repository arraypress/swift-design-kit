//
//  Brands.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A brand laid over a design: its colours pinned on the palette roles the
//  template already uses (so `accent` is the brand's accent), its type as
//  the design's pairing or faces, and its logo as an image layer — in the
//  `logo` layer when the design has one, else in the corner the words
//  leave most free. Everything is written into the design by value.
//

import CanvasKit
import CoreGraphics
import Foundation
import ImageIO

public enum Brands {

    /// The order plain colours (`#E4572E,#17BEBB`) fill the palette roles in.
    public static let colorOrder: [ColorRole] = [.accent, .secondary, .light, .dark, .dominant, .neutral]

    /// The places tried for the logo, in order: the corners, then the middles of the sides.
    static let corners: [Anchor] = [.bottomRight, .topRight, .bottomLeft, .topLeft, .right, .left, .bottom, .top]

    /// Colours from text: `#E4572E,#17BEBB` (in ``colorOrder``) or `accent=#E4572E,dark=#101010`.
    public static func colors(_ text: String) throws(DesignError) -> [ColorRole: DesignColor] {
        var colors: [ColorRole: DesignColor] = [:]
        var next = 0
        for part in text.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) where !part.isEmpty {
            let pieces = part.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            let role: ColorRole
            let value: String
            if pieces.count == 2 {
                guard let named = ColorRole(rawValue: pieces[0].lowercased()) else {
                    throw .invalid(Choices.refusal(pieces[0], at: "--colors", among: ColorRole.allCases.map(\.rawValue)))
                }
                role = named
                value = pieces[1]
            } else {
                guard next < colorOrder.count else { throw .invalid("--colors takes at most \(colorOrder.count) colours in order") }
                role = colorOrder[next]
                next += 1
                value = part
            }
            guard let color = DesignColor(value) else { throw .invalid("--colors: \(value) is not a colour (#RRGGBB)") }
            colors[role] = color
        }
        guard !colors.isEmpty else { throw .invalid("--colors names a colour or more: \"#E4572E,#17BEBB\"") }
        return colors
    }

    /// `design` in `brand`'s colours, type and logo.
    public static func applied(_ brand: Brand, to design: Design) throws(DesignError) -> Design {
        var branded = design
        if !brand.colors.isEmpty {
            var palette = design.palette ?? .standard
            palette.fixed.merge(brand.colors) { _, new in new }
            branded.palette = palette
        }
        if let pairing = brand.pairing {
            guard Pairings.named(pairing) != nil else { throw .invalid(Pairings.refusal(pairing, at: "brand.pairing")) }
            branded.fonts = Typesetting(pairing: pairing)
        }
        if brand.display != nil || brand.text != nil {
            var type = branded.fonts ?? Typesetting(pairing: Pairings.fallback)
            if let display = brand.display { type.display = display }
            if let text = brand.text { type.text = text }
            let pairing = Pairings.named(type.pairing ?? Pairings.fallback)
            type.scale = type.scale ?? pairing?.scale
            type.base = type.base ?? pairing?.base
            branded.fonts = type
        }
        if let logo = brand.logo {
            branded.layers = try withLogo(logo, brand: brand, in: branded)
        }
        branded.brand = brand.name
        return branded
    }

    /// The layers with the logo placed: into a `logo` layer, or a new one in the freest corner.
    static func withLogo(_ logo: String, brand: Brand, in design: Design) throws(DesignError) -> [Layer] {
        var layers = design.layers
        if let index = layers.firstIndex(where: { $0.id == "logo" }), case .image(var image) = layers[index].content {
            image.source = logo
            layers[index].content = .image(image)
            return layers
        }
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: logo) as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue, width > 0, height > 0 else {
            throw .missing("the brand's logo is not a picture this machine can read: \(logo)")
        }
        let corner = brand.corner ?? freestCorner(for: design, width: brand.logoWidth, aspect: width / height)
        let placement = Placement(anchor: corner, width: brand.logoWidth, aspect: width / height)
        layers.append(Layer(id: layers.contains { $0.id == "logo" } ? "brand-logo" : "logo", frame: placement,
                            content: .image(ImageContent(source: logo, fit: .fit))))
        return layers
    }

    /// The first corner (or side) whose logo-sized box covers none of the words — or the one covering least, as the
    /// design lays them out (in the system face — near enough to choose by).
    static func freestCorner(for design: Design, width: Double, aspect: Double) -> Anchor {
        let geometry = design.canvas.geometry
        let placed = Layouter.place(design, geometry: geometry, faces: [:])
        let words: [CGRect] = Layouter.entries(design.layers).compactMap { entry in
            guard case .text = entry.layer.content, let lines = placed.fits[entry.path]?.linesBounds else {
                if case .list = entry.layer.content { return placed.frames[entry.path] }
                return nil
            }
            return Layout.flipped(lines, height: Double(geometry.pixelHeight))
        }
        var best = corners[0], least = Double.infinity
        for corner in corners {
            let box = Layout.frame(Placement(anchor: corner, width: width, aspect: aspect), in: geometry.safe, grid: design.grid)
            let covered = Layout.overlap(box, words)
            if covered < least - 0.5 { least = covered; best = corner }
            if covered < 0.5 { break }
        }
        return best
    }
}
