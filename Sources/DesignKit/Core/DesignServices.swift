//
//  DesignServices.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// What a render may call on.
public struct DesignServices: Sendable {

    /// Pictures from words; `nil` refuses an `ai` background.
    public var generator: (any ImageGenerating)?

    /// Enlargement; `nil` leaves a small picture small (and the check says so).
    public var upscaler: (any ImageUpscaling)?

    /// Fetches open fonts on first use; `nil` refuses an open font not already fetched.
    public var fonts: (any FontFetching)?

    /// Depth, for a parallax motion; `nil` refuses one.
    public var depth: (any DepthEstimating)?

    /// The fill behind a parallax's subject; `nil` refuses a parallax.
    public var inpainter: (any Inpainting)?

    /// The subject a parallax moves as one rigid layer; `nil` moves the background planes alone.
    public var subject: (any SubjectMatting)?

    /// Where relative paths in the design (pictures, fonts, looks) are found.
    public var folder: URL

    /// Called with a short line as slow work starts (a model loading, a picture drawing).
    public var progress: (@Sendable (String) -> Void)?

    /// The services a render may use; any left out refuses the work that needs it.
    public init(generator: (any ImageGenerating)? = nil, upscaler: (any ImageUpscaling)? = nil,
                fonts: (any FontFetching)? = nil,
                folder: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                progress: (@Sendable (String) -> Void)? = nil) {
        self.generator = generator
        self.upscaler = upscaler
        self.fonts = fonts
        self.folder = folder
        self.progress = progress
    }
}
