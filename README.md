# TaskSemaphore

Semaphore with basic wait/signal for Swift Concurrency. Actor-based implementation
suspends and resumes Tasks using continuations: no threads are blocked.

Neither timeout nor initial value is supported.


## Usage

Each instance of a TaskSemaphore provides two [async] functions: a wait() and a signal().
Used together, they can provide exclusive task access to a resource or section(s) of code.

A function calls wait() to indicate the desire to use the resource. Access is granted by wait()
returning: wait() will pause all other callers until the program indicates it is done with the
resource.

When exclusive access to the resource is no longer needed, the program calls signal() on
the semaphore instance. If there are other tasks waiting on the semaphore, the first in line will be
scheduled.


    let coordinator = TaskSemaphore()
    detach {  // as many times as needed
        // do asynchrnous work...
        await coordinator.wait()
        // work here is serialized
        await coordinator.signal()
        // ...and asynchronous work continues
    }


## Implementation

The implementation is very simple, and is an interesting study in the expressive clarity of
Swift's new concurrecy features.

A Swift actor is used to serialize management of waiting tasks. Without the need for
additional syntax for locking or other protection, wait+signal need only a half-dozen lines
of code, and that code clearly expresses the queue behavior. Actors simplify writing sound code.

The implementation uses withCheckedContinuation in wait() to suspend the task if
another task is already using the resource. No Thread or DispatchQueue features are used,
no threads are suspended or spawned, and no busy-waiting is required. Swift's async/await
prepares the calling function for possible suspension during the wait(); continuations
allow the implementation to control when the task is suspended and returned to the
execution queue.
