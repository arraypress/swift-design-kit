//
//  SubjectIntegrity.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Whether a parallax's subject stays whole on a frame: its silhouette, moved
//  by its one transform, measured against what the frame shows there. Pure.
//

import CoreGraphics
import Foundation

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
