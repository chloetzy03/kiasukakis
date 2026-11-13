import UIKit

// The bottom sheet on the Explore screen. It has three faces:
// a ranked list of queues, a summary of the selected place, and an empty state when nothing nearby has a queue.
final class QueueSheetView: UIView {

    enum Mode { case list, detail }

    // Actions the screen listens for.
    var onSelectRow: ((Int) -> Void)?
    var onTapJoin: (() -> Void)?
    var onTapDetails: (() -> Void)?
    var onTapSave: (() -> Void)?
    var onClose: (() -> Void)?
    var onTapEmptyAction: (() -> Void)?

    // The area the user can drag to move the sheet.
    let headerView = UIView()
    private(set) var mode: Mode = .list
    private(set) var listModel: QueueListViewModel?

    // Extra space at the bottom so content is not hidden behind the tab bar.
    var bottomInset: CGFloat = 0 {
        didSet {
            guard bottomInset != oldValue else { return }
            tableBottom.constant = -bottomInset
            detailBottom.constant = -(bottomInset + 12)
            emptyBottom.constant = -(bottomInset + 12)
        }
    }

    // How much of the sheet shows in its smallest list position: the header and one row.
    var peekHeight: CGFloat { headerHeight + 66 }
    private let headerHeight: CGFloat = 64

    private let grabber = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var tableBottom: NSLayoutConstraint!

    private let detailView = UIView()
    private let nameLabel = UILabel()
    private let detailSubtitle = UILabel()
    private let waitDot = UIView()
    private let waitLabel = UILabel()
    private let sourceLabel = UILabel()
    private let queueLabel = UILabel()
    private let joinButton = UIButton(type: .system)
    private let detailsButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var detailBottom: NSLayoutConstraint!

    private let emptyView = UIView()
    private let emptyEyes = EyesView(radius: 17, gap: 25)
    private let emptyTitle = UILabel()
    private let emptyMessage = UILabel()
    private let emptyButton = UIButton(type: .system)
    private var emptyBottom: NSLayoutConstraint!

    private var rows: [QueueRowViewModel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.surface
        layer.cornerRadius = 22
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: -2)
        buildHeader()
        buildTable()
        buildDetail()
        buildEmpty()
        // The close button was added early, so later views (the summary) would cover part of it and eat the taps.
        bringSubviewToFront(closeButton)
        showListFace()
        enableDynamicType()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // MARK: - Layout

