//
//  Zer0WatchApp.swift
//  Zer0Watch (watchOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 3-4: Watch App)
//
//  Purpose: Entry point for Zer0 Inbox Apple Watch app.
//

import SwiftUI

#if os(watchOS)

@main
struct Zer0WatchApp: App {
    @StateObject private var watchManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            InboxView()
                .onAppear {
                    // Request initial inbox data from iPhone
                    watchManager.requestInboxUpdate()

                    Logger.info("⌚️ Zer0 Watch app launched", category: .watch)
                }
        }
    }
}

#endif
