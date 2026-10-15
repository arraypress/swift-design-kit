//
//  MachineImages.swift
//  DesignKitAI
//
//  Created by David Sherlock on 2026.
//
//  Backgrounds drawn from words on this machine: FLUX.2 Klein 4B (default)
//  or SANA Sprint 1.6B, the Core AI exports `imagine` installs, through
//  swift-image-generation. A design pins the model, the commit `imagine`
//  fetched it at, the shape drawn and the seed, so a replay draws the same
//  picture; the same pin is also a cache key, so a replay does not draw it
//  twice. Nothing is downloaded here: a model that is not installed is
//  refused with the `imagine` command that installs it.
//
//  Core AI compiles a model per program name the first time that program
//  loads it, so `design`'s first made background takes a few minutes and
//  leaves a compiled copy beside `imagine`'s (~/Library/Caches/coreai-cache).
//

import CoreGraphics
import CryptoKit
import DesignKit
import Foundation
import ImageGeneration
import ImageIO

public actor MachineImages: ImageGenerating {

    /// The commit each model's export is pinned to — the ones `imagine` fetches.
    public static let revisions: [GenerationModel: String] = [
        .flux2Klein4B: "726bf543fd2db64d35f080b1997592bb53ef17cd",
        .sanaSprint16B: "c47fa2507ae3a30a420d8ae72df8418961b0b056",
        .flux2Klein9B: "85a8562f245cdd4c27d83472fd14370406beec5f",
    ]

    /// The model used when a design names none.
    public static let defaultModel = GenerationModel.flux2Klein4B

    private let support: URL
    private let cache: URL?
    private var loaded: [String: ImageGenerator] = [:]

    /// - Parameters:
    ///   - support: Where `imagine` installs models (Application Support).
    ///   - cache: Where drawn backgrounds are kept by their pin; `nil` keeps none.
    public init(support: URL = MachineImages.applicationSupport, cache: URL? = MachineImages.defaultCache) {
        self.support = support
        self.cache = cache
    }

    public static var applicationSupport: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    public static var defaultCache: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("design/backgrounds")
    }

    // MARK: Pinning

    public nonisolated func pinned(_ fill: AIFill, width: Int, height: Int) throws(DesignError) -> AIFill {
        var fill = fill
        let model = try Self.model(fill.model)
        let installed = Self.installedAspects(model, support: support)
        guard !installed.isEmpty else {
            throw .modelMissing("\(model.rawValue) is not installed — `imagine model download\(Self.flag(model))` installs it")
        }
        if let wanted = fill.aspect {
            guard let aspect = ImageAspect(rawValue: wanted) else {
                throw .invalid("aspect \(wanted) is not a shape the models draw (\(ImageAspect.allCases.map(\.rawValue).joined(separator: ", ")))")
            }
            guard installed.contains(aspect) else {
                throw .modelMissing("\(model.rawValue) has no \(wanted) export installed (installed: \(installed.map(\.rawValue).joined(separator: ", "))); `imagine model download\(Self.flag(model)) --aspect \(wanted)` fetches it")
            }
        } else {
            fill.aspect = ImageAspect.nearest(width: width, height: height, among: installed).rawValue
        }
        if let steps = fill.steps, !model.stepRange.contains(steps) {
            throw .invalid("\(model.rawValue) takes \(model.stepRange.lowerBound)…\(model.stepRange.upperBound) steps; not \(steps)")
        }
        fill.model = model.rawValue
        fill.revision = Self.revisions[model]
        if fill.seed == nil { fill.seed = UInt32.random(in: 1...UInt32.max) }
        return fill
    }

    /// The `imagine model download` flag that names `model`.
    nonisolated static func flag(_ model: GenerationModel) -> String {
        switch model {
        case .flux2Klein4B: ""
        case .sanaSprint16B: " --fast"
        case .flux2Klein9B: " --quality"
        }
    }

    static func model(_ name: String?) throws(DesignError) -> GenerationModel {
        guard let name else { return defaultModel }
        guard let model = GenerationModel(rawValue: name.lowercased()) else {
            throw .invalid("model \(name) is not one of \(GenerationModel.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        return model
    }

    /// The shapes `model` can draw from what is installed.
    public nonisolated static func installedAspects(_ model: GenerationModel, support: URL = applicationSupport) -> [ImageAspect] {
        let folder = Self.folder(model, support: support)
        let manager = FileManager.default
        func has(_ path: String) -> Bool { manager.fileExists(atPath: folder.appendingPathComponent(path).path) }
        switch model {
        case .flux2Klein4B:
            guard has("TransformerSlot.aimodel") || has("Transformer.aimodel") else { return [] }
            return model.aspects.filter { aspect in
                has("\(aspect.shapeFolder)/metadata.json") && (aspect == .square || has("\(aspect.shapeFolder)/Transformer.aimodel"))
            }
        case .sanaSprint16B:
            guard has("Transformer.aimodel") else { return [] }
            return model.aspects.filter { $0 == .square || ($0.subfolder.map(has) ?? false) }
        case .flux2Klein9B:
            return has("Transformer.aimodel") ? [.square] : []
        }
    }

    nonisolated static func folder(_ model: GenerationModel, support: URL) -> URL {
        support.appendingPathComponent("imagine-\(model.rawValue)", isDirectory: true)
    }

    /// The export folder for one model and shape.
    nonisolated static func bundle(_ model: GenerationModel, aspect: ImageAspect, support: URL) -> URL {
        let folder = folder(model, support: support)
        switch model {
        case .flux2Klein4B: return folder.appendingPathComponent(aspect.shapeFolder, isDirectory: true)
        case .sanaSprint16B: return aspect.subfolder.map { folder.appendingPathComponent($0, isDirectory: true) } ?? folder
        case .flux2Klein9B: return folder
        }
    }

    // MARK: Drawing

    public func image(for fill: AIFill) async throws(DesignError) -> CGImage {
        let model = try Self.model(fill.model)
        guard let aspectName = fill.aspect, let aspect = ImageAspect(rawValue: aspectName), let seed = fill.seed else {
            throw .invalid("the background is not pinned (model, aspect, seed); make the design again")
        }
        let key = Self.cacheKey(fill)
        if let cached = cachedImage(key) { return cached }

        let bundle = Self.bundle(model, aspect: aspect, support: support)
        let generator: ImageGenerator
        if let warm = loaded[bundle.path] {
            generator = warm
        } else {
            do { generator = try await ImageGenerator(bundle: bundle) } catch {
                throw .failed("\(model.rawValue) (\(aspectName)) could not be loaded from \(bundle.path): \(error)")
            }
            loaded = [bundle.path: generator]
        }
        let prompt = [fill.prompt, fill.style].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        let made: [GeneratedImage]
        do { made = try await generator.generate(prompt, seed: seed, count: 1, steps: fill.steps) } catch {
            throw .failed("the background could not be drawn: \(error)")
        }
        guard let picture = made.first?.image else { throw .failed("the model drew nothing") }
        store(picture, key: key)
        return picture
    }

    /// The pin as a file name: what is drawn depends on nothing else.
    static func cacheKey(_ fill: AIFill) -> String {
        let text = [fill.model ?? "", fill.revision ?? "", fill.aspect ?? "", fill.seed.map(String.init) ?? "",
                    fill.steps.map(String.init) ?? "", fill.prompt, fill.style ?? ""].joined(separator: "\u{1F}")
        return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func cachedImage(_ key: String) -> CGImage? {
        guard let url = cache?.appendingPathComponent("\(key).png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func store(_ image: CGImage, key: String) {
        guard let cache else { return }
        try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        let url = cache.appendingPathComponent("\(key).png")
        guard let data = try? Exporter.png(image) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
