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
    private let stepTitles = ["Waiting", "Almost", "Called", "Done"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My ticket"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        buildLayout()
        presenter.viewDidLoad()
    }

    private func buildLayout() {
        let banner = UILabel()
        banner.text = "DEMO TICKET · SIMULATED QUEUE"
        banner.font = .preferredFont(forTextStyle: .caption1)
        banner.textColor = Theme.brandText
        banner.textAlignment = .center

        venueLabel.font = .preferredFont(forTextStyle: .title2).withBold()
        venueLabel.textAlignment = .center
        venueLabel.numberOfLines = 0

        numberLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 64, weight: .bold)
        numberLabel.textAlignment = .center
        numberLabel.adjustsFontSizeToFitWidth = true

        statusPill.font = .preferredFont(forTextStyle: .subheadline).withBold()
        statusPill.textColor = .white
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 14
        statusPill.clipsToBounds = true
        statusPill.setContentHuggingPriority(.required, for: .horizontal)
        statusPill.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let pillWidth = statusPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        pillWidth.isActive = true
        let pillRow = UIStackView(arrangedSubviews: [UIView(), statusPill, UIView()])
        pillRow.distribution = .equalCentering

        let ticketCard = card([venueLabel, numberLabel, pillRow], alignment: .fill, spacing: 10)

        let info = card([infoRow("Position", positionValue),
                         infoRow("Now serving", nowServingValue),
                         infoRow("Estimated wait", estimateValue),
                         infoRow("Party size", partyValue)], alignment: .fill, spacing: 10)

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
            let column = UIStackView(arrangedSubviews: [bar, label])
            column.axis = .vertical
            column.spacing = 4
            stepsStack.addArrangedSubview(column)
            stepBars.append(bar)
            stepLabels.append(label)
        }

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var advanceConfig = UIButton.Configuration.tinted()
        advanceConfig.cornerStyle = .large
        advanceConfig.buttonSize = .large
        advanceConfig.image = UIImage(systemName: "forward.fill")
        advanceConfig.imagePadding = 8
        advanceButton.configuration = advanceConfig
        advanceButton.addTarget(self, action: #selector(advanceTapped), for: .touchUpInside)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Leave queue"
        cancelConfig.baseForegroundColor = .systemRed
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let footnote = UILabel()
        footnote.text = "The demo button stands in for the venue calling customers. In a real queue, only the venue would move it forward."
        footnote.font = .preferredFont(forTextStyle: .caption1)
        footnote.textColor = .secondaryLabel
        footnote.numberOfLines = 0
        footnote.textAlignment = .center

        let content = UIStackView(arrangedSubviews: [banner, ticketCard, stepsStack, messageLabel, info, advanceButton, cancelButton, footnote])
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
        name.textColor = .secondaryLabel
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
        container.backgroundColor = .secondarySystemGroupedBackground
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
}

extension TicketDetailViewController: TicketDetailViewProtocol {

    func show(_ model: TicketDetailViewModel) {
        venueLabel.text = model.venueName
        numberLabel.text = model.ticketNumberText
        statusPill.text = model.statusText
        statusPill.backgroundColor = model.statusColor
        positionValue.text = model.positionText
        nowServingValue.text = model.nowServingText
        estimateValue.text = model.estimateText
        partyValue.text = model.partyText
        messageLabel.text = model.message

        stepsStack.isHidden = model.stepIndex == nil
        if let current = model.stepIndex {
            for index in stepBars.indices {
                stepBars[index].backgroundColor = index <= current ? model.statusColor : .systemGray5
                stepLabels[index].textColor = index == current ? .label : .secondaryLabel
            }
        }

        var config = advanceButton.configuration
        config?.title = model.advanceTitle
        advanceButton.configuration = config
        advanceButton.isHidden = !model.canAdvance
        cancelButton.isHidden = !model.canCancel
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
