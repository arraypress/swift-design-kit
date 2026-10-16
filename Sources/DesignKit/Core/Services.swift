//
//  Services.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What a design needs from outside the engine: pictures made from words
//  and enlargement, both on this machine. The engine only asks; the AI
//  product (DesignKitAI) answers with FLUX.2 Klein, SANA Sprint and SwinIR.
//  A design without made pictures needs neither.
//

import CoreGraphics
import Foundation

/// Makes a background from words.
public protocol ImageGenerating: Sendable {

    /// `fill` with everything a replay needs pinned — model, its revision,
    /// the shape drawn (from what is installed, nearest `width`×`height`) and
    /// a seed when it has none. Nothing is drawn.
    func pinned(_ fill: AIFill, width: Int, height: Int) throws(DesignError) -> AIFill

    /// The picture for a pinned fill. The same pin draws the same picture.
    func image(for fill: AIFill) async throws(DesignError) -> CGImage
}

/// Enlarges a picture.
public protocol ImageUpscaling: Sendable {

    /// How many times larger each side comes back.
    var factor: Int { get }

    /// `image`, `factor` times larger.
    func upscale(_ image: CGImage) async throws(DesignError) -> CGImage
}

/// What a render may call on.
public struct DesignServices: Sendable {

    /// Pictures from words; `nil` refuses an `ai` background.
    public var generator: (any ImageGenerating)?

    /// Enlargement; `nil` leaves a small picture small (and the check says so).
    public var upscaler: (any ImageUpscaling)?

    /// Fetches open fonts on first use; `nil` refuses an open font not already fetched.
    public var fonts: (any FontFetching)?

    /// Where relative paths in the design (pictures, fonts, looks) are found.
    public var folder: URL

    /// Called with a short line as slow work starts (a model loading, a picture drawing).
    public var progress: (@Sendable (String) -> Void)?

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
