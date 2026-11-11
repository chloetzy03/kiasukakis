import UIKit

final class JoinQueueViewController: UIViewController {

    var presenter: JoinQueuePresenterProtocol!

    private let venueLabel = UILabel()
    private let waitDot = UIView()
    private let waitLabel = UILabel()
    private let aheadLabel = UILabel()
    private let sourceLabel = UILabel()
    private let partyValueLabel = UILabel()
    private let stepper = UIStepper()
    private let warningLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Join queue"
        view.backgroundColor = Theme.background
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.presenter.didTapClose()
        })
        buildLayout()
        presenter.viewDidLoad()
    }

    private func buildLayout() {
        venueLabel.font = .preferredFont(forTextStyle: .title2).withBold()
        venueLabel.numberOfLines = 0

        // Simulated conditions card
        waitDot.layer.cornerRadius = 7
        waitDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([waitDot.widthAnchor.constraint(equalToConstant: 14),
                                     waitDot.heightAnchor.constraint(equalToConstant: 14)])
        waitLabel.font = .preferredFont(forTextStyle: .title3).withBold()
        let waitRow = UIStackView(arrangedSubviews: [waitDot, waitLabel, UIView()])
        waitRow.spacing = 8
        waitRow.alignment = .center
        aheadLabel.font = .preferredFont(forTextStyle: .subheadline)
        sourceLabel.font = .preferredFont(forTextStyle: .footnote)
        sourceLabel.textColor = .secondaryLabel
        let conditions = card([caption("QUEUE CONDITIONS"), waitRow, aheadLabel, sourceLabel])

        // Party size card
        partyValueLabel.font = .preferredFont(forTextStyle: .body)
        stepper.minimumValue = 1
        stepper.maximumValue = 8
        stepper.value = 1
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        let partyRow = UIStackView(arrangedSubviews: [partyValueLabel, UIView(), stepper])
        partyRow.alignment = .center
        let party = card([caption("PARTY SIZE"), partyRow])

        warningLabel.font = .preferredFont(forTextStyle: .subheadline)
        warningLabel.textColor = .systemRed
        warningLabel.numberOfLines = 0
        warningLabel.isHidden = true

        var config = UIButton.Configuration.filled()
        config.title = "Confirm and join"
        config.baseBackgroundColor = Theme.brand
        config.cornerStyle = .large
        config.buttonSize = .large
        confirmButton.configuration = config
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [venueLabel, conditions, party, warningLabel, confirmButton])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }

    private func card(_ views: [UIView]) -> UIView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.backgroundColor = Theme.surface
        container.layer.cornerRadius = 14
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }

    @objc private func stepperChanged() { presenter.didChangePartySize(Int(stepper.value)) }
    @objc private func confirmTapped() { presenter.didTapConfirm() }
}

extension JoinQueueViewController: JoinQueueViewProtocol {

    func show(_ model: JoinQueueViewModel) {
        venueLabel.text = model.venueName
        waitLabel.text = model.waitText
        waitLabel.textColor = .label
        waitDot.backgroundColor = model.waitColor
        aheadLabel.text = model.aheadText
        sourceLabel.text = model.sourceText
        partyValueLabel.text = model.partySizeText
        confirmButton.isEnabled = model.canJoin
        warningLabel.text = model.unavailableMessage
        warningLabel.isHidden = model.unavailableMessage == nil
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Can't join", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension UIFont {
    func withBold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
