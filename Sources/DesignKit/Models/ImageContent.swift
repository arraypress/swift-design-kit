//
//  ImageContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import ObjectCutout

/// A picture: a file, or the subject lifted out of one.
public struct ImageContent: Equatable, Sendable {
    /// The picture file's path.
    public var source: String
    /// Lift the subject off its background first (the sticker look).
    public var cutout: Bool
    /// A cut-out's edge: `crisp` (the default — tight, no halo), `soft`, or `feather:N`.
    public var edge: CutoutEdge
    /// Pixels a cut-out's edge is pulled in.
    public var choke: Double
    /// How it meets its frame.
    public var fit: FitMode
    /// The point of the picture kept in view when `fill` crops, as fractions (`[0.5, 0.3]`).
    public var focus: [Double]?
    /// The outline it is clipped to.
    public var mask: Mask?
    /// An outline round the mask's shape, or a sticker edge round a cut-out.
    public var stroke: Stroke?
    /// Enlarge on this machine when smaller than drawn. `nil` means yes on a
    /// print page (up to print resolution), no on screen.
    public var upscale: Bool?
    /// The upscaler that enlarged it (`swinir@<revision>`), written when made.
    public var upscaledWith: String?

    /// A picture from `source`.
    public init(source: String, cutout: Bool = false, edge: CutoutEdge = .crisp, choke: Double = 0, fit: FitMode = .fill,
                focus: [Double]? = nil, mask: Mask? = nil, stroke: Stroke? = nil, upscale: Bool? = nil, upscaledWith: String? = nil) {
        self.source = source
        self.cutout = cutout
        self.edge = edge
        self.choke = choke
        self.fit = fit
        self.focus = focus
        self.mask = mask
        self.stroke = stroke
        self.upscale = upscale
        self.upscaledWith = upscaledWith
    }
}
