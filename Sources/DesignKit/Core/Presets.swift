//
//  Presets.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The page sizes people actually make covers, posts and posters at. Safe
//  insets keep words clear of what each place draws over or crops away;
//  print pages are 300 dpi with 3 mm bleed and a 5 mm safe margin inside
//  the trim. Sizes come from each destination's published requirements.
//

import Foundation

public enum Presets {

    /// Every preset, screen first then print.
    public static let all: [Preset] = screen + print

    /// The preset called `name` (case ignored).
    public static func named(_ name: String) -> Preset? {
        all.first { $0.name == name.lowercased() }
    }

    static let screen: [Preset] = [
        Preset(name: "cover", summary: "Album, EP or single cover — 3000×3000, what the music stores ask for",
               width: 3000, height: 3000, safe: Insets(uniform: 0.06),
               rules: PlatformRules(minimumWidth: 3000, minimumHeight: 3000, square: true)),
        Preset(name: "streaming-safe", summary: "Square cover with wide margins, so words survive round corners, circle crops and tiny thumbnails",
               width: 3000, height: 3000, safe: Insets(uniform: 0.12),
               rules: PlatformRules(minimumWidth: 3000, minimumHeight: 3000, square: true)),
        Preset(name: "podcast-cover", summary: "Podcast show art — square, 1400 to 3000 pixels",
               width: 3000, height: 3000, safe: Insets(uniform: 0.08),
               rules: PlatformRules(minimumWidth: 1400, minimumHeight: 1400, maximumWidth: 3000, maximumHeight: 3000, square: true)),
        Preset(name: "ig-post", summary: "Square feed post, 1080×1080",
               width: 1080, height: 1080, safe: Insets(uniform: 0.06)),
        Preset(name: "ig-portrait", summary: "Portrait feed post, 4:5, 1080×1350",
               width: 1080, height: 1350, safe: Insets(uniform: 0.06)),
        Preset(name: "story", summary: "Story or reel, 9:16, 1080×1920 — clear of the header and reply bar",
               width: 1080, height: 1920, safe: Insets(top: 0.13, bottom: 0.18, left: 0.06, right: 0.06)),
        Preset(name: "youtube-thumbnail", summary: "Video thumbnail, 16:9, 1280×720 — clear of the duration badge",
               width: 1280, height: 720, safe: Insets(top: 0.06, bottom: 0.12, left: 0.05, right: 0.05),
               rules: PlatformRules(minimumWidth: 640, minimumHeight: 360)),
        Preset(name: "x-header", summary: "Profile header, 3:1, 1500×500 — clear of the profile picture and the crop on phones",
               width: 1500, height: 500, safe: Insets(top: 0.2, bottom: 0.2, left: 0.25, right: 0.06)),
    ]

    static let print: [Preset] = [
        Canvases.printPreset("a3", "A3 poster (297×420 mm)", 297, 420),
        Canvases.printPreset("a4", "A4 poster or flyer (210×297 mm)", 210, 297),
        Canvases.printPreset("a5", "A5 flyer (148×210 mm)", 148, 210),
        Canvases.printPreset("letter", "US Letter poster or flyer (8.5×11 in)", 215.9, 279.4),
        Canvases.printPreset("flyer-4x6", "4×6 in flyer or postcard", 101.6, 152.4),
        Canvases.printPreset("flyer-5x7", "5×7 in flyer", 127, 177.8),
        Canvases.printPreset("ticket", "Event ticket, 5.5×2 in", 139.7, 50.8),
    ]
}
