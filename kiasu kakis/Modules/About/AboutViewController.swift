import UIKit

// Static information screen, so it doesn't need the full VIPER split.
final class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        view.backgroundColor = Theme.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })

        let sections: [(String, String)] = [
            ("Kiasu Kakis", "A Singapore queue companion: see how long the wait is, join a virtual queue and head over when it's your turn. This is a student prototype."),
            ("Simulated data", "Venues, wait times and tickets in this app are simulated for demonstration. Places found by searching or moving the map are real locations from Apple Maps or Google and have no queue data."),
            ("Maps and location", "Maps and travel times come from Apple Maps. Search suggestions, ratings, hours and photos come from Google Places. Your location is used only while the app is open, to show travel time and your position on the map.")
        ]

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        for (heading, body) in sections {
            let headingLabel = UILabel()
            headingLabel.text = heading
            headingLabel.font = .preferredFont(forTextStyle: .headline)
            let bodyLabel = UILabel()
            bodyLabel.text = body
            bodyLabel.font = .preferredFont(forTextStyle: .body)
            bodyLabel.textColor = .secondaryLabel
            bodyLabel.numberOfLines = 0
            let section = UIStackView(arrangedSubviews: [headingLabel, bodyLabel])
            section.axis = .vertical
            section.spacing = 6
            stack.addArrangedSubview(section)
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
