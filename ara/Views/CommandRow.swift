import AppKit
import SwiftUI

/// One app-launch result, rendered as its own floating island.
struct CommandRow: View {
    let command: Command
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 9) {
            commandIcon
                .frame(width: 18, height: 18)

            Text(command.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)

            Spacer(minLength: 8)

            Text(command.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? AnyShapeStyle(.white.opacity(0.75)) : AnyShapeStyle(.tertiary))
                .lineLimit(1)
        }
        // Generous inset so the leading icon and trailing subtitle clear the
        // capsule's curves rather than sitting on them.
        .padding(.horizontal, 14)
        .frame(height: 34)
        .islandSurface(isHighlighted: isSelected)
        .contentShape(.capsule)
    }

    private var commandIcon: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: command.applicationURL.path))
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    let previewApplication = Command(
        id: "preview:application",
        title: "Terminal",
        subtitle: "Application",
        applicationURL: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
    )

    VStack(spacing: 6) {
        CommandRow(command: previewApplication, isSelected: true)
        CommandRow(command: previewApplication, isSelected: false)
    }
    .padding()
    .frame(width: 460)
}
