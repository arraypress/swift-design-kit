//
//  Variants.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The same design over several background seeds, and the contact sheet a
//  person or an agent picks one from.
//

import CanvasKit
import CoreGraphics
import Foundation

public enum Variants {

    /// `design` with its first background's seed set to each of `seeds`.
    /// Refused when that background has no seed (a colour, a file).
    public static func seeded(_ design: Design, seeds: [UInt64]) throws(DesignError) -> [Design] {
        guard let index = design.layers.firstIndex(where: { if case .background = $0.content { return true }; return false }),
              case .background(let background) = design.layers[index].content else {
            throw .invalid("the design has no background to vary")
        }
        return try seeds.map { seed throws(DesignError) in
            var copy = design
            var changed = background
            switch background.fill {
            case .ai(var fill):
                guard seed <= UInt64(UInt32.max) else { throw .invalid("a made picture's seed is at most \(UInt32.max)") }
                fill.seed = UInt32(seed)
                changed.fill = .ai(fill)
            case .gradient(var spec):
                spec.seed = seed
                changed.fill = .gradient(spec)
            default:
                throw .invalid("the background is a colour, a blend or a file; only a made picture or a gradient has a seed to vary")
            }
            copy.layers[index].content = .background(changed)
            return copy
        }
    }

    /// The seed the design's background holds, if any.
    public static func seed(of design: Design) -> UInt64? {
        for layer in design.layers {
            guard case .background(let background) = layer.content else { continue }
            switch background.fill {
            case .ai(let fill): return fill.seed.map(UInt64.init)
            case .gradient(let spec): return spec.seed
            default: return nil
            }
        }
        return nil
    }

    /// The seeds `text` names: a count (`6`: the design's seed and the five
    /// after it), a range (`3-8`) or a list (`1,5,9`).
    public static func seeds(_ text: String, from base: UInt64) throws(DesignError) -> [UInt64] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let count = Int(trimmed) {
            guard (1...64).contains(count) else { throw .invalid("--seeds \(count): between 1 and 64 pictures") }
            return (0..<UInt64(count)).map { base &+ $0 }
        }
        if trimmed.contains(","), case let parts = trimmed.split(separator: ",").map({ UInt64($0.trimmingCharacters(in: .whitespaces)) }),
           parts.allSatisfy({ $0 != nil }) {
            return parts.compactMap { $0 }
        }
        let bounds = trimmed.split(separator: "-").map { UInt64($0.trimmingCharacters(in: .whitespaces)) }
        if bounds.count == 2, let low = bounds[0], let high = bounds[1], low <= high, high - low < 64 {
            return Array(low...high)
        }
        throw .invalid("--seeds takes a count (6), a range (3-8) or a list (1,5,9); not \(text)")
    }

    /// The pictures side by side, `cell` pixels on their longest side, each
    /// labelled underneath.
    public static func contactSheet(_ pictures: [(image: CGImage, label: String)], cell: Double = 480,
                                    columns: Int? = nil) -> CGImage? {
        guard let first = pictures.first?.image else { return nil }
        let count = pictures.count
        let across = columns ?? min(count, count <= 4 ? count : Int(ceil(sqrt(Double(count)))))
        let down = Int(ceil(Double(count) / Double(across)))
        let aspect = Double(first.width) / Double(first.height)
        let cw = aspect >= 1 ? cell : cell * aspect, ch = aspect >= 1 ? cell / aspect : cell
        let gap = 24.0, label = 44.0
        let width = Int(Double(across) * (cw + gap) + gap), height = Int(Double(down) * (ch + label + gap) + gap)
        return Bitmaps.image(width: width, height: height) { context in
            context.setFillColor(DesignColor("#16181C")!.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            for (index, picture) in pictures.enumerated() {
                let column = index % across, row = index / across
                let x = gap + Double(column) * (cw + gap)
                let top = gap + Double(row) * (ch + label + gap)
                let rect = CGRect(x: x, y: Double(height) - top - ch, width: cw, height: ch)
                // Each picture inside its cell at its own shape.
                context.draw(picture.image, in: Bitmaps.placement(of: picture.image, in: rect, mode: .fit, focus: nil, flippedY: true))
                let style = TextStyle(weight: "semibold", size: 22, color: SlideColor("#E8E8E8"), alignment: "center",
                                      autoShrink: true, minimumSize: 10, maxLines: 1)
                TextDrawer.draw(text: picture.label, style: style, in: CGRect(x: x, y: rect.minY - label, width: cw, height: label - 8),
                                verticalAlignment: "middle", context: context, scale: 1)
            }
        }
    }
}
