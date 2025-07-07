import SwiftUI
import Combine

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
    let newValue: Bool
    
    // On the simulator, the Mac's keyboard is always considered a hardware keyboard.
    // GCKeyboard.coalesced will always be non-nil unless you manually disconnect it
    // from the Simulator's "Hardware" menu. For many testing purposes, it's easier
    // to treat the simulator as if no keyboard is attached by default.
#if targetEnvironment(simulator)
    // Use the actual value on the simulator to respect the "Connect Hardware Keyboard" menu setting.
    // If you wanted to ALWAYS force it to false on the sim, you would just do: `newValue = false`
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) {
      newValue = (GCKeyboard.coalesced != nil)
    } else {
      newValue = false
    }
#else
    // On a physical device, this correctly reflects the connection status.
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) {
      newValue = (GCKeyboard.coalesced != nil)
    } else {
      newValue = false
    }
#endif
    
    // Only publish a change if the value has actually changed.
    if isExternalKeyboardConnected != newValue {
      isExternalKeyboardConnected = newValue
#if DEBUG
      let environment =
#if targetEnvironment(simulator)
      "Simulator"
#else
      "Device"
#endif
      print("🔑 ExternalKeyboardMonitor: Status changed on \(environment) → \(isExternalKeyboardConnected)")
#endif
    }
  }
  
  private func observeKeyboardConnections() {
#if canImport(GameController)
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) {
      keyboardConnectObserver = NotificationCenter.default.addObserver(
        forName: .GCKeyboardDidConnect, object: nil, queue: .main
      ) { [weak self] _ in
        // No need for an extra Task block here, as we specified .main queue.
        self?.updateExternalKeyboardStatus()
      }
      
      keyboardDisconnectObserver = NotificationCenter.default.addObserver(
        forName: .GCKeyboardDidDisconnect, object: nil, queue: .main
      ) { [weak self] _ in
        // No need for an extra Task block here, as we specified .main queue.
        self?.updateExternalKeyboardStatus()
      }
    }
#endif
  }
}
