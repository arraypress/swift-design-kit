//
//  LayeredParallax.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A 2.5D loop in rigid layers. The main subject is cut out whole (BiRefNet)
//  and moves as one piece, most; the hole behind it is filled once (LaMa),
//  wide enough for the furthest it slides; the filled background is split by
//  its depth (Depth Anything) into up to three bands with soft borders, each
//  a rigid plane moving less the further it is — and where a nearer plane
//  slides off a farther one, the farther one has that strip filled too.
//  Nothing is warped pixel by pixel, so nothing tears: the 0.5 parallax did,
//  and broke a cyclist's spokes and legs apart.
//
//  The move is held small: the subject slides at most ``revealLimit`` of
//  the short side against the far plane, so the fill behind it stays small.
//

import CoreGraphics
import CoreImage
import Foundation
import Legibility

struct LayeredParallax {

    struct Plane {
        let image: CGImage
        /// Where it shows (grey, soft-bordered); `nil` everywhere (the far plane).
        let mask: CGImage?
        let weight: Double
    }

    /// The furthest the subject may slide against the far plane, as a share of the short side.
    static let revealLimit = 0.035

    let size: CGSize
    let planes: [Plane]
    /// The cut-out at the frame's size (clear elsewhere), or `nil`.
    let subject: CGImage?
    let centre: CGPoint
    let base: Double
    let dolly: Double
    let radius: Double
    let reveal: Double
    let limited: Bool

    func rect(weight: Double, phase: Double) -> CGRect {
        LayerMotion.rect(size: size, centre: centre, base: base, dolly: dolly, radius: radius, weight: weight, phase: phase)
    }

    /// The background planes, far to near.
    func drawPlanes(phase: Double, context: CGContext) {
        for plane in planes {
            let r = rect(weight: plane.weight, phase: phase)
            context.saveGState()
            if let mask = plane.mask { context.clip(to: r, mask: mask) }
            context.draw(plane.image, in: r)
            context.restoreGState()
        }
    }

    /// The subject, by its one transform.
    func drawSubject(phase: Double, context: CGContext) {
        guard let subject else { return }
        context.draw(subject, in: rect(weight: LayerMotion.subjectWeight, phase: phase))
    }

    // MARK: Making

