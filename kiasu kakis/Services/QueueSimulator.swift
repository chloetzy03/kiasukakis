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
    func snapshot(for venueID: String) -> QueueSnapshot
    func start()
    func stop()
}

// Pretends to be the venues' queue systems: waits drift up and down, and report times vary.
// Real places have no profile here, so they report "no recent data" (never a wait of 0).
final class QueueSimulator: QueueSimulating {

    static let shared = QueueSimulator(speed: .saved)

    struct Profile {
        let base: Double
        let range: ClosedRange<Double>
        let source: QueueDataSource
    }

    // Only these demo venues have a live queue. The others stay at "no recent reports" on purpose.
    static let profiles: [String: Profile] = [
        "v1": Profile(base: 40, range: 25...55, source: .communityObservation),
        "v2": Profile(base: 15, range: 6...30, source: .demoSimulation),
        "v4": Profile(base: 8, range: 3...18, source: .demoSimulation),
        "v6": Profile(base: 25, range: 12...45, source: .demoSimulation)
    ]

    private struct State {
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

    private let clock: () -> Date
    private var rng: any RandomNumberGenerator
    private var states: [String: State] = [:]
    private var timer: Timer?

    init(speed: SimulationSpeed,
         clock: @escaping () -> Date = Date.init,
         random: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.speed = speed
        self.clock = clock
        self.rng = random
        let now = clock()
        // Start with readings that are a little old, like real reports.
        for (index, id) in Self.profiles.keys.sorted().enumerated() {
            let profile = Self.profiles[id]!
            states[id] = State(wait: profile.base,
                               history: [profile.base],
                               updatedAt: now.addingTimeInterval(-Double(60 + index * 45)),
                               nextReading: now.addingTimeInterval(Double.random(in: speed.readingGap, using: &rng)))
        }
    }

    // MARK: - Reading

    func snapshot(for venueID: String) -> QueueSnapshot {
        guard let profile = Self.profiles[venueID], let state = states[venueID] else {
            return QueueSnapshot(venueID: venueID, waitMinutes: nil, source: .communityObservation, timestamp: .distantPast)
        }
        return QueueSnapshot(venueID: venueID,
                             waitMinutes: Int(state.wait.rounded()),
                             source: profile.source,
                             timestamp: state.updatedAt,
                             trend: Self.trend(of: state.history))
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
        for (id, profile) in Self.profiles {
            guard var state = states[id], now >= state.nextReading else { continue }
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
