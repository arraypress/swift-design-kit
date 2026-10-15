// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-design-kit",
    // macOS 27 / iOS 27: the AI product runs on Core AI (swift-image-generation
    // and swift-upscale floor there). The engine itself imports no Core AI.
    platforms: [
        .macOS("27.0"),
        .iOS("27.0"),
    ],
    products: [
        // The engine: a one-page design (cover art, flyers, posters) as a
        // strict recipe — canvas, ordered layers, template slots — laid out by
        // rule, drawn headlessly, checked blind, written as PNG/JPEG/PDF.
        .library(name: "DesignKit", targets: ["DesignKit"]),

        // AI backgrounds and upscaling on this machine: FLUX.2 Klein / SANA
        // Sprint through swift-image-generation, SwinIR through swift-upscale,
        // behind the engine's `ImageGenerating` / `ImageUpscaling`.
        .library(name: "DesignKitAI", targets: ["DesignKitAI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/arraypress/swift-canvas-kit.git", from: "0.5.1"),
        .package(url: "https://github.com/arraypress/swift-gradient-kit.git", from: "0.3.0"),
        .package(url: "https://github.com/arraypress/swift-object-cutout.git", from: "1.2.1"),
        .package(url: "https://github.com/arraypress/swift-media-kit.git", from: "0.1.0"),
        .package(url: "https://github.com/arraypress/swift-qr-kit.git", from: "1.1.0"),
        .package(url: "https://github.com/arraypress/swift-document-theme.git", from: "0.1.0"),
        .package(url: "https://github.com/arraypress/swift-recipe-kit.git", from: "0.3.1"),
        .package(url: "https://github.com/arraypress/swift-video-grade.git", from: "0.3.0"),
        .package(url: "https://github.com/arraypress/swift-legibility.git", from: "0.1.0"),
        .package(url: "https://github.com/arraypress/swift-image-generation.git", from: "0.13.2"),
        .package(url: "https://github.com/arraypress/swift-upscale.git", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "DesignKit",
            dependencies: [
                .product(name: "CanvasKit", package: "swift-canvas-kit"),
                .product(name: "GradientKit", package: "swift-gradient-kit"),
                .product(name: "ObjectCutout", package: "swift-object-cutout"),
                .product(name: "ImagePalette", package: "swift-media-kit"),
                .product(name: "QRKit", package: "swift-qr-kit"),
                .product(name: "DocumentTheme", package: "swift-document-theme"),
                .product(name: "RecipeKit", package: "swift-recipe-kit"),
                .product(name: "VideoGradeLook", package: "swift-video-grade"),
                .product(name: "Legibility", package: "swift-legibility"),
            ]
        ),
        .target(
            name: "DesignKitAI",
            dependencies: [
                "DesignKit",
                .product(name: "ImageGeneration", package: "swift-image-generation"),
                .product(name: "Upscale", package: "swift-upscale"),
            ]
        ),
        .testTarget(
            name: "DesignKitTests",
            dependencies: [
                "DesignKit",
                "DesignKitAI",
                .product(name: "CanvasKit", package: "swift-canvas-kit"),
                .product(name: "RecipeKit", package: "swift-recipe-kit"),
                .product(name: "Legibility", package: "swift-legibility"),
                .product(name: "VideoGradeLook", package: "swift-video-grade"),
                .product(name: "QRKit", package: "swift-qr-kit"),
            ]
        ),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
