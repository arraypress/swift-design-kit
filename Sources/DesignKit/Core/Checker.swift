//
//  Checker.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The checks run on every make, blind: every number is measured on the
//  drawn pixels, nothing is judged by eye. Each text layer is drawn alone
//  (where its ink really is — outline, shadow and plate included) and as
//  bare letters (the mask its contrast is measured through), and the
//  finished picture is read back by on-device text recognition.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility

public enum Checker {

    /// Type at least this many design units tall is large (WCAG's 3:1).
    public static let largeTextUnits = 30.0

    /// Ink this far past an edge (pixels at full size) counts.
    static let tolerance = 2.0

    static func check(_ prepared: PreparedDesign, plan: Plan, composite: CGImage?) -> CheckReport {
        let geometry = prepared.geometry
        let scale = Planner.measuringScale(geometry)
        var findings: [Finding] = []
        var measures: [TextMeasure] = []

        for entry in Layouter.entries(prepared.design.layers) {
            guard case .text(let text) = entry.layer.content else { continue }
            let path = entry.path, id = entry.layer.id
            let filled = Words.filled(text.text, vars: prepared.design.vars)
            let words = Words.plain(Words.cased(filled, text.textCase))
            let fit = plan.fits[path]
            let decision = plan.text[path]
            let name = id.map { "\"\($0)\"" } ?? "layer \(path)"

            for marker in Words.unfilled(filled) {
                findings.append(Finding(check: "unfilled", level: .fail, layer: path, id: id,
                                        message: "\(name) still says {\(marker)}: no value for that slot",
                                        fix: "--var \(marker)=… (or --set \(marker)=… on a recipe)"))
            }

            // Where the ink is.
            // Drawn on a larger sheet than the page, so ink that runs off the page is still seen.
            let margin = Double(max(geometry.pixelWidth, geometry.pixelHeight)) * 0.25
            let alone = render(prepared, plan: plan, scale: scale, filter: Painter.Filter(only: path), margin: margin)
            let ink = alone.flatMap { InkBox.bounds(of: $0) }.map {
                CGRect(x: $0.minX / scale - margin, y: $0.minY / scale - margin, width: $0.width / scale, height: $0.height / scale)
            }
            var insideSafe = true, insideTrim = true
            if let ink {
                let trim = InkBox.overflow(ink, inside: geometry.trim)
                let safe = InkBox.overflow(ink, inside: geometry.safe)
                insideTrim = trim.worst <= tolerance
                insideSafe = safe.worst <= tolerance
                if !insideTrim {
                    findings.append(Finding(check: "clipped", level: .fail, layer: path, id: id,
                                            message: "\(name) runs \(Int(trim.worst.rounded())) px past the edge of the page — it will be cut off",
                                            fix: "a smaller size, a narrower frame, or no rotation"))
                } else if !insideSafe {
                    findings.append(Finding(check: "safe-area", level: .warn, layer: path, id: id,
                                            message: "\(name) reaches \(Int(safe.worst.rounded())) px outside the safe area\(sides(safe))",
                                            fix: "frame.margin, a smaller frame, or area: safe"))
                }
            }

            if let fit, !fit.fits, text.fit == .shrink {
                findings.append(Finding(check: "fit", level: .fail, layer: path, id: id,
                                        message: "\(name) does not fit its frame even at its smallest size (\(units(fit.pointSize / geometry.unit)) units)",
                                        fix: "fewer words, a larger frame, a lower min_size, or more max_lines"))
            }

            // Contrast, letters against the ring round them.
            let sizeUnits = (fit?.pointSize ?? text.size * geometry.unit) / geometry.unit
            let needed = sizeUnits >= largeTextUnits ? Contrast.largeTextMinimum : Contrast.normalTextMinimum
            var ratio: Double?
            if let composite, let letters = render(prepared, plan: plan, scale: scale,
                                                    filter: Painter.Filter(only: path, lettersOnly: true)),
               let window = window(around: ink ?? plan.frames[path], scale: scale, geometry: geometry, in: composite),
               let compositeCrop = composite.cropping(to: window), let lettersCrop = letters.cropping(to: window) {
                // Measured in a window round the words: the same pixels, a fraction of the work.
                let measured = LetterRing.measure(composite: compositeCrop, letters: Pixels.mask(of: lettersCrop),
                                                  referenceScale: geometry.unit * scale)
                ratio = measured?.ratio
                if let measured, measured.ratio < needed {
                    let alpha = Contrast.plateAlpha(text: measured.text, background: measured.surround, target: needed)
                    let shade = Contrast.plateLuminance(forText: measured.text) == 0 ? "black" : "white"
                    let plate = alpha.map { "a \(shade) plate at \(Int(($0 * 100).rounded()))%" } ?? "a solid plate"
                    findings.append(Finding(
                        check: "contrast", level: measured.ratio < Contrast.largeTextMinimum ? .fail : .warn, layer: path, id: id,
                        message: "\(name) stands out \(String(format: "%.1f", measured.ratio)):1 from what touches it; it needs \(String(format: "%.1f", needed)):1",
                        fix: "\(plate) — \"plate\": {\"color\": \"auto\"} — or a stroke, \"color\": \"auto\", or a scrim on the background"))
                }
            }

            // Read back. `nil` when recognition could not run — reported as
            // not measured, never as unreadable.
            var read: Double? = 1
            if let composite, !words.trimmingCharacters(in: .whitespaces).isEmpty {
                let region = (ink ?? plan.frames[path] ?? geometry.trim).insetBy(dx: -geometry.unit * 20, dy: -geometry.unit * 20)
                    .intersection(geometry.bleed)
                let normalized = CGRect(x: region.minX / Double(geometry.pixelWidth), y: region.minY / Double(geometry.pixelHeight),
                                        width: region.width / Double(geometry.pixelWidth), height: region.height / Double(geometry.pixelHeight))
                read = ReadBack.measure(words, in: composite, rect: normalized)
                if let read, read < 1 {
                    findings.append(Finding(check: "read-back", level: read < 0.5 ? .fail : .warn, layer: path, id: id,
                                            message: "text recognition reads \(Int((read * 100).rounded()))% of \(name)'s words back",
                                            fix: read < 0.5 ? "more contrast, a plainer face, less tracking, or a larger size" : nil))
                } else if read == nil {
                    findings.append(Finding(check: "read-back", level: .warn, layer: path, id: id,
                                            message: "\(name) was not read back: text recognition could not run (the Neural Engine was busy)",
                                            fix: "run `design check` again when no image model is generating"))
                }
            }

            // Print size.
            var points: Double?
            if let dpi = geometry.dpi, let fit {
                let pt = fit.pointSize / dpi * 72
                points = pt
                if pt < 8 {
                    findings.append(Finding(check: "print-size", level: pt < 6 ? .fail : .warn, layer: path, id: id,
                                            message: "\(name) prints at \(String(format: "%.1f", pt)) pt; \(pt < 6 ? "too small to read" : "small for print (8 pt and up reads)")",
                                            fix: "a larger size or min_size"))
                }
            }

            if let note = decision?.note, decision?.movedTo == nil, note.contains("covered") {
                findings.append(Finding(check: "faces", level: .warn, layer: path, id: id, message: "\(name): \(note)"))
            }

            measures.append(TextMeasure(
                layer: path, id: id, words: words, sizePixels: (fit?.pointSize ?? 0).rounded(),
                sizeUnits: (sizeUnits * 10).rounded() / 10, sizePoints: points.map { ($0 * 10).rounded() / 10 },
                lines: fit?.lineCount ?? 0, fits: fit?.fits ?? false,
                ink: ink.map { [$0.minX, $0.minY, $0.width, $0.height].map { $0.rounded() } },
                insideSafe: insideSafe, insideTrim: insideTrim, contrast: ratio.map { ($0 * 100).rounded() / 100 },
                contrastNeeded: needed, readBack: read.map { ($0 * 100).rounded() / 100 },
                color: decision?.color.hex ?? "", plate: decision?.plate?.hex, movedTo: decision?.movedTo?.rawValue,
                note: decision?.note))
        }

        findings += resolution(prepared)
        findings += page(prepared, composite: composite)
        findings.sort { $0.level < $1.level }
        return CheckReport(findings: findings, text: measures, sources: prepared.sources)
    }

