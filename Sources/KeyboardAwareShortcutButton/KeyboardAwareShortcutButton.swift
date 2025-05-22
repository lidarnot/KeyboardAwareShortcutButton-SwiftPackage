import SwiftUI
// ExternalKeyboardMonitor is in the same module, so no explicit import needed here.

/// Describes the layout direction for the shortcut button's label and shortcut hint.
public enum ShortcutButtonLayoutDirection {
  case horizontal
  case vertical
}

/// A button that can display and optionally allow assignment of a keyboard shortcut.
/// It also shows shortcut information only when an external keyboard is connected.
public struct KeyboardAwareShortcutButton<LabelContent: View>: View {
  
  // Action to perform when the button is activated
  let action: () -> Void
  // Custom view builder for the button's label content
  let label: () -> LabelContent
  
  // Layout configuration
  let layoutDirection: ShortcutButtonLayoutDirection
  let shortcutVerticalPadding: CGFloat
  
  // Accessibility Identifiers
  let accessibilityIdentifierMainButton: String?
  let accessibilityIdentifierAssignButton: String?
  
  // State for the current shortcut
  @State private var currentShortcutKey: KeyEquivalent?
  @State private var currentShortcutModifiers: EventModifiers
  let displayShortcutOverlay: Bool // Renamed from displayShortuctOverlay for clarity
  
  // State to manage the UI for shortcut assignment (iOS 17+)
  @State private var isAssigningShortcut: Bool = false
  
  private let estimatedCaptionLineHeight: CGFloat = 16
  private let estimatedHorizontalShortcutTextWidth: CGFloat = 75
  
  let customPadding: CGFloat?
  
  // Monitor for external keyboard connection
  @StateObject private var externalKeyboardMonitor = ExternalKeyboardMonitor()
  
