//
//  Textures.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Texture layers, drawn procedurally from a seed — the same seed draws the
//  same marks at any size, measured in design units so a texture reads the
//  same on a post and a poster. Each is ink of one colour on transparency,
//  made to be blended (multiply, overlay, screen) at a low opacity.
//

import CoreGraphics
import Foundation

enum Textures {

    /// SplitMix64: small, fast, and the same everywhere.
    struct Random {
        var state: UInt64
        init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        /// `0..<1`.
        mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    }

    /// The texture, `width`×`height` pixels; `unit` pixels per design unit.
    static func render(_ texture: TextureContent, width: Int, height: Int, unit: Double) -> CGImage? {
        switch texture.kind {
        case .noise, .paper: pixelTexture(texture, width: width, height: height, unit: unit)
        case .halftone, .scanlines, .dust:
            Bitmaps.image(width: width, height: height) { context in
                context.setFillColor(texture.color.cgColor)
                context.setStrokeColor(texture.color.cgColor)
                switch texture.kind {
                case .halftone: halftone(texture, width: width, height: height, unit: unit, context: context)
                case .scanlines: scanlines(texture, width: width, height: height, unit: unit, context: context)
                default: dust(texture, width: width, height: height, unit: unit, context: context)
                }
            }
        }
    }

    /// Noise and paper, pixel by pixel: the ink's alpha varies.
    static func pixelTexture(_ texture: TextureContent, width: Int, height: Int, unit: Double) -> CGImage? {
        guard let context = Bitmaps.context(width: width, height: height), let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let ink = texture.color.components
        var random = Random(seed: texture.seed)
        let cell = max(1, Int((texture.scale * unit * 0.5).rounded()))
        // Paper: soft blotches from a coarse value-noise grid under the fine grain.
        let coarse = max(4, texture.scale * unit * 12)
        let gw = Int(Double(width) / coarse) + 2, gh = Int(Double(height) / coarse) + 2
        var grid = [Double](repeating: 0, count: gw * gh)
        if texture.kind == .paper { for i in grid.indices { grid[i] = random.unit() } }
        var fine = [Double](repeating: 0, count: ((width + cell - 1) / cell) * ((height + cell - 1) / cell))
        for i in fine.indices { fine[i] = random.unit() }
        let fineColumns = (width + cell - 1) / cell
        for y in 0..<height {
            for x in 0..<width {
                var value = fine[(y / cell) * fineColumns + x / cell]
                if texture.kind == .paper {
                    let gx = Double(x) / coarse, gy = Double(y) / coarse
                    let x0 = Int(gx), y0 = Int(gy), fx = gx - Double(x0), fy = gy - Double(y0)
                    let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
                    let top = grid[y0 * gw + x0] * (1 - sx) + grid[y0 * gw + x0 + 1] * sx
                    let bottom = grid[(y0 + 1) * gw + x0] * (1 - sx) + grid[(y0 + 1) * gw + x0 + 1] * sx
                    let blotch = top * (1 - sy) + bottom * sy
                    value = 0.55 * blotch + 0.45 * value * value
                }
                let alpha = min(1, max(0, value * texture.density))
                let i = (y * width + x) * 4
                pixels[i] = UInt8((ink.red * alpha * 255).rounded())
                pixels[i + 1] = UInt8((ink.green * alpha * 255).rounded())
                pixels[i + 2] = UInt8((ink.blue * alpha * 255).rounded())
                pixels[i + 3] = UInt8((alpha * 255).rounded())
            }
        }
        return context.makeImage()
    }

    /// A dot screen at 45°, the dots growing toward `angle` up to `density` cover.
    static func halftone(_ texture: TextureContent, width: Int, height: Int, unit: Double, context: CGContext) {
        let pitch = max(2, texture.scale * unit)
        let radians = (90 - texture.angle) * .pi / 180
        let direction = (x: cos(radians), y: sin(radians))
        let w = Double(width), h = Double(height)
        let reach = abs(w * direction.x) + abs(h * direction.y)
        let diagonal = (w * w + h * h).squareRoot()
        let steps = Int(diagonal / pitch) + 2
        for i in -steps...steps {
            for j in -steps...steps {
                // The 45° screen.
                let x = w / 2 + (Double(i) - Double(j)) * pitch / 2.0.squareRoot()
                let y = h / 2 + (Double(i) + Double(j)) * pitch / 2.0.squareRoot()
                guard x > -pitch, x < w + pitch, y > -pitch, y < h + pitch else { continue }
                let along = ((x - w / 2) * direction.x + (y - h / 2) * direction.y) / reach + 0.5
                let cover = min(1, max(0, along)) * texture.density
                let r = pitch / 2 * (cover * 4 / .pi).squareRoot() * 0.98
                guard r > 0.3 else { continue }
                context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            }
        }
    }

    /// Lines across, `scale` apart, `density` of the pitch thick.
    static func scanlines(_ texture: TextureContent, width: Int, height: Int, unit: Double, context: CGContext) {
        let pitch = max(2, texture.scale * unit)
        let thick = max(0.5, pitch * min(0.9, max(0.05, texture.density)))
        var y = 0.0
        while y < Double(height) {
            context.fill(CGRect(x: 0, y: y, width: Double(width), height: thick))
            y += pitch
        }
    }

    /// Specks and the odd hair, `density` setting how many.
    static func dust(_ texture: TextureContent, width: Int, height: Int, unit: Double, context: CGContext) {
        var random = Random(seed: texture.seed)
        let area = Double(width * height) / (unit * unit)
        let specks = Int(area / 2500 * texture.density * 40)
        let size = texture.scale * unit
        for _ in 0..<specks {
            let x = random.unit() * Double(width), y = random.unit() * Double(height)
            let r = size * (0.15 + random.unit() * random.unit() * 1.4)
            context.setAlpha(0.35 + random.unit() * 0.65)
            context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
        }
        context.setLineCap(.round)
        for _ in 0..<max(1, specks / 25) {
            let x = random.unit() * Double(width), y = random.unit() * Double(height)
            let length = size * (8 + random.unit() * 30)
            let turn = random.unit() * 2 * .pi
            context.setAlpha(0.3 + random.unit() * 0.5)
            context.setLineWidth(max(0.6, size * 0.25))
            context.move(to: CGPoint(x: x, y: y))
            context.addQuadCurve(to: CGPoint(x: x + cos(turn) * length, y: y + sin(turn) * length),
                                 control: CGPoint(x: x + cos(turn + 1) * length * 0.6, y: y + sin(turn + 1) * length * 0.6))
            context.strokePath()
        }
        context.setAlpha(1)
    }
}
