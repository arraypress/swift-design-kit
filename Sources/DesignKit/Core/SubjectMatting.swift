//
//  SubjectMatting.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// Lifts the main subject out of a picture.
public protocol SubjectMatting: Sendable {
    /// The model and its revision, as a recipe records them.
    var pin: String { get }
    /// The main subject of `image`, cut out at `image`'s own size (clear
    /// everywhere else, premultiplied), or `nil` when there is none.
    func subject(of image: CGImage) async throws(DesignError) -> CGImage?
}
