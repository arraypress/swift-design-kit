//
//  SizeStep.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The named sizes a text layer may take instead of a number, each one
/// step of the design's type scale from `body`.
public enum SizeStep: String, DesignChoice {
    /// The steps from smallest to largest: `caption` one below `body`, `giant` six above.
    case caption, body, lead, subtitle, title, headline, display, giant

    /// Steps from `body`.
    var steps: Int {
        switch self {
        case .caption: -1
        case .body: 0
        case .lead: 1
        case .subtitle: 2
        case .title: 3
        case .headline: 4
        case .display: 5
        case .giant: 6
        }
    }

    /// The size in design units on a scale with `base` as `body`.
    public func size(scale: Double, base: Double) -> Double {
        (base * pow(scale, Double(steps)) * 10).rounded() / 10
    }
}
