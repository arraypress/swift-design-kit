//
//  MachineUpscaler.swift
//  DesignKitAI
//
//  Created by David Sherlock on 2026.
//
//  ×4 enlargement on this machine with SwinIR-L (Apache-2.0), the model the
//  fleet's `upscale` and `imagine --upscale` install. A made background is
//  1024² and a cover is 3000²: this is what keeps it sharp.
//

import CoreGraphics
import CoreImage
import DesignKit
import Foundation
import Upscale

public actor MachineUpscaler: ImageUpscaling {

    public nonisolated let factor = 4

    /// SwinIR at the commit `upscale` installs it from.
    public nonisolated var pin: String { "\(UpscaleModel.swinir.rawValue)@\(UpscaleModel.swinir.revision)" }

    private let modelURL: URL
    private var runner: (any Upscaler)?

    /// The SwinIR model at `UPSCALE_MODEL`, or where `upscale` installs it.
    public init(modelURL: URL? = nil) {
        let environment = ProcessInfo.processInfo.environment["UPSCALE_MODEL"].map { URL(fileURLWithPath: $0) }
        self.modelURL = modelURL ?? environment ?? MachineImages.applicationSupport
            .appendingPathComponent("upscale", isDirectory: true).appendingPathComponent(UpscaleModel.swinir.path)
    }

    /// Whether the model is there.
    public nonisolated var isInstalled: Bool { FileManager.default.fileExists(atPath: modelURL.path) }

    public func upscale(_ image: CGImage) async throws(DesignError) -> CGImage {
        guard isInstalled else {
            throw .modelMissing("the SwinIR upscaler is not installed at \(modelURL.path) — `upscale` installs it on first use")
        }
        let upscaler: any Upscaler
        if let runner { upscaler = runner } else {
            do { upscaler = try await UpscaleModel.swinir.upscaler(at: modelURL) } catch {
                throw .failed("the upscaler could not be loaded: \(error)")
            }
            runner = upscaler
        }
        let output: CIImage?
        do { output = try await upscaler.upscale(CIImage(cgImage: image), isCancelled: nil, progress: nil) } catch {
            throw .failed("the picture could not be enlarged: \(error)")
        }
        let rect = CGRect(x: 0, y: 0, width: image.width * upscaler.scale, height: image.height * upscaler.scale)
        let context = CIContext(options: [.cacheIntermediates: false])
        guard let output, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let picture = context.createCGImage(output.cropped(to: rect), from: rect, format: .RGBA8, colorSpace: space) else {
            throw .failed("the upscaler returned nothing")
        }
        return picture
    }
}
