// Sources/KeyboardAwareShortcutButton/KeyboardAwareShortcutButton.swift
import SwiftUI

public enum ShortcutButtonLayoutDirection {
  case horizontal
  case vertical
}

public struct KeyboardAwareShortcutButton<LabelContent: View>: View {
  
  let action: () -> Void
  let label: () -> LabelContent
  
  let layoutDirection: ShortcutButtonLayoutDirection
  let shortcutVerticalPadding: CGFloat
  
  let accessibilityIdentifierMainButton: String?
  let accessibilityIdentifierAssignButton: String?
  
  @State private var currentShortcutKey: KeyEquivalent?
  @State private var currentShortcutModifiers: EventModifiers
  let displayShortcutOverlay: Bool
  
  let allowShortcutAssignment: Bool
  let showAssignShortcutIcon: Bool
  let isDefaultActionEquivalent: Bool // NEW: To make it also respond to Return key
  
  @State private var isAssigningShortcut: Bool = false
  
  private let estimatedCaptionLineHeight: CGFloat = 16
  private let estimatedHorizontalShortcutTextWidth: CGFloat = 75
  
  let customPadding: CGFloat?
  
  @StateObject private var externalKeyboardMonitor = ExternalKeyboardMonitor()
  
  // MARK: - Initializers
  
