import UIKit

// Card that slides up when a pin is selected.
final class VenuePreviewCardView: UIView {

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let waitLabel = UILabel()
    private let sourceLabel = UILabel()
    private let queueLabel = UILabel()
    private let dot = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.surface
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 3)

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel
        waitLabel.font = .preferredFont(forTextStyle: .title3).bold()
        sourceLabel.font = .preferredFont(forTextStyle: .caption1)
        sourceLabel.textColor = .secondaryLabel
        sourceLabel.numberOfLines = 0
        queueLabel.font = .preferredFont(forTextStyle: .subheadline)
        queueLabel.textColor = Theme.brandText

        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let waitRow = UIStackView(arrangedSubviews: [dot, waitLabel, UIView()])
        waitRow.spacing = 8
        waitRow.alignment = .center

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel, waitRow, sourceLabel, queueLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [textStack, chevron])
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func configure(with model: VenuePreviewViewModel) {
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
        waitLabel.text = model.waitText
        waitLabel.textColor = .label
        dot.backgroundColor = model.waitColor
        sourceLabel.text = model.sourceText
        queueLabel.text = model.queueText
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
