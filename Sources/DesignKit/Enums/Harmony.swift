//
//  Harmony.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How the accent is found from the dominant colour, round the OKLCh wheel.
public enum Harmony: String, DesignChoice {
    /// The art's own most colourful colour far enough from the dominant;
    /// else complementary.
    case auto
    /// 30° away: calm, close.
    case analogous
    /// 180° away: the strongest contrast.
    case complementary
    /// 150° away: contrast with less clash.
    case split
    /// The dominant's own hue, lighter or darker: one colour.
    case mono
}
