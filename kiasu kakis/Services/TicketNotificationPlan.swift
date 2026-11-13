import Foundation

struct PlannedNotification: Equatable {
    enum Kind { case leaveNow, almost, called }
    let kind: Kind
    let delay: TimeInterval
}

// Works out when to alert the user about a ticket. This is pure maths so it can be tested without the notification centre.
// A waiting ticket moves up one place every `interval`, starting from when it last moved.
enum TicketNotificationPlan {

    static func plan(for ticket: QueueTicket, interval: TimeInterval, now: Date) -> [PlannedNotification] {
        guard ticket.status == .waiting || ticket.status == .almostYourTurn, ticket.position >= 1, interval > 0 else { return [] }
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
        return planned
    }

    private static func delay(until last: Date, steps: Int, interval: TimeInterval, now: Date) -> TimeInterval {
        // Notifications need a delay above zero, so something already due fires in a second.
        max(1, last.addingTimeInterval(Double(steps) * interval).timeIntervalSince(now))
    }
}
