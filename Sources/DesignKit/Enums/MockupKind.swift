//
//  MockupKind.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a design is shown as.
public enum MockupKind: String, DesignChoice {
    /// A square record sleeve, the disc half out.
    case vinyl
    /// A CD in its jewel case.
    case cd
    /// A phone showing the design full screen.
    case phone
    /// A poster pasted on a plaster wall, turned a little in perspective.
    case poster
}
