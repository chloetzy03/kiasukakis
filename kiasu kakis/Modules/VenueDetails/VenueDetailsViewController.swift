import UIKit

final class VenueDetailsViewController: UIViewController {

    var presenter: VenueDetailsPresenterProtocol!

    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let addressLabel = UILabel()
    private let waitDot = UIView()
    private let waitLabel = UILabel()
    private let sourceLabel = UILabel()
    private let updatedLabel = UILabel()
    private let travelSpinner = UIActivityIndicatorView(style: .medium)
    private let travelSummaryLabel = UILabel()
    private let travelHintLabel = UILabel()
    private let travelActionButton = UIButton(type: .system)
    private let disclaimerLabel = UILabel()
    private let statusIcon = UIImageView()
    private let statusTitleLabel = UILabel()
    private let statusMessageLabel = UILabel()
    private let joinButton = UIButton(type: .system)
    private let mapsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        buildLayout()
        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    // MARK: - Layout

    private func buildLayout() {
        nameLabel.font = .preferredFont(forTextStyle: .title1).withTraits(.traitBold)
        nameLabel.numberOfLines = 0
        categoryLabel.font = .preferredFont(forTextStyle: .subheadline)
        categoryLabel.textColor = Theme.brandText
        addressLabel.font = .preferredFont(forTextStyle: .subheadline)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 0

        let header = UIStackView(arrangedSubviews: [categoryLabel, nameLabel, addressLabel])
        header.axis = .vertical
        header.spacing = 4

        // Wait card
        let waitTitle = caption("CURRENT WAIT")
        waitDot.layer.cornerRadius = 7
        waitDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([waitDot.widthAnchor.constraint(equalToConstant: 14),
                                     waitDot.heightAnchor.constraint(equalToConstant: 14)])
        waitLabel.font = .preferredFont(forTextStyle: .title2).withTraits(.traitBold)
        let waitRow = UIStackView(arrangedSubviews: [waitDot, waitLabel, UIView()])
        waitRow.spacing = 8
        waitRow.alignment = .center
        sourceLabel.font = .preferredFont(forTextStyle: .footnote)
        updatedLabel.font = .preferredFont(forTextStyle: .footnote)
        updatedLabel.textColor = .secondaryLabel
        updatedLabel.numberOfLines = 0
        let waitCard = card([waitTitle, waitRow, sourceLabel, updatedLabel])

        // Travel card
        travelSummaryLabel.font = .preferredFont(forTextStyle: .headline)
        travelSummaryLabel.numberOfLines = 0
        travelHintLabel.font = .preferredFont(forTextStyle: .footnote)
        travelHintLabel.textColor = .secondaryLabel
        travelHintLabel.numberOfLines = 0
        travelActionButton.configuration = .plain()
        travelActionButton.contentHorizontalAlignment = .leading
        travelActionButton.addTarget(self, action: #selector(travelActionTapped), for: .touchUpInside)
        let travelRow = UIStackView(arrangedSubviews: [travelSpinner, travelSummaryLabel])
        travelRow.spacing = 8
        travelRow.alignment = .center
        let travelCard = card([caption("GETTING THERE"), travelRow, travelHintLabel, travelActionButton])

        // Queue status card
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.setContentHuggingPriority(.required, for: .horizontal)
        statusIcon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        statusTitleLabel.font = .preferredFont(forTextStyle: .headline)
        statusTitleLabel.numberOfLines = 0
        statusMessageLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusMessageLabel.textColor = .secondaryLabel
        statusMessageLabel.numberOfLines = 0
        let statusText = UIStackView(arrangedSubviews: [statusTitleLabel, statusMessageLabel])
        statusText.axis = .vertical
        statusText.spacing = 4
        let statusRow = UIStackView(arrangedSubviews: [statusIcon, statusText])
        statusRow.spacing = 12
        statusRow.alignment = .top
        let statusCard = card([caption("VIRTUAL QUEUE"), statusRow])

        // Buttons
        var joinConfig = UIButton.Configuration.filled()
        joinConfig.cornerStyle = .large
        joinConfig.baseBackgroundColor = Theme.brand
        joinConfig.buttonSize = .large
        joinButton.configuration = joinConfig
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)

        var mapsConfig = UIButton.Configuration.tinted()
        mapsConfig.title = "View on map"
        mapsConfig.image = UIImage(systemName: "map")
        mapsConfig.imagePadding = 8
        mapsConfig.cornerStyle = .large
        mapsConfig.buttonSize = .large
        mapsButton.configuration = mapsConfig
        mapsButton.addTarget(self, action: #selector(mapsTapped), for: .touchUpInside)

        let disclaimer = disclaimerLabel
        disclaimer.font = .preferredFont(forTextStyle: .caption1)
        disclaimer.textColor = .secondaryLabel
        disclaimer.textAlignment = .center
        disclaimer.numberOfLines = 0

        let content = UIStackView(arrangedSubviews: [header, waitCard, travelCard, statusCard, joinButton, mapsButton, disclaimer])
        content.axis = .vertical
        content.spacing = 16
        content.setCustomSpacing(20, after: header)
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
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
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
        container.backgroundColor = .secondarySystemGroupedBackground
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

    // MARK: - Actions

    @objc private func joinTapped() { presenter.didTapJoin() }
    @objc private func mapsTapped() { presenter.didTapOpenInMaps() }
    @objc private func travelActionTapped() { presenter.didTapTravelAction() }
    @objc private func saveTapped() { presenter.didTapSave() }
}

// MARK: - VenueDetailsViewProtocol

extension VenueDetailsViewController: VenueDetailsViewProtocol {

    func showTravel(_ model: TravelViewModel) {
        model.isLoading ? travelSpinner.startAnimating() : travelSpinner.stopAnimating()
        travelSummaryLabel.text = model.summary
        travelHintLabel.text = model.hint
        travelHintLabel.isHidden = model.hint == nil
        var config = travelActionButton.configuration
        config?.title = model.actionTitle
        travelActionButton.configuration = config
        travelActionButton.isHidden = model.actionTitle == nil
    }

    func show(_ model: VenueDetailsViewModel) {
        title = model.name
        nameLabel.text = model.name
        categoryLabel.text = model.categoryText.uppercased()
        addressLabel.text = model.address
        waitLabel.text = model.waitText
        waitLabel.textColor = model.waitColor
        waitDot.backgroundColor = model.waitColor
        sourceLabel.text = model.sourceText
        updatedLabel.text = model.updatedText
        statusIcon.image = UIImage(systemName: model.statusSymbol)
        statusIcon.tintColor = model.statusColor
        statusTitleLabel.text = model.statusTitle
        statusMessageLabel.text = model.statusMessage
        disclaimerLabel.text = model.disclaimer

        var config = joinButton.configuration
        config?.title = model.hasActiveTicket ? "View my ticket" : (model.canJoin ? "Join demo queue" : model.statusTitle)
        joinButton.configuration = config
        joinButton.isEnabled = model.canJoin || model.hasActiveTicket

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: model.isSaved ? "bookmark.fill" : "bookmark"),
            style: .plain, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.accessibilityLabel = model.isSaved ? "Remove from saved" : "Save venue"
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
