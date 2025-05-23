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
  let accessibilityIdentifierAssignButton: String? // Still here for API consistency if enabled
  
  @State private var currentShortcutKey: KeyEquivalent?
  @State private var currentShortcutModifiers: EventModifiers
  let displayShortcutOverlay: Bool
  
  // --- NEW PARAMETERS ---
  /// Controls whether the shortcut assignment UI (icon and key press listening) is enabled.
  let allowShortcutAssignment: Bool
  /// Controls whether the "Assign Shortcut" icon is shown (only if assignment is also allowed and on iOS 17+).
  let showAssignShortcutIcon: Bool
  // --- END NEW PARAMETERS ---
  
  // isAssigningShortcut will only become true if allowShortcutAssignment is true
  @State private var isAssigningShortcut: Bool = false
  
  private let estimatedCaptionLineHeight: CGFloat = 16
  private let estimatedHorizontalShortcutTextWidth: CGFloat = 75
  
  let customPadding: CGFloat?
  
  @StateObject private var externalKeyboardMonitor = ExternalKeyboardMonitor()
  
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true,
    // --- NEW PARAMETERS WITH DEFAULTS ---
    allowShortcutAssignment: Bool = false, // Default to false
    showAssignShortcutIcon: Bool = false,   // Default to false
    // --- END NEW PARAMETERS ---
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
      allowShortcutAssignment: allowShortcutAssignment, // Pass through
      showAssignShortcutIcon: showAssignShortcutIcon,   // Pass through
      layoutDirection: layoutDirection,
      shortcutVerticalPadding: shortcutVerticalPadding,
      customPadding: customPadding,
      action: action,
      accessibilityIdentifierMainButton: accessibilityIdentifierMainButton,
      accessibilityIdentifierAssignButton: accessibilityIdentifierAssignButton,
      label: { Text(title) }
    )
  }
  
  public init(
    initialKey: KeyEquivalent? = nil,
    initialModifiers: EventModifiers = .command,
    displayShortcutOverlay: Bool = true,
    // --- NEW PARAMETERS WITH DEFAULTS ---
    allowShortcutAssignment: Bool = false, // Default to false
    showAssignShortcutIcon: Bool = false,   // Default to false
    // --- END NEW PARAMETERS ---
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
    self.layoutDirection = layoutDirection
    self.shortcutVerticalPadding = shortcutVerticalPadding
    self.customPadding = customPadding
    self.accessibilityIdentifierMainButton = accessibilityIdentifierMainButton
    self.accessibilityIdentifierAssignButton = accessibilityIdentifierAssignButton
  }
  
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
    let modString = modifiersDisplayString(for: currentShortcutModifiers)
    return "\(modString)\(keyEquivalentDisplayString(for: key))"
  }
  
  private func shouldShowShortcutTextInfo() -> Bool {
    displayShortcutOverlay &&
    ( (allowShortcutAssignment && isAssigningShortcut) || shortcutDisplayString != nil || currentShortcutKey == nil) && // Modified condition
    externalKeyboardMonitor.isExternalKeyboardConnected
  }
  
  @ViewBuilder
  private var shortcutTextInfoViewForOverlay: some View {
    // Only show "Press new shortcut..." if assignment is allowed AND we are assigning
    if allowShortcutAssignment && isAssigningShortcut {
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
              .padding(.trailing, customPadding ?? 8)
          }
        }
      }
  }
  
  @ViewBuilder
  private var assignShortcutButtonView: some View {
    // This button only makes sense if assignment is allowed
    if allowShortcutAssignment {
      Button {
        isAssigningShortcut.toggle()
      } label: {
        Image(systemName: isAssigningShortcut ? "keyboard.fill" : "keyboard")
          .foregroundColor(isAssigningShortcut ? .blue : .accentColor)
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
    
    let actualButton = Button(action: {
      // If we are in assignment mode (and assignment is allowed), tapping the main button cancels assignment.
      if allowShortcutAssignment && isAssigningShortcut {
        isAssigningShortcut = false
      } else {
        action()
      }
    }) {
      buttonContent
    }
//      .buttonStyle(PlainButtonStyle())
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
      
      // Conditionally include the assignShortcutButtonView
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
        // Show icon ONLY IF:
        // 1. OS supports it (iOS 17+)
        // 2. Feature is enabled (`allowShortcutAssignment` AND `showAssignShortcutIcon`)
        // 3. External keyboard is connected
        // 4. Shortcut overlay is generally displayed
        if allowShortcutAssignment && showAssignShortcutIcon && externalKeyboardMonitor.isExternalKeyboardConnected && displayShortcutOverlay {
          assignShortcutButtonView
        }
      }
    }
    
    // Apply .onKeyPress modifier conditionally for shortcut assignment
    // ONLY if allowShortcutAssignment is true
    return viewHierarchy
      .if(allowShortcutAssignment && isAssigningShortcut) { view_in_transform in // Modified condition
        Group {
          if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            view_in_transform.onKeyPress(phases: .down) { press in
              // ... (key press handling logic remains the same) ...
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
  }
}
