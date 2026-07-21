//
//  AppDelegate.swift
//  ara
//
//  Bridges NSApplication lifecycle events onto the overlay manager.
//

import AppKit

/// Minimal delegate: the app's job is to keep the overlay reachable.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let triggers = TriggerCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ara runs as an accessory: no Dock icon, no menu bar presence, no
        // standard window. `INFOPLIST_KEY_LSUIElement` already sets this before
        // launch (which avoids a Dock icon flash); this call keeps the
        // behaviour explicit and correct even if that build setting is lost.
        NSApp.setActivationPolicy(.accessory)

        triggers.start()
        triggers.showOverlay()
    }

    /// Hiding the overlay must never terminate the app — it is a background
    /// process that stays resident waiting to be summoned again.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
