import XCTest
@testable import KeyboardAwareShortcutButton
import SwiftUI

class KeyEquivalentExtensionTests: XCTestCase {
  
  func testIsArrowKey_TrueForArrowKeys() {
    XCTAssertTrue(KeyEquivalent.upArrow.isArrowKey)
    XCTAssertTrue(KeyEquivalent.downArrow.isArrowKey)
    XCTAssertTrue(KeyEquivalent.leftArrow.isArrowKey)
    XCTAssertTrue(KeyEquivalent.rightArrow.isArrowKey)
  }
  
  func testIsArrowKey_FalseForNonArrowKeys() {
    XCTAssertFalse(KeyEquivalent("a").isArrowKey)
    XCTAssertFalse(KeyEquivalent.space.isArrowKey)
    XCTAssertFalse(KeyEquivalent.return.isArrowKey)
    XCTAssertFalse(KeyEquivalent("1").isArrowKey)
  }
  
  func testIsFunctionKey_IsCurrentlyFalse() {
    // This test reflects the current implementation where isFunctionKey always returns false.
    // If KeyEquivalent gains .f1 etc. and you implement checks, update this.
//    XCTAssertFalse(KeyEquivalent.f1.isFunctionKey, "F1 key (assuming .f1 is available)") // .f1 is iOS 15+
    XCTAssertFalse(KeyEquivalent("f").isFunctionKey)
    XCTAssertFalse(KeyEquivalent.escape.isFunctionKey)
  }
}
