import UIKit

// A row of pill-shaped filter buttons that scrolls sideways. One of them is selected at a time.
final class ChipBarView: UIView {

    // Called with the index of the chip the user tapped.
    var onSelect: ((Int) -> Void)?

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var titles: [String] = []
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerYAnchor),
            scroll.contentLayoutGuide.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // Does nothing when the titles and selection are unchanged, so live updates don't make the bar flicker.
    func setTitles(_ newTitles: [String], selectedIndex newSelection: Int) {
        guard newTitles != titles else { select(newSelection); return }
        titles = newTitles
        selectedIndex = newSelection
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, title) in newTitles.enumerated() {
            stack.addArrangedSubview(makeChip(title: title, index: index))
        }
    }

    func select(_ index: Int) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        for case let chip as UIButton in stack.arrangedSubviews { chip.setNeedsUpdateConfiguration() }
        // Keep the selected chip on screen, for example when a filter is chosen from outside the bar.
        if stack.arrangedSubviews.indices.contains(index) {
            layoutIfNeeded()
            scroll.scrollRectToVisible(stack.arrangedSubviews[index].frame.insetBy(dx: -16, dy: 0), animated: true)
        }
    }

    private func makeChip(title: String, index: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.buttonSize = .small
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
            return attributes
        }
        // RoomyButton keeps the touch area at least 44 points even though the chip looks slimmer.
        let chip = RoomyButton(configuration: config)
        chip.tag = index
        // Runs whenever the chip needs restyling, including when light or dark mode changes.
        chip.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            let selected = button.tag == self.selectedIndex
            button.configuration?.baseBackgroundColor = selected ? Theme.brand : Theme.surface
            button.configuration?.baseForegroundColor = selected ? .white : .label
            button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
        chip.addAction(UIAction { [weak self] _ in
            self?.select(index)
            self?.onSelect?(index)
        }, for: .touchUpInside)
        return chip
    }
}
