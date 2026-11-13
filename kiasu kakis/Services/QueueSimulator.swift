import Foundation

extension Notification.Name {
    // Posted every simulator tick. QueueService listens to it to move tickets forward.
    static let queueSimulatorDidTick = Notification.Name("queueSimulatorDidTick")
    // Posted when anything a screen shows has changed (a wait time or a ticket). Presenters refresh on this.
    static let queueDataDidChange = Notification.Name("queueDataDidChange")
}

// How fast the simulated queues move. Demo is for showing the app in a few seconds;
// realistic is how it would feel with a real queue.
enum SimulationSpeed: String, CaseIterable {
    case demo
    case realistic

    static let defaultsKey = "queueSimulationSpeed"

    static var saved: SimulationSpeed {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(SimulationSpeed.init(rawValue:)) ?? .demo
    }

    var title: String { self == .demo ? "Demo" : "Realistic" }
    var detail: String { self == .demo ? "Queues move in seconds" : "Queues move in minutes" }

    // How often the simulator wakes up.
    var tickInterval: TimeInterval { self == .demo ? 1 : 10 }
    // How long a venue waits between new readings.
    var readingGap: ClosedRange<TimeInterval> { self == .demo ? 3...6 : 60...180 }
    // The most a wait can change in one reading, in minutes.
    var maxStep: Double { self == .demo ? 2.5 : 1.2 }
    // How long one group in the queue takes to be served.
    var groupInterval: TimeInterval { self == .demo ? 8 : 300 }

    func estimateText(groups: Int) -> String {
        let seconds = Double(groups) * groupInterval
        if seconds < 60 { return "About \(Int(seconds.rounded())) sec" }
        return "About \(Int((seconds / 60).rounded())) min"
    }
}

protocol QueueSimulating: AnyObject {
    var speed: SimulationSpeed { get set }
    func snapshot(for venue: Venue) -> QueueSnapshot
    // Someone standing in the line says how long it is. Only used for places with no queue system of their own.
    func submitReport(minutes: Int, for venue: Venue)
    func start()
    func stop()
}

// Pretends to be the venues' queue systems: waits drift up and down, and report times vary.
// Real places have no profile here, so they report "no recent data" (never a wait of 0).
final class QueueSimulator: QueueSimulating {

    static let shared = QueueSimulator(speed: .saved)

    private struct State {
        let profile: QueueProfile
        var wait: Double
        var history: [Double]
        var updatedAt: Date
        var nextReading: Date
    }

    private static let historyLength = 5
    // A wait must move by this many minutes across the recent readings to count as rising or falling.
    private static let trendThreshold = 2.0

    var speed: SimulationSpeed {
        didSet {
            guard speed != oldValue else { return }
            UserDefaults.standard.set(speed.rawValue, forKey: SimulationSpeed.defaultsKey)
            let now = clock()
            for id in states.keys { states[id]?.nextReading = now }
            if timer != nil { start() }
            tick()
        }
    }

    private let profiles: QueueProfileProviding
    private let reports: CrowdReporting
    private let clock: () -> Date
    private var rng: any RandomNumberGenerator
    // A queue starts the first time anyone asks about a venue, so the app never simulates places nobody looks at.
    private var states: [String: State] = [:]
    private var venuesWithoutQueue: Set<String> = []
    private var timer: Timer?

    init(speed: SimulationSpeed,
         profiles: QueueProfileProviding = SimulatedQueueCatalog(),
         reports: CrowdReporting = CrowdReportStore.shared,
         clock: @escaping () -> Date = Date.init,
         random: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.speed = speed
        self.profiles = profiles
        self.reports = reports
        self.clock = clock
        self.rng = random
    }

    // MARK: - Reading

    func snapshot(for venue: Venue) -> QueueSnapshot {
        // A fresh report from a real person beats the simulated number.
        if venue.queueSupport == .crowd, let report = reports.latestFresh(for: venue.id, now: clock()) {
            return QueueSnapshot(venueID: venue.id, waitMinutes: report.minutes, source: .userReport, timestamp: report.date)
        }
        guard let state = state(for: venue) else {
            return QueueSnapshot(venueID: venue.id, waitMinutes: nil, source: .communityObservation, timestamp: .distantPast)
        }
        return QueueSnapshot(venueID: venue.id,
                             waitMinutes: Int(state.wait.rounded()),
                             source: state.profile.source,
                             timestamp: state.updatedAt,
                             trend: Self.trend(of: state.history))
    }

    func submitReport(minutes: Int, for venue: Venue) {
        reports.submit(CrowdReport(venueID: venue.id, minutes: minutes, date: clock()))
        NotificationCenter.default.post(name: .queueDataDidChange, object: nil)
    }

    // Returns the venue's queue, starting it on first use. Venues without a queue are remembered, so asking again is cheap.
    private func state(for venue: Venue) -> State? {
        if let existing = states[venue.id] { return existing }
        guard !venuesWithoutQueue.contains(venue.id) else { return nil }
        guard let profile = profiles.profile(for: venue) else {
            venuesWithoutQueue.insert(venue.id)
            return nil
        }
        let now = clock()
        // The first reading is a little old, like a real report.
        let state = State(profile: profile,
                          wait: profile.base,
                          history: [profile.base],
                          updatedAt: now.addingTimeInterval(-Double.random(in: 30...180, using: &rng)),
                          nextReading: now.addingTimeInterval(Double.random(in: speed.readingGap, using: &rng)))
        states[venue.id] = state
        return state
    }

    static func trend(of history: [Double]) -> QueueTrend {
        guard let first = history.first, let last = history.last, history.count > 1 else { return .steady }
        let change = last - first
        if change >= trendThreshold { return .rising }
        if change <= -trendThreshold { return .falling }
        return .steady
    }

    // MARK: - Running

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: speed.tickInterval, repeats: true) { [weak self] _ in self?.tick() }
        // .common keeps it running while the user scrolls or drags the map.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // One step of the simulation. Returns true if any wait time changed.
    @discardableResult
    func tick() -> Bool {
        let now = clock()
        var changed = false
        // Sorted, so the same seed gives the same result every run.
        for id in states.keys.sorted() {
            guard var state = states[id], now >= state.nextReading else { continue }
            let profile = state.profile
            // Drift back toward the usual wait, plus a random nudge, and stay inside the allowed range.
            let pull = (profile.base - state.wait) * 0.12
            let nudge = Double.random(in: -speed.maxStep...speed.maxStep, using: &rng)
            state.wait = min(max(state.wait + pull + nudge, profile.range.lowerBound), profile.range.upperBound)
            state.history.append(state.wait)
            if state.history.count > Self.historyLength { state.history.removeFirst() }
            state.updatedAt = now
            state.nextReading = now.addingTimeInterval(Double.random(in: speed.readingGap, using: &rng))
            states[id] = state
            changed = true
        }
        NotificationCenter.default.post(name: .queueSimulatorDidTick, object: self, userInfo: ["waitsChanged": changed])
        return changed
    }
}
