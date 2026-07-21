//
//  TriggerCoordinator.swift
//  ara
//
//  Wires every way of summoning the overlay to the overlay itself.
//

import AppKit

/// Routes every way of summoning Ara to the overlay.
@MainActor
final class TriggerCoordinator {

    private let hotkeyManager = HotkeyManager()
    private var statusItem: NSStatusItem?

    /// Installs every trigger source.
    func start() {
        installGlobalHotkey()
        installStatusItem()
    }

    // MARK: - Routing

    func toggleOverlay() {
        OverlayWindowManager.shared.toggle()
    }

    func showOverlay() {
        OverlayWindowManager.shared.show()
    }

    // MARK: - Sources

    private func installGlobalHotkey() {
        let shortcut = Shortcut.toggleOverlay
        hotkeyManager.register(shortcut) { [weak self] in
            self?.toggleOverlay()
        }
    }

    /// Menu bar fallback for opening and quitting an accessory app.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        item.button?.image = NSImage(
            systemSymbolName: "command",
            accessibilityDescription: "Ara"
        )

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Show Overlay (\(Shortcut.toggleOverlay))",
            action: #selector(showFromMenuBar),
            keyEquivalent: ""
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Ara",
            action: #selector(quit),
            keyEquivalent: "q"
        ).target = self

        item.menu = menu
        statusItem = item
    }

    @objc private func showFromMenuBar() {
        showOverlay()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
