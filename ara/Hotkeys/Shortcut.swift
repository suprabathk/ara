//
//  Shortcut.swift
//  ara
//
//  Key-combination model. Nothing here knows how a shortcut gets registered.
//

import Carbon.HIToolbox
import Foundation

/// A physical key, identified by its virtual key code.
///
/// Codes are positional, not character-based: `.a` is the key in the QWERTY "A"
/// position on every layout. That matches how system-wide shortcuts behave.
struct Key: Hashable, Sendable {
    /// Carbon virtual key code (`kVK_*`).
    let carbonKeyCode: UInt32
    /// Label used when describing the shortcut to a human.
    let displayName: String

    init(carbonKeyCode: Int, displayName: String) {
        self.carbonKeyCode = UInt32(carbonKeyCode)
        self.displayName = displayName
    }
}

extension Key {
    static let a = Key(carbonKeyCode: kVK_ANSI_A, displayName: "A")
    static let b = Key(carbonKeyCode: kVK_ANSI_B, displayName: "B")
    static let c = Key(carbonKeyCode: kVK_ANSI_C, displayName: "C")
    static let d = Key(carbonKeyCode: kVK_ANSI_D, displayName: "D")
    static let e = Key(carbonKeyCode: kVK_ANSI_E, displayName: "E")
    static let f = Key(carbonKeyCode: kVK_ANSI_F, displayName: "F")
    static let g = Key(carbonKeyCode: kVK_ANSI_G, displayName: "G")
    static let h = Key(carbonKeyCode: kVK_ANSI_H, displayName: "H")
    static let i = Key(carbonKeyCode: kVK_ANSI_I, displayName: "I")
    static let j = Key(carbonKeyCode: kVK_ANSI_J, displayName: "J")
    static let k = Key(carbonKeyCode: kVK_ANSI_K, displayName: "K")
    static let l = Key(carbonKeyCode: kVK_ANSI_L, displayName: "L")
    static let m = Key(carbonKeyCode: kVK_ANSI_M, displayName: "M")
    static let n = Key(carbonKeyCode: kVK_ANSI_N, displayName: "N")
    static let o = Key(carbonKeyCode: kVK_ANSI_O, displayName: "O")
    static let p = Key(carbonKeyCode: kVK_ANSI_P, displayName: "P")
    static let q = Key(carbonKeyCode: kVK_ANSI_Q, displayName: "Q")
    static let r = Key(carbonKeyCode: kVK_ANSI_R, displayName: "R")
    static let s = Key(carbonKeyCode: kVK_ANSI_S, displayName: "S")
    static let t = Key(carbonKeyCode: kVK_ANSI_T, displayName: "T")
    static let u = Key(carbonKeyCode: kVK_ANSI_U, displayName: "U")
    static let v = Key(carbonKeyCode: kVK_ANSI_V, displayName: "V")
    static let w = Key(carbonKeyCode: kVK_ANSI_W, displayName: "W")
    static let x = Key(carbonKeyCode: kVK_ANSI_X, displayName: "X")
    static let y = Key(carbonKeyCode: kVK_ANSI_Y, displayName: "Y")
    static let z = Key(carbonKeyCode: kVK_ANSI_Z, displayName: "Z")

    static let space = Key(carbonKeyCode: kVK_Space, displayName: "Space")
    static let `return` = Key(carbonKeyCode: kVK_Return, displayName: "↩")
    static let escape = Key(carbonKeyCode: kVK_Escape, displayName: "esc")
}

/// Modifier keys held alongside the main key.
struct ModifierFlags: OptionSet, Hashable, Sendable {
    let rawValue: Int

    static let command = ModifierFlags(rawValue: 1 << 0)
    static let option  = ModifierFlags(rawValue: 1 << 1)
    static let control = ModifierFlags(rawValue: 1 << 2)
    static let shift   = ModifierFlags(rawValue: 1 << 3)

    /// Translated into the bit flags Carbon's hotkey API expects.
    var carbonFlags: UInt32 {
        var flags: Int = 0
        if contains(.control) { flags |= controlKey }
        if contains(.option)  { flags |= optionKey }
        if contains(.shift)   { flags |= shiftKey }
        if contains(.command) { flags |= cmdKey }
        return UInt32(flags)
    }

    /// Symbols in the order macOS conventionally renders them.
    var displayName: String {
        var symbols = ""
        if contains(.control) { symbols += "⌃" }
        if contains(.option)  { symbols += "⌥" }
        if contains(.shift)   { symbols += "⇧" }
        if contains(.command) { symbols += "⌘" }
        return symbols
    }
}

/// A key plus its modifiers — the unit `HotkeyManager` registers.
struct Shortcut: Hashable, Sendable, CustomStringConvertible {
    let key: Key
    let modifiers: ModifierFlags

    init(key: Key, modifiers: ModifierFlags) {
        self.key = key
        self.modifiers = modifiers
    }

    var description: String { modifiers.displayName + key.displayName }
}

extension Shortcut {
    /// The overlay's toggle shortcut.
    ///
    /// Temporary and deliberately declared in one place: user-configurable
    /// shortcuts would replace this constant with stored values, and nothing
    /// else in the app would need to change.
    static let toggleOverlay = Shortcut(key: .a, modifiers: [.command, .option])
}