  /// Initializes a shortcut button that ALSO acts as a default action (responds to Return key),
  /// in addition to its primary defined shortcut.
  ///
  /// - Parameters:
  ///   - defaultActionWithTitle: The text title for the button.
  ///   - primaryKey: The primary `KeyEquivalent` for the button (e.g., first letter of title).
  ///                 If nil, only the Return key will be its shortcut.
  ///   - primaryModifiers: The `EventModifiers` for the primary shortcut. Default is `.command` if primaryKey is not nil.
  ///   - displayShortcutOverlay: Whether to display the primary shortcut hint. Default is `true`.
  ///   - layoutDirection: The layout direction for label and shortcut hint. Default is `.vertical`.
  ///   - shortcutVerticalPadding: Padding for vertical layout. Default is `4`.
  ///   - customPadding: Custom padding to override calculated amounts.
  ///   - accessibilityIdentifierMainButton: Accessibility ID for the main button.
  ///   - action: The action to perform.
  public init(
    defaultActionWithTitle title: String,
    primaryKey: KeyEquivalent? = nil, // User can explicitly provide a primary key
    primaryModifiers: EventModifiers? = nil, // User can explicitly provide primary modifiers
    displayShortcutOverlay: Bool = true,
    layoutDirection: ShortcutButtonLayoutDirection = .vertical,
    shortcutVerticalPadding: CGFloat = 4,
    customPadding: CGFloat? = nil,
    accessibilityIdentifierMainButton: String? = nil,
    action: @escaping () -> Void
  ) where LabelContent == Text {
    // Determine primary key and modifiers
    let actualPrimaryKey: KeyEquivalent?
    let actualPrimaryModifiers: EventModifiers
    
    if let pk = primaryKey {
      actualPrimaryKey = pk
      actualPrimaryModifiers = primaryModifiers ?? [] // If key provided, modifiers can be empty
    } else if let firstChar = title.first?.lowercased() {
      actualPrimaryKey = KeyEquivalent(Character(firstChar))
      actualPrimaryModifiers = primaryModifiers ?? .command // Default to command if auto-deriving from title
    } else {
      actualPrimaryKey = nil // No title, no primary key specified
      actualPrimaryModifiers = primaryModifiers ?? []
    }
    
    self.init(
      initialKey: actualPrimaryKey,
      initialModifiers: actualPrimaryModifiers,
      displayShortcutOverlay: displayShortcutOverlay,
      allowShortcutAssignment: false, // Default actions typically not reassignable
      showAssignShortcutIcon: false,
      isDefaultActionEquivalent: true, // Key change: THIS makes it respond to Return
      layoutDirection: layoutDirection,
      shortcutVerticalPadding: shortcutVerticalPadding,
      customPadding: customPadding,
      title: title,
      action: action,
      accessibilityIdentifierMainButton: accessibilityIdentifierMainButton,
      accessibilityIdentifierAssignButton: nil
    )
  }
  
  
  /// Initializes a shortcut button with a text title and automatically derives a Command + FirstLetter shortcut.
  public init(
    _ title: String,
    displayShortcutOverlay: Bool = true,
    allowShortcutAssignment: Bool = false,
    showAssignShortcutIcon: Bool = false,
    isDefaultActionEquivalent: Bool = false, // Added isDefaultActionEquivalent
    layoutDirection: ShortcutButtonLayoutDirection = .vertical,
    shortcutVerticalPadding: CGFloat = 4,
    customPadding: CGFloat? = nil,
    accessibilityIdentifierMainButton: String? = nil,
    action: @escaping () -> Void
  ) where LabelContent == Text {
    let firstCharKey: KeyEquivalent? = title.first.map { KeyEquivalent(Character($0.lowercased())) }
    
    self.init(
      initialKey: firstCharKey,
      initialModifiers: .command,
      displayShortcutOverlay: displayShortcutOverlay,
      allowShortcutAssignment: allowShortcutAssignment,
      showAssignShortcutIcon: showAssignShortcutIcon,
      isDefaultActionEquivalent: isDefaultActionEquivalent, // Pass through
      layoutDirection: layoutDirection,
      shortcutVerticalPadding: shortcutVerticalPadding,
      customPadding: customPadding,
      title: title,
      action: action,
      accessibilityIdentifierMainButton: accessibilityIdentifierMainButton,
      accessibilityIdentifierAssignButton: nil
    )
  }
  
  
  /// Initializes a shortcut button with a text title and explicit shortcut parameters.
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true,
    allowShortcutAssignment: Bool = false,
    showAssignShortcutIcon: Bool = false,
    isDefaultActionEquivalent: Bool = false, // Added isDefaultActionEquivalent
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
      allowShortcutAssignment: allowShortcutAssignment,
      showAssignShortcutIcon: showAssignShortcutIcon,
      isDefaultActionEquivalent: isDefaultActionEquivalent, // Pass through
      layoutDirection: layoutDirection,
      shortcutVerticalPadding: shortcutVerticalPadding,
      customPadding: customPadding,
      action: action,
      accessibilityIdentifierMainButton: accessibilityIdentifierMainButton,
      accessibilityIdentifierAssignButton: accessibilityIdentifierAssignButton,
      label: { Text(title) }
    )
  }
  
  /// Initializes a shortcut button with custom label content and explicit shortcut parameters (most flexible).
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true,
    allowShortcutAssignment: Bool = false,
    showAssignShortcutIcon: Bool = false,
    isDefaultActionEquivalent: Bool = false, // NEW: Parameter to make it also default
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
    self.allowShortcutAssignment = allowShortcutAssignment
    self.showAssignShortcutIcon = showAssignShortcutIcon
    self.isDefaultActionEquivalent = isDefaultActionEquivalent // Store it
    self.layoutDirection = layoutDirection
    self.shortcutVerticalPadding = shortcutVerticalPadding
    self.customPadding = customPadding
    self.accessibilityIdentifierMainButton = accessibilityIdentifierMainButton
    self.accessibilityIdentifierAssignButton = accessibilityIdentifierAssignButton
  }
  
  // ... (keyEquivalentDisplayString, modifiersDisplayString, etc. remain the same) ...
  func keyEquivalentDisplayString(for key: KeyEquivalent) -> String {
    let char_fb = key.character
    if char_fb == KeyEquivalent.space.character { return "Space" }
    if char_fb == KeyEquivalent.return.character { return "↩" }
    // ... rest of the conditions
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
    if char_fb == KeyEquivalent.pageDown.character { return "⇟" } // Typo fixed: return "⇟"
    if char_fb == KeyEquivalent.clear.character { return "Clear" }
    else {
      if char_fb.unicodeScalars.first?.properties.generalCategory == .control { return "?" }
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
    // Don't show "↩" if it's the primary key and isDefaultActionEquivalent is true,
    // unless displayShortcutOverlay is specifically for it.
    // This logic could be refined if the "↩" display needs more nuance.
    if isDefaultActionEquivalent && key.character == KeyEquivalent.return.character && !displayShortcutOverlay {
      // If it's a default action whose primary key is .return, and overlay is off for it,
      // don't show any shortcut string. This avoids showing "↩" by default for these.
      // If another primary key is set, that one will be shown.
      return nil
    }
    let modString = modifiersDisplayString(for: currentShortcutModifiers)
    return "\(modString)\(keyEquivalentDisplayString(for: key))"
  }
  
  private func shouldShowShortcutTextInfo() -> Bool {
    // Only show the specific "Press new shortcut..." if assignment is enabled for this button.
    let showAssignText = allowShortcutAssignment && isAssigningShortcut
    
    // Show general shortcut info if:
    // 1. Overlay is enabled AND
    // 2. We are assigning OR there's a shortcut to display (or no shortcut is set yet) AND
    // 3. Keyboard is connected.
    return displayShortcutOverlay &&
    (showAssignText || shortcutDisplayString != nil || currentShortcutKey == nil) &&
    externalKeyboardMonitor.isExternalKeyboardConnected
  }
  
  @ViewBuilder
  private var shortcutTextInfoViewForOverlay: some View {
    if allowShortcutAssignment && isAssigningShortcut {
      Text("Press new shortcut...")
        .font(.caption)
        .foregroundColor(.accentColor)
    } else if let shortcutStr = shortcutDisplayString {
      Text(shortcutStr)
        .font(.caption)
        .foregroundColor(.secondary)
    } else if currentShortcutKey == nil && displayShortcutOverlay { // Only show (No shortcut) if overlay is on
      // And also avoid showing "(No shortcut)" if this is a default action button
      // whose primary key is .return and its overlay is off.
      if !(isDefaultActionEquivalent && (currentShortcutKey == nil || currentShortcutKey?.character == KeyEquivalent.return.character)) {
        Text("(No shortcut)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
  
  @ViewBuilder
  private var labelWithOverlaidShortcut: some View {
    // ... (same as before)
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
              .padding(.trailing, customPadding ?? 8)
          }
        }
      }
  }
  
  @ViewBuilder
  private var assignShortcutButtonView: some View {
    // ... (same as before)
    if allowShortcutAssignment {
      Button {
        isAssigningShortcut.toggle()
      } label: {
        Image(systemName: isAssigningShortcut ? "keyboard.fill" : "keyboard")
      }
      .buttonStyle(PlainButtonStyle())
      .accessibilityLabel(isAssigningShortcut ? "Cancel shortcut assignment" : "Assign shortcut")
      .accessibilityIdentifier(accessibilityIdentifierAssignButton ?? "KeyboardAwareShortcutButton.assignButton")
    }
  }
  
  public var body: some View {
    let buttonContent = HStack(alignment: .center, spacing: 4) {
      labelWithOverlaidShortcut
    }
    
    // Main button with its primary shortcut
    let actualButton = Button(action: {
      if allowShortcutAssignment && isAssigningShortcut {
        isAssigningShortcut = false
      } else {
        action()
      }
    }) {
      buttonContent
    }
      .accessibilityIdentifier(accessibilityIdentifierMainButton ?? "KeyboardAwareShortcutButton.mainButton")
    
    let mainButtonWithPrimaryShortcut = Group {
      if let sk = currentShortcutKey {
        // Avoid applying .keyboardShortcut for .return if it's handled by isDefaultActionEquivalent
        if !(isDefaultActionEquivalent && sk.character == KeyEquivalent.return.character) {
          actualButton.keyboardShortcut(sk, modifiers: currentShortcutModifiers)
        } else {
          actualButton // Primary is .return, handled by the default action mechanism
        }
      } else {
        actualButton // No primary shortcut key
      }
    }
    
    // Container for the main button and the (optional) assign icon
    let buttonAndAssignIcon = HStack(spacing: 8) {
      mainButtonWithPrimaryShortcut
      
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
        if allowShortcutAssignment && showAssignShortcutIcon && externalKeyboardMonitor.isExternalKeyboardConnected && displayShortcutOverlay {
          assignShortcutButtonView
        }
      }
    }
    
    // Apply the .onKeyPress for assignment IF enabled
    let viewWithAssignmentHandling = buttonAndAssignIcon
      .if(allowShortcutAssignment && isAssigningShortcut) { view_in_transform in
        Group {
          if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            view_in_transform.onKeyPress(phases: .down) { press in
              let keyChar = press.key.character
              let isCharOrNumber = keyChar.isLetter || keyChar.isNumber
              
              let isAllowedSingleKey = keyChar == KeyEquivalent.space.character ||
              keyChar == KeyEquivalent.return.character ||
              keyChar == KeyEquivalent.escape.character ||
              keyChar == KeyEquivalent.tab.character ||
              press.key.isArrowKey ||
              press.key.isFunctionKey
              
              if press.modifiers.isEmpty && isCharOrNumber && !isAllowedSingleKey {
#if DEBUG
                print("⚠️ Shortcut Assignment: Plain character '\(keyChar)' without modifiers is not recommended. Shortcut not assigned.")
#endif
                self.isAssigningShortcut = false
                return .handled
              }
              
              self.currentShortcutKey = press.key
              self.currentShortcutModifiers = press.modifiers
              self.isAssigningShortcut = false
              
#if DEBUG
              if let newKey = self.currentShortcutKey {
                print("✅ Shortcut Assigned: \(self.modifiersDisplayString(for: self.currentShortcutModifiers))\(self.keyEquivalentDisplayString(for: newKey))")
              }
#endif
              return .handled
            }
          } else {
            view_in_transform
          }
        }
      }
    
    // Apply the .keyboardShortcut for the default action (Return key) IF isDefaultActionEquivalent is true
    // This is separate so it doesn't interfere with the primary shortcut display or assignment.
    return viewWithAssignmentHandling.if(isDefaultActionEquivalent) { view in
        view.keyboardShortcut(.return, modifiers: [])
      }
  }
}
