//
//  KeyEventMonitor.swift
//  ara
//
//  Intercepts palette navigation keys before they reach the search field.
//

import AppKit
import SwiftUI

/// Keys the palette responds to.
enum PaletteKey {
    case escape
    case up
    case down
    case `return`

    /// Maps a raw key event, ignoring anything with modifiers held.
    init?(event: NSEvent) {
        let modifiers: NSEvent.ModifierFlags = [.command, .control, .option]
        guard event.modifierFlags.intersection(modifiers).isEmpty else { return nil }

        switch Int(event.keyCode) {
        case 53: self = .escape
        case 126: self = .up
        case 125: self = .down
        case 36, 76: self = .return   // Return and keypad Enter
        default: return nil
        }
    }
}

private struct KeyEventMonitorModifier: ViewModifier {
    let handler: (PaletteKey) -> Void

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear(perform: install)
            .onDisappear(perform: remove)
    }

    /// A *local* monitor sees key events before they are dispatched to the
    /// responder chain. That is what makes arrow keys usable here: the search
    /// field is first responder and would otherwise consume (and beep at) them.
    private func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Only act when the overlay itself owns keyboard focus.
            guard event.window is OverlayPanel,
                  let key = PaletteKey(event: event)
            else { return event }

            handler(key)
            return nil // Swallow the event so AppKit does not also handle it.
        }
    }

    private func remove() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

extension View {
    /// Handles palette navigation keys for as long as the view is on screen.
    func onPaletteKey(_ handler: @escaping (PaletteKey) -> Void) -> some View {
        modifier(KeyEventMonitorModifier(handler: handler))
    }
}
