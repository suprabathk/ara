//
//  RecentApplicationsStore.swift
//  ara
//
//  Persists app-launch recency for the app launcher.
//

import Foundation

struct RecentApplicationsStore {
    private static let key = "appLauncher.recentApplicationPaths"
    private static let limit = 20

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var paths: [String] {
        defaults.stringArray(forKey: Self.key) ?? []
    }

    func recordLaunch(at url: URL) {
        let path = url.path
        var updated = paths.filter { $0 != path }
        updated.insert(path, at: 0)

        if updated.count > Self.limit {
            updated = Array(updated.prefix(Self.limit))
        }

        defaults.set(updated, forKey: Self.key)
    }
}
