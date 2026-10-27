//
//  Area.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The rectangle a frame is placed in.
public enum Area: String, DesignChoice {
    /// Inside the safe insets — where words belong. The default.
    case safe
    /// The finished size: for print, the page after trimming.
    case trim
    /// Everything, out to the bleed — where a background belongs.
    case bleed
}
