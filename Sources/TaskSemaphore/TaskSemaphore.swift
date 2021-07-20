//
//  TaskSemaphore.swift
//
//
//  Created by Kit Transue on 2021-07-13.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

/// Simple semaphore to support restricting Task concurrency of a critical section of code
/// between calls to ``wait()`` and ``signal()``.
public actor TaskSemaphore {
    // Swift Concurrency actors make this implementation very easy
    var serializedTasks: [CheckedContinuation<Void, Never>] = []

    public init() {
    }

    // FIXME: with the Swift syntax, would these be better named "available" and "release"?
    //   await resource.isAvailable()
    //   await resource.release()
    // is pretty catchy

    /// indicate desire to use critical section.
    ///
    /// If the critical section is already being accessed, suspend the
    /// current task until the critical section becomes available. Once the call returns, other callers of
    /// wait() will be blocked until ``signal()`` is called to release the critical section.
    ///
    /// - Note: The wait queue is a FIFO: calls to wait() return in the order they were called.
    public func wait() async {
        // "return await..." or "let _: Void = await..." can be used to give
        // withCheckedContinuation enough context to infer its T parameter type
        // as Void:
        return await withCheckedContinuation { continuation in
            serializedTasks.append(continuation)
            if serializedTasks.count == 1 {
                serializedTasks.first!.resume()
            }
        }
    }

    /// Release the critical section.
    ///
    /// If other tasks are queued calling wait(), the first in line is scheduled.
    public func signal() {
        serializedTasks.remove(at: 0)
        serializedTasks.first?.resume()
    }

}
