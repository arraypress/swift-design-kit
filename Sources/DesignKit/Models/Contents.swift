//
//  Contents.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What each kind of layer draws. Sizes are design units (a thousandth of
//  the canvas's shorter side); positions inside a frame are fractions.
//

import Foundation
import ObjectCutout
import VideoGradeLook

/// The picture behind everything: a fill, and the treatments that make words
/// read over it.
public struct BackgroundContent: Equatable, Sendable {
    public var fill: Fill
    /// How a picture fill meets the frame.
    public var fit: FitMode
    /// Blur, in design units.
    public var blur: Double
    /// A flat black wash, `0…1`.
    public var darken: Double
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
    /// before drawing it. `nil` means yes for a made picture, no for a file.
    public var upscale: Bool?

    public init(fill: Fill, fit: FitMode = .fill, blur: Double = 0, darken: Double = 0, scrim: Scrim? = nil,
                grade: LookReference? = nil, duotone: [DesignColor]? = nil, gradientMap: [DesignColor]? = nil,
                grain: Double = 0, vignette: Double = 0, upscale: Bool? = nil) {
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
    }
}

/// A look: inline (as a recipe holds it) or a file to read when the design is made.
public enum LookReference: Equatable, Sendable {
    case file(String)
    case look(GradeLook)
}

/// Words.
public struct TextContent: Equatable, Sendable {
    /// The words. `{slot}` markers are filled from the design's vars;
    /// `**accent**`, `*italic*` and `~muted~` style spans.
    public var text: String
    /// A role (`display`, `text`: the design's pairing says which face), a
    /// family installed on this Mac, a bundled face (`inter`, `source-serif`,
    /// `jetbrains-mono`), an open font (fetched on first use), or a path to a
    /// `.ttf` / `.otf`. `nil` is the system face.
    public var font: String?
    /// `thin` … `black`; `nil` is the role's weight, or bold.
    public var weight: String?
    /// Size, in design units.
    public var size: Double
    /// A named size on the design's type scale (`title`, `body`…), used instead of `size`.
    public var step: SizeStep?
    /// The smallest `fit: shrink` goes, in design units.
    public var minSize: Double?
    public var maxLines: Int?
    public var fit: TextFitMode
    /// Letter spacing, in thousandths of the size.
    public var tracking: Double
    /// A multiple of the natural line height.
    public var lineHeight: Double
    public var textCase: TextCase
    public var align: TextAlign
    public var valign: VerticalAlign
    public var color: Paint
    /// The colour `**accent**` spans take.
    public var accent: Paint?
    /// The colour `~muted~` spans take.
    public var muted: Paint?
    /// Letters filled with a blend, top to bottom.
    public var gradient: [DesignColor]?
    public var stroke: Stroke?
    public var plate: Plate?
    /// What the words keep clear of, moving to another anchor when they would cover it.
    public var avoid: [Avoid]

    public init(text: String, font: String? = nil, weight: String? = nil, size: Double = 80, step: SizeStep? = nil,
                minSize: Double? = nil, maxLines: Int? = nil, fit: TextFitMode = .shrink, tracking: Double = 0,
                lineHeight: Double = 1, textCase: TextCase = .none, align: TextAlign = .center,
                valign: VerticalAlign = .middle, color: Paint = .color(.white), accent: Paint? = nil,
                muted: Paint? = nil, gradient: [DesignColor]? = nil, stroke: Stroke? = nil,
                plate: Plate? = nil, avoid: [Avoid] = []) {
        self.text = text
        self.font = font
        self.weight = weight
        self.size = size
        self.step = step
        self.minSize = minSize
        self.maxLines = maxLines
        self.fit = fit
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.textCase = textCase
        self.align = align
        self.valign = valign
        self.color = color
        self.accent = accent
        self.muted = muted
        self.gradient = gradient
        self.stroke = stroke
        self.plate = plate
        self.avoid = avoid
    }
}

/// A picture: a file, or the subject lifted out of one.
public struct ImageContent: Equatable, Sendable {
    public var source: String
    /// Lift the subject off its background first (the sticker look).
    public var cutout: Bool
    /// A cut-out's edge: `crisp` (the default — tight, no halo), `soft`, or `feather:N`.
    public var edge: CutoutEdge
    /// Pixels a cut-out's edge is pulled in.
    public var choke: Double
    public var fit: FitMode
    /// The point of the picture kept in view when `fill` crops, as fractions (`[0.5, 0.3]`).
    public var focus: [Double]?
    public var mask: Mask?
    public var stroke: Stroke?
    /// Enlarge on this machine when smaller than drawn. `nil` means no.
    public var upscale: Bool?

