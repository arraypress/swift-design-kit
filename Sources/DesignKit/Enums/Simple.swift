//
//  Simple.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The small word lists a design is written with.
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

/// How a picture meets its frame.
public enum FitMode: String, DesignChoice {
    /// Cover the frame, cropping what overhangs (around `focus`).
    case fill
    /// Show all of it, inside the frame.
    case fit
}

/// How the words are cased when drawn.
public enum TextCase: String, DesignChoice {
    case none
    case upper
    case lower
    case title
}

/// Horizontal alignment of lines.
public enum TextAlign: String, DesignChoice {
    case left
    case center
    case right
}

/// Where the block of lines sits in its frame, top to bottom.
public enum VerticalAlign: String, DesignChoice {
    case top
    case middle
    case bottom
}

/// Whether text shrinks to fit its frame.
public enum TextFitMode: String, DesignChoice {
    /// Step the size down until it fits (height, `max_lines`, a single word on one line).
    case shrink
    /// Draw at the size given; overflow is reported by the checks.
    case none
}

/// A shape layer's outline.
public enum ShapeKind: String, DesignChoice {
    case rect
    case rounded
    case ellipse
    case line
    case polygon
    case star
}

/// The outline a picture is clipped to.
public enum MaskShape: String, DesignChoice {
    case rect
    case rounded
    case circle
    case polygon
}

/// What a text stroke does.
public enum StrokeStyle: String, DesignChoice {
    /// Filled letters with a keyline round them — the legibility treatment.
    case outline
    /// The outline only — the display treatment.
    case hollow
}

/// What a text layer keeps clear of.
public enum Avoid: String, DesignChoice {
    /// Faces found in what lies under the text.
    case faces
    /// Cut-out subjects (image layers with `cutout`).
    case subject
}

/// Which edge a background's scrim darkens from.
public enum ScrimEdge: String, DesignChoice {
    case bottom
    case top
    case both
    /// Measured: deep where the words sit over something bright, light where
    /// they already read, on the edge they are nearest.
    case auto
}

/// QR error correction.
public enum QRLevel: String, DesignChoice {
    case low
    case medium
    case quartile
    case high
}
