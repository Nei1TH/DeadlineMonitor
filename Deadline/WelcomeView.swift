import SwiftUI
import UniformTypeIdentifiers

/// The initial view presented to the user when no Vault is open.
///
/// This view provides two main actions:
/// 1. Create New Vault: Creates a new JSON file.
/// 2. Open Existing Vault: Opens an existing JSON file from the file system.
struct WelcomeView: View {
    /// Callback closure to pass the selected file URL back to the parent view (AppEntryView).
    var onFileSelected: (URL) -> Void
    
    @State private var isImporting = false
    @State private var isExporting = false
    /// An empty document instance used as a template for creating new files.
    @State private var document = JSONDocument(items: [])

    var body: some View {
        VStack(spacing: 30) {
            Text("Deadline Monitor")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select a vault to start tracking your deadlines.")
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Button: Create New Vault
                Button(action: { isExporting = true }) {
                    VStack {
                        Image(systemName: "plus.square")
                            .font(.system(size: 40))
                        Text("Create New Vault")
                            .fontWeight(.medium)
                    }
                    .frame(width: 150, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Button: Open Existing Vault
                Button(action: { isImporting = true }) {
                    VStack {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                        Text("Open Existing Vault")
                            .fontWeight(.medium)
                    }
                    .frame(width: 150, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(50)
        .frame(width: 600, height: 400)
        // MARK: - File Import (Open Existing)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onFileSelected(url)
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        // MARK: - File Export (Create New)
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: .json,
            defaultFilename: "Deadlines"
        ) { result in
            switch result {
            case .success(let url):
                onFileSelected(url)
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Helper Types

/// A helper struct conforming to `FileDocument`.
/// This is required by SwiftUI's `fileExporter` to handle file creation and encoding/decoding.
struct JSONDocument: FileDocument {
    // Define that this document type handles JSON files
    static var readableContentTypes: [UTType] { [.json] }
    
    var items: [DeadlineItem]
    
    init(items: [DeadlineItem]) {
        self.items = items
    }
    
    // Initialize from an existing file
    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        if data.isEmpty {
            self.items = []
        } else {
            self.items = try JSONDecoder().decode([DeadlineItem].self, from: data)
        }
    }
    
    // Save to a file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(items)
        return FileWrapper(regularFileWithContents: data)
    }
}
