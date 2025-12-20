import SwiftUI

/// The root coordinator view that manages the app's state between the Welcome screen and the Main Content.
/// It also handles the persistence of the selected Vault (using Bookmarks) so the user doesn't have to re-select it on every launch.
struct AppEntryView: View {
    // Stores the currently open file URL. If nil, the WelcomeView is shown.
    @State private var currentFileURL: URL?
    
    // UserDefaults Key for storing the Security Scoped Bookmark
    private let bookmarkKey = "LastOpenedVaultBookmark"
    
    var body: some View {
        Group {
            if let url = currentFileURL {
                // If a URL is set, show the main content (The Deadline List)
                ContentView(fileURL: url, onClose: {
                    closeVault()
                })
            } else {
                // Otherwise, show the Welcome screen (Create/Open Vault)
                WelcomeView(onFileSelected: { url in
                    openVault(url: url)
                })
            }
        }
        // Set a minimum window size for the app
        .frame(minWidth: 300, minHeight: 400)
        .onAppear {
            // Set default window size (only if not restored by system)
            if let window = NSApplication.shared.windows.first {
                let defaultSize = CGSize(width: 300, height: 300)
                // Only resize if the current size is the system default (usually small)
                // or you can force it every time by removing the condition.
                if window.frame.width < defaultSize.width || window.frame.height < defaultSize.height {
                    window.setContentSize(defaultSize)
                    window.center() // Optional: Center the window
                }
            }
            
            // When the app starts, try to restore the last opened vault
            loadLastOpenedVault()
        }
    }
    
    // MARK: - Vault Management
    
    /// Opens the specified Vault URL and saves a bookmark for future access.
    private func openVault(url: URL) {
        // 1. Attempt to access the security scoped resource.
        // Note: For URLs restored from bookmarks, this step is mandatory.
        // For URLs coming directly from the file importer, the system usually grants temporary access,
        // but we call it explicitly for consistency.
        let accessing = url.startAccessingSecurityScopedResource()
        if !accessing {
            print("⚠️ Warning: Could not start accessing security scoped resource directly. (Might be a standard file path)")
        }
        
        // 2. Save a bookmark to UserDefaults to remember this vault across app launches.
        saveBookmark(for: url)
        
        // 3. Update the state to switch the view.
        currentFileURL = url
    }
    
    /// Closes the current Vault, releases file access, and clears the bookmark.
    private func closeVault() {
        guard let url = currentFileURL else { return }
        
        // 1. Stop accessing the resource (balance the startAccessing call).
        url.stopAccessingSecurityScopedResource()
        
        // 2. Remove the bookmark from UserDefaults.
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        
        // 3. Reset the state to show the WelcomeView.
        currentFileURL = nil
    }
    
    // MARK: - Bookmark Persistence
    
    /// Creates and saves a security-scoped bookmark for the given URL.
    /// This allows the app to access the file again after a restart.
    private func saveBookmark(for url: URL) {
        do {
            // Create a security-scoped bookmark
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            print("✅ Vault bookmark saved.")
        } catch {
            print("❌ Failed to save vault bookmark: \(error)")
        }
    }
    
    /// Attempts to load and resolve the last opened vault from UserDefaults.
    private func loadLastOpenedVault() {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        
        var isStale = false
        do {
            // Resolve the bookmark data back into a URL
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("⚠️ Bookmark is stale, attempting to renew...")
                saveBookmark(for: url)
            }
            
            // Try to access the resource
            let accessing = url.startAccessingSecurityScopedResource()
            if accessing {
                print("✅ Automatically opened vault: \(url.path)")
                currentFileURL = url
            } else {
                print("❌ Failed to access restored vault URL. Permission denied.")
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
            }
        } catch {
            print("❌ Failed to resolve bookmark: \(error)")
            // If resolution fails (e.g., file moved or deleted), clear the bookmark.
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
}
