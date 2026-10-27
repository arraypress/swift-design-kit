//
//  Preparation.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Everything a design takes from outside, fetched and made once: made
//  pictures pinned and drawn, gradients drawn, files read (and lifted, for a
//  cut-out), small pictures enlarged, looks read and inlined, plates treated,
//  fonts registered. Drawing afterwards needs none of it again.
//

import CanvasKit
import CoreGraphics
import CoreImage
import Foundation
import ObjectCutout
import QRKit
import RecipeKit
import VideoGrade
import VideoGradeLook

/// Everything a design takes from outside, fetched and made once before drawing.
public enum Preparation {

    /// Enlargement past this asks for an upscale (when one is allowed).
    public static let upscaleThreshold = 1.25

    /// `design` made ready to draw.
    public static func prepare(_ design: Design, services: DesignServices) async throws(DesignError) -> PreparedDesign {
        try Validation.check(design)
        let geometry = design.canvas.geometry
        var made = try pinned(design, services: services, geometry: geometry)

        var faces: [String: ResolvedFace] = [:]
        for entry in Layouter.entries(made.layers) {
            if case .text(let text) = entry.layer.content {
                faces[entry.path] = try await Fonts.face(for: text, typesetting: made.fonts, folder: services.folder,
                                                         fetcher: services.fonts)
            }
        }
        // Lists become lines once their frames are known; the lines' faces are resolved like any text.
        if Lists.any(made.layers) {
            let frames = Layouter.place(made, geometry: geometry, faces: faces).frames
            made.layers = try await Lists.expanded(made.layers, frames: frames, design: made, geometry: geometry, services: services)
            for entry in Layouter.entries(made.layers) where faces[entry.path] == nil {
                if case .text(let text) = entry.layer.content {
                    faces[entry.path] = try await Fonts.face(for: text, typesetting: made.fonts, folder: services.folder,
                                                             fetcher: services.fonts)
                }
            }
        }
        // Google faces pin the commit they came from.
        var fontCommitWas: String?
        if faces.values.contains(where: { $0.family.map(Fonts.isFetched) ?? false }) {
            if let was = made.googleFonts, was != OpenFonts.commit { fontCommitWas = was }
            made.googleFonts = OpenFonts.commit
        }
        let placed = Layouter.place(made, geometry: geometry, faces: faces)
        let textRegions = placed.fits.values.compactMap(\.linesBounds)

        var pictures: [String: PreparedPicture] = [:]
        var sources: [SourceNote] = []
        for entry in Layouter.entries(made.layers) {
            guard let frame = placed.frames[entry.path] else { continue }
            let width = max(1, Int(frame.width.rounded())), height = max(1, Int(frame.height.rounded()))
            switch entry.layer.content {
            case .background(let background):
                let (picture, note) = try await plate(background, width: width, height: height, entry: entry,
                                                      frame: frame, geometry: geometry, textRegions: textRegions,
                                                      services: services)
                pictures[entry.path] = picture
                if let note { sources.append(note) }
            case .image(let image):
                let (picture, note) = try await picture(image, width: frame.width, height: frame.height, entry: entry,
                                                        unit: geometry.unit, print: geometry.dpi != nil, services: services)
                pictures[entry.path] = picture
                sources.append(note)
            case .qr(let qr):
                pictures[entry.path] = PreparedPicture(image: try code(qr, vars: made.vars))
            case .texture(let texture):
                guard let image = Textures.render(texture, width: width, height: height, unit: geometry.unit) else {
                    throw .failed("a \(width)×\(height) \(texture.kind.rawValue) texture could not be made")
                }
                pictures[entry.path] = PreparedPicture(image: image)
            case .text, .shape, .group, .list:
                break
            }
        }
        // The upscaler that enlarged a picture is pinned on its layer; a replay enlarged by another says so.
        for index in sources.indices {
            guard let pin = sources[index].upscaledWith else { continue }
            let path = sources[index].layer
            made.layers = Layouter.updating(made.layers, at: path) { layer in
                switch layer.content {
                case .background(var background):
                    if let was = background.upscaledWith, was != pin { sources[index].upscaledWithWas = was }
                    background.upscaledWith = pin
                    layer.content = .background(background)
                case .image(var image):
                    if let was = image.upscaledWith, was != pin { sources[index].upscaledWithWas = was }
                    image.upscaledWith = pin
                    layer.content = .image(image)
                default:
                    break
                }
            }
        }
        return PreparedDesign(design: made, geometry: geometry, pictures: pictures, faces: faces, sources: sources,
                              fontCommitWas: fontCommitWas)
    }

