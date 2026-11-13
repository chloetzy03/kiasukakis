import UIKit
import MapKit

// Map pin drawn as a small coloured pill such as "15m". Real places with no queue data are tiny grey dots.
final class WaitPinView: MKAnnotationView {

    static let reuseID = "WaitPin"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "Shows a summary of this place"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func configure(with pin: VenuePinViewModel) {
        accessibilityLabel = pin.spokenText
        if pin.isPlaceDot {
            image = Self.dotImage()
            centerOffset = .zero
            // Dots never hide each other, so every real place stays visible.
            collisionMode = .none
            displayPriority = .defaultLow
        } else {
            let pill = Self.pillImage(text: pin.labelText, symbol: pin.symbolName,
                                      fill: pin.fillColor, textColor: pin.textColor)
            image = pill
            centerOffset = CGPoint(x: 0, y: -pill.size.height / 2)
            collisionMode = .rectangle
            // Featured places always show. Others are hidden when they would overlap, and appear as you zoom in.
            displayPriority = pin.isFeatured ? .required : .defaultHigh
        }
    }

    // The selected pin grows a little.
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let scale: CGFloat = selected ? 1.2 : 1
        UIView.animate(withDuration: animated ? Motion.duration(0.15) : 0) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    // MARK: - Drawing

    private static let margin: CGFloat = 4

    private static func pillImage(text: String, symbol: String?, fill: UIColor, textColor: UIColor) -> UIImage {
        let baseFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let font = baseFont.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 13) } ?? baseFont
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let icon = symbol.flatMap {
            UIImage(systemName: $0, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))?
                .withTintColor(textColor, renderingMode: .alwaysOriginal)
        }

        let padding: CGFloat = 9, height: CGFloat = 28, pointer: CGFloat = 7, border: CGFloat = 2
        let iconWidth = icon.map { $0.size.width + 4 } ?? 0
        let pillWidth = ceil(padding * 2 + iconWidth + textSize.width)
        let size = CGSize(width: pillWidth + (margin + border) * 2,
                          height: height + pointer + (margin + border) * 2)

        return UIGraphicsImageRenderer(size: size).image { context in
            let inset = margin + border
            let pillRect = CGRect(x: inset, y: inset, width: pillWidth, height: height)
            let path = UIBezierPath(roundedRect: pillRect, cornerRadius: height / 2)
            let midX = size.width / 2
            path.move(to: CGPoint(x: midX - 6, y: pillRect.maxY - 1))
            path.addLine(to: CGPoint(x: midX, y: pillRect.maxY + pointer))
            path.addLine(to: CGPoint(x: midX + 6, y: pillRect.maxY - 1))
            path.close()

            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3,
                                        color: UIColor.black.withAlphaComponent(0.3).cgColor)
            path.lineWidth = border * 2
            path.lineJoinStyle = .round
            UIColor.white.setStroke()
            path.stroke()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            fill.setFill()
            path.fill()

            var x = pillRect.minX + padding
            if let icon {
                icon.draw(at: CGPoint(x: x, y: pillRect.midY - icon.size.height / 2))
                x += iconWidth
            }
            (text as NSString).draw(at: CGPoint(x: x, y: pillRect.midY - textSize.height / 2),
                                    withAttributes: [.font: font, .foregroundColor: textColor])
        }
    }

    private static func dotImage() -> UIImage {
        let diameter: CGFloat = 14
        let size = CGSize(width: diameter + margin * 2, height: diameter + margin * 2)
        return UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(x: margin, y: margin, width: diameter, height: diameter)
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 2,
                                        color: UIColor.black.withAlphaComponent(0.3).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: rect).fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            UIColor.systemGray.setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2)).fill()
        }
    }
}
