import Foundation

// How a venue handles its queue, in words the screens can show. One place decides this so the map sheet,
// the venue page and the saved list never disagree.
struct QueueSupportInfo: Equatable {
    let symbol: String
    let title: String
    let message: String
    // Short line for lists and the map sheet.
    let shortText: String
    // What the main button says when the user has no ticket for this venue.
    let actionTitle: String
    let isPositive: Bool
    // True when the main button does something: join in the app, or go to the venue's own system.
    let canAct: Bool

    init(venue: Venue) {
        switch venue.queueSupport {
        case .native:
            self = QueueSupportInfo(symbol: "checkmark.circle.fill", title: "Virtual queue available",
                                    message: "Join from your phone and track your turn without standing in line.",
                                    shortText: "Virtual queue available", actionTitle: "Join queue",
                                    isPositive: true, canAct: true)
        case .external:
            self = QueueSupportInfo(symbol: "arrow.up.right.square", title: "Queue run by the restaurant",
                                    message: "This place has its own queue system. Join through them, and use Kiasu Kakis to check the wait first.",
                                    shortText: "Joins through the restaurant", actionTitle: "Join via restaurant",
                                    isPositive: false, canAct: venue.externalQueueURL != nil)
        case .crowd:
            self = QueueSupportInfo(symbol: "person.2.fill", title: "Community-reported wait",
                                    message: "This stall has no remote queue. The wait comes from reports by people in line, so queue on site.",
                                    shortText: "Community report · queue on site", actionTitle: "Report the wait",
                                    isPositive: false, canAct: true)
        case .closed:
            self = QueueSupportInfo(symbol: "moon.zzz.fill", title: "Queue closed",
                                    message: "This venue isn't accepting new tickets right now.",
                                    shortText: "Queue closed", actionTitle: "Queue closed",
                                    isPositive: false, canAct: false)
        case .unsupported where !venue.isDemo:
            self = QueueSupportInfo(symbol: "info.circle", title: "No queue information",
                                    message: "This is a real place from Apple Maps or Google. Kiasu Kakis has no queue data for it, and remote joining isn't available.",
                                    shortText: "Real place · no queue data", actionTitle: "No queue available",
                                    isPositive: false, canAct: false)
        case .unsupported:
            self = QueueSupportInfo(symbol: "nosign", title: "Remote queue not supported",
                                    message: "This venue doesn't offer remote joining. You'd need to queue on site.",
                                    shortText: "Remote queue not supported", actionTitle: "Remote queue not supported",
                                    isPositive: false, canAct: false)
        }
    }

    private init(symbol: String, title: String, message: String, shortText: String,
                 actionTitle: String, isPositive: Bool, canAct: Bool) {
        self.symbol = symbol; self.title = title; self.message = message; self.shortText = shortText
        self.actionTitle = actionTitle; self.isPositive = isPositive; self.canAct = canAct
    }
}
