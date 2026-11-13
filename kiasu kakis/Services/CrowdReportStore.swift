import Foundation

protocol CrowdReporting: AnyObject {
    func latestFresh(for venueID: String, now: Date) -> CrowdReport?
    func submit(_ report: CrowdReport)
}

// Keeps the newest report for each place, saved on the phone.
final class CrowdReportStore: CrowdReporting {

    static let shared = CrowdReportStore()

    private static let filename = "crowd_reports.json"
    private let store: LocalStore
    private var reports: [String: CrowdReport] {
        didSet { store.save(Array(reports.values), to: Self.filename) }
    }

    init(store: LocalStore = LocalStore()) {
        self.store = store
        let saved = store.load([CrowdReport].self, from: Self.filename) ?? []
        self.reports = Dictionary(saved.map { ($0.venueID, $0) }, uniquingKeysWith: { first, second in first.date > second.date ? first : second })
    }

    func latestFresh(for venueID: String, now: Date) -> CrowdReport? {
        reports[venueID].flatMap { $0.isFresh(at: now) ? $0 : nil }
    }

    func submit(_ report: CrowdReport) { reports[report.venueID] = report }
}
