//
//  CutoutSubject.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The subject a parallax moves as one piece, from swift-object-cutout:
//  BiRefNet on Core AI where `cutout` has installed it (its own alpha, the
//  colour decontaminated, as the cut-out layers use), Vision's subject mask
//  otherwise — unless the model is required.
//

import CoreGraphics
import CoreImage
import Foundation
import ObjectCutout

/// The subject of a picture as one piece, for a parallax to move: BiRefNet
/// when installed, else Vision's subject mask.
public struct CutoutSubject: SubjectMatting {

    private let requireModel: Bool

    /// Where BiRefNet comes from and where it is kept, for a caller that fetches it
    /// (the same copy `cutout` installs: Application Support/`folder`/`asset`).
    public static let repository = SubjectModel.repository
    /// The model's file name.
    public static let asset = SubjectModel.assetName
    /// The Application Support folder it is kept in.
    public static let folder = SubjectModel.sharedFolder
    /// Its licence.
    public static let licence = SubjectModel.licence
    /// The revision pinned.
    public static let revision = SubjectModel.revision

    /// - Parameter requireModel: refuse rather than fall back to Vision when
    ///   BiRefNet is not installed.
    public init(requireModel: Bool = false) { self.requireModel = requireModel }

    /// The model that will run, as recorded in a design.
    public var pin: String {
        if (try? Matte.usesModel(requireModel ? .model : .automatic)) == true {
            return "birefnet-general@\(SubjectModel.revision) (\(SubjectModel.repository))"
        }
        return "vision-foreground-instance"
    }

    /// The subject's mask, or nil when the picture has none.
    public func subject(of image: CGImage) async throws(DesignError) -> CGImage? {
        let engine: MatteEngine = requireModel ? .model : .automatic
        return try await Offload.run { () throws(DesignError) -> CGImage? in
            let input = CIImage(cgImage: image)
            do {
                guard let mask = try Matte.subjectMask(for: input, engine: engine) else { return nil }
                let edge: EdgeOptions = try Matte.usesModel(engine) ? .forModel(.crisp) : .crisp
                guard let cut = Matte.cutout(from: input, mask: mask, edge: edge) else { return nil }
                return Bitmaps.render(cut.image, extent: input.extent)
            } catch {
                throw .failed("the subject could not be lifted out for the parallax: \(error.localizedDescription)")
            }
        }
    }
}
