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
        case .star, .burst: return star(points: shape.count, inner: shape.inner, in: frame)
        case .frame:
            return frameRect(frame, inset: shape.inset * unit + lineWidth(shape, unit: unit) / 2, radius: shape.radius * unit)
        case .doubleFrame:
            let first = shape.inset * unit + lineWidth(shape, unit: unit) / 2
            let path = CGMutablePath()
            path.addPath(frameRect(frame, inset: first, radius: shape.radius * unit))
            path.addPath(frameRect(frame, inset: first + shape.gap * unit + lineWidth(shape, unit: unit),
                                   radius: max(0, shape.radius * unit - shape.gap * unit)))
            return path
        case .brackets: return brackets(frame.insetBy(dx: shape.inset * unit + lineWidth(shape, unit: unit) / 2,
                                                      dy: shape.inset * unit + lineWidth(shape, unit: unit) / 2),
                                        length: shape.length)
        case .filmStrip: return filmStrip(frame, holes: shape.count)
        case .arrow:
            let ends = (shape.points ?? [[0, 0.5], [1, 0.5]]).map { point($0, in: frame) }
            let path = CGMutablePath()
            path.addLines(between: ends)
            return path
        case .ring:
            let path = CGMutablePath()
            path.addEllipse(in: frame)
            path.addEllipse(in: frame.insetBy(dx: frame.width * (1 - shape.inner) / 2, dy: frame.height * (1 - shape.inner) / 2))
            return path
        case .badge: return badge(frame, scallops: shape.count, inner: shape.inner)
        case .divider:
            let path = CGMutablePath()
            let d = min(frame.height, frame.width * 0.04) / 2
            path.move(to: CGPoint(x: frame.minX, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.midX - d * 2.2, y: frame.midY))
            path.move(to: CGPoint(x: frame.midX + d * 2.2, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            return path
        }
    }

    /// The width a shape's lines are drawn at, pixels.
    static func lineWidth(_ shape: ShapeContent, unit: Double) -> Double {
        (shape.stroke?.width ?? 4) * unit
    }

    /// Shapes drawn as lines only, never filled.
    static func isLines(_ kind: ShapeKind) -> Bool {
        [.line, .frame, .doubleFrame, .brackets, .arrow, .divider].contains(kind)
    }

    /// Shapes whose holes are cut by the even-odd rule.
    static func isEvenOdd(_ kind: ShapeKind) -> Bool { [.filmStrip, .ring].contains(kind) }

    static func frameRect(_ frame: CGRect, inset: Double, radius: Double) -> CGPath {
        let box = frame.insetBy(dx: inset, dy: inset)
        guard box.width > 0, box.height > 0 else { return CGMutablePath() }
        return radius > 0 ? rounded(box, radius: max(0, radius - inset)) : CGPath(rect: box, transform: nil)
    }

    /// An L at each corner, its arms `length` of the shorter side.
    static func brackets(_ box: CGRect, length: Double) -> CGPath {
        let arm = min(box.width, box.height) * length
        let path = CGMutablePath()
        for (x, dx) in [(box.minX, 1.0), (box.maxX, -1.0)] {
            for (y, dy) in [(box.minY, 1.0), (box.maxY, -1.0)] {
                path.move(to: CGPoint(x: x + dx * arm, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + dy * arm))
            }
        }
        return path
    }

    /// A strip's edges: a band top and bottom, each with `holes` sprocket holes.
    static func filmStrip(_ frame: CGRect, holes: Int) -> CGPath {
        let path = CGMutablePath()
        let band = min(frame.height * 0.14, frame.width * 0.09)
        let count = max(2, holes)
        let pitch = frame.width / Double(count)
        let hole = CGSize(width: pitch * 0.5, height: band * 0.5)
        for y in [frame.minY, frame.maxY - band] {
            path.addRect(CGRect(x: frame.minX, y: y, width: frame.width, height: band))
            for i in 0..<count {
                let r = CGRect(x: frame.minX + pitch * (Double(i) + 0.25), y: y + (band - hole.height) / 2,
                               width: hole.width, height: hole.height)
                path.addPath(CGPath(roundedRect: r, cornerWidth: hole.height * 0.25, cornerHeight: hole.height * 0.25, transform: nil))
            }
        }
        return path
    }

    /// A seal: a disc `inner` of the box with `scallops` round bumps on its rim.
    static func badge(_ frame: CGRect, scallops: Int, inner: Double) -> CGPath {
        let path = CGMutablePath()
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let rx = frame.width / 2, ry = frame.height / 2
        let core = inner
        path.addEllipse(in: CGRect(x: center.x - rx * core, y: center.y - ry * core, width: 2 * rx * core, height: 2 * ry * core))
        let count = max(6, scallops)
        let bump = (1 - core) + core * sin(.pi / Double(count))
        for i in 0..<count {
            let angle = Double.pi / 2 + Double(i) * 2 * .pi / Double(count)
            let cx = center.x + cos(angle) * rx * (1 - bump), cy = center.y + sin(angle) * ry * (1 - bump)
            path.addEllipse(in: CGRect(x: cx - rx * bump, y: cy - ry * bump, width: 2 * rx * bump, height: 2 * ry * bump))
        }
        return path
    }

    /// An arrow's head at the last point of `ends`, `size` long.
    static func arrowHead(from: CGPoint, to: CGPoint, size: Double) -> CGPath {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let path = CGMutablePath()
        path.move(to: to)
        path.addLine(to: CGPoint(x: to.x - cos(angle - 0.45) * size, y: to.y - sin(angle - 0.45) * size))
        path.addLine(to: CGPoint(x: to.x - cos(angle + 0.45) * size, y: to.y - sin(angle + 0.45) * size))
        path.closeSubpath()
        return path
    }

    /// The divider's centre diamond.
    static func diamond(in frame: CGRect) -> CGPath {
        let d = min(frame.height, frame.width * 0.04) / 2
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: frame.midX, y: frame.midY + d), CGPoint(x: frame.midX + d, y: frame.midY),
                                CGPoint(x: frame.midX, y: frame.midY - d), CGPoint(x: frame.midX - d, y: frame.midY)])
        path.closeSubpath()
        return path
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
