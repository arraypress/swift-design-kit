//
//  Support.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Small designs, stand-in services, and pixel probes.
//

import CoreGraphics
import Foundation
import Legibility
@testable import DesignKit

/// A made-picture service that draws a known picture: a vertical blend whose
/// colours follow the seed, so seeds can be told apart without a model.
struct FakeGenerator: ImageGenerating {
    func pinned(_ fill: AIFill, width: Int, height: Int) throws(DesignError) -> AIFill {
        var fill = fill
        fill.model = fill.model ?? "fake"
        fill.revision = "test"
        fill.aspect = fill.aspect ?? "1:1"
        fill.seed = fill.seed ?? 7
        return fill
    }

    func image(for fill: AIFill) async throws(DesignError) -> CGImage {
        let seed = Double(fill.seed ?? 0)
        return Bitmaps.image(width: 256, height: 256) { context in
            Shapes.linear([DesignColor(hex: ColorParsing.hex(red: (seed * 37).truncatingRemainder(dividingBy: 255) / 255, green: 0.2, blue: 0.4)),
                           DesignColor(hex: "#101010")], angle: 180, in: CGRect(x: 0, y: 0, width: 256, height: 256), context: context)
        }!
    }
}

/// Doubles a picture's size by repeating pixels — enough to prove the path.
struct FakeUpscaler: ImageUpscaling {
    let factor = 4
    func upscale(_ image: CGImage) async throws(DesignError) -> CGImage {
        Bitmaps.image(width: image.width * 4, height: image.height * 4) { context in
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width * 4, height: image.height * 4))
        }!
    }
}

enum Probe {

    static let folder: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("design-kit-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static let services = DesignServices(generator: FakeGenerator(), upscaler: FakeUpscaler(), folder: folder)

    /// A design from JSON.
    static func design(_ json: String) throws -> Design { try Recipes.decoded(Data(json.utf8)) }

    /// A design on a small custom square with these layers (a JSON array's insides).
    static func square(_ layers: String, size: Int = 400, vars: String = "{}") throws -> Design {
        try design(##"{"design": 1, "canvas": {"width": \##(size), "height": \##(size), "safe": 0.05}, "vars": \##(vars), "layers": [\##(layers)]}"##)
    }

    static func render(_ design: Design) async throws -> Rendered {
        try await DesignEngine.render(design, services: services)
    }

    /// The RGBA of a pixel (top-left origin).
    static func pixel(_ image: CGImage, _ x: Int, _ y: Int) -> [UInt8] {
        let bytes = Pixels.rgba(of: image)!
        let offset = (y * image.width + x) * 4
        return Array(bytes[offset..<offset + 4])
    }

    /// A picture file of one colour (with an optional square of another), written to the test folder.
    static func pictureFile(_ name: String, width: Int, height: Int, color: String, square: (String, CGRect)? = nil) throws -> String {
        let image = Bitmaps.image(width: width, height: height) { context in
            context.setFillColor(DesignColor(color)!.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            if let square {
                context.setFillColor(DesignColor(square.0)!.cgColor)
                context.fill(square.1)
            }
        }!
        let url = folder.appendingPathComponent(name)
        try Exporter.png(image).write(to: url)
        return url.path
    }
}
