//
//  FitMode.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How a picture meets its frame.
public enum FitMode: String, DesignChoice {
    /// Cover the frame, cropping what overhangs (around `focus`).
    case fill
    /// Show all of it, inside the frame.
    case fit
}
