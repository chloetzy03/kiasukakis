import UIKit

final class TicketDetailViewController: UIViewController {

    var presenter: TicketDetailPresenterProtocol!

    private let venueLabel = UILabel()
    private let numberLabel = UILabel()
    private let statusPill = UILabel()
    private let positionValue = UILabel()
    private let nowServingValue = UILabel()
    private let estimateValue = UILabel()
    private let partyValue = UILabel()
    private let messageLabel = UILabel()
    private let stepsStack = UIStackView()
    private var stepBars: [UIView] = []
    private var stepLabels: [UILabel] = []
    private let advanceButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let proximityActionButton = UIButton(type: .system)
    private let stepTitles = ["Waiting", "Almost", "Called", "Done"]
    private var lastStatus: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My ticket"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.background
        buildLayout()
        view.enableDynamicType()
        presenter.viewDidLoad()
    }

    private func buildLayout() {
        venueLabel.font = .preferredFont(forTextStyle: .title2).withBold()
        venueLabel.textAlignment = .center
        venueLabel.numberOfLines = 0

        numberLabel.font = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: UIFont.monospacedDigitSystemFont(ofSize: 64, weight: .bold), maximumPointSize: 96)
        numberLabel.adjustsFontForContentSizeCategory = true
        numberLabel.textAlignment = .center
        numberLabel.adjustsFontSizeToFitWidth = true

        statusPill.font = .preferredFont(forTextStyle: .subheadline).withBold()
        statusPill.textColor = .white
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 14
        statusPill.clipsToBounds = true
        statusPill.setContentHuggingPriority(.required, for: .horizontal)
        statusPill.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        let pillWidth = statusPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        pillWidth.isActive = true
        let pillRow = UIStackView(arrangedSubviews: [UIView(), statusPill, UIView()])
        pillRow.distribution = .equalCentering

        let ticketCard = card([venueLabel, numberLabel, pillRow], alignment: .fill, spacing: 10)

        stepsStack.distribution = .fillEqually
        stepsStack.spacing = 6
        for title in stepTitles {
            let bar = UIView()
            bar.layer.cornerRadius = 3
            bar.heightAnchor.constraint(equalToConstant: 6).isActive = true
            let label = UILabel()
            label.text = title
            label.font = .preferredFont(forTextStyle: .caption2)
            label.textAlignment = .center
            // Long words shrink a little instead of turning into "Wai…" at large text sizes.
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            let column = UIStackView(arrangedSubviews: [bar, label])
            column.axis = .vertical
            column.spacing = 4
            stepsStack.addArrangedSubview(column)
            stepBars.append(bar)
            stepLabels.append(label)
        }

        messageLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // Small, quiet control that stands in for the venue calling customers.
        var advanceConfig = UIButton.Configuration.plain()
        advanceConfig.baseForegroundColor = Theme.secondaryText
        advanceConfig.buttonSize = .small
        advanceButton.configuration = advanceConfig
        advanceButton.addTarget(self, action: #selector(advanceTapped), for: .touchUpInside)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Leave queue"
        cancelConfig.baseForegroundColor = .systemRed
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        var actionConfig = UIButton.Configuration.plain()
        actionConfig.baseForegroundColor = Theme.brandText
        proximityActionButton.configuration = actionConfig
        proximityActionButton.addTarget(self, action: #selector(proximityActionTapped), for: .touchUpInside)
        let info = card([infoRow("Position", positionValue),
                         infoRow("Now serving", nowServingValue),
                         infoRow("Estimated wait", estimateValue),
                         infoRow("Party size", partyValue)], alignment: .fill, spacing: 10)

        let content = UIStackView(arrangedSubviews: [ticketCard, stepsStack, messageLabel, proximityActionButton, info, cancelButton, advanceButton])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func infoRow(_ title: String, _ value: UILabel) -> UIView {
        let name = UILabel()
        name.text = title
        name.font = .preferredFont(forTextStyle: .subheadline)
        name.textColor = Theme.secondaryText
        value.font = .preferredFont(forTextStyle: .subheadline).withBold()
        value.textAlignment = .right
        value.numberOfLines = 0
        return UIStackView(arrangedSubviews: [name, value])
    }

    private func card(_ views: [UIView], alignment: UIStackView.Alignment, spacing: CGFloat) -> UIView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.alignment = alignment
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.backgroundColor = Theme.surface
        container.layer.cornerRadius = 14
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }

    @objc private func advanceTapped() { presenter.didTapAdvance() }
    @objc private func cancelTapped() { presenter.didTapCancel() }
    @objc private func proximityActionTapped() { presenter.didTapProximityAction() }
}

extension TicketDetailViewController: TicketDetailViewProtocol {

    func show(_ model: TicketDetailViewModel) {
        venueLabel.text = model.venueName
        numberLabel.text = model.ticketNumberText
        statusPill.text = model.statusText
        // VoiceOver would read "#061" as "number sign zero six one".
        if let number = Int(model.ticketNumberText.dropFirst()) { numberLabel.accessibilityLabel = "Ticket number \(number)" }
        // The status changes by itself now, so tell VoiceOver users when it does.
        if let lastStatus, lastStatus != model.statusText {
            UIAccessibility.post(notification: .announcement, argument: "Your ticket is now \(model.statusText). \(model.positionText).")
        }
        lastStatus = model.statusText
        statusPill.backgroundColor = model.statusColor
        positionValue.text = model.positionText
        nowServingValue.text = model.nowServingText
        estimateValue.text = model.estimateText
        partyValue.text = model.partyText
        messageLabel.text = model.message
        messageLabel.isHidden = model.message.isEmpty

        stepsStack.isHidden = model.stepIndex == nil
        // The four coloured bars read as one progress indicator.
        stepsStack.isAccessibilityElement = true
        stepsStack.accessibilityLabel = "Progress"
        if let current = model.stepIndex { stepsStack.accessibilityValue = "Step \(current + 1) of \(stepTitles.count): \(stepTitles[current])" }
        if let current = model.stepIndex {
            for index in stepBars.indices {
                stepBars[index].backgroundColor = index <= current ? model.statusColor : .systemGray5
                stepLabels[index].textColor = index == current ? .label : Theme.secondaryText
            }
        }

        var config = advanceButton.configuration
        config?.title = model.advanceTitle
        advanceButton.configuration = config
        advanceButton.isHidden = !model.canAdvance
        cancelButton.isHidden = !model.canCancel

        var action = proximityActionButton.configuration
        action?.title = model.promptActionTitle
        proximityActionButton.configuration = action
        proximityActionButton.isHidden = model.promptActionTitle == nil
    }

    func askToConfirmCancel() {
        let alert = UIAlertController(title: "Leave this queue?",
                                      message: "Your ticket will be cancelled.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stay", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave queue", style: .destructive) { [weak self] _ in
            self?.presenter.didConfirmCancel()
        })
        present(alert, animated: true)
    }
}

private extension UIFont {
    func withBold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
