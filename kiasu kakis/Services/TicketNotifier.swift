import Foundation
import UserNotifications

protocol TicketNotifying: AnyObject {
    func requestPermissionIfNeeded()
    // Makes the scheduled alerts match the tickets. Safe to call often: it only reschedules what changed.
    func sync(tickets: [QueueTicket], interval: TimeInterval, grace: TimeInterval, now: Date)
}

// For tests and anywhere alerts aren't wanted.
final class NoopTicketNotifier: TicketNotifying {
    func requestPermissionIfNeeded() {}
    func sync(tickets: [QueueTicket], interval: TimeInterval, grace: TimeInterval, now: Date) {}
}

// Local notifications, so the phone can tell the user even when the app is closed. No server is needed.
final class LocalTicketNotifier: NSObject, TicketNotifying, UNUserNotificationCenterDelegate {

    static let shared = LocalTicketNotifier()

    // Set by the app so tapping an alert can open the ticket.
    var onOpenTicket: ((UUID) -> Void)?

    private let center = UNUserNotificationCenter.current()
    private var signatures: [UUID: String] = [:]

    func requestPermissionIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func sync(tickets: [QueueTicket], interval: TimeInterval, grace: TimeInterval, now: Date) {
        for ticket in tickets {
            let plan = TicketNotificationPlan.plan(for: ticket, interval: interval, grace: grace, now: now)
            let signature = "\(ticket.status.rawValue)-\(ticket.position)-\(interval)-\(ticket.lastProgressAt?.timeIntervalSince1970 ?? 0)-\(ticket.travelMinutes ?? -1)-\(ticket.arrivedAt != nil)-\(grace)-\(ticket.calledAt?.timeIntervalSince1970 ?? 0)"
            guard signatures[ticket.id] != signature else { continue }
            signatures[ticket.id] = signature
            center.removePendingNotificationRequests(withIdentifiers: Self.identifiers(for: ticket))
            for item in plan { schedule(item, for: ticket) }
        }
    }

    private func schedule(_ item: PlannedNotification, for ticket: QueueTicket) {
        let content = UNMutableNotificationContent()
        switch item.kind {
        case .leaveNow:
            content.title = "Time to leave for \(ticket.venueName)"
            content.body = "It takes about \(ticket.travelMinutes ?? 0) min to get there. Head off now so you arrive when you're called."
        case .lastCall:
            content.title = "Last call at \(ticket.venueName)"
            content.body = "Your spot will be given away soon. Go in now."
        case .expired:
            content.title = "Your spot at \(ticket.venueName) was released"
            content.body = "You didn't arrive in time. You can join the queue again."
        case .almost:
            content.title = "You're next at \(ticket.venueName)"
            content.body = "One group ahead of you. Head over now."
        case .called:
            content.title = "It's your turn at \(ticket.venueName)"
            content.body = "Walk in and show ticket #\(ticket.ticketNumber)."
        }
        content.sound = .default
        content.userInfo = ["ticketID": ticket.id.uuidString]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.delay, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.identifier(ticket.id, item.kind), content: content, trigger: trigger))
    }

    private static func identifier(_ id: UUID, _ kind: PlannedNotification.Kind) -> String {
        "ticket-\(id.uuidString)-\(kind)"
    }

    // Once a ticket is called, the "your turn" alert has done its job, so only the late alerts are replaced.
    private static func identifiers(for ticket: QueueTicket) -> [String] {
        let kinds: [PlannedNotification.Kind] = ticket.status == .called
            ? [.lastCall, .expired]
            : [.leaveNow, .almost, .called, .lastCall, .expired]
        return kinds.map { identifier(ticket.id, $0) }
    }

    // Show alerts as banners even while the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let text = response.notification.request.content.userInfo["ticketID"] as? String, let id = UUID(uuidString: text) else { return }
        await MainActor.run { onOpenTicket?(id) }
    }
}
