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

    /// `edit` with model, revision, shape and seed pinned for a picture `width`×`height`.
    func pinned(_ edit: AIEdit, width: Int, height: Int) throws(DesignError) -> AIEdit

    /// `image` changed by a pinned edit. The same pin and picture draw the same result.
    func edited(_ image: CGImage, edit: AIEdit) async throws(DesignError) -> CGImage
}

public extension ImageGenerating {
    func pinned(_ edit: AIEdit, width: Int, height: Int) throws(DesignError) -> AIEdit {
        throw .modelMissing("this image model cannot edit pictures")
    }

    func edited(_ image: CGImage, edit: AIEdit) async throws(DesignError) -> CGImage {
        throw .modelMissing("this image model cannot edit pictures")
    }
}

/// Enlarges a picture.
public protocol ImageUpscaling: Sendable {

    /// How many times larger each side comes back.
    var factor: Int { get }

    /// The model and its pinned revision (`swinir@5f65a34…`), recorded in a recipe when it enlarges a picture.
    var pin: String { get }

    /// `image`, `factor` times larger.
    func upscale(_ image: CGImage) async throws(DesignError) -> CGImage
}

/// Finds how near each part of a picture is.
public protocol DepthEstimating: Sendable {
    /// The model and its revision, as a recipe records them.
    var pin: String { get }
    /// Relative nearness for every pixel of `image`, `0…1` (1 nearest), row by row from the top.
    func nearness(of image: CGImage) async throws(DesignError) -> [Float]
}

/// Fills in part of a picture.
public protocol Inpainting: Sendable {
    var pin: String { get }
    /// `image` with what `mask` marks (white) filled from its surroundings.
    func filled(_ image: CGImage, mask: CGImage) async throws(DesignError) -> CGImage
}

/// Lifts the main subject out of a picture.
public protocol SubjectMatting: Sendable {
    /// The model and its revision, as a recipe records them.
    var pin: String { get }
    /// The main subject of `image`, cut out at `image`'s own size (clear
    /// everywhere else, premultiplied), or `nil` when there is none.
    func subject(of image: CGImage) async throws(DesignError) -> CGImage?
}

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
