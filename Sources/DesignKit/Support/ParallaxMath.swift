//
//  ParallaxMath.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The arithmetic of a layered parallax, kept apart so it can be tested:
//  where each rigid layer sits on a frame, how much the frame must be
//  enlarged so no layer's edge shows, how far one layer slides against
//  another (what the fill has to cover), the art's depth quantised into a
//  few bands, and the subject-integrity measure.
//
//  Every layer moves by ONE transform a frame — a scale about a fixed point
//  and an offset — so nothing in a layer can tear: the 0.5 parallax warped
//  the art by its depth pixel by pixel, and the thin parts of a cyclist
//  (spokes, limbs) landed at different depths and broke apart.
//

import CoreGraphics
import Foundation

/// Where each rigid layer is on a frame.
enum LayerMotion {

    /// How much each layer moves, by how near it is: the far plane least, the subject most.
    static func planeWeights(count: Int) -> [Double] {
        switch count {
        case ...1: [0.3]
        case 2: [0.15, 0.55]
        default: [0.15, 0.4, 0.7]
        }
    }

    /// Every weight a plane can have, for sizing the frame before the planes are known.
    static let allPlaneWeights = [0.15, 0.3, 0.4, 0.55, 0.7]

    /// The subject's weight.
    static let subjectWeight = 1.0

    /// The camera's offset for a layer of `weight` at `phase` (0…1): a slow
    /// side-to-side sway with a slight figure-of-eight lift, eased at its
    /// turns (sines), closing on itself.
    static func offset(radius: Double, weight: Double, phase: Double) -> CGVector {
        let turn = 2 * Double.pi * phase
        return CGVector(dx: radius * weight * sin(turn), dy: radius * weight * 0.4 * sin(2 * turn))
    }

    /// A gentle push in and back (a dolly), more for nearer layers.
    static func scale(base: Double, dolly: Double, weight: Double, phase: Double) -> Double {
        base * (1 + dolly * weight * (1 - cos(2 * Double.pi * phase)) / 2)
    }

    /// The rectangle a layer the frame's size is drawn in: scaled about
    /// `centre` (CoreGraphics space), then offset.
    static func rect(size: CGSize, centre: CGPoint, base: Double, dolly: Double, radius: Double, weight: Double,
                     phase: Double) -> CGRect {
        let s = scale(base: base, dolly: dolly, weight: weight, phase: phase)
        let d = offset(radius: radius, weight: weight, phase: phase)
        return CGRect(x: centre.x * (1 - s) + d.dx, y: centre.y * (1 - s) + d.dy, width: size.width * s, height: size.height * s)
    }

    /// Where a point of the still lands for a layer.
    static func map(_ point: CGPoint, centre: CGPoint, base: Double, dolly: Double, radius: Double, weight: Double,
                    phase: Double) -> CGPoint {
        let s = scale(base: base, dolly: dolly, weight: weight, phase: phase)
        let d = offset(radius: radius, weight: weight, phase: phase)
        return CGPoint(x: centre.x + (point.x - centre.x) * s + d.dx, y: centre.y + (point.y - centre.y) * s + d.dy)
    }

    /// The smallest base scale at which every layer of `weights` covers the
    /// frame on every one of `frames` frames — no edge ever shows.
    static func baseScale(size: CGSize, centre: CGPoint, dolly: Double, radius: Double, weights: [Double], frames: Int) -> Double {
        var needed = 1.0
        for index in 0..<max(1, frames) {
            let phase = Double(index) / Double(max(1, frames))
            for weight in weights {
                let d = offset(radius: radius, weight: weight, phase: phase)
                let k = 1 + dolly * weight * (1 - cos(2 * Double.pi * phase)) / 2
                // Left/bottom edges: centre·(1−s) + d ≤ 0; right/top: centre + (side−centre)·s + d ≥ side.
                var s = 1.0
                if centre.x > 0 { s = max(s, 1 + d.dx / centre.x) }
                if size.width - centre.x > 0 { s = max(s, 1 - d.dx / (size.width - centre.x)) }
                if centre.y > 0 { s = max(s, 1 + d.dy / centre.y) }
                if size.height - centre.y > 0 { s = max(s, 1 - d.dy / (size.height - centre.y)) }
                needed = max(needed, s / k)
            }
        }
        // Half a pixel more, so rounding never shows an edge.
        return needed + 1 / Double(max(size.width, size.height))
    }

