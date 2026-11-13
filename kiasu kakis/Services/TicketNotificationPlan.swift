import Foundation

struct PlannedNotification: Equatable {
    enum Kind { case leaveNow, almost, called, lastCall, expired }
    let kind: Kind
    let delay: TimeInterval
}

// Works out when to alert the user about a ticket. This is pure maths so it can be tested without the notification centre.
// A waiting ticket moves up one place every `interval`, starting from when it last moved.
// After being called, the user has `grace` seconds to arrive (more if they asked for time).
enum TicketNotificationPlan {

    static func plan(for ticket: QueueTicket, interval: TimeInterval, grace: TimeInterval = 300, now: Date) -> [PlannedNotification] {
        guard interval > 0, grace > 0 else { return [] }
        switch ticket.status {
        case .waiting, .almostYourTurn: return waitingPlan(for: ticket, interval: interval, grace: grace, now: now)
        case .called: return latePlan(calledAt: ticket.calledAt ?? now, for: ticket, grace: grace, now: now)
        case .completed, .cancelled, .expired: return []
        }
    }

    private static func waitingPlan(for ticket: QueueTicket, interval: TimeInterval, grace: TimeInterval, now: Date) -> [PlannedNotification] {
        guard ticket.position >= 1 else { return [] }
        let last = ticket.lastProgressAt ?? now
        var planned: [PlannedNotification] = []
        // Leave when the trip takes as long as the queue still has to run. One group is about 5 minutes.
        if let travel = ticket.travelMinutes, travel > 2, ticket.arrivedAt == nil {
            let groupsToWait = Double(ticket.position) - Double(travel) / Double(QueueService.minutesPerGroup)
            let when = last.addingTimeInterval(max(groupsToWait, 0) * interval)
            planned.append(PlannedNotification(kind: .leaveNow, delay: max(1, when.timeIntervalSince(now))))
        }
        // "Almost" means one group is ahead. A ticket that is already there only needs the final alert.
        if ticket.position >= 2 {
            planned.append(PlannedNotification(kind: .almost, delay: delay(until: last, steps: ticket.position - 1, interval: interval, now: now)))
        }
        planned.append(PlannedNotification(kind: .called, delay: delay(until: last, steps: ticket.position, interval: interval, now: now)))
        // The ticket will be called at a known time, so its last call and release time are known too.
        let calledAt = last.addingTimeInterval(Double(ticket.position) * interval)
        return planned + latePlan(calledAt: calledAt, for: ticket, grace: grace, now: now)
    }

    // A last call shortly before the spot is given away, and a note once it has been.
    private static func latePlan(calledAt: Date, for ticket: QueueTicket, grace: TimeInterval, now: Date) -> [PlannedNotification] {
        guard ticket.arrivedAt == nil else { return [] }
        let deadline = calledAt.addingTimeInterval(grace * Double(1 + ticket.extensionCount))
        let lead = min(60, grace / 3)
        return [PlannedNotification(kind: .lastCall, delay: max(1, deadline.addingTimeInterval(-lead).timeIntervalSince(now))),
                PlannedNotification(kind: .expired, delay: max(1, deadline.timeIntervalSince(now)))]
    }

    private static func delay(until last: Date, steps: Int, interval: TimeInterval, now: Date) -> TimeInterval {
        // Notifications need a delay above zero, so something already due fires in a second.
        max(1, last.addingTimeInterval(Double(steps) * interval).timeIntervalSince(now))
    }
}
