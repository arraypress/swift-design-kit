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

/// Runs a render's tasks on dispatch threads rather than the cooperative
/// pool. Preparing a design makes many blocking calls (CoreText asks the
/// font daemon about every face, Vision waits on its own queues); with
/// several renders at once — Swift Testing runs tests in parallel — those
/// calls held every cooperative thread while the replies they waited on
/// needed one, and the process stopped (measured: two hung test runs, every
/// thread in a font-registry reply wait). Dispatch adds threads when its
/// threads block; the cooperative pool does not.
final class DispatchExecutor: TaskExecutor {

    static let shared = DispatchExecutor()

    private let queue = DispatchQueue(label: "design-kit.render", qos: .userInitiated, attributes: .concurrent)

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedTaskExecutor()
        queue.async { job.runSynchronously(on: executor) }
    }
}
