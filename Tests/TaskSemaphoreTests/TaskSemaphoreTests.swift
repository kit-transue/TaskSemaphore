import XCTest
@testable import TaskSemaphore

final class TaskSemaphoreTests: XCTestCase {
    func testShouldOrder() throws {
        actor SequenceChecker {
            var current = 0
            func check(shouldBe: Int) {
                XCTAssertEqual(current, shouldBe)
                current += 1
            }
        }

        let progress = SequenceChecker()
        let shouldComplete = XCTestExpectation(description: "all checks should run")


        let coordinator = TaskSemaphore()

        detach {
            await Task.sleep(500_000_000)
            await progress.check(shouldBe: 6)
            shouldComplete.fulfill()
        }

        // launch in reverse order, to make it clear that detached operations
        // run in parallel but are sequenced by their first Task.sleep
        detach {
            await Task.sleep(20_000_000)
            await coordinator.wait()
            await progress.check(shouldBe: 4)
            await Task.yield()
            await Task.sleep(10_000_000)
            await progress.check(shouldBe: 5)
            await coordinator.signal()
        }
        detach {
            await Task.sleep(10_000_000)
            await coordinator.wait()
            await progress.check(shouldBe: 2)
            await Task.yield()
            await Task.sleep(50_000_000)
            await progress.check(shouldBe: 3)
            await coordinator.signal()
        }
        detach {
            await coordinator.wait()
            await progress.check(shouldBe: 0)
            await Task.yield()
            await Task.sleep(100_000_000)
            await progress.check(shouldBe: 1)
            await coordinator.signal()
        }

        wait(for: [shouldComplete], timeout: 1.0)
    }
}