    /// How far, in frame pixels, a layer of weight `a` slides against one of
    /// weight `b` at any point of `region` (CoreGraphics space) over the loop:
    /// what a fill behind the nearer one must reach.
    static func slide(between a: Double, and b: Double, region: CGRect, size: CGSize, centre: CGPoint, base: Double, dolly: Double,
                      radius: Double, frames: Int) -> Double {
        let corners = [CGPoint(x: region.minX, y: region.minY), CGPoint(x: region.maxX, y: region.minY),
                       CGPoint(x: region.minX, y: region.maxY), CGPoint(x: region.maxX, y: region.maxY)]
        var most = 0.0
        for index in 0..<max(1, frames) {
            let phase = Double(index) / Double(max(1, frames))
            for corner in corners {
                let p = map(corner, centre: centre, base: base, dolly: dolly, radius: radius, weight: a, phase: phase)
                let q = map(corner, centre: centre, base: base, dolly: dolly, radius: radius, weight: b, phase: phase)
                most = max(most, hypot(p.x - q.x, p.y - q.y))
            }
        }
        return most
    }
}

/// The art's depth in a few bands.
enum DepthBands {

    /// `values` (`width`×`height`) averaged down so the longest side is at most `longest`.
    static func downsampled(_ values: [Float], width: Int, height: Int, longest: Int) -> (values: [Float], width: Int, height: Int) {
        let factor = max(1, Int((Double(max(width, height)) / Double(longest)).rounded(.up)))
        guard factor > 1 else { return (values, width, height) }
        let w = max(1, width / factor), h = max(1, height / factor)
        var out = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                var total: Float = 0
                for dy in 0..<factor { for dx in 0..<factor { total += values[(y * factor + dy) * width + x * factor + dx] } }
                out[y * w + x] = total / Float(factor * factor)
            }
        }
        return (out, w, h)
    }

    /// Up to `count` band centres by 1-D k-means (seeded at evenly spaced
    /// quantiles, so the same depth gives the same bands), merging any two
    /// closer than `minGap`: a flat picture gets one plane.
    static func centres(_ values: [Float], count: Int, minGap: Float = 0.12) -> [Float] {
        guard !values.isEmpty, count > 0 else { return [] }
        let sorted = values.sorted()
        var centres = (0..<count).map { sorted[min(sorted.count - 1, Int(Double(sorted.count) * (Double($0) + 0.5) / Double(count)))] }
        for _ in 0..<30 {
            var sums = [Double](repeating: 0, count: centres.count), counts = [Int](repeating: 0, count: centres.count)
            for value in values {
                var best = 0
                for index in 1..<centres.count where abs(value - centres[index]) < abs(value - centres[best]) { best = index }
                sums[best] += Double(value)
                counts[best] += 1
            }
            let next = centres.indices.map { counts[$0] > 0 ? Float(sums[$0] / Double(counts[$0])) : centres[$0] }
            if next == centres { break }
            centres = next
        }
        centres.sort()
        var merged: [Float] = []
        for centre in centres {
            if let last = merged.last, centre - last < minGap { merged[merged.count - 1] = (last + centre) / 2 } else { merged.append(centre) }
        }
        return merged
    }

    /// The borders between bands: half-way between neighbouring centres.
    static func thresholds(_ centres: [Float]) -> [Float] {
        zip(centres, centres.dropFirst()).map { ($0 + $1) / 2 }
    }

    /// For each threshold, the pixels at least that near (the bands from it
    /// nearward, together), with specks smaller than `radius` closed and opened away.
    static func cumulativeMasks(_ values: [Float], width: Int, height: Int, thresholds: [Float], radius: Int = 2) -> [[Bool]] {
        thresholds.map { threshold in
            let raw = values.map { $0 >= threshold }
            let closed = erode(dilate(raw, width: width, height: height, radius: radius), width: width, height: height, radius: radius)
            return dilate(erode(closed, width: width, height: height, radius: radius), width: width, height: height, radius: radius)
        }
    }

    static func dilate(_ mask: [Bool], width: Int, height: Int, radius: Int) -> [Bool] {
        morph(mask, width: width, height: height, radius: radius, any: true)
    }

    static func erode(_ mask: [Bool], width: Int, height: Int, radius: Int) -> [Bool] {
        morph(mask, width: width, height: height, radius: radius, any: false)
    }

    /// A square max (`any`) or min filter, separably; outside the picture counts as the edge pixel.
    private static func morph(_ mask: [Bool], width: Int, height: Int, radius: Int, any: Bool) -> [Bool] {
        guard radius > 0 else { return mask }
        var rows = mask
        for y in 0..<height {
            for x in 0..<width {
                var result = !any
                for dx in -radius...radius {
                    let v = mask[y * width + min(width - 1, max(0, x + dx))]
                    if v == any { result = any; break }
                }
                rows[y * width + x] = result
            }
        }
        var out = rows
        for y in 0..<height {
            for x in 0..<width {
                var result = !any
                for dy in -radius...radius {
                    let v = rows[min(height - 1, max(0, y + dy)) * width + x]
                    if v == any { result = any; break }
                }
                out[y * width + x] = result
            }
        }
        return out
    }
}

