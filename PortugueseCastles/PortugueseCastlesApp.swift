//
// PortugueseCastlesApp.swift
//
// This is the entry point for the Portuguese Castles application.
// It defines the app structure and sets up the initial view hierarchy.
// The app uses SwiftUI's App protocol to define the application lifecycle
// and scene structure.
//

import SwiftUI

/// Main application entry point
/// The @main attribute identifies this struct as the application's entry point
@main
struct PortugueseCastlesApp: App {
    /// Defines the scene structure for the application
    /// Returns a Scene that contains the application's main window group
    var body: some Scene {
        WindowGroup {
            // ContentView is the root view of the application
            // It handles all the main UI components and user interactions
            ContentView()
        }
    }
} 