//
//  QRLevel.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// QR error correction.
public enum QRLevel: String, DesignChoice {
    /// About 7% of the code can be lost and it still reads.
    case low
    /// About 15%.
    case medium
    /// About 25%.
    case quartile
    /// About 30%.
    case high
}
