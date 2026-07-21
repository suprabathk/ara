//
//  CommandExecutor.swift
//  ara
//
//  Executes palette commands.
//

import AppKit
import os

@MainActor
struct CommandExecutor {
    private nonisolated static let logger = Logger(subsystem: "com.ara.app", category: "Commands")

    func run(_ command: Command) {
        launchApplication(at: command.applicationURL)
    }

    private func launchApplication(at url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { application, error in
            if let error {
                Self.logger.error(
                    "Could not launch \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
                return
            }

            RecentApplicationsStore().recordLaunch(at: url)
        }
    }
}
