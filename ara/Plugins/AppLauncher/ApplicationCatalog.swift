//
//  ApplicationCatalog.swift
//  ara
//
//  Discovers installed macOS applications for the app launcher.
//

import Foundation

struct ApplicationCatalog {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func commands() -> [Command] {
        applicationURLs()
            .compactMap(command)
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private func command(for url: URL) -> Command? {
        guard let bundle = Bundle(url: url) else { return nil }

        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        return Command(
            id: "app-launcher:\(url.path)",
            title: name,
            subtitle: "Application",
            applicationURL: url
        )
    }

    private func applicationURLs() -> [URL] {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        ]

        var seen = Set<String>()
        var urls: [URL] = []

        for root in roots where fileManager.fileExists(atPath: root.path) {
            for url in applications(under: root) {
                guard seen.insert(url.path).inserted else { continue }
                urls.append(url)
            }
        }

        return urls
    }

    private func applications(under root: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            urls.append(url)
            enumerator.skipDescendants()
        }

        return urls
    }
}
