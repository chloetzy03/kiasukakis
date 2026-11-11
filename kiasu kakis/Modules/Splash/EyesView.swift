import UIKit

// The brand's two eyes. Drawn in code (not an image) so the pupils can move.
final class EyesView: UIView {

    private let radius: CGFloat
    private let gap: CGFloat
    private var eyeLayers: [CALayer] = []
    private var pupilLayers: [CALayer] = []

    private static let ink = UIColor(hex: 0x2A1215)
    private static let sclera = UIColor(hex: 0xFFFDF8)

    init(radius: CGFloat, gap: CGFloat) {
        self.radius = radius
        self.gap = gap
        // Extra height above the eyes leaves room for the eyebrows.
        super.init(frame: CGRect(x: 0, y: 0, width: 2 * (gap + radius), height: radius * 3.2))
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        buildLayers()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var intrinsicContentSize: CGSize { bounds.size }

    private func buildLayers() {
        let centerY = bounds.height / 2
        for side in [-1, 1] as [CGFloat] {
            let centerX = bounds.width / 2 + side * gap

            // The eye is a clipping container, so a pupil can never leave the white.
            let eye = CALayer()
            eye.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
            eye.position = CGPoint(x: centerX, y: centerY)
            eye.cornerRadius = radius
            eye.masksToBounds = true
            eye.backgroundColor = Self.sclera.cgColor
            layer.addSublayer(eye)
            eyeLayers.append(eye)

            let pupilSize = radius * 1.04
            let pupil = CALayer()
            pupil.bounds = CGRect(x: 0, y: 0, width: pupilSize, height: pupilSize)
            pupil.position = CGPoint(x: radius, y: radius - radius * 0.18)
            pupil.cornerRadius = pupilSize / 2
            pupil.backgroundColor = Self.ink.cgColor
            eye.addSublayer(pupil)
            pupilLayers.append(pupil)

            let shine = CALayer()
            let shineSize = radius * 0.3
            shine.bounds = CGRect(x: 0, y: 0, width: shineSize, height: shineSize)
            shine.position = CGPoint(x: pupilSize * 0.62, y: pupilSize * 0.34)
            shine.cornerRadius = shineSize / 2
            shine.backgroundColor = Self.sclera.cgColor
            pupil.addSublayer(shine)

            // Eyebrows slope down toward the nose, which gives the determined "kiasu" look.
            let browY = centerY - radius * 1.38
            let path = UIBezierPath()
            path.move(to: CGPoint(x: centerX + side * radius * 0.95, y: browY - radius * 0.12))
            path.addLine(to: CGPoint(x: centerX - side * radius * 0.95, y: browY + radius * 0.12))
            let brow = CAShapeLayer()
            brow.path = path.cgPath
            brow.strokeColor = Self.ink.cgColor
            brow.lineWidth = radius * 0.3
            brow.lineCap = .round
            layer.addSublayer(brow)
        }
    }

    // Pupils glance left and right. Skipped when the user has Reduce Motion turned on.
    func startLooking() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let travel = radius * 0.4
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, travel, travel, -travel, -travel, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.duration = 3.2
        animation.repeatCount = .infinity
        animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: 5)
        pupilLayers.forEach { $0.add(animation, forKey: "look") }
    }

    func stopLooking() {
        pupilLayers.forEach { $0.removeAnimation(forKey: "look") }
    }
}
