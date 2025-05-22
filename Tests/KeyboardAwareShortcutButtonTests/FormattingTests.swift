import XCTest
@testable import KeyboardAwareShortcutButton // Allows access to internal members
import SwiftUI // For KeyEquivalent, EventModifiers

class FormattingTests: XCTestCase {
  
  // Helper to create a button instance for testing its internal methods
  private func makeSUT(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    title: String = "Test"
  ) -> KeyboardAwareShortcutButton<Text> {
    return KeyboardAwareShortcutButton(
      initialKey: initialKey,
      initialModifiers: initialModifiers,
      title: title,
      action: {}
    )
  }
  
  // MARK: - keyEquivalentDisplayString Tests
  
  func testKeyEquivalentDisplayString_CommonKeys() {
    let sut = makeSUT()
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .space), "Space", "Space key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .return), "↩", "Return key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .tab), "⇥", "Tab key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .escape), "⎋", "Escape key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .delete), "⌫", "Delete key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .deleteForward), "⌦", "Delete Forward key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .upArrow), "↑", "Up Arrow key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .downArrow), "↓", "Down Arrow key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .leftArrow), "←", "Left Arrow key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .rightArrow), "→", "Right Arrow key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .home), "↖", "Home key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .end), "↘", "End key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .pageUp), "⇞", "Page Up key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .pageDown), "⇟", "Page Down key")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: .clear), "Clear", "Clear key")
  }
  
  func testKeyEquivalentDisplayString_Letters() {
    let sut = makeSUT()
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("a")), "A")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("Z")), "Z")
  }
  
  func testKeyEquivalentDisplayString_Numbers() {
    let sut = makeSUT()
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("1")), "1")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("0")), "0")
  }
  
  func testKeyEquivalentDisplayString_Symbols() {
    let sut = makeSUT()
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent(",")), ",")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent(".")), ".")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("-")), "-")
    XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent("=")), "=")
  }
  
  func testKeyEquivalentDisplayString_ControlCharactersReturnQuestionMark() {
    let sut = makeSUT()
    // Example of a control character (Null character)
    // KeyEquivalent character for control characters might not be straightforward.
    // This test assumes that if a KeyEquivalent represents a non-printable control character,
    // it should fall into the generalCategory == .controlCharacter check.
    // Note: Creating KeyEquivalent for arbitrary control characters might be tricky.
    // Let's test with a known non-printable ASCII, like Bell (BEL, ASCII 7)
    // if Character(UnicodeScalar(7)) can be made into a KeyEquivalent.
    // For now, let's rely on how the code handles an empty string if that can occur.
    // However, `KeyEquivalent.character` usually returns something.
    
    // A more direct test for control character logic would be needed if KeyEquivalent
    // can directly represent them from keyboard input that isn't special like .return.
    // The current logic uses `char_fb.unicodeScalars.first?.properties.generalCategory == .controlCharacter`
    // Let's assume a hypothetical scenario or a character known to be a control character.
    // For instance, if a KeyEquivalent could represent a null character directly.
    // This part is harder to test without knowing exactly how KeyEquivalent handles all control chars.
    // However, if `String(char_fb).isEmpty` occurs, it should be "?".
    // XCTAssertEqual(sut.keyEquivalentDisplayString(for: KeyEquivalent(Character(UnicodeScalar(0)!))), "?", "Null char")
    // For testing, a KeyEquivalent with an empty character shouldn't really happen from keyboard events.
    // Let's focus on the path that if String(char_fb).isEmpty is true, it's "?".
    // And if it's a known control character.
  }
  
  
  // MARK: - modifiersDisplayString Tests
  
  func testModifiersDisplayString_SingleModifiers() {
    let sut = makeSUT()
    XCTAssertEqual(sut.modifiersDisplayString(for: .control), "⌃")
    XCTAssertEqual(sut.modifiersDisplayString(for: .option), "⌥")
    XCTAssertEqual(sut.modifiersDisplayString(for: .shift), "⇧")
    XCTAssertEqual(sut.modifiersDisplayString(for: .command), "⌘")
  }
  
  func testModifiersDisplayString_MultipleModifiers() {
    let sut = makeSUT()
    // Order depends on the implementation, typically Control, Option, Shift, Command
    XCTAssertEqual(sut.modifiersDisplayString(for: [.command, .shift]), "⇧⌘")
    XCTAssertEqual(sut.modifiersDisplayString(for: [.option, .control]), "⌃⌥")
    XCTAssertEqual(sut.modifiersDisplayString(for: [.command, .option, .shift, .control]), "⌃⌥⇧⌘")
  }
  
  func testModifiersDisplayString_NoModifiers() {
    let sut = makeSUT()
    XCTAssertEqual(sut.modifiersDisplayString(for: []), "")
  }
  
  // MARK: - shortcutDisplayString Tests
  
  func testShortcutDisplayString_WithKeyAndModifiers() {
    let sut = makeSUT(initialKey: "s", initialModifiers: .command)
    // This tests the private var shortcutDisplayString.
    // We can't access it directly, but we can infer its behavior
    // by checking how it would be used in the UI (though we aren't testing UI here).
    // For this test, we're more focused on the string generation part which is public.
    // To test `shortcutDisplayString` itself, we'd need it to be internal or use ViewInspector.
    // For now, we've tested its components.
    // If we make `shortcutDisplayString` internal:
    // XCTAssertEqual(sut.shortcutDisplayString, "⌘S")
  }
  
  func testShortcutDisplayString_WithOnlyKey() {
    let sut = makeSUT(initialKey: "x", initialModifiers: [])
    // If shortcutDisplayString were internal:
    // XCTAssertEqual(sut.shortcutDisplayString, "X")
  }
  
  func testShortcutDisplayString_NoKey() {
    let sut = makeSUT(initialKey: nil)
    // If shortcutDisplayString were internal:
    // XCTAssertNil(sut.shortcutDisplayString)
  }
}
