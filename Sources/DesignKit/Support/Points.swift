//
//  Points.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

enum Points {
    /// Each point a pair of finite numbers; at least `needed` of them.
    static func check(_ points: [[Double]]?, at path: String, needed: Int) throws(RecipeError) {
        guard let points else {
            if needed > 0 { throw RecipeError("\(path) is missing: at least \(needed) points, [[x, y], …] as fractions of the frame") }
            return
        }
        guard points.count >= needed, points.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isFinite) }) else {
            throw RecipeError("\(path) is [[x, y], …] as fractions of the frame, at least \(max(needed, 1)) of them")
        }
    }
}
