import Foundation

// Saves and loads Codable values as JSON files in the app's private Application Support folder.
struct LocalStore {

    private let directory: URL

    init(directory: URL = LocalStore.defaultDirectory) {
        self.directory = directory
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    // Returns nil if the file doesn't exist yet or can't be read, so the app starts fresh instead of crashing.
    func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(filename)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    func save<T: Encodable>(_ value: T, to filename: String) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(value).write(to: fileURL(filename), options: .atomic)
        } catch {
            print("LocalStore: could not save \(filename): \(error)")
        }
    }

    private func fileURL(_ filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }
}
