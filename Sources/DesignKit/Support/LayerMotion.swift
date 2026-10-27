//
//  LayerMotion.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Where each rigid layer of a parallax sits on a frame, how much the frame
//  must be enlarged so no layer's edge shows, and how far one layer slides
//  against another (what the fill has to cover). Every layer moves by ONE
//  transform a frame — a scale about a fixed point and an offset — so nothing
//  in a layer can tear: the 0.5 parallax warped the art by its depth pixel by
//  pixel, and the thin parts of a cyclist (spokes, limbs) broke apart. Pure.
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
