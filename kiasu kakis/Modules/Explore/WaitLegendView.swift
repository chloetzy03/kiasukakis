import UIKit

// A small key for the pin colours, so first-time users know what green and orange mean.
final class WaitLegendView: UIView {

    private static let items: [(UIColor, String)] = [
        (Theme.waitShort, "Under 15 min"),
        (Theme.waitMedium, "15–30"),
        (Theme.waitLong, "30+")
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.layer.cornerRadius = 15
        blur.clipsToBounds = true
        addSubview(blur)

        let row = UIStackView(arrangedSubviews: Self.items.map { makeItem(color: $0.0, text: $0.1) })
        row.axis = .horizontal
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(row)
        row.enableDynamicType()

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 7),
            row.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -7),
            row.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -12)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "Pin colours: green is under 15 minutes, orange is 15 to 30, red is over 30."
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func makeItem(color: UIColor, text: String) -> UIView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .label
        let item = UIStackView(arrangedSubviews: [dot, label])
        item.spacing = 5
        item.alignment = .center
        return item
    }
}
