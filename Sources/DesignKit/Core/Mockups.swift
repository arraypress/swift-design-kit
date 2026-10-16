//
//  Mockups.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A finished design shown as the thing it becomes: a record sleeve with
//  the disc sliding out, a CD jewel case, a phone, a poster pasted on a
//  wall. Everything in the scene is drawn here — studio backdrop, grooves,
//  plastic, glass, plaster — from the design and a seed, so a mockup is
//  synthetic, repeatable, and carries no photograph or brand. The poster
//  is turned in perspective (Core Image) and lit; the others are shaded
//  with gradients, gloss and soft shadows.
//

import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// What a design is shown as.
public enum MockupKind: String, DesignChoice {
    /// A square record sleeve, the disc half out.
    case vinyl
    /// A CD in its jewel case.
    case cd
    /// A phone showing the design full screen.
    case phone
    /// A poster pasted on a plaster wall, turned a little in perspective.
    case poster
}

public enum Mockups {

    /// `design` shown as `kind`, on a scene `width`×`height`; `seed` varies the backdrop's grain.
    public static func render(_ design: CGImage, kind: MockupKind, width: Int = 2400, height: Int = 1800, seed: UInt64 = 1) -> CGImage? {
        switch kind {
        case .poster: return poster(design, width: width, height: height, seed: seed)
        default:
            return Bitmaps.image(width: width, height: height) { context in
                let scene = CGRect(x: 0, y: 0, width: width, height: height)
                backdrop(context, scene, seed: seed)
                switch kind {
                case .vinyl: vinyl(design, in: scene, context: context)
                case .cd: jewelCase(design, in: scene, context: context)
                default: phone(design, in: scene, context: context)
                }
            }
        }
    }

    // MARK: The studio

