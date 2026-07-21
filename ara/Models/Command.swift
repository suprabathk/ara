//
//  Command.swift
//  ara
//
//  A launchable application entry in the command palette.
//

import Foundation

/// A launchable application surfaced in the palette.
struct Command: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let applicationURL: URL

    init(id: String, title: String, subtitle: String, applicationURL: URL) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.applicationURL = applicationURL
    }
}
