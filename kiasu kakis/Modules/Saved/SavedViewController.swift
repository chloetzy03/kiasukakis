import UIKit

final class SavedViewController: UIViewController {

    var presenter: SavedPresenterProtocol!

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = UIStackView()
    private var rows: [SavedVenueRowViewModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavedCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        let icon = UIImageView(image: UIImage(systemName: "bookmark"))
        icon.tintColor = Theme.brandText
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let heading = UILabel()
        heading.text = "No saved venues yet"
        heading.font = .preferredFont(forTextStyle: .title2)
        let message = UILabel()
        message.text = "Tap the bookmark on a venue's page to keep it here for quick access."
        message.font = .preferredFont(forTextStyle: .body)
        message.textColor = .secondaryLabel
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

extension SavedViewController: SavedViewProtocol {

    func show(rows: [SavedVenueRowViewModel]) {
        self.rows = rows
        tableView.reloadData()
    }

    func showEmptyState(_ isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}

extension SavedViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = row.name
        content.secondaryText = row.subtitle
        content.image = UIImage(systemName: "circle.fill")
        content.imageProperties.tintColor = row.waitColor
        content.imageProperties.maximumSize = CGSize(width: 12, height: 12)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectVenue(id: rows[indexPath.row].id)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let id = rows[indexPath.row].id
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            self?.presenter.didRemoveVenue(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}