    /// Pictures drawn larger than their pixels.
    static func resolution(_ prepared: PreparedDesign) -> [Finding] {
        prepared.sources.compactMap { note in
            guard note.enlargementAfter > Preparation.upscaleThreshold else { return nil }
            let level: Finding.Level = note.enlargementAfter > 2.5 && prepared.geometry.dpi != nil ? .fail : .warn
            let name = note.id.map { "\"\($0)\"" } ?? "layer \(note.layer)"
            return Finding(check: "resolution", level: level, layer: note.layer, id: note.id,
                           message: "\(name) is drawn \(String(format: "%.1f", note.enlargementAfter))× its own size (\(note.sourceWidth)×\(note.sourceHeight)); it will look soft",
                           fix: note.upscaled ? "a larger picture" : "\"upscale\": true on the layer (enlarges ×4 on this machine), or a larger picture")
        }
    }

    /// The page's own rules: size, shape, bleed.
    static func page(_ prepared: PreparedDesign, composite: CGImage?) -> [Finding] {
        var findings: [Finding] = []
        let canvas = prepared.design.canvas
        let rules = canvas.rules
        let place = canvas.preset ?? "this page"
        if let minimum = rules.minimumWidth, canvas.width < minimum {
            findings.append(Finding(check: "platform", level: .fail, message: "\(place) needs at least \(minimum) px across; this is \(canvas.width)"))
        }
        if let minimum = rules.minimumHeight, canvas.height < minimum {
            findings.append(Finding(check: "platform", level: .fail, message: "\(place) needs at least \(minimum) px tall; this is \(canvas.height)"))
        }
        if let maximum = rules.maximumWidth, canvas.width > maximum {
            findings.append(Finding(check: "platform", level: .fail, message: "\(place) takes at most \(maximum) px across; this is \(canvas.width)"))
        }
        if let maximum = rules.maximumHeight, canvas.height > maximum {
            findings.append(Finding(check: "platform", level: .fail, message: "\(place) takes at most \(maximum) px tall; this is \(canvas.height)"))
        }
        if rules.square, canvas.width != canvas.height {
            findings.append(Finding(check: "platform", level: .fail, message: "\(place) must be square; this is \(canvas.width)×\(canvas.height)"))
        }
        if rules.needsBleed || canvas.dpi != nil {
            let millimetres = canvas.dpi.map { Double(canvas.bleed) / $0 * Canvases.millimetresPerInch } ?? 0
            if millimetres < 2.9 {
                findings.append(Finding(check: "bleed", level: .fail,
                                        message: "a print page needs 3 mm of bleed; this has \(String(format: "%.1f", millimetres)) mm",
                                        fix: "\"canvas\": {\"bleed\": \(canvas.dpi.map { Canvases.pixels(3, dpi: $0) } ?? 35)}"))
            } else if let composite, !coversEdges(composite) {
                findings.append(Finding(check: "bleed", level: .fail,
                                        message: "the picture does not reach the bleed edge — white will show at the trim",
                                        fix: "put a background first (it fills out to the bleed)"))
            }
        }
        return findings
    }