    public init(source: String, cutout: Bool = false, edge: CutoutEdge = .crisp, choke: Double = 0, fit: FitMode = .fill,
                focus: [Double]? = nil, mask: Mask? = nil, stroke: Stroke? = nil, upscale: Bool? = nil) {
        self.source = source
        self.cutout = cutout
        self.edge = edge
        self.choke = choke
        self.fit = fit
        self.focus = focus
        self.mask = mask
        self.stroke = stroke
        self.upscale = upscale
    }
}

/// The outline a picture is clipped to.
public struct Mask: Equatable, Sendable {
    public var shape: MaskShape
    /// Corner radius for `rounded`, in design units.
    public var radius: Double
    /// Corners for `polygon`, as fractions of the frame (`[[0.5, 0], [1, 1], [0, 1]]`).
    public var points: [[Double]]?

    public init(shape: MaskShape, radius: Double = 40, points: [[Double]]? = nil) {
        self.shape = shape
        self.radius = radius
        self.points = points
    }
}

/// A drawn shape.
public struct ShapeContent: Equatable, Sendable {
    public var shape: ShapeKind
    public var fill: Paint?
    /// A blend instead of a flat fill.
    public var gradient: [DesignColor]?
    /// The blend's angle, degrees, 0 up, clockwise.
    public var angle: Double
    public var stroke: Stroke?
    /// Corner radius for `rounded`, in design units.
    public var radius: Double
    /// Corners for `polygon` and the ends of a `line`, as fractions of the frame.
    public var points: [[Double]]?
    /// A star's, burst's or badge's points; a film strip's holes along each edge.
    public var count: Int
    /// A star's or ring's inner radius, as a fraction of the outer.
    public var inner: Double
    /// How far a frame sits inside its box, in design units.
    public var inset: Double
    /// The space between a double frame's two lines, in design units.
    public var gap: Double
    /// A corner bracket's arm, or an arrow's head, as a fraction of the box's shorter side.
    public var length: Double

    public init(shape: ShapeKind, fill: Paint? = nil, gradient: [DesignColor]? = nil, angle: Double = 180,
                stroke: Stroke? = nil, radius: Double = 40, points: [[Double]]? = nil, count: Int = 5,
                inner: Double = 0.45, inset: Double = 0, gap: Double = 12, length: Double = 0.18) {
        self.shape = shape
        self.fill = fill
        self.gradient = gradient
        self.angle = angle
        self.stroke = stroke
        self.radius = radius
        self.points = points
        self.count = count
        self.inner = inner
        self.inset = inset
        self.gap = gap
        self.length = length
    }
}

/// A QR code — a link or text — for a flyer.
public struct QRContent: Equatable, Sendable {
    public var text: String
    public var color: DesignColor
    public var background: DesignColor
    public var level: QRLevel

    public init(text: String, color: DesignColor = .black, background: DesignColor = .white, level: QRLevel = .medium) {
        self.text = text
        self.color = color
        self.background = background
        self.level = level
    }
}

/// A texture drawn over what is under it — usually blended (`multiply`,
/// `overlay`, `screen`) at a low opacity. The same seed draws the same grain.
public struct TextureContent: Equatable, Sendable {
    public var kind: TextureKind
    /// The ink.
    public var color: DesignColor
    /// The size of its marks (dots, lines, specks), in design units.
    public var scale: Double
    /// How much of it there is, `0…1`.
    public var density: Double
    /// Halftone dots grow toward this direction, scanlines run along it (degrees, 0 up).
    public var angle: Double
    public var seed: UInt64

    public init(kind: TextureKind, color: DesignColor = .black, scale: Double? = nil, density: Double = 0.5,
                angle: Double = 180, seed: UInt64 = 1) {
        self.kind = kind
        self.color = color
        self.scale = scale ?? kind.defaultScale
        self.density = density
        self.angle = angle
        self.seed = seed
    }
}

/// Fades a layer out toward one edge (or out from its centre).
public struct Fade: Equatable, Sendable {
    /// Where it fades to.
    public var edge: FadeEdge
    /// Fully there up to this far across the frame toward the edge (`0…1`)…
    public var start: Double
    /// …and gone by here.
    public var end: Double

    public init(edge: FadeEdge = .bottom, start: Double = 0.5, end: Double = 1) {
        self.edge = edge
        self.start = start
        self.end = end
    }
}
