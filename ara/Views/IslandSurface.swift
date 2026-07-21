//
//  IslandSurface.swift
//  ara
//
//  The shared look of every floating island.
//

import SwiftUI

/// Gives a view its own detached, vibrant surface.
///
/// Every element in the overlay is an independent island rather than a section
/// of one card, so this carries the whole visual identity: material, rounding,
/// hairline edge and drop shadow. Changing the palette's look means changing
/// this one modifier.
private struct IslandSurface: ViewModifier {
    var isHighlighted: Bool

    /// Fully rounded: a capsule derives its radius from half the island's
    /// height, so every island stays pill-shaped regardless of its size.
    private var shape: Capsule {
        Capsule(style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background {
                if isHighlighted {
                    shape.fill(.tint)
                } else {
                    // Real behind-window vibrancy per island: with a fully
                    // transparent panel, SwiftUI's own materials would render as
                    // flat grey rather than blurring the desktop.
                    VisualEffectBackground()
                        .clipShape(shape)
                }
            }
            .overlay {
                // Hairline edge keeps islands legible against light desktops.
                shape.strokeBorder(.white.opacity(isHighlighted ? 0.22 : 0.12), lineWidth: 1)
            }
            // Each island casts its own shadow — this is what separates them
            // visually now that there is no enclosing card.
    }
}

extension View {
    /// Renders the view as a detached floating island.
    func islandSurface(isHighlighted: Bool = false) -> some View {
        modifier(IslandSurface(isHighlighted: isHighlighted))
    }
}
