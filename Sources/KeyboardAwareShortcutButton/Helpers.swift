import SwiftUI

// MARK: - KeyEquivalent Extensions (Internal)

extension KeyEquivalent {
  var isArrowKey: Bool {
    let c = self.character
    return c == KeyEquivalent.upArrow.character ||
           c == KeyEquivalent.downArrow.character ||
           c == KeyEquivalent.leftArrow.character ||
           c == KeyEquivalent.rightArrow.character
  }
  
  var isFunctionKey: Bool {
    // Note: KeyEquivalent.f1, .f2 etc. were added in iOS 15/macOS 12.
    // If you add specific checks, compare characters: self.character == KeyEquivalent.f1.character
    return false // Placeholder as original F-key cases were commented out
  }
}

// MARK: - View Modifier (Internal or Public if you want to expose it)

extension View {
    /// Conditionally applies a transform to a view.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
