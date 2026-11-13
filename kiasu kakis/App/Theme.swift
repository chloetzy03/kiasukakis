import UIKit

enum Theme {
    // Brand crimson #bd091c. Dark mode uses lighter reds so it stays readable on dark backgrounds.
    // `brand` is for filled shapes (white text on top); `brandText` is for text, icons and tints.
    static let brand = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xE0283C) : UIColor(hex: 0xBD091C) }
    static let brandText = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFF5A6B) : UIColor(hex: 0xBD091C) }

    // Warm cream replaces stark white. Cards sit slightly lighter than the page.
    static let background = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x170C0D) : UIColor(hex: 0xFBF4EA) }
    static let surface = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x241618) : UIColor(hex: 0xFFFCF7) }

    // Blue for "save", so it can't be mistaken for the red "delete" next to it.
    static let saveAction = UIColor(hex: 0x1D6FA5)

    // Wait-time colours. Unknown is grey so missing data is never read as "0 min".
    // Green and orange are dark enough for white text on top (4.5:1 contrast or better).
    static let waitShort = UIColor(hex: 0x1F7A44)
    static let waitMedium = UIColor(hex: 0xF5A623)
    static let waitLong = UIColor(hex: 0xC2410C)
    // Green used as text, which needs a lighter version on dark backgrounds.
    static let waitShortText = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x4CC38A) : UIColor(hex: 0x1F7A44) }

    // The system grey for secondary text is too faint on the cream background (3:1), so this is a warmer, darker one.
    static let secondaryText = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xB9A9A4) : UIColor(hex: 0x6E5F5A) }
    static let waitUnknown = UIColor.systemGray

    static func waitColor(forMinutes minutes: Int?) -> UIColor {
        guard let minutes else { return waitUnknown }
        switch minutes {
        case ..<15: return waitShort
        case 15..<30: return waitMedium
        default: return waitLong
        }
    }

    // Amber is light, so text on it is dark; white stays readable on the other colours.
    static func pinTextColor(forMinutes minutes: Int?) -> UIColor {
        guard let minutes, (15..<30).contains(minutes) else { return .white }
        return UIColor(hex: 0x3A2A00)
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
