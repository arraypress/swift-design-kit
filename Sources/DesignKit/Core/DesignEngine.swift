//
//  DesignEngine.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The whole job: prepare (fetch and make everything outside the design),
//  plan (decide what depends on what is drawn), draw at full size, check.
//

import CoreGraphics
import Foundation

/// The whole job: prepare, plan, draw at full size, check.
public enum DesignEngine {

    /// `design` drawn and checked.
    public static func render(_ design: Design, services: DesignServices) async throws(DesignError) -> Rendered {
        // Off the cooperative pool: preparing blocks on the font daemon and on Vision (see DispatchExecutor).
        let prepared = try await withTaskExecutorPreference(DispatchExecutor.shared) { () async throws(DesignError) -> PreparedDesign in
            try await Preparation.prepare(design, services: services)
        }
        return try await Offload.run { () throws(DesignError) -> Rendered in try finish(prepared) }
    }

    /// A prepared design planned, drawn and checked.
    public static func finish(_ prepared: PreparedDesign) throws(DesignError) -> Rendered {
        let (plan, composite) = Planner.plan(prepared)
        guard let image = draw(prepared, plan: plan, scale: 1) else {
            throw .failed("a \(prepared.geometry.pixelWidth)×\(prepared.geometry.pixelHeight) picture could not be made")
        }
        let report = Checker.check(prepared, plan: plan, composite: composite)
        return Rendered(prepared: prepared, plan: plan, image: image, report: report)
    }

    /// The design drawn at `scale` (1 is full size).
    public static func draw(_ prepared: PreparedDesign, plan: Plan, scale: Double) -> CGImage? {
        Checker.render(prepared, plan: plan, scale: scale, filter: .all)
    }
}
