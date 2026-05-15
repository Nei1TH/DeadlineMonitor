import Foundation

/// A manager class responsible for handling low-level file operations.
/// It encapsulates the logic for reading from and writing to JSON files,
/// including handling Security Scoped Resources (essential for Sandbox compliance).
class JSONManager {
    enum JSONManagerError: LocalizedError {
        case readFailed(URL, underlying: Error)
        case decodeFailed(URL, underlying: Error)
        case encodeFailed(underlying: Error)
        case writeFailed(URL, underlying: Error)
        
        var errorDescription: String? {
            switch self {
            case .readFailed(let url, _):
                return "Failed to read vault file: \(url.lastPathComponent)"
            case .decodeFailed(let url, _):
                return "Vault file is not valid JSON: \(url.lastPathComponent)"
            case .encodeFailed:
                return "Failed to prepare data for saving."
            case .writeFailed(let url, _):
                return "Failed to save vault file: \(url.lastPathComponent)"
            }
        }
    }
    
    /// The URL of the JSON file currently being managed.
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    // MARK: - CRUD Operations
    
    private func withSecurityScopedAccess<T>(_ operation: () throws -> T) throws -> T {
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        return try operation()
    }
    
    /// Saves the provided list of items to the JSON file.
    /// - Parameter items: The array of `DeadlineItem` to save.
    func save(items: [DeadlineItem]) throws {
        try withSecurityScopedAccess {
            let data: Data
            do {
                data = try JSONEncoder().encode(items)
            } catch {
                throw JSONManagerError.encodeFailed(underlying: error)
            }
            
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                throw JSONManagerError.writeFailed(fileURL, underlying: error)
            }
        }
    }
    
    /// Loads the list of items from the JSON file.
    /// - Returns: An array of `DeadlineItem`. Returns an empty array if loading fails.
    func load() throws -> [DeadlineItem] {
        try withSecurityScopedAccess {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch {
                throw JSONManagerError.readFailed(fileURL, underlying: error)
            }
            
            do {
                return try JSONDecoder().decode([DeadlineItem].self, from: data)
            } catch {
                throw JSONManagerError.decodeFailed(fileURL, underlying: error)
            }
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
