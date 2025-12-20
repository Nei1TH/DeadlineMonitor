//
//  DeadlineApp.swift
//  Deadline
//
//  Created by Neil on 19/11/2025.
//

import SwiftUI

/// The main entry point of the application.
///
/// This application follows a Document-based architecture style (similar to Obsidian),
/// where the user chooses a "Vault" (a JSON file) to store their data.
/// It uses SwiftUI's App lifecycle.
@main
struct DeadlineApp: App {
    var body: some Scene {
        WindowGroup {
            // AppEntryView acts as the root coordinator, deciding whether to show
            // the Welcome screen (Vault selection) or the Main Content (Deadline list).
            AppEntryView()
        }
    }
}
