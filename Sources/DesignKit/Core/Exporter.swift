//
//  Exporter.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  PNG, JPEG and PDF. PNG and JPEG carry no metadata, so the same design
//  writes the same bytes. The PDF is drawn by the same painter as the
//  picture, so its words stay vector text; a print page gets its bleed, a
//  TrimBox and BleedBox, and crop marks in a slug round the bleed.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum OutputFormat: String, DesignChoice {
    case png
    case jpeg
    case pdf

    /// The format a file name asks for.
    public static func of(_ url: URL) -> OutputFormat? {
        switch url.pathExtension.lowercased() {
        case "png": .png
        case "jpg", "jpeg": .jpeg
        case "pdf": .pdf
        default: nil
        }
    }
}

public enum Exporter {

    /// The slug round a print page that holds the crop marks, millimetres.
    static let slugMM = 12.0

    /// Writes `rendered` as `format`.
    public static func write(_ rendered: Rendered, to url: URL, format: OutputFormat, quality: Double = 0.92) throws(DesignError) {
        let data: Data
        switch format {
        case .png: data = try encode(rendered.image, type: .png, quality: nil)
        case .jpeg: data = try encode(flattened(rendered.image), type: .jpeg, quality: quality)
        case .pdf: data = try pdf(rendered)
        }
        do { try data.write(to: url, options: .atomic) } catch {
            throw .failed("could not write \(url.path): \(error.localizedDescription)")
        }
    }

    /// The picture at most `side` pixels on its longest side (a preview, a contact-sheet cell).
    public static func scaled(_ rendered: Rendered, longestSide side: Double) -> CGImage? {
        let geometry = rendered.prepared.geometry
        let scale = min(1, side / Double(max(geometry.pixelWidth, geometry.pixelHeight)))
        return DesignEngine.draw(rendered.prepared, plan: rendered.plan, scale: scale)
    }

    /// PNG bytes for a picture, no metadata.
    public static func png(_ image: CGImage) throws(DesignError) -> Data { try encode(image, type: .png, quality: nil) }

    /// JPEG bytes for a picture (flattened on white), no metadata.
    public static func jpeg(_ image: CGImage, quality: Double = 0.92) throws(DesignError) -> Data {
        try encode(flattened(image), type: .jpeg, quality: quality)
    }

    /// PNG or JPEG bytes for `image`, no metadata.
    public static func encode(_ image: CGImage, type: UTType, quality: Double?) throws(DesignError) -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            throw .failed("could not make a \(type.preferredFilenameExtension ?? "picture") encoder")
        }
        var options: [CFString: Any] = [:]
        if let quality { options[kCGImageDestinationLossyCompressionQuality] = quality }
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw .failed("could not encode the picture") }
        return data as Data
    }

    /// `image` over white, for formats with no transparency.
    static func flattened(_ image: CGImage) -> CGImage {
        Bitmaps.image(width: image.width, height: image.height) { context in
            context.setFillColor(DesignColor.white.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        } ?? image
    }

    // MARK: PDF

    /// The page as a PDF: points at the page's dpi (72 per pixel's inch for a screen page).
    static func pdf(_ rendered: Rendered) throws(DesignError) -> Data {
        let prepared = rendered.prepared
        let geometry = prepared.geometry
        let canvas = prepared.design.canvas
        let points = 72 / (geometry.dpi ?? 72)
        let marks = canvas.cropMarks
        let slug = marks ? slugMM / Canvases.millimetresPerInch * 72 : 0
        let bleedBox = CGRect(x: slug, y: slug, width: Double(geometry.pixelWidth) * points, height: Double(geometry.pixelHeight) * points)
        let bleed = Double(canvas.bleed) * points
        let trimBox = bleedBox.insetBy(dx: bleed, dy: bleed)
        var media = CGRect(x: 0, y: 0, width: bleedBox.width + 2 * slug, height: bleedBox.height + 2 * slug)

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &media, nil) else { throw .failed("could not start a PDF") }
        func box(_ rect: CGRect) -> CFData {
            var value = rect
            return Data(bytes: &value, count: MemoryLayout<CGRect>.size) as CFData
        }
        let info: [CFString: Any] = [kCGPDFContextMediaBox: box(media), kCGPDFContextTrimBox: box(trimBox),
                                     kCGPDFContextBleedBox: box(bleedBox), kCGPDFContextCropBox: box(media)]
        context.beginPDFPage(info as CFDictionary)
        context.saveGState()
        context.translateBy(x: slug, y: slug)
        context.scaleBy(x: points, y: points)
        context.clip(to: CGRect(x: 0, y: 0, width: geometry.pixelWidth, height: geometry.pixelHeight))
        Painter.draw(prepared, plan: rendered.plan, in: context, deviceScale: points)
        context.restoreGState()
        if marks { cropMarks(trim: trimBox, bleed: bleed, in: context) }
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    /// Hairline marks at each corner of the trim, clear of the bleed.
    static func cropMarks(trim: CGRect, bleed: Double, in context: CGContext) {
        let gap = bleed + 1 / Canvases.millimetresPerInch * 72
        let length = 6 / Canvases.millimetresPerInch * 72
        context.setStrokeColor(DesignColor.black.cgColor)
        context.setLineWidth(0.25)
        for x in [trim.minX, trim.maxX] {
            for y in [trim.minY, trim.maxY] {
                let dx: Double = x == trim.minX ? -1 : 1, dy: Double = y == trim.minY ? -1 : 1
                context.move(to: CGPoint(x: x + dx * gap, y: y))
                context.addLine(to: CGPoint(x: x + dx * (gap + length), y: y))
                context.move(to: CGPoint(x: x, y: y + dy * gap))
                context.addLine(to: CGPoint(x: x, y: y + dy * (gap + length)))
            }
        }
        context.strokePath()
    }
}