    /// Whether every pixel round the edge of `image` is opaque.
    static func coversEdges(_ image: CGImage) -> Bool {
        guard let pixels = Pixels.rgba(of: image) else { return false }
        let w = image.width, h = image.height
        // One pixel in: a measuring picture drawn at a fraction of full size
        // antialiases its outermost row whatever is drawn there.
        guard w > 4, h > 4 else { return false }
        for x in 1..<(w - 1) where pixels[(w + x) * 4 + 3] < 250 || pixels[((h - 2) * w + x) * 4 + 3] < 250 { return false }
        for y in 1..<(h - 1) where pixels[(y * w + 1) * 4 + 3] < 250 || pixels[(y * w + w - 2) * 4 + 3] < 250 { return false }
        return true
    }

    /// A design drawn at `scale`, all of it or a filtered part.
    static func render(_ prepared: PreparedDesign, plan: Plan, scale: Double, filter: Painter.Filter, margin: Double = 0) -> CGImage? {
        let geometry = prepared.geometry
        let width = Int(((Double(geometry.pixelWidth) + 2 * margin) * scale).rounded())
        let height = Int(((Double(geometry.pixelHeight) + 2 * margin) * scale).rounded())
        return Bitmaps.image(width: width, height: height) { context in
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: margin, y: margin)
            Painter.draw(prepared, plan: plan, in: context, deviceScale: scale, filter: filter)
        }
    }

    /// The measuring picture's pixels round `rect` (full-size, top-left), with room for the ring.
    static func window(around rect: CGRect?, scale: Double, geometry: CanvasGeometry, in image: CGImage) -> CGRect? {
        guard let rect else { return nil }
        let margin = geometry.unit * 12
        let grown = rect.insetBy(dx: -margin, dy: -margin)
        let scaled = CGRect(x: grown.minX * scale, y: grown.minY * scale, width: grown.width * scale, height: grown.height * scale)
            .integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return scaled.isNull || scaled.width < 4 || scaled.height < 4 ? nil : scaled
    }

    static func sides(_ overflow: Overflow) -> String {
        let named = [("top", overflow.top), ("bottom", overflow.bottom), ("left", overflow.left), ("right", overflow.right)]
            .filter { $0.1 > tolerance }.map(\.0)
        return named.isEmpty ? "" : " (\(named.joined(separator: ", ")))"
    }

    static func units(_ value: Double) -> String { String(format: "%.0f", value) }
}