  /// Initializes a shortcut button with a text title.
  /// - Parameters:
  ///   - initialKey: The initial `KeyEquivalent` for the shortcut.
  ///   - initialModifiers: The initial `EventModifiers` for the shortcut. Default is `.command`.
  ///   - displayShortcutOverlay: Whether to display the shortcut hint overlay. Default is `true`.
  ///   - layoutDirection: The layout direction for label and shortcut hint. Default is `.vertical`.
  ///   - shortcutVerticalPadding: Padding for vertical layout. Default is `4`.
  ///   - customPadding: Custom padding to override calculated amounts.
  ///   - title: The text title for the button.
  ///   - action: The action to perform when the button is tapped.
  ///   - accessibilityIdentifierMainButton: Accessibility ID for the main button.
  ///   - accessibilityIdentifierAssignButton: Accessibility ID for the assignment button (iOS 17+).
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true,
    layoutDirection: ShortcutButtonLayoutDirection = .vertical,
    shortcutVerticalPadding: CGFloat = 4,
    customPadding: CGFloat? = nil,
    title: String,
    action: @escaping () -> Void,
    accessibilityIdentifierMainButton: String? = nil,
    accessibilityIdentifierAssignButton: String? = nil
  ) where LabelContent == Text {
    self.init(
      initialKey: initialKey,
      initialModifiers: initialModifiers,
      displayShortcutOverlay: displayShortcutOverlay,
      layoutDirection: layoutDirection,
      shortcutVerticalPadding: shortcutVerticalPadding,
      customPadding: customPadding,
      action: action,
      accessibilityIdentifierMainButton: accessibilityIdentifierMainButton,
      accessibilityIdentifierAssignButton: accessibilityIdentifierAssignButton,
      label: { Text(title) }
    )
  }
  
  /// Initializes a shortcut button with custom label content.
  /// - Parameters:
  ///   - initialKey: The initial `KeyEquivalent` for the shortcut.
  ///   - initialModifiers: The initial `EventModifiers` for the shortcut. Default is `.command`.
  ///   - displayShortcutOverlay: Whether to display the shortcut hint overlay. Default is `true`.
  ///   - layoutDirection: The layout direction for label and shortcut hint. Default is `.vertical`.
  ///   - shortcutVerticalPadding: Padding for vertical layout. Default is `4`.
  ///   - customPadding: Custom padding to override calculated amounts.
  ///   - action: The action to perform when the button is tapped.
  ///   - accessibilityIdentifierMainButton: Accessibility ID for the main button.
  ///   - accessibilityIdentifierAssignButton: Accessibility ID for the assignment button (iOS 17+).
  ///   - label: A view builder for the button's label content.
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true, // Corrected typo from displayShortuctOverlay
    layoutDirection: ShortcutButtonLayoutDirection = .vertical,
    shortcutVerticalPadding: CGFloat = 4,
    customPadding: CGFloat? = nil,
    action: @escaping () -> Void,
    accessibilityIdentifierMainButton: String? = nil,
    accessibilityIdentifierAssignButton: String? = nil,
    @ViewBuilder label: @escaping () -> LabelContent
  ) {
    self.action = action
    self.label = label
    self._currentShortcutKey = State(initialValue: initialKey)
    self._currentShortcutModifiers = State(initialValue: initialModifiers)
    self.displayShortcutOverlay = displayShortcutOverlay
    self.layoutDirection = layoutDirection
    self.shortcutVerticalPadding = shortcutVerticalPadding
    self.customPadding = customPadding
    self.accessibilityIdentifierMainButton = accessibilityIdentifierMainButton
    self.accessibilityIdentifierAssignButton = accessibilityIdentifierAssignButton
  }
  
  // MARK: - Shortcut Display Strings (Internal)
  
  func keyEquivalentDisplayString(for key: KeyEquivalent) -> String {
    let char_fb = key.character
    
    if char_fb == KeyEquivalent.space.character { return "Space" }
    if char_fb == KeyEquivalent.return.character { return "↩" }
    if char_fb == KeyEquivalent.tab.character { return "⇥" }
    if char_fb == KeyEquivalent.escape.character { return "⎋" }
    if char_fb == KeyEquivalent.delete.character { return "⌫" }
    if char_fb == KeyEquivalent.deleteForward.character { return "⌦" }
    if char_fb == KeyEquivalent.upArrow.character { return "↑" }
    if char_fb == KeyEquivalent.downArrow.character { return "↓" }
    if char_fb == KeyEquivalent.leftArrow.character { return "←" }
    if char_fb == KeyEquivalent.rightArrow.character { return "→" }
    if char_fb == KeyEquivalent.home.character { return "↖" }
    if char_fb == KeyEquivalent.end.character { return "↘" }
    if char_fb == KeyEquivalent.pageUp.character { return "⇞" }
    if char_fb == KeyEquivalent.pageDown.character { return "⇟" }
    if char_fb == KeyEquivalent.clear.character { return "Clear" }
    else {
      if char_fb.unicodeScalars.first?.properties.generalCategory == .control {
        return "?"
      }
      if char_fb.isLetter { return String(char_fb).uppercased() }
      if char_fb.isNumber || char_fb.isSymbol || char_fb.isPunctuation { return String(char_fb) }
      if char_fb.isASCII && !char_fb.isWhitespace { return String(char_fb).uppercased() }
      if String(char_fb).isEmpty { return "?" }
      if char_fb.isWhitespace && char_fb != " " { return "?" }
      return String(char_fb)
    }
  }
  
  private func modifiersDisplayString(for modifiers: EventModifiers) -> String {
    var displayString = ""
    if modifiers.contains(.control) { displayString += "⌃" }
    if modifiers.contains(.option) { displayString += "⌥" }
    if modifiers.contains(.shift) { displayString += "⇧" }
    if modifiers.contains(.command) { displayString += "⌘" }
    return displayString
  }
  
  private var shortcutDisplayString: String? {
    guard let key = currentShortcutKey else { return nil }
    let modString = modifiersDisplayString(for: currentShortcutModifiers)
    return "\(modString)\(keyEquivalentDisplayString(for: key))"
  }
  
  // MARK: - View Logic (Internal)
  
  private func shouldShowShortcutTextInfo() -> Bool {
    displayShortcutOverlay &&
    (isAssigningShortcut || shortcutDisplayString != nil || currentShortcutKey == nil) &&
    externalKeyboardMonitor.isExternalKeyboardConnected
  }
  
  @ViewBuilder
  private var shortcutTextInfoViewForOverlay: some View {
    if isAssigningShortcut { // Only true on iOS 17+ if assignShortcutButtonView is used
      Text("Press new shortcut...")
        .font(.caption)
        .foregroundColor(.blue)
    } else if let shortcutStr = shortcutDisplayString {
      Text(shortcutStr)
        .font(.caption)
        .foregroundColor(.secondary)
    } else {
      Text("(No shortcut)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  @ViewBuilder
  private var labelWithOverlaidShortcut: some View {
    let baseLabel = label()
    let showInfo = shouldShowShortcutTextInfo()
    
    let paddingEdge: Edge.Set = layoutDirection == .vertical ? .bottom : .trailing
    let paddingAmount: CGFloat = if showInfo {
      layoutDirection == .vertical ? (estimatedCaptionLineHeight + shortcutVerticalPadding) : (estimatedHorizontalShortcutTextWidth + 8)
    } else {
      0
    }
    let overlayAlignment: Alignment = layoutDirection == .vertical ? .bottom : .trailing
    
    baseLabel
      .overlay(alignment: overlayAlignment) {
        if showInfo {
          if layoutDirection == .vertical {
            shortcutTextInfoViewForOverlay
              .padding(paddingEdge, customPadding ?? paddingAmount)
          } else {
            shortcutTextInfoViewForOverlay
              .padding(.trailing, customPadding ?? 8) // Default horizontal padding
          }
        }
      }
  }
  
  /// The button to toggle shortcut assignment mode (iOS 17+).
  @ViewBuilder
  private var assignShortcutButtonView: some View {
    Button {
      isAssigningShortcut.toggle()
    } label: {
      Image(systemName: isAssigningShortcut ? "keyboard.fill" : "keyboard")
        .foregroundColor(isAssigningShortcut ? .blue : .accentColor)
    }
    .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle for icon-like buttons
    .accessibilityLabel(isAssigningShortcut ? "Cancel shortcut assignment" : "Assign shortcut")
    .accessibilityIdentifier(accessibilityIdentifierAssignButton ?? "KeyboardAwareShortcutButton.assignButton")
  }
  
  // MARK: - Body
  
  public var body: some View {
    let buttonContent = HStack(alignment: .center, spacing: 4) { // Reduced spacing
      labelWithOverlaidShortcut
    }
    
    let actualButton = Button(action: {
      if isAssigningShortcut { // isAssigningShortcut will be false on iOS < 17 from UI
        isAssigningShortcut = false
      } else {
        action()
      }
    }) {
      buttonContent
    }
      .buttonStyle(PlainButtonStyle()) // Consistent button style
      .accessibilityIdentifier(accessibilityIdentifierMainButton ?? "KeyboardAwareShortcutButton.mainButton")
    
    let mainButtonWithKeyboardShortcut = Group {
      if let sk = currentShortcutKey {
        actualButton.keyboardShortcut(sk, modifiers: currentShortcutModifiers)
      } else {
        actualButton
      }
    }
    
    let viewHierarchy = HStack(spacing: 8) {
      mainButtonWithKeyboardShortcut
      
      // Conditionally include the assignShortcutButtonView only on iOS 17+
      // and if an external keyboard is connected and overlay is enabled.
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) { // watchOS included for completeness of #available
        if externalKeyboardMonitor.isExternalKeyboardConnected && displayShortcutOverlay {
          assignShortcutButtonView
        }
      }
    }
    
    // Apply .onKeyPress modifier conditionally for shortcut assignment (iOS 17+)
    return viewHierarchy
      .if(isAssigningShortcut) { view_in_transform in
        Group { // Required by .if for type consistency
          if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            view_in_transform.onKeyPress(phases: .down) { press in
              let keyChar = press.key.character
              let isCharOrNumber = keyChar.isLetter || keyChar.isNumber
              
              // Compare characters for iOS < 17 compatibility logic in isAllowedSingleKey
              let isAllowedSingleKey = keyChar == KeyEquivalent.space.character ||
              keyChar == KeyEquivalent.return.character ||
              keyChar == KeyEquivalent.escape.character ||
              keyChar == KeyEquivalent.tab.character ||
              press.key.isArrowKey || // Uses internal KeyEquivalent extension
              press.key.isFunctionKey  // Uses internal KeyEquivalent extension
              
              if press.modifiers.isEmpty && isCharOrNumber && !isAllowedSingleKey {
#if DEBUG
                print("⚠️ Shortcut Assignment: Plain character '\(keyChar)' without modifiers is not recommended. Shortcut not assigned.")
#endif
                self.isAssigningShortcut = false // Exit assignment mode
                return .handled
              }
              
              self.currentShortcutKey = press.key
              self.currentShortcutModifiers = press.modifiers
              self.isAssigningShortcut = false // Exit assignment mode
              
#if DEBUG
              if let newKey = self.currentShortcutKey {
                print("✅ Shortcut Assigned: \(self.modifiersDisplayString(for: self.currentShortcutModifiers))\(self.keyEquivalentDisplayString(for: newKey))")
              }
#endif
              return .handled
            }
          } else {
            // On OS < iOS 17, isAssigningShortcut should ideally not be true
            // as assignShortcutButtonView is not shown.
            // If it is, return view unmodified from the transform.
            view_in_transform
          }
        }
      }
  }
}
