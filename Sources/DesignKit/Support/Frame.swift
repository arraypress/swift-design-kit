//
//  Frame.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  One frame of an animated cover's loop: the art moved by the loop's phase,
//  light leaks, specks and grain over it, the still words on top.
//

import CoreGraphics
import Foundation

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
