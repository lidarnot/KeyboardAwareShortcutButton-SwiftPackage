Okay, here's a `README.md` for your `KeyboardAwareShortcutButton` Swift package.


# KeyboardAwareShortcutButton

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS-blue.svg)](https://developer.apple.com/swift/)

A SwiftUI `Button` component that intelligently displays keyboard shortcut hints only when an external keyboard is connected. It also supports optional runtime shortcut assignment and can be configured to act as a default action button (responding to the Return key).

## Features

*   **Keyboard Aware Shortcut Display**: Shows shortcut hints (e.g., "⌘S") only when an external keyboard is detected.
*   **Customizable Shortcuts**: Define custom `KeyEquivalent` and `EventModifiers` for your buttons.
*   **Automatic Shortcut Derivation**: Can automatically derive a `⌘ + FirstCharacter` shortcut from a button's title.
*   **Runtime Shortcut Assignment**: (Optional) Allows users to assign their own keyboard shortcuts at runtime (requires iOS 17+, macOS 14+, tvOS 17+).
*   **Default Action Button**: (Optional) Can be configured to respond to the `Return` key, similar to a default button in a dialog.
*   **Flexible Labeling**: Use simple `String` titles or provide a custom `@ViewBuilder` for the button's label.
*   **Layout Options**: Control the layout direction (horizontal/vertical) of the shortcut hint relative to the label.
*   **Accessibility**: Supports accessibility identifiers for UI testing.
*   **Lightweight**: Minimal dependencies, primarily relying on SwiftUI and `GameController` (for keyboard detection).

## Requirements

*   **Basic Functionality & Keyboard Detection**:
    *   iOS 14.0+
    *   macOS 11.0+
    *   tvOS 14.0+
*   **Runtime Shortcut Assignment Feature (`.onKeyPress`)**:
    *   iOS 17.0+
    *   macOS 14.0+
    *   tvOS 17.0+
*   Swift 5.7+

## Installation

You can add `KeyboardAwareShortcutButton` to your project using Swift Package Manager.

1.  In Xcode, select **File > Add Packages...**
2.  Enter the repository URL: `https://github.com/your_username/KeyboardAwareShortcutButton-SwiftPackage.git` (Replace with your actual GitHub repo URL)
3.  Choose the version or branch you want to use.
4.  Add the `KeyboardAwareShortcutButton` product to your target.

## Usage

Import the package in your SwiftUI file:

```swift
import SwiftUI
import KeyboardAwareShortcutButton
```

### Basic Button with Auto-Derived Shortcut

If you provide a title, the button will attempt to use `⌘ + FirstCharacter` as its shortcut.

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            KeyboardAwareShortcutButton("Save") {
                print("Save action triggered!")
            }
            // Default shortcut: ⌘S (if an external keyboard is connected)
        }
        .padding()
    }
}
```

### Button with Explicit Shortcut

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            KeyboardAwareShortcutButton(
                initialKey: .s,
                initialModifiers: [.command, .shift],
                title: "Save All"
            ) {
                print("Save All action triggered!")
            }
            // Shortcut: ⇧⌘S (if an external keyboard is connected)
        }
        .padding()
    }
}
```

### Default Action Button

This button will respond to the `Return` key. You can optionally provide a `primaryKey` for an additional shortcut.

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            KeyboardAwareShortcutButton(
                defaultActionWithTitle: "Submit",
                primaryKey: "s", // Optional: also triggers with ⌘S
                primaryModifiers: .command
            ) {
                print("Submit action triggered!")
            }
            // Responds to Return key, and also ⌘S in this example
        }
        .padding()
    }
}
```

### Button with Shortcut Assignment Enabled

Users can click an icon to enter "assignment mode" and press their desired key combination.
**Note:** Shortcut assignment requires iOS 17+, macOS 14+, or tvOS 17+.

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            KeyboardAwareShortcutButton(
                initialKey: "p",
                initialModifiers: .option,
                allowShortcutAssignment: true, // Enable assignment
                showAssignShortcutIcon: true,  // Show the keyboard icon
                title: "Preferences"
            ) {
                print("Preferences action triggered!")
            }
            // Initial shortcut: ⌥P, user can reassign
        }
        .padding()
    }
}
```

### Custom Label Content

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            KeyboardAwareShortcutButton(
                initialKey: "o",
                initialModifiers: .command,
                action: { print("Open action!") }
            ) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Open File")
                }
            }
        }
        .padding()
    }
}
```

## Key Parameters

The `KeyboardAwareShortcutButton` has several initializers. The most flexible one includes:

*   `initialKey: KeyEquivalent?`: The key for the shortcut (e.g., `Character("s")`, `.return`, `.space`).
*   `initialModifiers: EventModifiers`: Modifiers for the shortcut (e.g., `.command`, `[.shift, .option]`).
*   `displayShortcutOverlay: Bool`: Whether to show the shortcut hint (default `true`).
*   `allowShortcutAssignment: Bool`: Enables runtime shortcut assignment (default `false`).
*   `showAssignShortcutIcon: Bool`: If assignment is allowed, shows an icon to trigger assignment mode (default `false`).
*   `isDefaultActionEquivalent: Bool`: If `true`, the button also responds to the `Return` key (default `false`).
*   `layoutDirection: ShortcutButtonLayoutDirection`: `.horizontal` or `.vertical` placement of the shortcut hint (default `.vertical`).
*   `shortcutVerticalPadding: CGFloat`: Padding for vertical layout.
*   `customPadding: CGFloat?`: Override default padding calculations.
*   `action: () -> Void`: The closure executed when the button is tapped or shortcut is triggered.
*   `label: () -> LabelContent`: A `@ViewBuilder` for the button's content.
*   `accessibilityIdentifierMainButton: String?`: Accessibility ID for the main button.
*   `accessibilityIdentifierAssignButton: String?`: Accessibility ID for the assign shortcut button.

## Components

*   **`KeyboardAwareShortcutButton`**: The main SwiftUI `View` you'll use.
*   **`ExternalKeyboardMonitor`**: An `ObservableObject` class that detects the connection status of an external hardware keyboard. This is used internally by `KeyboardAwareShortcutButton` but can also be used independently if needed.

    ```swift
    @StateObject private var keyboardMonitor = ExternalKeyboardMonitor()

    var body: some View {
        if keyboardMonitor.isExternalKeyboardConnected {
            Text("An external keyboard is connected.")
        } else {
            Text("No external keyboard detected.")
        }
    }
    ```

## How Keyboard Detection Works

The `ExternalKeyboardMonitor` uses the `GameController` framework (`GCKeyboard.coalesced != nil`) to check for the presence of a connected hardware keyboard. It listens to `.GCKeyboardDidConnect` and `.GCKeyboardDidDisconnect` notifications to update its status. On platforms or OS versions where `GameController` is unavailable for this purpose, it defaults to reporting no external keyboard connected.

## Contributing

Contributions, issues, and feature requests are welcome! Please feel free to open an issue or submit a pull request.

## License

This package is available under the MIT license. See the LICENSE file for more info. (You'll need to add a LICENSE file to your repo, typically MIT).
