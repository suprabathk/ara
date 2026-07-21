//
//  OverlayView.swift
//  ara
//
//  Root content of the overlay panel.
//

import SwiftUI

struct OverlayView: View {
    @Bindable var model: CommandPaletteModel

    @FocusState private var isSearchFocused: Bool

    /// Gap between islands.
    private let islandSpacing: CGFloat = 6

    var body: some View {
        // No enclosing card: the panel is transparent and every element is its
        // own island, so the desktop shows through the gaps between them.
        // Bottom-anchored, with results stacking upward from the search field.
        VStack(alignment: .leading, spacing: islandSpacing) {
            resultsList

            SearchBar(text: $model.query, focus: $isSearchFocused)
        }
        // Breathing room so island shadows are not clipped by the panel edge.
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        // The gaps between islands are transparent but still belong to the
        // panel, so clicks there do not reach the desktop and would not
        // otherwise dismiss. Treat empty space as "clicked outside".
        .background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { OverlayWindowManager.shared.hide() }
        }
        .onPaletteKey(handle)
        .onAppear { isSearchFocused = true }
        // The panel is reused, so `onAppear` fires only once. The manager bumps
        // `presentationID` on every show; that is what re-focuses the field.
        .onChange(of: model.presentationID) { isSearchFocused = true }
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: islandSpacing) {
                    ForEach(model.results.reversed()) { command in
                        CommandRow(command: command, isSelected: model.isSelected(command))
                            .id(command.id)
                            .onTapGesture {
                                model.select(command)
                                model.runSelectedCommand()
                            }
                    }
                }
                // Horizontal room for island shadows, which the ScrollView
                // would otherwise clip at its bounds.
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // A fully clear background can still miss wheel routing on macOS.
            // This is visually transparent, but gives the gaps a real hit
            // surface so scrolling works between rows.
            .background(Color.primary.opacity(0.001))
            .contentShape(.rect)
            // Keeps the list adjacent to the search field when it overflows.
            .defaultScrollAnchor(.bottom)
            .scrollContentBackground(.hidden)
            .onChange(of: model.selectedIndex) {
                guard let command = model.selectedCommand else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(command.id, anchor: .center)
                }
            }
        }
        // `.bottom` so a short result set rests against the search field rather
        // than floating in the middle of the panel.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func handle(_ key: PaletteKey) {
        switch key {
        case .escape:
            OverlayWindowManager.shared.hide()
        case .up:
            model.moveSelection(by: 1)
        case .down:
            model.moveSelection(by: -1)
        case .return:
            model.runSelectedCommand()
        }
    }
}

#Preview {
    let previewApplication = Command(
        id: "preview:application",
        title: "Terminal",
        subtitle: "Application",
        applicationURL: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
    )

    OverlayView(model: CommandPaletteModel(commands: [previewApplication]))
        .frame(width: 480, height: 320)
}
