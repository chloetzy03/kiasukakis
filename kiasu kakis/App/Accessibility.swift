import UIKit

// Small helpers so every screen treats accessibility the same way.
enum Motion {
    // Animations become instant when the user has turned on Reduce Motion.
    static func duration(_ normal: TimeInterval) -> TimeInterval {
        UIAccessibility.isReduceMotionEnabled ? 0 : normal
    }
}

extension UIView {
    // Makes every label in this view grow and shrink when the user changes their text size,
    // without having to relaunch the app. Fonts must come from preferredFont for this to work.
    func enableDynamicType() {
        if let label = self as? UILabel { label.adjustsFontForContentSizeCategory = true }
        subviews.forEach { $0.enableDynamicType() }
    }
}

extension QueueFormatting {
    // Turns the arrows into words, because VoiceOver reads "▲" as "black up-pointing triangle".
    static func spoken(_ text: String) -> String {
        text.replacingOccurrences(of: "▲", with: "rising")
            .replacingOccurrences(of: "▼", with: "falling")
            .replacingOccurrences(of: "→ ", with: "")
            .replacingOccurrences(of: "→", with: "")
            .replacingOccurrences(of: " · ", with: ", ")
    }
}

// A button whose touch area is at least 44 x 44 points, even when it looks smaller.
final class RoomyButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dx = min(0, (bounds.width - 44) / 2)
        let dy = min(0, (bounds.height - 44) / 2)
        return bounds.insetBy(dx: dx, dy: dy).contains(point)
    }
}