/// Whether the subject stays whole on a frame.
enum SubjectIntegrity {

    /// One frame measured.
    struct Measure: Equatable {
        /// The silhouette pixels showing the subject, over all of them (the
        /// rendered subject region against the mask moved by its one transform).
        var iou: Double
        /// Pixels well inside the silhouette that show something else — background through the subject.
        var leaked: Int
    }

    /// Compares `scene` (the frame before light, grain and words) with
    /// `subject` (the cut-out alone, drawn by its single transform), both
    /// premultiplied RGBA of the same size. Where the subject is opaque the
    /// scene must equal it; where it is partly transparent the scene may be
    /// lighter only by what shows through (`(1−α)·255`). `nil` when the
    /// subject is not on the frame.
    static func measure(scene: [UInt8], subject: [UInt8], width: Int, height: Int, tolerance: Int = 10) -> Measure? {
        guard scene.count == subject.count, scene.count == width * height * 4 else { return nil }
        var silhouette = 0, shown = 0, leaked = 0
        for y in 0..<height {
            for x in 0..<width {
                let o = (y * width + x) * 4
                let alpha = Int(subject[o + 3])
                guard alpha >= 128 else { continue }
                silhouette += 1
                let through = 255 - alpha
                var matches = true
                for c in 0..<3 {
                    let d = Int(scene[o + c]) - Int(subject[o + c])
                    if d < -tolerance || d > through + tolerance { matches = false; break }
                }
                if matches { shown += 1; continue }
                // Deep inside: this pixel and its four neighbours fully opaque.
                guard alpha >= 253, x > 0, y > 0, x < width - 1, y < height - 1,
                      subject[o - 4 + 3] >= 253, subject[o + 4 + 3] >= 253,
                      subject[o - width * 4 + 3] >= 253, subject[o + width * 4 + 3] >= 253 else { continue }
                leaked += 1
            }
        }
        guard silhouette > 0 else { return nil }
        return Measure(iou: Double(shown) / Double(silhouette), leaked: leaked)
    }

    /// Intersection over union of two masks (alpha ≥ 128 in premultiplied RGBA, or grey bytes with `stride` 1).
    static func iou(_ a: [UInt8], _ b: [UInt8], stride: Int = 4, offset: Int = 3) -> Double? {
        guard a.count == b.count, !a.isEmpty else { return nil }
        var inter = 0, union = 0
        for index in Swift.stride(from: offset, to: a.count, by: stride) {
            let x = a[index] >= 128, y = b[index] >= 128
            if x && y { inter += 1 }
            if x || y { union += 1 }
        }
        return union == 0 ? nil : Double(inter) / Double(union)
    }
}
