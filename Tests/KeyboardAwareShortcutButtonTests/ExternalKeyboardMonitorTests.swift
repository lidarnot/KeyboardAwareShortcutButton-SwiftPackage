import XCTest
@testable import KeyboardAwareShortcutButton
import Combine // For AnyCancellable

@MainActor // Ensures tests involving MainActor types run on the main actor
class ExternalKeyboardMonitorTests: XCTestCase {

    var monitor: ExternalKeyboardMonitor!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        // This runs on the main thread due to @MainActor
        monitor = ExternalKeyboardMonitor()
        cancellables = []
    }

    override func tearDown() {
        monitor = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialIsExternalKeyboardConnected_IsFalse() {
        // The initial status update is deferred via Task.
        // We expect it to be false before that Task completes.
        // And generally, without GameController actually reporting a keyboard.
        XCTAssertFalse(monitor.isExternalKeyboardConnected, "Initially, keyboard should be reported as not connected.")
    }
    
    func testIsExternalKeyboardConnected_AfterShortDelay_RemainsFalseWithoutGameController() async throws {
        // Create an expectation
        let expectation = XCTestExpectation(description: "Monitor updates isExternalKeyboardConnected")

        // Subscribe to changes
        var receivedValue: Bool?
        monitor.$isExternalKeyboardConnected
            .dropFirst() // Often we want to ignore the initial value for this kind of test
            .sink { value in
                receivedValue = value
                // We don't necessarily expect a change here in a unit test environment
                // without actual GameController events.
                // This sink is more for observing if anything unexpected happens.
            }
            .store(in: &cancellables)

        // The Task in init might not have run yet.
        // Let it run for a very short period.
        // This is a bit of a smell for unit tests (relying on time),
        // but inherent with the Task in init.
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // In a test environment without a real GameController and keyboard,
        // GCKeyboard.coalesced will be nil.
        XCTAssertFalse(monitor.isExternalKeyboardConnected, "After init Task, should still be false without GameController input.")
        
        // Fulfill if we just want to ensure the test runs through
        expectation.fulfill() // Fulfill to not wait indefinitely if no change is expected.
        
        // We don't necessarily `wait(for: [expectation], timeout: 0.2)` if no change is expected.
        // The purpose of the sink was more to catch an unexpected true.
        // If the Task in init was guaranteed to publish, we'd use the expectation more directly.
    }

    // Note: Testing the actual change due to GCKeyboardDidConnect/Disconnect notifications
    // is very difficult in a pure unit test without:
    // 1. A way to mock GCKeyboard.coalesced.
    // 2. A way to reliably post and observe these specific system notifications within the test.
    // This typically leans towards integration or UI testing.
    // For unit tests, we've tested the initial state and the fact it doesn't
    // spontaneously turn true without external factors.
}
