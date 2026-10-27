//
//  ImageGenerating.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
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
    /// Refuses: a generator that cannot edit pictures says so.
    func pinned(_ edit: AIEdit, width: Int, height: Int) throws(DesignError) -> AIEdit {
        throw .modelMissing("this image model cannot edit pictures")
    }

    /// Refuses: a generator that cannot edit pictures says so.
    func edited(_ image: CGImage, edit: AIEdit) async throws(DesignError) -> CGImage {
        throw .modelMissing("this image model cannot edit pictures")
    }
}
