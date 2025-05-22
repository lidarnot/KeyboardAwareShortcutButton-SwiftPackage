// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "KeyboardAwareShortcutButton",
  platforms: [
    .iOS(.v16),
    .macOS(.v12), // For ExternalKeyboardMonitor (GCKeyboard)
    .tvOS(.v14)   // For ExternalKeyboardMonitor (GCKeyboard)
    // watchOS is excluded as GCKeyboard and .onKeyPress are less relevant or have different availability
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "KeyboardAwareShortcutButton",
      targets: ["KeyboardAwareShortcutButton"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "KeyboardAwareShortcutButton",
      dependencies: []),
    .testTarget( // Optional: if you plan to add tests
      name: "KeyboardAwareShortcutButtonTests",
      dependencies: ["KeyboardAwareShortcutButton"]),
  ]
)
