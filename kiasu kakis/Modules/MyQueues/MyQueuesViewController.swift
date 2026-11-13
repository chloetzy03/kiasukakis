import UIKit

final class MyQueuesViewController: UIViewController {

    var presenter: MyQueuesPresenterProtocol!

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UIStackView()
    private var sections: [TicketSectionViewModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TicketCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        let icon = UIImageView(image: UIImage(systemName: "ticket"))
        icon.tintColor = Theme.brandText
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let heading = UILabel()
        heading.text = "No tickets yet"
        heading.font = .preferredFont(forTextStyle: .title2)
        let message = UILabel()
        message.text = "Join a queue from a venue and your ticket will show up here."
        message.font = .preferredFont(forTextStyle: .body)
        message.textColor = Theme.secondaryText
        message.numberOfLines = 0
        message.textAlignment = .center
        [icon, heading, message].forEach(emptyView.addArrangedSubview)
        emptyView.axis = .vertical
        emptyView.alignment = .center
        emptyView.spacing = 12
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 16),
            emptyView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }
}

extension MyQueuesViewController: MyQueuesViewProtocol {

    func show(sections: [TicketSectionViewModel]) {
        self.sections = sections
        tableView.reloadData()
    }

    func showEmptyState(_ isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}

extension MyQueuesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.secondaryText = row.subtitle
        content.secondaryTextProperties.color = Theme.secondaryText
        content.image = UIImage(systemName: "circle.fill")
        content.imageProperties.tintColor = row.statusColor
        content.imageProperties.maximumSize = CGSize(width: 12, height: 12)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Swipe right to save the place. Swipe left to delete a finished ticket.
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = sections[indexPath.section].rows[indexPath.row]
        let action = UIContextualAction(style: .normal, title: row.isSaved ? "Unsave" : "Save") { [weak self] _, _, done in
            self?.presenter.didToggleSaved(ticketID: row.id)
            done(true)
        }
        action.image = UIImage(systemName: row.isSaved ? "bookmark.slash" : "bookmark")
        action.backgroundColor = Theme.saveAction
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = sections[indexPath.section].rows[indexPath.row]
        guard row.canDelete else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.presenter.didDeleteTicket(id: row.id)
            done(true)
        }
        // A long swipe must not delete by accident, so the person has to tap the Delete button.
        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectTicket(id: sections[indexPath.section].rows[indexPath.row].id)
    }
}
