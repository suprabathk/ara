//
//  SearchBar.swift
//  ara
//

import SwiftUI

/// The palette's query field, as its own island. Purely presentational — focus
/// is owned by the parent so it can be restored whenever the overlay reopens.
struct SearchBar: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            TextField("Search commands...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular))
                .focused(focus)
                // Return is handled by the palette-wide key monitor, so the
                // field itself does nothing on submit.
                .onSubmit {}
        }
        // Generous inset: on a capsule the left curve eats into the content
        // box, so a rectangular padding value would crowd the icon.
        .padding(.horizontal, 16)
        .frame(height: 42)
        .islandSurface()
    }
}
