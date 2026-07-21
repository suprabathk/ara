//
//  OverlayPanel.swift
//  ara
//
//  AppKit panel that hosts the overlay. SwiftUI has no equivalent for a
//  borderless, floating, key-accepting window, so this is bridged by hand.
//

import AppKit

/// A borderless floating panel that behaves like a command palette.
final class OverlayPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            // Deliberately NOT `.nonactivatingPanel`. That mask lets a panel
            // take events without activating its app, which is right for a
            // tool palette floating over another app's document — and wrong
            // here. Ara is typed into, so it must genuinely own keyboard
            // focus; with that mask the panel takes key status and then loses
            // it back to the previously frontmost app.
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Float above ordinary windows without reaching screen-saver levels.
        level = .floating

        // The rounded corners are drawn by SwiftUI, so the panel itself must be
        // transparent — otherwise the square backing shows through the corners.
        isOpaque = false
        backgroundColor = .clear

        // The window draws no shadow of its own: the content is a set of
        // detached islands over a fully transparent panel, so an AppKit shadow
        // would outline the whole rectangle. Each island casts its own instead.
        hasShadow = false

        // A borderless panel is not key by default; both of these are required
        // for the search field to take focus the moment the overlay appears.
        becomesKeyOnlyIfNeeded = false
        hidesOnDeactivate = false

        // Dragging is off: empty panel space now dismisses on click, and the
        // palette re-anchors to the bottom-left on every show, so a moved
        // window would not stay moved anyway.
        isMovableByWindowBackground = false
        animationBehavior = .utilityWindow

        // Ride along to whichever Space the user is on, and sit above full
        // screen apps. `.transient` is intentionally absent: it asks the system
        // to hide the window whenever the owning app deactivates, which fights
        // the panel for focus rather than merely tidying Mission Control.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isExcludedFromWindowsMenu = true
        isFloatingPanel = true
    }

    // Borderless windows return `false` for both of these by default, which
    // would leave the palette unable to receive keyboard input at all.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Routes Escape to a close, matching palette conventions.
    ///
    /// `cancelOperation(_:)` is the standard responder-chain hook for Escape;
    /// handling it here covers the case where the focused text field would
    /// otherwise swallow the key (or beep).
    override func cancelOperation(_ sender: Any?) {
        OverlayWindowManager.shared.hide()
    }
}
