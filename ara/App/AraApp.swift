//
//  AraApp.swift
//  ara
//
//  Created by Suprabath Kondapally on 20/07/26.
//

import SwiftUI

@main
struct AraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Ara has no conventional document or main window — the overlay panel
        // is driven entirely by `OverlayWindowManager`. `Settings` is used as
        // the app's sole scene because it declares no window at launch.
        Settings {
            EmptyView()
        }
    }
}
