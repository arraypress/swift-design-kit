//
//  Offload.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Blocking work run on a dispatch queue rather than a Swift concurrency
//  thread. Vision's text recognition and subject lifting wait synchronously
//  on queues of their own; several renders doing that at once on the
//  cooperative pool — one thread a core — was measured to deadlock every
//  thread in it. Off the pool, they only wait.
//

import Foundation

enum Offload {

    /// `work`'s result, computed on a global queue.
    static func run<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { continuation.resume(returning: work()) }
        }
    }

    /// The same for work that throws a design error.
    static func run<T: Sendable>(_ work: @escaping @Sendable () throws(DesignError) -> T) async throws(DesignError) -> T {
        let result: Result<T, DesignError> = await run { () -> Result<T, DesignError> in
            do throws(DesignError) { return .success(try work()) } catch { return .failure(error) }
        }
        return try result.get()
    }
}
