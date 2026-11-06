import UIKit

enum Theme {
    // Brand colour #bd091c
    static let brand = UIColor(hex: 0xBD091C)

    // Wait-time colours. Unknown is grey so missing data is never read as "0 min".
    static let waitShort = UIColor(hex: 0x2E9E5B)
    static let waitMedium = UIColor(hex: 0xF5A623)
    static let waitLong = UIColor(hex: 0xFF5A36)
    static let waitUnknown = UIColor.systemGray

    static func waitColor(forMinutes minutes: Int?) -> UIColor {
        guard let minutes else { return waitUnknown }
        switch minutes {
        case ..<15: return waitShort
        case 15..<30: return waitMedium
        default: return waitLong
        }
    }

    static func color(for status: QueueStatus) -> UIColor {
        switch status {
        case .waiting: return .systemBlue
        case .almostYourTurn: return waitMedium
        case .called: return waitShort
        case .completed, .cancelled, .expired: return .systemGray
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
