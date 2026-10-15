//
//  CanvasSpec+Geometry.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

public extension CanvasSpec {

    /// The page laid out in pixels.
    var geometry: CanvasGeometry { Canvases.geometry(self) }

    /// The page a preset makes.
    init(preset: Preset) { self = Canvases.spec(for: preset) }

    /// The rules of the place this page is for (none for a custom size).
    var rules: PlatformRules { preset.flatMap(Presets.named)?.rules ?? PlatformRules() }
}
