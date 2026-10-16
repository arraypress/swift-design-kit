//
//  Fades.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A layer faded toward an edge: a soft mask the layer is clipped to while
//  it draws — a grey picture, white where the layer shows. The mask covers
//  the frame and twice its size round it (the frame's shadow and anything
//  past its edge fade with it), at a modest resolution: it is a smooth ramp,
//  and CoreGraphics interpolates it in a bitmap and a PDF alike.
//

import CoreGraphics
import Foundation

enum Fades {

    /// Mask pixels across the frame itself.
    static let resolution = 256

    /// The mask for `fade` over `frame` (CoreGraphics space): the image and
    /// the rectangle it is stretched over.
    static func mask(_ fade: Fade, frame: CGRect) -> (image: CGImage, rect: CGRect)? {
        guard frame.width > 0, frame.height > 0 else { return nil }
        let n = resolution * 3
        var bytes = [UInt8](repeating: 0, count: n * n)
        for row in 0..<n {
            for column in 0..<n {
                // Position in frame fractions: 0…1 across the frame, -1…2 over the mask.
                let fx = (Double(column) + 0.5) / Double(resolution) - 1
                let fy = (Double(row) + 0.5) / Double(resolution) - 1   // from the top
                bytes[row * n + column] = UInt8((visibility(fade, x: fx, y: fy) * 255).rounded())
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: n,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return (image, frame.insetBy(dx: -frame.width, dy: -frame.height))
    }

    /// How much of the layer shows at frame fractions (x from the left, y from the top).
    static func visibility(_ fade: Fade, x: Double, y: Double) -> Double {
        let t: Double
        switch fade.edge {
        case .bottom: t = y
        case .top: t = 1 - y
        case .right: t = x
        case .left: t = 1 - x
        case .radial:
            let dx = x - 0.5, dy = y - 0.5
            t = (dx * dx + dy * dy).squareRoot() / 0.5.squareRoot()
        }
        let u = min(1, max(0, (t - fade.start) / max(0.0001, fade.end - fade.start)))
        return 1 - u * u * (3 - 2 * u)
    }
}
