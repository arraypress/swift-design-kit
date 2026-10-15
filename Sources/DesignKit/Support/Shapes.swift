//
//  Shapes.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Paths and blends in CoreGraphics space (origin bottom-left). Points given
//  as fractions of a frame read from its top-left, as a design tool does.
//

import CoreGraphics
import Foundation

enum Shapes {

    /// A point given as fractions of `frame` from its top-left.
    static func point(_ pair: [Double], in frame: CGRect) -> CGPoint {
        CGPoint(x: frame.minX + frame.width * (pair.first ?? 0), y: frame.maxY - frame.height * (pair.last ?? 0))
    }

    /// The outline of a shape layer.
    static func path(_ shape: ShapeContent, in frame: CGRect, unit: Double) -> CGPath {
        switch shape.shape {
        case .rect: return CGPath(rect: frame, transform: nil)
        case .rounded: return rounded(frame, radius: shape.radius * unit)
        case .ellipse: return CGPath(ellipseIn: frame, transform: nil)
        case .line:
            let ends = shape.points ?? [[0, 0.5], [1, 0.5]]
            let path = CGMutablePath()
            path.addLines(between: ends.map { point($0, in: frame) })
            return path
        case .polygon: return polygon(shape.points ?? [], in: frame)
        case .star: return star(points: shape.count, inner: shape.inner, in: frame)
        }
    }

    /// The outline a mask clips to.
    static func path(_ mask: Mask, in frame: CGRect, unit: Double) -> CGPath {
        switch mask.shape {
        case .rect: CGPath(rect: frame, transform: nil)
        case .rounded: rounded(frame, radius: mask.radius * unit)
        case .circle: CGPath(ellipseIn: frame, transform: nil)
        case .polygon: polygon(mask.points ?? [], in: frame)
        }
    }

    static func rounded(_ frame: CGRect, radius: Double) -> CGPath {
        let r = min(radius, min(frame.width, frame.height) / 2)
        return CGPath(roundedRect: frame, cornerWidth: r, cornerHeight: r, transform: nil)
    }

    static func polygon(_ points: [[Double]], in frame: CGRect) -> CGPath {
        let path = CGMutablePath()
        guard points.count >= 3 else { return path }
        path.addLines(between: points.map { point($0, in: frame) })
        path.closeSubpath()
        return path
    }

    /// A star with `points` tips, its inner corners at `inner` of the outer radius, one tip up.
    static func star(points: Int, inner: Double, in frame: CGRect) -> CGPath {
        let path = CGMutablePath()
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let rx = frame.width / 2, ry = frame.height / 2
        let corners = max(3, points) * 2
        for index in 0..<corners {
            let angle = Double.pi / 2 - Double(index) * Double.pi / Double(max(3, points))
            let scale = index.isMultiple(of: 2) ? 1 : inner
            let p = CGPoint(x: center.x + cos(angle) * rx * scale, y: center.y + sin(angle) * ry * scale)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// A straight blend over `rect`; 0° points up, clockwise.
    static func linear(_ colors: [DesignColor], angle: Double, in rect: CGRect, context: CGContext) {
        guard let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: colors.map(\.cgColor) as CFArray, locations: nil) else { return }
        let radians = (90 - angle) * .pi / 180
        let direction = CGVector(dx: cos(radians), dy: sin(radians))
        let reach = (abs(rect.width * direction.dx) + abs(rect.height * direction.dy)) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: center.x - direction.dx * reach, y: center.y - direction.dy * reach),
                                   end: CGPoint(x: center.x + direction.dx * reach, y: center.y + direction.dy * reach),
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    /// A blend from the centre of `rect` out to its corners.
    static func radial(_ colors: [DesignColor], in rect: CGRect, context: CGContext) {
        guard let gradient = CGGradient(colorsSpace: Bitmaps.sRGB, colors: colors.map(\.cgColor) as CFArray, locations: nil) else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                   endRadius: hypot(rect.width, rect.height) / 2, options: [.drawsAfterEndLocation])
    }
}
