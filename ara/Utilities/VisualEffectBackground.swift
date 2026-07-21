//
//  VisualEffectBackground.swift
//  ara
//
//  Exposes NSVisualEffectView to SwiftUI.
//

import AppKit
import SwiftUI

/// Vibrancy material for the overlay.
///
/// SwiftUI's `.background(.ultraThinMaterial)` only blurs content inside the
/// app; a floating palette needs to blur the desktop behind it, which requires
/// `NSVisualEffectView` with a `behindWindow` blending mode.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}