    /// The layers for `art`, moving by `amount` over `frames` frames.
    static func make(art: CGImage, amount: Double, frames: Int, depth: any DepthEstimating, inpainter: any Inpainting,
                     services: DesignServices) async throws(DesignError) -> LayeredParallax {
        let width = art.width, height = art.height
        let size = CGSize(width: width, height: height)
        let short = Double(min(width, height))

        // The subject, whole.
        var subject: CGImage?
        var alpha: [UInt8] = []
        if let matting = services.subject {
            services.progress?("lifting the subject out whole")
            if let cut = try await matting.subject(of: art), let fitted = Animator.scaled(cut, width, height),
               let bytes = Pixels.rgba(of: fitted) {
                let values = Swift.stride(from: 3, to: bytes.count, by: 4).map { bytes[$0] }
                let area = Double(values.lazy.filter { $0 >= 128 }.count) / Double(width * height)
                // Specks and near-whole-frame "subjects" are not a subject to move.
                if area >= 0.002, area <= 0.7 { subject = fitted; alpha = values }
            }
        }

        // The point every layer scales about: the subject's middle (kept off the edges), else the frame's.
        var centre = CGPoint(x: size.width / 2, y: size.height / 2)
        var bounds = CGRect(origin: .zero, size: size)
        if subject != nil {
            var sx = 0.0, sy = 0.0, count = 0.0
            var minX = width, minY = height, maxX = 0, maxY = 0
            for y in 0..<height {
                for x in 0..<width where alpha[y * width + x] >= 128 {
                    sx += Double(x); sy += Double(y); count += 1
                    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                }
            }
            centre = CGPoint(x: min(max(sx / count, size.width * 0.25), size.width * 0.75),
                             y: min(max(size.height - sy / count, size.height * 0.25), size.height * 0.75))
            bounds = CGRect(x: minX, y: height - maxY - 1, width: maxX - minX + 1, height: maxY - minY + 1)
        }

        // The move, held so the subject never slides far against the far plane.
        var radius = size.width * amount * 0.5, dolly = amount * 0.5
        let far = LayerMotion.planeWeights(count: 3)[0]
        func measured() -> (base: Double, reveal: Double) {
            let base = LayerMotion.baseScale(size: size, centre: centre, dolly: dolly, radius: radius,
                                             weights: LayerMotion.allPlaneWeights, frames: frames)
            let reveal = LayerMotion.slide(between: subject != nil ? LayerMotion.subjectWeight : LayerMotion.allPlaneWeights.last!, and: far,
                                           region: bounds, size: size, centre: centre, base: base, dolly: dolly, radius: radius, frames: frames)
            return (base, reveal)
        }
        var (base, reveal) = measured()
        var limited = false
        let limit = revealLimit * short
        for _ in 0..<3 where reveal > limit {
            let cut = limit / reveal * 0.98
            radius *= cut
            dolly *= cut
            limited = true
            (base, reveal) = measured()
        }

        // The hole behind the subject, wide enough for the furthest it slides, filled once.
        var clean = art
        if subject != nil {
            let reach = reveal.rounded(.up) + 3
            guard let hole = Masks.grown(Masks.gray(alpha.map { $0 >= 8 ? 255 : 0 }, width: width, height: height), by: reach) else {
                throw .failed("the hole behind the subject could not be drawn")
            }
            services.progress?("filling behind the subject")
            clean = try await inpainter.filled(art, mask: hole)
        }

        // The background's depth, in bands.
        services.progress?("finding the background's depth")
        let nearness = try await depth.nearness(of: clean)
        guard nearness.count == width * height else { throw .failed("the depth map is not the picture's size") }
        let small = DepthBands.downsampled(nearness, width: width, height: height, longest: 160)
        let thresholds = DepthBands.thresholds(DepthBands.centres(small.values, count: 3))
        let cumulative = DepthBands.cumulativeMasks(small.values, width: small.width, height: small.height, thresholds: thresholds)
        let weights = LayerMotion.planeWeights(count: cumulative.count + 1)
        let sigma = max(1.5, 0.004 * short)
        var softs: [CGImage] = [], hards: [[UInt8]] = []
        for mask in cumulative {
            guard let lowres = Masks.gray(mask.map { $0 ? 255 : 0 }, width: small.width, height: small.height),
                  let soft = Masks.enlarged(lowres, width: width, height: height, sigma: sigma),
                  let bytes = Masks.bytes(of: soft) else { throw .failed("the depth bands could not be drawn") }
            softs.append(soft)
            hards.append(bytes.map { $0 >= 128 ? 255 : 0 })
        }

        // Each plane but the nearest has the strip a nearer plane slides off filled.
        var images: [CGImage] = []
        for index in 0..<weights.count {
            guard index + 1 < weights.count else { images.append(clean); continue }
            let slide = LayerMotion.slide(between: weights[index + 1], and: weights[index], region: CGRect(origin: .zero, size: size),
                                          size: size, centre: centre, base: base, dolly: dolly, radius: radius, frames: frames)
            let reach = slide.rounded(.up) + 2 * sigma + 4
            guard let hard = Masks.gray(hards[index], width: width, height: height),
                  let inner = Masks.shrunk(hard, by: reach), let innerBytes = Masks.bytes(of: inner) else {
                throw .failed("the strip behind a depth band could not be drawn")
            }
            let strip = zip(hards[index], innerBytes).map { $0 >= 128 && $1 < 128 ? UInt8(255) : 0 }
            guard strip.contains(255) else { images.append(clean); continue }
            guard let stripMask = Masks.gray(strip, width: width, height: height) else { throw .failed("the strip could not be drawn") }
            services.progress?("filling behind depth band \(index + 1) of \(weights.count)")
            images.append(try await inpainter.filled(clean, mask: stripMask))
        }
        let planes = weights.indices.map { Plane(image: images[$0], mask: $0 == 0 ? nil : softs[$0 - 1], weight: weights[$0]) }
        return LayeredParallax(size: size, planes: planes, subject: subject, centre: centre, base: base, dolly: dolly,
                               radius: radius, reveal: (reveal * 10).rounded() / 10, limited: limited)
    }
}
