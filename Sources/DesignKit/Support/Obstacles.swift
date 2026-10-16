//
//  Obstacles.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What a text layer keeps clear of, as one mask at the measuring scale:
//  the subject's own pixels where Vision lifted it, plus rectangles (faces,
//  cut-out pictures). One mask means a face inside a lifted subject is
//  counted once. A summed-area table answers "how much of this rectangle
//  is covered" in four reads, so trying every placement costs nothing.
//

import CoreGraphics
import Foundation

struct Obstacles: Sendable {

    /// The mask's size, in measuring pixels.
    let width: Int
    let height: Int
    /// Measuring pixels per full-size pixel.
    let scale: Double
    /// Covered pixels above and left of each corner, `(width + 1) × (height + 1)`.
    private let table: [Int32]

    /// Nothing to avoid.
    var isEmpty: Bool { table.last == 0 }

    /// `mask` (measuring pixels, top row first; `nil` for none) with
    /// `rects` (full-size pixels, top-left) filled in.
    init(mask: [Bool]?, rects: [CGRect], width: Int, height: Int, scale: Double) {
        self.width = width
        self.height = height
        self.scale = scale
        var covered = mask?.count == width * height ? mask! : [Bool](repeating: false, count: width * height)
        for rect in rects {
            let scaled = CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale)
            let x0 = max(0, Int(scaled.minX.rounded())), x1 = min(width, Int(scaled.maxX.rounded()))
            let y0 = max(0, Int(scaled.minY.rounded())), y1 = min(height, Int(scaled.maxY.rounded()))
            guard x1 > x0, y1 > y0 else { continue }
            for y in y0..<y1 { for x in x0..<x1 { covered[y * width + x] = true } }
        }
        var table = [Int32](repeating: 0, count: (width + 1) * (height + 1))
        for y in 0..<height {
            var row: Int32 = 0
            for x in 0..<width {
                if covered[y * width + x] { row += 1 }
                table[(y + 1) * (width + 1) + x + 1] = table[y * (width + 1) + x + 1] + row
            }
        }
        self.table = table
    }

    /// The covered measuring pixels inside `rect` (full-size pixels, top-left).
    func covered(_ rect: CGRect) -> Int {
        let x0 = min(width, max(0, Int((rect.minX * scale).rounded()))), x1 = min(width, max(0, Int((rect.maxX * scale).rounded())))
        let y0 = min(height, max(0, Int((rect.minY * scale).rounded()))), y1 = min(height, max(0, Int((rect.maxY * scale).rounded())))
        guard x1 > x0, y1 > y0 else { return 0 }
        let w = width + 1
        return Int(table[y1 * w + x1] - table[y0 * w + x1] - table[y1 * w + x0] + table[y0 * w + x0])
    }

    /// The share (`0…1`) of `rects` (full-size pixels, top-left — a text
    /// layer's lines) that is covered.
    func share(of rects: [CGRect]) -> Double {
        let area = rects.reduce(0.0) { $0 + max(0, $1.width * scale) * max(0, $1.height * scale) }
        guard area >= 1 else { return 0 }
        return Double(rects.reduce(0) { $0 + covered($1) }) / area
    }
}