    /// `image` changed by a pinned edit, or as it is when there is none.
    static func edited(_ image: CGImage, _ edit: AIEdit?, services: DesignServices) async throws(DesignError) -> CGImage {
        guard let edit else { return image }
        guard let generator = services.generator else {
            throw .modelMissing("this design edits its background with words, and no image model is available here")
        }
        services.progress?("editing the background: \"\(edit.prompt)\" (seed \(edit.seed.map(String.init) ?? "?"))")
        return try await generator.edited(image, edit: edit)
    }

    // MARK: Pinning

    /// The design with every made picture pinned and every look read in.
    static func pinned(_ design: Design, services: DesignServices, geometry: CanvasGeometry) throws(DesignError) -> Design {
        var design = design
        design.fonts = try Fonts.pinned(design.fonts, usesRoles: usesRoles(design.layers), fetcher: services.fonts)
        design.layers = try design.layers.map { layer throws(DesignError) in
            guard case .background(var background) = layer.content else { return layer }
            var layer = layer
            if case .ai(let fill) = background.fill {
                guard let generator = services.generator else {
                    throw .modelMissing("this design draws its background from words, and no image model is available here")
                }
                let frame = Layout.frame(layer.frame, in: geometry.rect(layer.frame.area ?? .bleed), grid: design.grid)
                background.fill = .ai(try generator.pinned(fill, width: Int(frame.width), height: Int(frame.height)))
            }
            if let edit = background.edit {
                guard let generator = services.generator else {
                    throw .modelMissing("this design edits its background with words, and no image model is available here")
                }
                let frame = Layout.frame(layer.frame, in: geometry.rect(layer.frame.area ?? .bleed), grid: design.grid)
                background.edit = try generator.pinned(edit, width: Int(frame.width), height: Int(frame.height))
            }
            if case .file(let path) = background.grade {
                let url = URL(fileURLWithPath: RecipePaths.usable(path, from: services.folder))
                do { background.grade = .look(try LookFile.read(url)) } catch {
                    throw .invalid("the look \(path): \((error as? RecipeError)?.message ?? error.localizedDescription)")
                }
            }
            layer.content = .background(background)
            return layer
        }
        return design
    }

    /// Whether any text layer names a role (`display`, `text`) or a named size.
    static func usesRoles(_ layers: [Layer]) -> Bool {
        Layouter.entries(layers).contains { entry in
            guard case .text(let text) = entry.layer.content else { return false }
            return text.step != nil || text.font.map { Fonts.roles.contains($0.lowercased()) } ?? false
        }
    }

    // MARK: Backgrounds

