//
//  Animator.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  An animated cover: the design's art moving under its still words, as a
//  seamless loop. Every movement is a periodic function of the loop's phase
//  — a push in and back, a figure-of-eight drift, a camera circling a
//  depth-split picture — so the frame after the last is the first. Over the
//  art: light leaks on closed paths, specks that rise one frame-height a
//  loop, and grain from a cycle of eight. No video model: the parallax
//  splits the art by its depth (Depth Anything), and what the near part
//  uncovers is filled (LaMa) before anything moves.
//
//  Measured on every loop: the seam (the last frame against the first, as
//  a multiple of the typical step between frames — near 1 is seamless), and
//  each text layer's contrast on every frame (its letters against the ring
//  of pixels round them), with read-back on three frames.
//

import CoreGraphics
import CoreImage
import Foundation
import Legibility

/// Animated covers: the design's art moving under its still words, written as a seamless MP4 loop.
public enum Animator {

    /// The longest side a loop is drawn at.
    public static let longestSide = 1920.0

    /// A seam more than this many times the typical step between frames shows as a jump.
    public static let seamLimit = 1.6

    /// Writes `rendered` as a looping MP4 (H.264) moving by `motion`.
    public static func animate(_ rendered: Rendered, motion: MotionSpec, to url: URL,
                               services: DesignServices) async throws(DesignError) -> AnimationReport {
        let prepared = rendered.prepared, plan = rendered.plan
        let geometry = prepared.geometry
        let scale = min(1, longestSide / Double(max(geometry.pixelWidth, geometry.pixelHeight)))
        // Even sides, as H.264 wants.
        let width = Int(Double(geometry.pixelWidth) * scale / 2) * 2, height = Int(Double(geometry.pixelHeight) * scale / 2) * 2
        let size = CGSize(width: width, height: height)
        guard let art = scaled(Checker.render(prepared, plan: plan, scale: scale, filter: Painter.Filter(artOnly: true)), width, height),
              let overlay = scaled(Checker.render(prepared, plan: plan, scale: scale, filter: { var f = Painter.Filter.all; f.overArt = true; return f }()), width, height)
        else { throw .failed("the art and the words could not be drawn apart") }

        var pinned = motion
        var layered: LayeredParallax?
        if motion.kind == .parallax {
            guard let depth = services.depth, let inpainter = services.inpainter else {
                throw .modelMissing("a parallax loop needs the depth and fill models (img's Depth Anything and LaMa)")
            }
            layered = try await LayeredParallax.make(art: art, amount: motion.amount, frames: motion.frameCount, depth: depth,
                                                     inpainter: inpainter, services: services)
            pinned.depthModel = depth.pin
            pinned.fillModel = inpainter.pin
            pinned.subjectModel = layered?.subject != nil ? services.subject?.pin : nil
        }

        let frames = motion.frameCount
        let grains = (0..<8).compactMap { index in
            Textures.render(TextureContent(kind: .noise, color: .black, density: 0.5, seed: motion.seed &+ UInt64(index)),
                            width: width, height: height, unit: 1)
        }
        let specks = Particles.make(count: motion.particles, seed: motion.seed)

        // The words' letters, for the contrast on every frame (at a measuring size).
        let measureScale = min(1, 640 / Double(max(width, height)))
        let mw = max(8, Int(Double(width) * measureScale)), mh = max(8, Int(Double(height) * measureScale))
        let textLayers = Layouter.entries(prepared.design.layers).compactMap { entry -> (path: String, id: String, words: String, letters: [Bool], ink: CGRect?)? in
            guard case .text(let text) = entry.layer.content,
                  let letters = Checker.render(prepared, plan: plan, scale: scale * measureScale, filter: Painter.Filter(only: entry.path, lettersOnly: true)),
                  let fitted = Self.scaled(letters, mw, mh) else { return nil }
            let words = Words.plain(Words.cased(Words.filled(text.text, vars: prepared.design.vars), text.textCase))
            let ink = rendered.report.text.first { $0.layer == entry.path }?.ink.map {
                CGRect(x: $0[0] / Double(geometry.pixelWidth), y: $0[1] / Double(geometry.pixelHeight),
                       width: $0[2] / Double(geometry.pixelWidth), height: $0[3] / Double(geometry.pixelHeight))
            }
            return (entry.path, entry.layer.id ?? entry.path, words, Pixels.mask(of: fitted), ink)
        }

        let writer = try VideoWriter(url: url, size: size, fps: motion.fps)
        var lowest: [String: Double] = [:]
        var reads: [String: Double] = [:]
        var steps: [Double] = []
        var first: [UInt8]?, previous: [UInt8]?
        var seam = 0.0
        var integrity: Double?, leaked: Int?, recut: Double?
        let recutFrames: Set<Int> = [0, frames / 3, 2 * frames / 3]
        for index in 0..<frames {
            let phase = Double(index) / Double(frames)
            var scene: [UInt8]?, sceneImage: CGImage?
            let measuring = layered?.subject != nil
            guard let frame = Bitmaps.image(width: width, height: height, { context in
                Frame.draw(phase: phase, motion: motion, far: art, layered: layered, overlay: overlay,
                           grain: grains.isEmpty ? nil : grains[index % grains.count], specks: specks, size: size, context: context,
                           afterArt: measuring ? { context in
                               scene = Bitmaps.bytes(of: context)
                               if recutFrames.contains(index) { sceneImage = context.makeImage() }
                           } : nil)
            }) else { throw .failed("frame \(index) could not be drawn") }
            try writer.append(frame, at: index)
            // The subject, alone by its one transform, against what the frame shows.
            if let layered, let scene, let alone = Bitmaps.bytes(width: width, height: height, { layered.drawSubject(phase: phase, context: $0) }) {
                if let measure = SubjectIntegrity.measure(scene: scene, subject: alone, width: width, height: height) {
                    integrity = min(integrity ?? 1, measure.iou)
                    leaked = max(leaked ?? 0, measure.leaked)
                }
                if let sceneImage, let matting = services.subject, let again = try await matting.subject(of: sceneImage),
                   let fitted = scaled(again, width, height), let bytes = Pixels.rgba(of: fitted), let iou = SubjectIntegrity.iou(bytes, alone) {
                    recut = min(recut ?? 1, iou)
                }
            }
            guard let small = scaled(frame, mw, mh), let bytes = Pixels.rgba(of: small) else { continue }
            if let previous { steps.append(Frame.difference(previous, bytes)) }
            if first == nil { first = bytes }
            if index == frames - 1, let first { seam = Frame.difference(bytes, first) }
            previous = bytes
            for layer in textLayers {
                if let measured = LetterRing.measure(composite: small, letters: layer.letters, referenceScale: geometry.unit * scale * measureScale) {
                    lowest[layer.id] = min(lowest[layer.id] ?? .infinity, measured.ratio)
                }
                if [0, frames / 3, 2 * frames / 3].contains(index), !layer.words.trimmingCharacters(in: .whitespaces).isEmpty {
                    let region = layer.ink?.insetBy(dx: -0.02, dy: -0.02).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
                    if let read = ReadBack.measure(layer.words, in: frame, rect: region) { reads[layer.id] = min(reads[layer.id] ?? 1, read) }
                }
            }
        }
        try await writer.finish()

        let typical = steps.sorted()[safe: steps.count / 2] ?? 0
        let ratio = typical > 0 ? seam / typical : (seam == 0 ? 1 : .infinity)
        var findings: [Finding] = []
        if ratio > seamLimit {
            findings.append(Finding(check: "loop", level: .fail, message: "the loop jumps: its last frame differs from its first \(String(format: "%.1f", ratio))× more than frames usually do",
                                    fix: "report it — every motion is meant to close"))
        }
        for layer in textLayers {
            let needed = (rendered.report.text.first { $0.layer == layer.path }?.contrastNeeded) ?? Contrast.largeTextMinimum
            if let worst = lowest[layer.id], worst < needed {
                findings.append(Finding(check: "contrast", level: worst < Contrast.largeTextMinimum ? .fail : .warn, layer: layer.path, id: layer.id,
                                        message: "\"\(layer.id)\" falls to \(String(format: "%.1f", worst)):1 on some frames as the art moves; it needs \(String(format: "%.1f", needed)):1",
                                        fix: "a plate, a scrim, less movement (amount), or fewer leaks"))
            }
        }
        var parallax: ParallaxReport?
        if let layered {
            let report = ParallaxReport(planes: layered.planes.count, subject: layered.subject != nil,
                                        integrity: integrity.map { ($0 * 1000).rounded(.down) / 1000 }, leaked: leaked,
                                        recut: recut.map { ($0 * 1000).rounded() / 1000 }, reveal: layered.reveal, limited: layered.limited)
            findings += Self.findings(report, amount: motion.amount, short: Double(min(width, height)))
            parallax = report
        }
        return AnimationReport(file: url.path, width: width, height: height, frames: frames, seconds: motion.seconds, fps: motion.fps,
                               motion: pinned, seam: (ratio * 100).rounded() / 100,
                               lowestContrast: lowest.mapValues { ($0 * 100).rounded() / 100 },
                               readBack: reads.mapValues { ($0 * 100).rounded() / 100 }, parallax: parallax, findings: findings)
    }

