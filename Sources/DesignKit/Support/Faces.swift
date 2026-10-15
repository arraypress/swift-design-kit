//
//  Faces.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation
import Vision

enum Faces {

    /// Faces in `image`, as rects in its pixels (top-left), each grown by a
    /// fifth so hair and chin count.
    static func find(in image: CGImage) -> [CGRect] {
        let request = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: image).perform([request])
        let w = Double(image.width), h = Double(image.height)
        return (request.results ?? []).map { face in
            let box = face.boundingBox
            let rect = CGRect(x: box.minX * w, y: (1 - box.maxY) * h, width: box.width * w, height: box.height * h)
            return rect.insetBy(dx: -rect.width * 0.1, dy: -rect.height * 0.1)
        }
    }
}
