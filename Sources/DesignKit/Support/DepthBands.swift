//
//  DepthBands.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The art's depth quantised into a few bands, for a parallax's planes. Pure.
//

import CoreGraphics
import Foundation

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