    static func plate(_ background: BackgroundContent, width pageWidth: Int, height: Int, entry: Layouter.Entry, frame: CGRect,
                      geometry: CanvasGeometry, textRegions: [CGRect],
                      services: DesignServices) async throws(DesignError) -> (PreparedPicture, SourceNote?) {
        // A background spanning several pages (a carousel) is drawn once across all of them; this page takes its slice.
        let span = background.span.flatMap { $0.count == 2 && $0[1] > 1 ? (index: $0[0], count: $0[1]) : nil }
        let width = pageWidth * (span?.count ?? 1)
        var note: SourceNote?
        var base: CGImage
        switch background.fill {
        case .color(let color):
            base = try solid(width: width, height: height) { $0.setFillColor(color.cgColor); $0.fill(CGRect(x: 0, y: 0, width: width, height: height)) }
        case .linear(let colors, let angle):
            base = try solid(width: width, height: height) { Shapes.linear(colors, angle: angle, in: CGRect(x: 0, y: 0, width: width, height: height), context: $0) }
        case .radial(let colors):
            base = try solid(width: width, height: height) { Shapes.radial(colors, in: CGRect(x: 0, y: 0, width: width, height: height), context: $0) }
        case .gradient(let spec):
            services.progress?("drawing gradient seed \(spec.seed)")
            base = try GradientFills.render(spec, width: width, height: height)
        case .image(let path):
            let source = try await edited(try load(path, folder: services.folder), background.edit, services: services)
            let (enlarged, upscaled, before) = try await enlarged(source, width: Double(width), height: Double(height),
                                                                  mode: background.fit,
                                                                  allowed: background.upscale ?? (background.edit != nil || geometry.dpi != nil),
                                                                  services: services)
            note = SourceNote(layer: entry.path, id: entry.layer.id, kind: background.edit == nil ? "file" : "edited", sourceWidth: source.width,
                              sourceHeight: source.height, enlargement: before,
                              enlargementAfter: Bitmaps.enlargement(of: enlarged, width: Double(width), height: Double(height), mode: background.fit),
                              upscaled: upscaled)
            guard let fitted = Bitmaps.fitted(enlarged, width: width, height: height, mode: background.fit,
                                              backdrop: DesignColor.black.cgColor) else { throw .failed("the background could not be drawn") }
            base = fitted
        case .ai(let fill):
            guard let generator = services.generator else { throw .modelMissing("no image model is available here") }
            services.progress?("drawing \"\(fill.prompt)\" (seed \(fill.seed.map(String.init) ?? "?"))")
            let made = try await edited(try await generator.image(for: fill), background.edit, services: services)
            let (enlarged, upscaled, before) = try await enlarged(made, width: Double(width), height: Double(height),
                                                                  mode: .fill, allowed: background.upscale ?? true,
                                                                  services: services)
            note = SourceNote(layer: entry.path, id: entry.layer.id, kind: "ai", sourceWidth: made.width,
                              sourceHeight: made.height, enlargement: before,
                              enlargementAfter: Bitmaps.enlargement(of: enlarged, width: Double(width), height: Double(height), mode: .fill),
                              upscaled: upscaled)
            guard let fitted = Bitmaps.fitted(enlarged, width: width, height: height, mode: .fill) else {
                throw .failed("the background could not be drawn")
            }
            base = fitted
        }
        // A drawn fill changed by words: the edit at the model's size, enlarged back to the frame.
        switch background.fill {
        case .color, .linear, .radial, .gradient:
            if let edit = background.edit {
                let changed = try await edited(base, edit, services: services)
                let (enlarged, upscaled, before) = try await enlarged(changed, width: Double(width), height: Double(height), mode: .fill,
                                                                      allowed: background.upscale ?? true, services: services)
                note = SourceNote(layer: entry.path, id: entry.layer.id, kind: "edited", sourceWidth: changed.width,
                                  sourceHeight: changed.height, enlargement: before,
                                  enlargementAfter: Bitmaps.enlargement(of: enlarged, width: Double(width), height: Double(height), mode: .fill),
                                  upscaled: upscaled)
                guard let fitted = Bitmaps.fitted(enlarged, width: width, height: height, mode: .fill) else {
                    throw .failed("the edited background could not be drawn")
                }
                base = fitted
            }
        case .image, .ai:
            break
        }
        if note?.upscaled == true { note?.upscaledWith = services.upscaler?.pin }
        if let span {
            guard let slice = base.cropping(to: CGRect(x: span.index * pageWidth, y: 0, width: pageWidth, height: height)) else {
                throw .failed("page \(span.index + 1)'s slice of the background could not be cut")
            }
            base = slice
        }
        // Text regions in the plate's own CoreGraphics space.
        let plateCG = Layout.flipped(frame, height: Double(geometry.pixelHeight))
        let regions = textRegions.map { $0.offsetBy(dx: -plateCG.minX, dy: -plateCG.minY) }
        var look: VideoGrade?
        if case .look(let reference)? = background.grade { look = reference.resolved }
        let treated = try PlateEffects.apply(background, to: base, look: look, unit: geometry.unit, textRegions: regions)
        return (PreparedPicture(image: treated), note)
    }

    static func solid(width: Int, height: Int, _ draw: (CGContext) -> Void) throws(DesignError) -> CGImage {
        guard let image = Bitmaps.image(width: width, height: height, draw) else { throw .failed("a \(width)×\(height) picture could not be made") }
        return image
    }

    // MARK: Pictures

