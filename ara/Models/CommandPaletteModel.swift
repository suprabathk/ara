//
//  CommandPaletteModel.swift
//  ara
//
//  Presentation state for the command palette.
//

import Foundation
import Observation

/// Owns palette state and ranks app-launch suggestions for the current query.
@Observable
final class CommandPaletteModel {
    private static let resultLimit = 4

    var query: String = "" {
        didSet { selectedIndex = 0 }
    }

    var selectedIndex: Int = 0

    /// Changes on every presentation. Views observe it to re-apply focus, which
    /// `onAppear` cannot do because the overlay's hosting view is never torn
    /// down between openings.
    private(set) var presentationID = UUID()

    private let allCommands: [Command]
    private let executor = CommandExecutor()
    private let recentApplications = RecentApplicationsStore()

    init(commands: [Command]) {
        self.allCommands = commands
    }

    var results: [Command] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let matches = allCommands.filter { command in
            command.title.localizedCaseInsensitiveContains(trimmedQuery)
                || command.subtitle.localizedCaseInsensitiveContains(trimmedQuery)
        }

        let recentRanks = Dictionary(
            uniqueKeysWithValues: recentApplications.paths.enumerated().map { index, path in
                (path, index)
            }
        )

        let sortedMatches = matches.sorted { lhs, rhs in
            let lhsScore = matchScore(command: lhs, query: trimmedQuery)
            let rhsScore = matchScore(command: rhs, query: trimmedQuery)
            if lhsScore != rhsScore { return lhsScore < rhsScore }

            let lhsRank = recentRanks[lhs.applicationURL.path] ?? Int.max
            let rhsRank = recentRanks[rhs.applicationURL.path] ?? Int.max

            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        return Array(sortedMatches.prefix(Self.resultLimit))
    }

    var selectedCommand: Command? {
        results.indices.contains(selectedIndex) ? results[selectedIndex] : nil
    }

    private func matchScore(command: Command, query: String) -> Int {
        let title = command.title
        let subtitle = command.subtitle

        if title.localizedCaseInsensitiveCompare(query) == .orderedSame { return 0 }
        if localizedCaseInsensitiveStartsWith(title, query) { return 1 }
        if title.localizedCaseInsensitiveContains(query) { return 2 }
        if localizedCaseInsensitiveStartsWith(subtitle, query) { return 3 }
        return 4
    }

    private func localizedCaseInsensitiveStartsWith(_ value: String, _ query: String) -> Bool {
        value.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive, .anchored],
            locale: .current
        ) != nil
    }

    func isSelected(_ command: Command) -> Bool {
        selectedCommand?.id == command.id
    }

    func select(_ command: Command) {
        guard let index = results.firstIndex(of: command) else { return }
        selectedIndex = index
    }

    /// Moves the selection by `offset`, clamped to the result bounds.
    func moveSelection(by offset: Int) {
        guard !results.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + offset, 0), results.count - 1)
    }

    /// Resets the palette to its opening state and signals that it is being
    /// presented, so views can restore focus.
    func beginPresentation() {
        query = ""
        selectedIndex = 0
        presentationID = UUID()
    }

    func runSelectedCommand() {
        guard let command = selectedCommand else { return }
        executor.run(command)
        OverlayWindowManager.shared.hideAfterCommand()
    }
}
