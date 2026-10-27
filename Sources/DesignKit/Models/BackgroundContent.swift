//
//  BackgroundContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The picture behind everything: a fill, and the treatments that make words
/// read over it.
public struct BackgroundContent: Equatable, Sendable {
    /// What it is made of: a colour, a blend, a gradient, a picture, or one made from words.
    public var fill: Fill
    /// How a picture fill meets the frame.
    public var fit: FitMode
    /// Blur, in design units.
    public var blur: Double
    /// A flat black wash, `0…1`.
    public var darken: Double
    /// A wash that darkens it toward an edge so words read.
    public var scrim: Scrim?
    /// A look — the `grade` section img and vid write — or a path to one.
    public var grade: LookReference?
    /// Two colours the picture's tones are mapped between, dark then light.
    public var duotone: [DesignColor]?
    /// Colours the picture's tones are mapped through, darkest first (two or more).
    public var gradientMap: [DesignColor]?
    /// Film grain, `0…1`.
    public var grain: Double
    /// Darkened corners, `0…1`.
    public var vignette: Double
    /// Enlarge a picture smaller than its frame on this machine (SwinIR ×4)
    /// before drawing it. `nil` means yes for a made or edited picture and on
    /// a print page, no for a file on screen.
    public var upscale: Bool?
    /// The picture changed in place by words, on this machine.
    public var edit: AIEdit?
    /// The upscaler that enlarged it (`swinir@<revision>`), written when made.
    public var upscaledWith: String?
    /// `[page, pages]`: one background drawn across a carousel's pages, this page taking slice `page` (from 0).
    public var span: [Int]?

    /// A background of `fill`, untreated unless told.
    public init(fill: Fill, fit: FitMode = .fill, blur: Double = 0, darken: Double = 0, scrim: Scrim? = nil,
                grade: LookReference? = nil, duotone: [DesignColor]? = nil, gradientMap: [DesignColor]? = nil,
                grain: Double = 0, vignette: Double = 0, upscale: Bool? = nil, edit: AIEdit? = nil, upscaledWith: String? = nil) {
        self.fill = fill
        self.fit = fit
        self.blur = blur
        self.darken = darken
        self.scrim = scrim
        self.grade = grade
        self.duotone = duotone
        self.gradientMap = gradientMap
        self.grain = grain
        self.vignette = vignette
        self.upscale = upscale
        self.edit = edit
        self.upscaledWith = upscaledWith
        self.span = nil
    }
}