    static func picture(_ content: ImageContent, width: Double, height: Double, entry: Layouter.Entry, unit: Double,
                        print: Bool = false, services: DesignServices) async throws(DesignError) -> (PreparedPicture, SourceNote) {
        var source = try load(content.source, folder: services.folder)
        var kind = "file"
        if content.cutout {
            services.progress?("lifting the subject out of \(content.source)")
            let original = source, name = content.source, edge = EdgeOptions(edge: content.edge, choke: content.choke)
            source = try await Offload.run { () throws(DesignError) -> CGImage in try lifted(original, name: name, edge: edge) }
            kind = "cutout"
        }
        let (image, upscaled, before) = try await enlarged(source, width: width, height: height, mode: content.fit,
                                                           allowed: content.upscale ?? print, services: services)
        var picture = PreparedPicture(image: image)
        if content.cutout, content.mask == nil, let stroke = content.stroke, stroke.width > 0 {
            let drawnScale = Bitmaps.enlargement(of: image, width: width, height: height, mode: content.fit)
            let pad = stroke.width * unit / max(drawnScale, 0.0001)
            picture.outline = Outlines.outline(of: image, radius: pad, color: stroke.color.fixed ?? .white)
            picture.pad = pad.rounded(.up)
        }
        var note = SourceNote(layer: entry.path, id: entry.layer.id, kind: kind, sourceWidth: source.width,
                              sourceHeight: source.height, enlargement: before,
                              enlargementAfter: Bitmaps.enlargement(of: image, width: width, height: height, mode: content.fit),
                              upscaled: upscaled)
        if upscaled { note.upscaledWith = services.upscaler?.pin }
        return (picture, note)
    }

    /// A picture file, relative to `folder`.
    static func load(_ path: String, folder: URL) throws(DesignError) -> CGImage {
        let full = RecipePaths.usable(path, from: folder)
        guard FileManager.default.fileExists(atPath: full) else { throw .missing("no picture at \(full)") }
        guard let image = SlideRenderer.loadImage(at: full) else { throw .invalid("\(path) is not a picture this machine can read") }
        return image
    }

    /// The subject lifted off its background, cropped to it.
    static func lifted(_ image: CGImage, name: String, edge: EdgeOptions = .crisp) throws(DesignError) -> CGImage {
        let input = CIImage(cgImage: image)
        let result: (image: CIImage, bounds: CGRect)?
        do {
            result = try Matte.cutout(from: input, mode: .subject, edge: edge).map { ($0.image, $0.bounds) }
        } catch {
            throw .failed("the subject could not be lifted out of \(name): \(error.localizedDescription)")
        }
        guard let result, result.bounds.width >= 2, result.bounds.height >= 2,
              let lifted = Bitmaps.render(result.image, extent: result.bounds.integral) else {
            throw .failed("no subject was found in \(name) to lift out")
        }
        return lifted
    }

    /// `image` enlarged on this machine when it would be drawn more than
    /// ``upscaleThreshold`` times its size and that is allowed.
    static func enlarged(_ image: CGImage, width: Double, height: Double, mode: FitMode, allowed: Bool,
                         services: DesignServices) async throws(DesignError) -> (CGImage, Bool, Double) {
        let before = Bitmaps.enlargement(of: image, width: width, height: height, mode: mode)
        guard allowed, before > upscaleThreshold, let upscaler = services.upscaler else { return (image, false, before) }
        services.progress?("enlarging a \(image.width)×\(image.height) picture ×\(upscaler.factor)")
        return (try await upscaler.upscale(image), true, before)
    }

    // MARK: QR

    static func code(_ qr: QRContent, vars: [String: String]) throws(DesignError) -> CGImage {
        let level: QRCorrectionLevel = switch qr.level {
        case .low: .low
        case .medium: .medium
        case .quartile: .quartile
        case .high: .high
        }
        func color(_ c: DesignColor) -> QRColor {
            let parts = c.components
            return QRColor(red: parts.red, green: parts.green, blue: parts.blue, alpha: parts.alpha)
        }
        do {
            return try QRGenerator.image(for: .text(Words.filled(qr.text, vars: vars)), size: 1024, level: level,
                                         foreground: color(qr.color), background: color(qr.background))
        } catch {
            throw .invalid("the QR code could not be made: \(error.localizedDescription) (too much text for one code?)")
        }
    }
}