    /// The lowest share of the subject's silhouette that must show the subject on every frame.
    public static let integrityLimit = 0.98

    /// A re-cut subject matching its moved mask less than this is worth a look.
    public static let recutLimit = 0.85

    /// What a layered parallax's measures say.
    static func findings(_ report: ParallaxReport, amount: Double, short: Double) -> [Finding] {
        var findings: [Finding] = []
        if !report.subject {
            findings.append(Finding(check: "subject", level: .warn, message: "no subject was lifted out, so only the background planes move",
                                    fix: "use zoom or drift, or a picture with a clear subject"))
        }
        if let integrity = report.integrity, integrity < integrityLimit {
            findings.append(Finding(check: "subject", level: .fail,
                                    message: "the subject breaks up as it moves: on one frame only \(Int((integrity * 100).rounded(.down)))% of its outline shows it",
                                    fix: "report it — the subject is meant to move as one piece"))
        }
        if let leaked = report.leaked, leaked > 0 {
            findings.append(Finding(check: "subject", level: .fail, message: "background shows through the subject on some frame (\(leaked) pixels)",
                                    fix: "report it — the subject is drawn whole over the planes"))
        }
        if let recut = report.recut, recut < recutLimit {
            findings.append(Finding(check: "subject", level: .warn,
                                    message: "the subject cut again from the moving frames matches its outline only \(Int((recut * 100).rounded()))%",
                                    fix: "look at the loop; a smaller amount moves it less"))
        }
        if report.limited {
            findings.append(Finding(check: "motion", level: .warn,
                                    message: "the move was held to \(Int(report.reveal.rounded())) px of slide (amount \(amount) asked for more) so the fill behind the subject stays small",
                                    fix: "a smaller amount"))
        }
        return findings
    }

    static func scaled(_ image: CGImage?, _ width: Int, _ height: Int) -> CGImage? {
        guard let image else { return nil }
        if image.width == width, image.height == height { return image }
        return Bitmaps.image(width: width, height: height) { $0.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height)) }
    }
}
