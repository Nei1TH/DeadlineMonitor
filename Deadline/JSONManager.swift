import Foundation

/// A manager class responsible for handling low-level file operations.
/// It encapsulates the logic for reading from and writing to JSON files,
/// including handling Security Scoped Resources (essential for Sandbox compliance).
class JSONManager {
    /// The URL of the JSON file currently being managed.
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    // MARK: - CRUD Operations
    
    /// Saves the provided list of items to the JSON file.
    /// - Parameter items: The array of `DeadlineItem` to save.
    func save(items: [DeadlineItem]) {
        // Start accessing the security scoped resource.
        // This is required to access files outside the app's sandbox (e.g., user selected files).
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try JSONEncoder().encode(items)
            // .atomic write ensures data integrity by writing to a temporary file first.
            try data.write(to: fileURL, options: .atomic)
            print("✅ Saved \(items.count) items to: \(fileURL.path)")
        } catch {
            print("❌ Error saving JSON: \(error)")
        }
    }
    
    /// Loads the list of items from the JSON file.
    /// - Returns: An array of `DeadlineItem`. Returns an empty array if loading fails.
    func load() -> [DeadlineItem] {
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            print("📂 Loading from: \(fileURL.path)")
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([DeadlineItem].self, from: data)
            print("✅ Loaded \(items.count) items")
            return items
        } catch {
            print("⚠️ Error loading JSON: \(error)")
            return []
        }
    }
    
    /// Checks if the file exists at the specified URL.
    /// - Returns: `true` if the file exists, `false` otherwise.
    func fileExists() -> Bool {
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
