//
//  Particles.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

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
