import SwiftUI // For @MainActor, @Published, ObservableObject
import Combine // For @Published

#if canImport(GameController)
import GameController
#endif

/// Publishes the connection state of a hardware keyboard.
/// Supported on iOS 14+, macOS 11+, tvOS 14+.
@MainActor
public final class ExternalKeyboardMonitor: ObservableObject {
  
  @Published public private(set) var isExternalKeyboardConnected = false
  
  public init() {
    // Defer the initial status update to ensure 'self' is fully initialized
    // and the call happens cleanly within the main actor context.
    Task { @MainActor [weak self] in
      self?.updateExternalKeyboardStatus()
    }
    observeKeyboardConnections()
  }
  
  deinit {
    if let o = keyboardConnectObserver { NotificationCenter.default.removeObserver(o) }
    if let o = keyboardDisconnectObserver { NotificationCenter.default.removeObserver(o) }
  }
  
  private var keyboardConnectObserver: Any?
  private var keyboardDisconnectObserver: Any?
  
  private func updateExternalKeyboardStatus() {
    // This method is implicitly @MainActor because the class is @MainActor.
#if canImport(GameController)
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) {
      let previous = isExternalKeyboardConnected
      isExternalKeyboardConnected = (GCKeyboard.coalesced != nil)
      if previous != isExternalKeyboardConnected {
#if DEBUG
        // Consider using a Logger for package libraries instead of print
        // if you want more control over debug output for consumers.
        print("🔑 ExternalKeyboardMonitor: Status changed → \(isExternalKeyboardConnected)")
#endif
      }
      return
    }
#endif
    
    // Fallback for platforms / OS versions without GameController
    let previous = isExternalKeyboardConnected
    isExternalKeyboardConnected = false // Default to false if GameController isn't available/supported
    if previous != isExternalKeyboardConnected {
#if DEBUG
      print("🔑 ExternalKeyboardMonitor: Status changed (fallback) → \(isExternalKeyboardConnected)")
#endif
    }
  }
  
  private func observeKeyboardConnections() {
#if canImport(GameController)
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) {
      keyboardConnectObserver = NotificationCenter.default.addObserver(
        forName: .GCKeyboardDidConnect, object: nil, queue: .main
      ) { [weak self] _ in
        Task { @MainActor [weak self] in // Ensure main actor context for Swift 6
            self?.updateExternalKeyboardStatus()
        }
      }
      
      keyboardDisconnectObserver = NotificationCenter.default.addObserver(
        forName: .GCKeyboardDidDisconnect, object: nil, queue: .main
      ) { [weak self] _ in
        Task { @MainActor [weak self] in // Ensure main actor context for Swift 6
            self?.updateExternalKeyboardStatus()
        }
      }
    }
#endif
  }
}
