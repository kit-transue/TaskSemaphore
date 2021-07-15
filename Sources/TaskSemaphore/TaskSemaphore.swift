//
//  TaskSemaphore.swift
//
//
//  Created by Kit Transue on 2021-07-13.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

public actor TaskSemaphore {
    var serializedTasks: [CheckedContinuation<Bool, Never>] = []

    public init() {
    }

    public func wait() async -> Bool {
        await withCheckedContinuation { continuation in
            serializedTasks.append(continuation)
            if serializedTasks.count == 1 {
                serializedTasks.first!.resume(returning: true)
            }
        }
    }
    
    public func signal() {
        serializedTasks.remove(at: 0)
        serializedTasks.first?.resume(returning: true)
    }

}
