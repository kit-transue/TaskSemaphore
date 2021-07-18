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
    var serializedTasks: [CheckedContinuation<Bool, Never>] = []

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
        let _ = await waitImpl()
    }

    // FIXME: Bool here is a throwaway dummy, because I can't get the syntax
    // for capturing a void continuation to compile. Get this right.
    func waitImpl() async -> Bool {
        await withCheckedContinuation { continuation in
            serializedTasks.append(continuation)
            if serializedTasks.count == 1 {
                serializedTasks.first!.resume(returning: true)
            }
        }
    }

    /// Release the critical section.
    ///
    /// If other tasks are queued calling wait(), the first in line is scheduled.
    public func signal() {
        serializedTasks.remove(at: 0)
        serializedTasks.first?.resume(returning: true)
    }

}