    /// A soft-lit studio sweep: lighter at the top left, a little grain.
    static func backdrop(_ context: CGContext, _ scene: CGRect, seed: UInt64) {
        let space = Bitmaps.sRGB
        let colors = [CGColor(srgbRed: 0.93, green: 0.92, blue: 0.90, alpha: 1), CGColor(srgbRed: 0.78, green: 0.76, blue: 0.73, alpha: 1)]
        if let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 1]) {
            context.drawRadialGradient(gradient, startCenter: CGPoint(x: scene.width * 0.35, y: scene.height * 0.8), startRadius: 0,
                                       endCenter: CGPoint(x: scene.width * 0.5, y: scene.height * 0.5),
                                       endRadius: hypot(scene.width, scene.height) * 0.75, options: [.drawsAfterEndLocation])
        }
        if let grain = Textures.render(TextureContent(kind: .noise, color: .black, density: 0.25, seed: seed),
                                       width: Int(scene.width), height: Int(scene.height), unit: 1) {
            context.saveGState()
            context.setAlpha(0.18)
            context.draw(grain, in: scene)
            context.restoreGState()
        }
    }

    /// A soft shadow under whatever `draw` fills.
    static func shadowed(_ context: CGContext, blur: Double, offset: CGSize, alpha: Double, _ draw: () -> Void) {
        context.saveGState()
        context.setShadow(offset: offset, blur: blur, color: CGColor(gray: 0, alpha: alpha))
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        draw()
        context.endTransparencyLayer()
        context.restoreGState()
    }

    /// The design's average colour (the record label takes it).
    static func average(_ image: CGImage) -> CGColor {
        guard let one = Bitmaps.image(width: 1, height: 1, { context in
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }), let bytes = Bitmaps.rgba(one) else { return CGColor(gray: 0.5, alpha: 1) }
        return CGColor(srgbRed: Double(bytes[0]) / 255, green: Double(bytes[1]) / 255, blue: Double(bytes[2]) / 255, alpha: 1)
    }

    /// A light band across `rect`, for gloss.
    static func gloss(_ context: CGContext, over clip: CGPath, rect: CGRect, strength: Double) {
        context.saveGState()
        context.addPath(clip)
        context.clip()
        let colors = [CGColor(gray: 1, alpha: strength), CGColor(gray: 1, alpha: 0)]
        if let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: colors as CFArray, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.maxY),
                                       end: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.35), options: [])
        }
        context.restoreGState()
    }

    // MARK: Vinyl

    static func vinyl(_ design: CGImage, in scene: CGRect, context: CGContext) {
        let side = scene.height * 0.72
        let sleeve = CGRect(x: scene.midX - side * 0.72, y: scene.midY - side / 2, width: side, height: side)
        let diameter = side * 0.96
        let disc = CGRect(x: sleeve.minX + side * 0.4 + (side - diameter) / 2, y: sleeve.midY - diameter / 2, width: diameter, height: diameter)
        // The disc first: it slides out from behind the sleeve.
        shadowed(context, blur: side * 0.03, offset: CGSize(width: side * 0.01, height: -side * 0.015), alpha: 0.35) {
            context.setFillColor(CGColor(gray: 0.04, alpha: 1))
            context.fillEllipse(in: disc)
        }
        let centre = CGPoint(x: disc.midX, y: disc.midY)
        // Grooves: fine rings, lighter and darker by turns.
        let ringCount = 90
        for ring in 0..<ringCount {
            let radius = diameter / 2 * (0.36 + 0.62 * Double(ring) / Double(ringCount))
            context.setStrokeColor(CGColor(gray: ring.isMultiple(of: 2) ? 0.12 : 0.02, alpha: 0.8))
            context.setLineWidth(max(1, diameter * 0.0025))
            context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
        }
        // Sheen: two opposite light wedges.
        context.saveGState()
        context.addEllipse(in: disc)
        context.clip()
        for start in [Double.pi * 0.15, Double.pi * 1.15] {
            let wedge = CGMutablePath()
            wedge.move(to: centre)
            wedge.addArc(center: centre, radius: diameter, startAngle: start, endAngle: start + 0.35, clockwise: false)
            wedge.closeSubpath()
            context.addPath(wedge)
            context.setFillColor(CGColor(gray: 1, alpha: 0.07))
            context.fillPath()
        }
        context.restoreGState()
        // The label, in the cover's own colour, and the spindle hole.
        let label = diameter * 0.33
        context.setFillColor(average(design))
        context.fillEllipse(in: CGRect(x: centre.x - label / 2, y: centre.y - label / 2, width: label, height: label))
        context.setFillColor(CGColor(gray: 0.85, alpha: 1))
        let hole = diameter * 0.02
        context.fillEllipse(in: CGRect(x: centre.x - hole / 2, y: centre.y - hole / 2, width: hole, height: hole))
        // The sleeve.
        shadowed(context, blur: side * 0.04, offset: CGSize(width: side * 0.012, height: -side * 0.02), alpha: 0.45) {
            context.draw(design, in: sleeve)
        }
        let edge = CGPath(rect: sleeve, transform: nil)
        gloss(context, over: edge, rect: sleeve, strength: 0.12)
        context.addPath(edge)
        context.setStrokeColor(CGColor(gray: 0, alpha: 0.18))
        context.setLineWidth(max(1, side * 0.002))
        context.strokePath()
    }

    // MARK: CD

    static func jewelCase(_ design: CGImage, in scene: CGRect, context: CGContext) {
        // A jewel case is 142 × 125 mm; its cover 120 mm square, set right of the hinge.
        let height = scene.height * 0.68, width = height * 142 / 125
        let box = CGRect(x: scene.midX - width / 2, y: scene.midY - height / 2, width: width, height: height)
        let radius = height * 0.015
        let shape = CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil)
        shadowed(context, blur: height * 0.04, offset: CGSize(width: height * 0.012, height: -height * 0.02), alpha: 0.4) {
            context.addPath(shape)
            context.setFillColor(CGColor(gray: 0.05, alpha: 0.9))
            context.fillPath()
        }
        let cover = height * 120 / 125 * 0.98
        let art = CGRect(x: box.maxX - cover - height * 0.025, y: box.midY - cover / 2, width: cover, height: cover)
        context.draw(design, in: art)
        // The hinge: a clear strip with ridges.
        let hinge = CGRect(x: box.minX, y: box.minY, width: art.minX - box.minX, height: box.height)
        context.setFillColor(CGColor(gray: 1, alpha: 0.10))
        context.fill(hinge)
        context.setStrokeColor(CGColor(gray: 1, alpha: 0.25))
        context.setLineWidth(max(1, height * 0.002))
        for step in 1...3 {
            let x = hinge.minX + hinge.width * Double(step) / 4
            context.move(to: CGPoint(x: x, y: hinge.minY + height * 0.02))
            context.addLine(to: CGPoint(x: x, y: hinge.maxY - height * 0.02))
        }
        context.strokePath()
        // Plastic: a clear sheen, a diagonal glare, a bright rim.
        context.addPath(shape)
        context.setFillColor(CGColor(gray: 1, alpha: 0.04))
        context.fillPath()
        context.saveGState()
        context.addPath(shape)
        context.clip()
        let glare = CGMutablePath()
        glare.move(to: CGPoint(x: box.minX + box.width * 0.35, y: box.maxY))
        glare.addLine(to: CGPoint(x: box.minX + box.width * 0.62, y: box.maxY))
        glare.addLine(to: CGPoint(x: box.minX + box.width * 0.30, y: box.minY))
        glare.addLine(to: CGPoint(x: box.minX + box.width * 0.03, y: box.minY))
        glare.closeSubpath()
        context.addPath(glare)
        context.setFillColor(CGColor(gray: 1, alpha: 0.09))
        context.fillPath()
        context.restoreGState()
        context.addPath(shape)
        context.setStrokeColor(CGColor(gray: 1, alpha: 0.55))
        context.setLineWidth(max(1, height * 0.004))
        context.strokePath()
    }

    // MARK: Phone

    static func phone(_ design: CGImage, in scene: CGRect, context: CGContext) {
        let height = scene.height * 0.86, width = height * 9 / 19.5
        let body = CGRect(x: scene.midX - width / 2, y: scene.midY - height / 2, width: width, height: height)
        let corner = width * 0.15
        let shape = CGPath(roundedRect: body, cornerWidth: corner, cornerHeight: corner, transform: nil)
        shadowed(context, blur: height * 0.035, offset: CGSize(width: height * 0.01, height: -height * 0.02), alpha: 0.45) {
            context.addPath(shape)
            context.setFillColor(CGColor(gray: 0.08, alpha: 1))
            context.fillPath()
        }
        // The frame's edge, a little lighter.
        context.addPath(shape)
        context.setStrokeColor(CGColor(gray: 0.35, alpha: 1))
        context.setLineWidth(max(1, width * 0.012))
        context.strokePath()
        let inset = width * 0.035
        let screen = body.insetBy(dx: inset, dy: inset)
        let screenCorner = corner - inset
        let screenShape = CGPath(roundedRect: screen, cornerWidth: screenCorner, cornerHeight: screenCorner, transform: nil)
        context.saveGState()
        context.addPath(screenShape)
        context.clip()
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(screen)
        if Double(design.width) / Double(design.height) <= 0.7 {
            // A story or a tall poster fills the screen.
            context.draw(design, in: Bitmaps.placement(of: design, in: screen, mode: .fill, focus: nil, flippedY: true))
        } else {
            // A cover is shown as a player shows it: the art on its own blurred, darkened colours, a bar and controls under it.
            if let backdrop = Bitmaps.render(CIImage(cgImage: design).clampedToExtent().applyingGaussianBlur(sigma: Double(design.width) * 0.06)
                                                .cropped(to: CGRect(x: 0, y: 0, width: design.width, height: design.height)),
                                             extent: CGRect(x: 0, y: 0, width: design.width, height: design.height)) {
                context.draw(backdrop, in: Bitmaps.placement(of: backdrop, in: screen, mode: .fill, focus: nil, flippedY: true))
                context.setFillColor(CGColor(gray: 0, alpha: 0.35))
                context.fill(screen)
            }
            let side = screen.width * 0.84
            let art = CGRect(x: screen.midX - side * Double(design.width) / Double(max(design.width, design.height)) / 2,
                             y: screen.maxY - screen.height * 0.17 - side, width: side * Double(design.width) / Double(max(design.width, design.height)),
                             height: side * Double(design.height) / Double(max(design.width, design.height)))
            shadowed(context, blur: side * 0.05, offset: CGSize(width: 0, height: -side * 0.02), alpha: 0.5) {
                context.saveGState()
                context.addPath(CGPath(roundedRect: art, cornerWidth: side * 0.03, cornerHeight: side * 0.03, transform: nil))
                context.clip()
                context.draw(design, in: art)
                context.restoreGState()
            }
            // Two lines where the title would be, a progress bar, three controls — shapes only, no words.
            let left = screen.midX - side / 2
            var y = art.minY - side * 0.12
            for (share, alpha) in [(0.55, 0.9), (0.35, 0.55)] {
                let bar = CGRect(x: left, y: y, width: side * share, height: side * 0.045)
                context.addPath(CGPath(roundedRect: bar, cornerWidth: bar.height / 2, cornerHeight: bar.height / 2, transform: nil))
                context.setFillColor(CGColor(gray: 1, alpha: alpha))
                context.fillPath()
                y -= side * 0.08
            }
            y -= side * 0.04
            context.setFillColor(CGColor(gray: 1, alpha: 0.3))
            context.fill(CGRect(x: left, y: y, width: side, height: side * 0.012))
            context.setFillColor(CGColor(gray: 1, alpha: 0.9))
            context.fill(CGRect(x: left, y: y, width: side * 0.38, height: side * 0.012))
            let controls = y - side * 0.2
            for (offset, radius) in [(-0.3, 0.05), (0.0, 0.085), (0.3, 0.05)] {
                let centre = CGPoint(x: screen.midX + side * offset, y: controls)
                context.fillEllipse(in: CGRect(x: centre.x - side * radius, y: centre.y - side * radius, width: side * radius * 2, height: side * radius * 2))
            }
        }
        context.restoreGState()
        // The camera island, and a faint reflection on the glass.
        let island = CGRect(x: screen.midX - width * 0.16, y: screen.maxY - width * 0.13, width: width * 0.32, height: width * 0.09)
        context.addPath(CGPath(roundedRect: island, cornerWidth: island.height / 2, cornerHeight: island.height / 2, transform: nil))
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fillPath()
        gloss(context, over: screenShape, rect: screen, strength: 0.10)
    }

    // MARK: Poster

    static func poster(_ design: CGImage, width: Int, height: Int, seed: UInt64) -> CGImage? {
        let scene = CGRect(x: 0, y: 0, width: width, height: height)
        // The wall: warm plaster, lit from the upper left, with paper-like blotches.
        guard let wall = Bitmaps.image(width: width, height: height, { context in
            context.setFillColor(CGColor(srgbRed: 0.86, green: 0.83, blue: 0.78, alpha: 1))
            context.fill(scene)
            if let plaster = Textures.render(TextureContent(kind: .paper, color: DesignColor("#5C5040")!, density: 0.55, seed: seed),
                                             width: width, height: height, unit: Double(min(width, height)) / 1000) {
                context.saveGState()
                context.setBlendMode(.multiply)
                context.setAlpha(0.6)
                context.draw(plaster, in: scene)
                context.restoreGState()
            }
            let light = [CGColor(gray: 1, alpha: 0.28), CGColor(gray: 0, alpha: 0.22)]
            if let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: light as CFArray, locations: [0, 1]) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: scene.width * 0.25, y: scene.height * 0.95), startRadius: 0,
                                           endCenter: CGPoint(x: scene.width * 0.4, y: scene.height * 0.6),
                                           endRadius: hypot(scene.width, scene.height) * 0.8, options: [.drawsAfterEndLocation])
            }
        }) else { return nil }

        // The poster, shaded like paper (a soft crease of light across it), then turned.
        let aspect = Double(design.width) / Double(design.height)
        let posterHeight = Double(height) * 0.74, posterWidth = posterHeight * aspect
        let pw = Int(posterWidth), ph = Int(posterHeight)
        guard let paper = Bitmaps.image(width: pw, height: ph, { context in
            context.draw(design, in: CGRect(x: 0, y: 0, width: pw, height: ph))
            let shade = [CGColor(gray: 1, alpha: 0.10), CGColor(gray: 0, alpha: 0.10)]
            if let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: shade as CFArray, locations: [0, 1]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: Double(ph)), end: CGPoint(x: Double(pw), y: 0), options: [])
            }
            // Tape at the top corners.
            for x in [Double(pw) * 0.02, Double(pw) * 0.86] {
                context.saveGState()
                context.translateBy(x: x + Double(pw) * 0.06, y: Double(ph) * 0.985)
                context.rotate(by: x < Double(pw) / 2 ? 0.35 : -0.35)
                context.setFillColor(CGColor(srgbRed: 0.95, green: 0.92, blue: 0.82, alpha: 0.72))
                context.fill(CGRect(x: -Double(pw) * 0.07, y: -Double(ph) * 0.018, width: Double(pw) * 0.14, height: Double(ph) * 0.036))
                context.restoreGState()
            }
        }) else { return nil }
        // Turned: the right edge a little further away.
        let left = scene.midX - posterWidth / 2, bottom = scene.midY - posterHeight / 2
        let filter = CIFilter.perspectiveTransform()
        filter.inputImage = CIImage(cgImage: paper)
        filter.topLeft = CGPoint(x: left, y: bottom + posterHeight)
        filter.bottomLeft = CGPoint(x: left, y: bottom)
        filter.topRight = CGPoint(x: left + posterWidth * 0.96, y: bottom + posterHeight * 0.975)
        filter.bottomRight = CGPoint(x: left + posterWidth * 0.96, y: bottom + posterHeight * 0.025)
        guard let turned = filter.outputImage else { return nil }
        let shadow = turned.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.35),
        ]).applyingGaussianBlur(sigma: Double(height) * 0.012).transformed(by: CGAffineTransform(translationX: Double(height) * 0.008, y: -Double(height) * 0.012))
        let composed = turned.composited(over: shadow.composited(over: CIImage(cgImage: wall)))
        return Bitmaps.render(composed, extent: scene)
    }
}
