//
//  DispatchExecutor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

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
