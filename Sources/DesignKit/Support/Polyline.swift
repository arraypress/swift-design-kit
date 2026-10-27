//
//  Polyline.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// A sampled curve, walked by distance along it.
struct Polyline {
    let points: [CGPoint]
    /// The distance from the start to each point.
    let distances: [Double]

    init(_ points: [CGPoint]) {
        self.points = points
        var distances = [0.0]
        for index in 1..<max(1, points.count) {
            distances.append(distances[index - 1] + hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y))
        }
        self.distances = distances
    }

    var length: Double { distances.last ?? 0 }

    /// The point `distance` along, and the direction of travel there (radians,
    /// counter-clockwise from the x axis). Off either end it carries straight on.
    func point(at distance: Double) -> (CGPoint, Double) {
        guard points.count >= 2 else { return (points.first ?? .zero, 0) }
        var low = 0, high = distances.count - 1
        while high - low > 1 {
            let mid = (low + high) / 2
            if distances[mid] <= distance { low = mid } else { high = mid }
        }
        let a = points[low], b = points[high]
        let span = max(1e-9, distances[high] - distances[low])
        let t = (distance - distances[low]) / span
        let angle = atan2(b.y - a.y, b.x - a.x)
        return (CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), angle)
    }
}
