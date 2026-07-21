//
//  OverlayWindowManager.swift
//  ara
//
//  Owns the lifetime and placement of the overlay panel.
//

import AppKit
import SwiftUI

/// Single owner of the overlay panel.
///
/// The panel is created lazily and then reused: showing and hiding never
/// destroys it, so the palette is always cheap to reopen.
@MainActor
final class OverlayWindowManager {

    static let shared = OverlayWindowManager()

    /// Design size of the palette.
    private static let overlaySize = CGSize(width: 480, height: 320)

    /// Gap between the palette and the screen edges it is anchored to.
    private static let screenMargin: CGFloat = 16

    private var panel: OverlayPanel?
    private let model = CommandPaletteModel(commands: ApplicationCatalog().commands())

    /// The app that was frontmost when the overlay was summoned, so focus can
    /// be handed back on hide.
    private var previouslyActiveApp: NSRunningApplication?

    private init() {
        observeAppDeactivation()
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    // MARK: - Visibility

    func show() {
        let panel = panel ?? makePanel()

        // Captured before activating ourselves, otherwise the frontmost app is
        // already Ara. Guarding on the bundle identifier keeps a second `show()`
        // from overwriting the real previous app with ourselves.
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            previouslyActiveApp = frontmost
        }

        position(panel, on: activeScreen())

        // Bring the app forward so the borderless panel can take key status,
        // then hand it focus. Order matters: activating after `makeKey` can
        // bounce first-responder status back to another window.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // Clears the query and re-asserts search focus. Done after the panel is
        // key, and every time: the panel is reused across openings, so SwiftUI's
        // `onAppear` fires only for the first presentation.
        model.beginPresentation()
    }

    /// Dismisses the overlay and hands focus back to the app it interrupted.
    func hide() {
        hide(restoringFocus: true)
    }

    /// Dismisses after a command runs. Commands may intentionally focus another
    /// app, so restoring the previous app would undo the command's effect.
    func hideAfterCommand() {
        hide(restoringFocus: false)
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    /// - Parameter restoringFocus: whether to reactivate the app that was
    ///   frontmost when the overlay opened. False when the overlay is closing
    ///   *because* the user moved to another app — that app already has focus,
    ///   and restoring would drag them somewhere they did not ask to go.
    private func hide(restoringFocus: Bool) {
        guard isVisible else { return }

        panel?.orderOut(nil)

        if restoringFocus {
            // Return the user to whatever they were doing. Without this the
            // overlay leaves Ara active, and the app they came from stays
            // unfocused.
            if let previouslyActiveApp, !previouslyActiveApp.isTerminated {
                previouslyActiveApp.activate()
            } else {
                // Nothing to restore — step aside rather than holding activation.
                NSApp.hide(nil)
            }
        }

        previouslyActiveApp = nil
    }

    // MARK: - Click-outside dismissal

    /// Dismisses the overlay when the user clicks away, the way Spotlight does.
    ///
    /// Ara has exactly one window, so "the app stopped being active" and "the
    /// user clicked outside the palette" are the same event — no click or
    /// mouse-location tracking is needed.
    private func observeAppDeactivation() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delivered on the main queue, so main-actor state is safe here.
            // `self` rather than `.shared`: the observer is installed from
            // within `init`, where touching the singleton would re-enter its
            // own lazy initialization.
            MainActor.assumeIsolated {
                self?.hide(restoringFocus: false)
            }
        }
    }

    // MARK: - Construction

    private func makePanel() -> OverlayPanel {
        let panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: Self.overlaySize)
        )

        let hostingView = NSHostingView(rootView: OverlayView(model: model))
        // Let SwiftUI's own background (and its rounded clip) define the look.
        hostingView.layer?.backgroundColor = .clear
        panel.contentView = hostingView

        self.panel = panel
        return panel
    }

    // MARK: - Placement

    /// The screen the user is currently working on: the one owning the key
    /// window, else the one under the pointer, else the primary display.
    private func activeScreen() -> NSScreen? {
        if let screen = NSApp.keyWindow?.screen { return screen }
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            return screen
        }
        return NSScreen.main
    }

    /// Anchors the palette to the bottom-left of `screen`.
    ///
    /// `visibleFrame` is used rather than `frame` so the palette clears the Dock
    /// and menu bar. In AppKit's coordinate space `minY` is the bottom edge.
    private func position(_ panel: NSPanel, on screen: NSScreen?) {
        guard let frame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let origin = CGPoint(
            x: frame.minX + Self.screenMargin,
            y: frame.minY + Self.screenMargin
        )

        panel.setFrame(NSRect(origin: origin, size: Self.overlaySize), display: true)
    }
}
