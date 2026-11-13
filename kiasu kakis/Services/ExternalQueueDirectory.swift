import Foundation

// Places that run their own queue system. We don't try to replace it: we show the wait and send people to it.
protocol ExternalQueueProviding {
    func queueURL(for venue: Venue) -> URL?
}

// A small starter list. A real version would come from partners or a server, not from the app itself.
struct ExternalQueueDirectory: ExternalQueueProviding {

    private static let entries: [(name: String, url: String)] = [
        ("din tai fung", "https://www.dintaifung.com.sg")
    ]

    func queueURL(for venue: Venue) -> URL? {
        let name = SearchText.normalized(venue.name)
        return Self.entries.first { name.contains(SearchText.normalized($0.name)) }.flatMap { URL(string: $0.url) }
    }
}
