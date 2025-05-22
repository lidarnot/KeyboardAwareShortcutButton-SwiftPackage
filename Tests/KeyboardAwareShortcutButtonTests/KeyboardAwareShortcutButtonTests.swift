import XCTest
@testable import KeyboardAwareShortcutButton
import SwiftUI

final class KeyboardAwareShortcutButtonInitializationTests: XCTestCase { // Renamed class
  
  func testInitialization_WithTitle() {
    let actionExecuted = XCTestExpectation(description: "Action executed")
    actionExecuted.isInverted = true // We don't expect it to be called on init
    
    let sut = KeyboardAwareShortcutButton(title: "My Button", action: {
      actionExecuted.fulfill()
    })
    
    XCTAssertNotNil(sut, "Button should initialize with a title.")
    // We can't easily inspect the Text content here without ViewInspector
    // but we know it compiled and initialized.
    
    wait(for: [actionExecuted], timeout: 0.1) // Ensure action wasn't called
  }
  
  func testInitialization_WithCustomLabel() {
    let actionExecuted = XCTestExpectation(description: "Action executed")
    actionExecuted.isInverted = true
    
    let sut = KeyboardAwareShortcutButton(action: {
      actionExecuted.fulfill()
    }, label: {
      HStack {
        Image(systemName: "star")
        Text("Custom")
      }
    })
    
    XCTAssertNotNil(sut, "Button should initialize with a custom label.")
    wait(for: [actionExecuted], timeout: 0.1)
  }
  
  // Testing the actual button tap action would ideally use ViewInspector
  // or XCUITest. For XCTest, we've just confirmed init.
}