    private func buildHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)

        grabber.backgroundColor = Theme.secondaryText.withAlphaComponent(0.35)
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(grabber)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.accessibilityTraits = .header
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = Theme.secondaryText
        subtitleLabel.textAlignment = .right
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 8
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleRow)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: headerHeight),
            grabber.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 38),
            grabber.heightAnchor.constraint(equalToConstant: 5),
            titleRow.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
            titleRow.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 18),
            titleRow.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -18),
            titleRow.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10)
        ])

        var closeConfig = UIButton.Configuration.plain()
        closeConfig.image = UIImage(systemName: "xmark.circle.fill")
        closeConfig.baseForegroundColor = Theme.secondaryText
        closeButton.configuration = closeConfig
        closeButton.accessibilityLabel = "Close"
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func buildTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(QueueRowCell.self, forCellReuseIdentifier: QueueRowCell.reuseID)
        tableView.contentInset.bottom = 8
        addSubview(tableView)
        // The list ends above the tab bar, so rows never show through it.
        tableBottom = tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableBottom
        ])
    }

    private func buildDetail() {
        nameLabel.font = UIFont.preferredFont(forTextStyle: .title3).withBoldTrait()
        nameLabel.numberOfLines = 0
        nameLabel.accessibilityTraits = .header
        detailSubtitle.font = .preferredFont(forTextStyle: .footnote)
        detailSubtitle.textColor = Theme.secondaryText
        detailSubtitle.numberOfLines = 0

        waitDot.layer.cornerRadius = 7
        waitDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([waitDot.widthAnchor.constraint(equalToConstant: 14),
                                     waitDot.heightAnchor.constraint(equalToConstant: 14)])
        waitLabel.font = UIFont.preferredFont(forTextStyle: .title2).withBoldTrait()
        let waitRow = UIStackView(arrangedSubviews: [waitDot, waitLabel, UIView()])
        waitRow.spacing = 8
        waitRow.alignment = .center

        sourceLabel.font = .preferredFont(forTextStyle: .caption1)
        sourceLabel.textColor = Theme.secondaryText
        sourceLabel.numberOfLines = 0
        queueLabel.font = .preferredFont(forTextStyle: .subheadline)
        queueLabel.textColor = Theme.brandText
        queueLabel.numberOfLines = 0

        var joinConfig = UIButton.Configuration.filled()
        joinConfig.cornerStyle = .large
        joinConfig.baseBackgroundColor = Theme.brand
        joinConfig.buttonSize = .large
        joinButton.configuration = joinConfig
        joinButton.addAction(UIAction { [weak self] _ in self?.onTapJoin?() }, for: .touchUpInside)

        var detailsConfig = UIButton.Configuration.tinted()
        detailsConfig.title = "Details"
        detailsConfig.image = UIImage(systemName: "chevron.right")
        detailsConfig.imagePlacement = .trailing
        detailsConfig.imagePadding = 4
        detailsConfig.cornerStyle = .large
        detailsConfig.baseForegroundColor = Theme.brandText
        detailsConfig.baseBackgroundColor = Theme.brand
        detailsButton.configuration = detailsConfig
        detailsButton.addAction(UIAction { [weak self] _ in self?.onTapDetails?() }, for: .touchUpInside)

        // Save sits beside Details, away from the close button, so the two can't be tapped by mistake.
        saveButton.addAction(UIAction { [weak self] _ in self?.onTapSave?() }, for: .touchUpInside)
        let secondaryActions = UIStackView(arrangedSubviews: [saveButton, detailsButton])
        secondaryActions.spacing = 10
        secondaryActions.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [nameLabel, detailSubtitle, waitRow, sourceLabel, queueLabel, joinButton, secondaryActions])
        stack.axis = .vertical
        stack.spacing = 6
        stack.setCustomSpacing(12, after: detailSubtitle)
        stack.setCustomSpacing(12, after: queueLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        detailView.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(stack)
        addSubview(detailView)
        detailBottom = detailView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        NSLayoutConstraint.activate([
            detailView.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            detailView.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: trailingAnchor),
            detailBottom,
            stack.topAnchor.constraint(equalTo: detailView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -52),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: detailView.bottomAnchor)
        ])
        // The buttons use the full width, so they get their own trailing edge.
        joinButton.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -18).isActive = true
        secondaryActions.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -18).isActive = true
    }

    private func buildEmpty() {
        // The eyes are white, so they sit on a red tile to show up on the cream sheet.
        let eyesTile = UIView()
        eyesTile.backgroundColor = Theme.brand
        eyesTile.layer.cornerRadius = 16
        eyesTile.isAccessibilityElement = false
        emptyEyes.translatesAutoresizingMaskIntoConstraints = false
        eyesTile.translatesAutoresizingMaskIntoConstraints = false
        eyesTile.addSubview(emptyEyes)
        NSLayoutConstraint.activate([
            emptyEyes.topAnchor.constraint(equalTo: eyesTile.topAnchor, constant: 8),
            emptyEyes.bottomAnchor.constraint(equalTo: eyesTile.bottomAnchor, constant: -8),
            emptyEyes.leadingAnchor.constraint(equalTo: eyesTile.leadingAnchor, constant: 18),
            emptyEyes.trailingAnchor.constraint(equalTo: eyesTile.trailingAnchor, constant: -18)
        ])
        emptyTitle.font = UIFont.preferredFont(forTextStyle: .headline)
        emptyTitle.textAlignment = .center
        emptyTitle.numberOfLines = 0
        emptyMessage.font = .preferredFont(forTextStyle: .footnote)
        emptyMessage.textColor = Theme.secondaryText
        emptyMessage.textAlignment = .center
        emptyMessage.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .large
        config.baseBackgroundColor = Theme.brand
        emptyButton.configuration = config
        emptyButton.addAction(UIAction { [weak self] _ in self?.onTapEmptyAction?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [eyesTile, emptyTitle, emptyMessage, emptyButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(12, after: emptyMessage)
        stack.translatesAutoresizingMaskIntoConstraints = false

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(stack)
        addSubview(emptyView)
        emptyBottom = emptyView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            emptyView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyBottom,
            stack.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: emptyView.bottomAnchor)
        ])
    }

    // MARK: - Showing things

    func showList(_ model: QueueListViewModel) {
        guard model != listModel else { return }
        listModel = model
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        rows = model.rows
        tableView.reloadData()
        if mode == .list { showListFace() }
        emptyTitle.text = model.empty?.title
        emptyMessage.text = model.empty?.message
        var config = emptyButton.configuration
        config?.title = model.empty?.buttonTitle
        emptyButton.configuration = config
        emptyButton.isHidden = model.empty?.buttonTitle == nil
        if model.empty != nil { emptyEyes.startLooking() } else { emptyEyes.stopLooking() }
        if mode == .list { showListFace() }
    }

    func showDetail(_ model: VenuePreviewViewModel) {
        mode = .detail
        nameLabel.text = model.name
        detailSubtitle.text = model.subtitle
        waitLabel.text = model.waitText
        waitLabel.accessibilityLabel = "Current wait, " + QueueFormatting.spoken(model.waitText)
        waitDot.backgroundColor = model.waitColor
        sourceLabel.text = model.sourceText
        sourceLabel.accessibilityLabel = QueueFormatting.spoken(model.sourceText)
        queueLabel.text = model.queueText
        var config = joinButton.configuration
        config?.title = model.joinTitle
        joinButton.configuration = config
        joinButton.isEnabled = model.canJoin
        var saveConfig = UIButton.Configuration.tinted()
        saveConfig.title = model.isSaved ? "Saved" : "Save"
        saveConfig.image = UIImage(systemName: model.isSaved ? "bookmark.fill" : "bookmark")
        saveConfig.imagePadding = 6
        saveConfig.cornerStyle = .large
        saveConfig.baseForegroundColor = Theme.brandText
        saveConfig.baseBackgroundColor = Theme.brand
        saveButton.configuration = saveConfig
        saveButton.accessibilityLabel = model.isSaved ? "Remove from saved" : "Save this place"
        showDetailFace()
    }

    func showListAgain() {
        mode = .list
        showListFace()
    }

    private func showListFace() {
        let isEmpty = listModel?.empty != nil
        headerView.isHidden = false
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        closeButton.isHidden = true
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        detailView.isHidden = true
    }

    private func showDetailFace() {
        headerView.isHidden = false
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        closeButton.isHidden = false
        tableView.isHidden = true
        emptyView.isHidden = true
        detailView.isHidden = false
    }

    // MARK: - Sizes the screen needs to pick the sheet's height

    func detailHeight(width: CGFloat) -> CGFloat {
        layoutIfNeeded()
        let target = CGSize(width: width - 70, height: UIView.layoutFittingCompressedSize.height)
        let stack = detailView.subviews[0]
        return 28 + 16 + stack.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required,
                                                       verticalFittingPriority: .fittingSizeLevel).height
    }

    func emptyHeight(width: CGFloat) -> CGFloat {
        let stack = emptyView.subviews[0]
        let target = CGSize(width: width - 48, height: UIView.layoutFittingCompressedSize.height)
        return headerHeight + 4 + 20 + stack.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required,
                                                                     verticalFittingPriority: .fittingSizeLevel).height
    }
}

// MARK: - Table

extension QueueSheetView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: QueueRowCell.reuseID, for: indexPath) as! QueueRowCell
        cell.configure(with: rows[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectRow?(indexPath.row)
    }
}

// MARK: - Row

final class QueueRowCell: UITableViewCell {

    static let reuseID = "QueueRowCell"

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let badge = PaddedLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withBoldTrait()
        nameLabel.numberOfLines = 0
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = Theme.secondaryText
        subtitleLabel.numberOfLines = 0
        badge.font = UIFont.preferredFont(forTextStyle: .footnote).withBoldTrait()
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let texts = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        texts.axis = .vertical
        texts.spacing = 2
        let row = UIStackView(arrangedSubviews: [texts, badge])
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        contentView.enableDynamicType()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func configure(with model: QueueRowViewModel) {
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
        badge.text = model.waitText
        badge.backgroundColor = model.badgeColor
        badge.textColor = model.badgeTextColor
        accessibilityLabel = model.spoken
        accessibilityHint = "Shows this place's queue"
    }
}

// A label with space around its text, used for the wait badge.
final class PaddedLabel: UILabel {
    private let insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

private extension UIFont {
    func withBoldTrait() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
