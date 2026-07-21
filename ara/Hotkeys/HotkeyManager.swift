//
//  HotkeyManager.swift
//  ara
//
//  System-wide hotkey registration.
//

import Carbon.HIToolbox
import Foundation
import os

/// Registers system-wide shortcuts and invokes a closure when one fires.
///
/// Deliberately knows nothing about windows, overlays, or SwiftUI — it maps a
/// `Shortcut` to an action and stops there. Callers decide what the action does.
///
/// Carbon's `RegisterEventHotKey` is used rather than an `NSEvent` global
/// monitor because it needs no Accessibility permission: the shortcut works the
/// moment the app launches, with no consent dialog. Carbon is long-deprecated in
/// spirit but this API remains the supported route for system-wide hotkeys and
/// has no modern replacement.
@MainActor
final class HotkeyManager {

    private static let logger = Logger(subsystem: "com.ara.app", category: "Hotkeys")

    /// Four-character signature identifying this app's hotkeys to Carbon.
    /// `nonisolated` so the C callback (which cannot be main-actor isolated)
    /// can read it. Safe: an immutable `Sendable` constant.
    fileprivate nonisolated static let signature: OSType = {
        let chars = Array("ARAX".utf8)
        return chars.reduce(OSType(0)) { ($0 << 8) | OSType($1) }
    }()

    private var actions: [UInt32: () -> Void] = [:]
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextID: UInt32 = 1

    deinit {
        // `unregisterAll()` is main-actor isolated; tear down directly here.
        for ref in hotkeyRefs.values { UnregisterEventHotKey(ref) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    // MARK: - Registration

    /// Registers `shortcut` system-wide.
    ///
    /// - Returns: `true` on success. Registration fails when another app already
    ///   owns the combination; that is reported and survivable, never fatal.
    @discardableResult
    func register(_ shortcut: Shortcut, action: @escaping () -> Void) -> Bool {
        guard installEventHandlerIfNeeded() else { return false }

        let id = nextID
        nextID += 1

        let hotkeyID = EventHotKeyID(signature: Self.signature, id: id)
        var ref: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.key.carbonKeyCode,
            shortcut.modifiers.carbonFlags,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr, let ref else {
            Self.logger.error(
                """
                Could not register global hotkey \(shortcut.description, privacy: .public) \
                (OSStatus \(status)). It is most likely already claimed by another \
                application or a system shortcut. Ara will keep running — use the \
                menu bar item to open the overlay.
                """
            )
            return false
        }

        actions[id] = action
        hotkeyRefs[id] = ref
        return true
    }

    func unregisterAll() {
        for ref in hotkeyRefs.values { UnregisterEventHotKey(ref) }
        hotkeyRefs.removeAll()
        actions.removeAll()
    }

    // MARK: - Carbon plumbing

    /// Installs the single application-wide handler that receives every hotkey
    /// press, lazily on first registration.
    private func installEventHandlerIfNeeded() -> Bool {
        guard eventHandler == nil else { return true }

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // `self` is passed unretained as user data: the manager outlives the
        // handler (it is torn down in `deinit`), so there is no dangling risk.
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventCallback,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            Self.logger.error(
                """
                Could not install the Carbon hotkey event handler (OSStatus \(status)). \
                Global shortcuts will be unavailable; the menu bar item still works.
                """
            )
            eventHandler = nil
            return false
        }

        return true
    }

    /// Called from the Carbon callback once the hotkey ID is decoded.
    fileprivate func handleHotkey(id: UInt32) {
        actions[id]?()
    }
}

/// C callback trampoline. Must be a bare function — Carbon takes a function
/// pointer, so this cannot be a closure that captures context.
///
/// `nonisolated` is required: this target defaults declarations to `@MainActor`,
/// and an actor-isolated function cannot be converted to `@convention(c)`.
private nonisolated func hotkeyEventCallback(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard status == noErr, hotkeyID.signature == HotkeyManager.signature else {
        return OSStatus(eventNotHandledErr)
    }

    // Carbon dispatches hotkey events on the main run loop, so main-actor state
    // is safe to touch here without hopping (which would also lose ordering).
    MainActor.assumeIsolated {
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotkey(id: hotkeyID.id)
    }

    return noErr
}
