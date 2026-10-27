//
//  MotionKind.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How an animated cover's art moves.
public enum MotionKind: String, DesignChoice {
    /// A slow push in and back out.
    case zoom
    /// A slow figure-of-eight drift.
    case drift
    /// 2.5D in rigid layers: the subject cut out whole and moving most, the
    /// background behind it filled and split by depth into 2–3 planes that
    /// move less the further they are.
    case parallax
}
