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

import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import Legibility

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

/// What a loop measured.
public struct AnimationReport: Codable, Equatable, Sendable {
    public var file: String
    public var width: Int
    public var height: Int
    public var frames: Int
    public var seconds: Double
    public var fps: Int
    /// The motion as made (with the models a parallax used).
    public var motion: MotionSpec
    /// The last frame against the first, over the typical step between frames: about 1 is seamless.
    public var seam: Double
    /// Each text layer's lowest contrast over all frames.
    public var lowestContrast: [String: Double]
    /// Each text layer's lowest read-back over three frames.
    public var readBack: [String: Double]
    /// For a parallax: its planes and whether the subject stayed whole.
    public var parallax: ParallaxReport?
    public var findings: [Finding]
    public var passed: Bool { !findings.contains { $0.level == .fail } }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

/// One frame of a loop.
enum Frame {

    static func draw(phase: Double, motion: MotionSpec, far: CGImage, layered: LayeredParallax?, overlay: CGImage, grain: CGImage?,
                     specks: [Particles.Speck], size: CGSize, context: CGContext, afterArt: ((CGContext) -> Void)? = nil) {
        let full = CGRect(origin: .zero, size: size)
        let a = motion.amount
        let turn = 2 * Double.pi * phase
        switch motion.kind {
        case .zoom:
            let zoom = 1 + a * (1 - cos(turn)) / 2
            context.draw(far, in: full.insetBy(dx: -size.width * (zoom - 1) / 2, dy: -size.height * (zoom - 1) / 2))
        case .drift:
            let grown = full.insetBy(dx: -size.width * a, dy: -size.height * a)
            context.draw(far, in: grown.offsetBy(dx: size.width * a * 0.9 * sin(turn), dy: size.height * a * 0.45 * sin(2 * turn)))
        case .parallax:
            if let layered {
                layered.drawPlanes(phase: phase, context: context)
                layered.drawSubject(phase: phase, context: context)
            } else {
                context.draw(far, in: full)
            }
        }
        afterArt?(context)
        if motion.leaks > 0 { leaks(phase: phase, strength: motion.leaks, seed: motion.seed, size: size, context: context) }
        if !specks.isEmpty { Particles.draw(specks, phase: phase, size: size, context: context) }
        if let grain, motion.grain > 0 {
            context.saveGState()
            context.setBlendMode(.overlay)
            context.setAlpha(min(1, motion.grain * 2.5))
            context.draw(grain, in: full)
            context.restoreGState()
        }
        context.draw(overlay, in: full)
    }

    /// Warm light washing in from the edges on closed paths, screened over the art.
    static func leaks(phase: Double, strength: Double, seed: UInt64, size: CGSize, context: CGContext) {
        var random = Textures.Random(seed: seed &+ 99)
        let colors = [CGColor(srgbRed: 1, green: 0.54, blue: 0.24, alpha: 1), CGColor(srgbRed: 1, green: 0.24, blue: 0.5, alpha: 1),
                      CGColor(srgbRed: 1, green: 0.82, blue: 0.4, alpha: 1)]
        context.saveGState()
        context.setBlendMode(.screen)
        for (index, color) in colors.enumerated() {
            let start = random.unit() * 2 * .pi, speed = Double(index % 2 == 0 ? 1 : -1)
            let angle = start + speed * 2 * .pi * phase
            let centre = CGPoint(x: size.width * (0.5 + 0.55 * cos(angle)), y: size.height * (0.5 + 0.5 * sin(angle)))
            // Breathing in and out twice a loop.
            let alpha = strength * 0.55 * (0.6 + 0.4 * sin(4 * .pi * phase + start))
            let radius = max(size.width, size.height) * (0.45 + 0.1 * Double(index))
            if let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: [color.copy(alpha: alpha)!, color.copy(alpha: 0)!] as CFArray, locations: [0, 1]) {
                context.drawRadialGradient(gradient, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: radius, options: [])
            }
        }
        context.restoreGState()
    }

    /// Mean absolute difference of two RGBA buffers, 0…255.
    static func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var total = 0
        for index in stride(from: 0, to: a.count, by: 4) {
            total += abs(Int(a[index]) - Int(b[index])) + abs(Int(a[index + 1]) - Int(b[index + 1])) + abs(Int(a[index + 2]) - Int(b[index + 2]))
        }
        return Double(total) / Double(a.count / 4 * 3)
    }
}

/// Specks of dust rising through the frame, one frame-height a loop.
enum Particles {
    struct Speck { let x: Double, y: Double, size: Double, sway: Double, phase: Double, alpha: Double }

    static func make(count: Int, seed: UInt64) -> [Speck] {
        var random = Textures.Random(seed: seed &+ 7)
        return (0..<count).map { _ in
            Speck(x: random.unit(), y: random.unit(), size: 0.0015 + random.unit() * 0.004, sway: 0.004 + random.unit() * 0.012,
                  phase: random.unit(), alpha: 0.25 + random.unit() * 0.55)
        }
    }

    static func draw(_ specks: [Speck], phase: Double, size: CGSize, context: CGContext) {
        context.saveGState()
        context.setBlendMode(.screen)
        let side = max(size.width, size.height)
        for speck in specks {
            let y = (speck.y + phase).truncatingRemainder(dividingBy: 1)
            let x = speck.x + speck.sway * sin(2 * .pi * (phase + speck.phase))
            let flicker = 0.7 + 0.3 * sin(2 * .pi * (2 * phase + speck.phase))
            let radius = speck.size * side
            context.setFillColor(CGColor(gray: 1, alpha: speck.alpha * flicker))
            context.fillEllipse(in: CGRect(x: x * size.width - radius, y: y * size.height - radius, width: radius * 2, height: radius * 2))
        }
        context.restoreGState()
    }
}

/// H.264 frames into an MP4.
final class VideoWriter {
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let fps: Int
    private let size: CGSize

    init(url: URL, size: CGSize, fps: Int) throws(DesignError) {
        try? FileManager.default.removeItem(at: url)
        do { writer = try AVAssetWriter(outputURL: url, fileType: .mp4) } catch {
            throw .failed("could not start \(url.path): \(error.localizedDescription)")
        }
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: Int(size.width * size.height * 6), AVVideoExpectedSourceFrameRateKey: fps],
        ])
        input.expectsMediaDataInRealTime = false
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width), kCVPixelBufferHeightKey as String: Int(size.height),
        ])
        writer.add(input)
        guard writer.startWriting() else { throw .failed("could not start the video: \(writer.error?.localizedDescription ?? "?")") }
        writer.startSession(atSourceTime: .zero)
        self.fps = fps
        self.size = size
    }

    func append(_ image: CGImage, at index: Int) throws(DesignError) {
        while !input.isReadyForMoreMediaData { usleep(2000) }
        guard let pool = adaptor.pixelBufferPool else { throw .failed("no frame buffers for the video") }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard let buffer else { throw .failed("no frame buffer for frame \(index)") }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: Bitmaps.sRGB,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        guard adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps))) else {
            throw .failed("frame \(index) could not be written: \(writer.error?.localizedDescription ?? "?")")
        }
    }

    func finish() async throws(DesignError) {
        input.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed { throw .failed("the video could not be finished: \(writer.error?.localizedDescription ?? "?")") }
    }
}
