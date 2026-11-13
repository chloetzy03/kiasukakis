import UIKit

// Static information screen, so it doesn't need the full VIPER split.
final class AboutViewController: UIViewController {

    private let iconService: AppIconChanging = AppIconService()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About & Settings"
        view.backgroundColor = Theme.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })

        let sections: [(String, String)] = [
            ("Kiasu Kakis", "A Singapore queue companion: see how long the wait is, join a virtual queue and head over when it's your turn. This is a student prototype."),
            ("Simulated data", "The places are real, but their wait times and tickets are simulated for demonstration. Other food places found on the map are real locations from Apple Maps or Google and have no queue data."),
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
            bodyLabel.textColor = Theme.secondaryText
            bodyLabel.numberOfLines = 0
            let section = UIStackView(arrangedSubviews: [headingLabel, bodyLabel])
            section.axis = .vertical
            section.spacing = 6
            stack.addArrangedSubview(section)
        }
        stack.addArrangedSubview(makeSpeedSection())
        if iconService.isSupported { stack.addArrangedSubview(makeIconSection()) }
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        stack.enableDynamicType()
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // Demo speed is for showing the app quickly. Realistic speed shows how a real queue would feel.
    private func makeSpeedSection() -> UIView {
        let heading = UILabel()
        heading.text = "Queue simulation speed"
        heading.font = .preferredFont(forTextStyle: .headline)

        let control = UISegmentedControl(items: SimulationSpeed.allCases.map(\.title))
        control.selectedSegmentIndex = SimulationSpeed.allCases.firstIndex(of: QueueSimulator.shared.speed) ?? 0
        control.accessibilityLabel = "Queue simulation speed"

        let detail = UILabel()
        detail.font = .preferredFont(forTextStyle: .footnote)
        detail.textColor = Theme.secondaryText
        detail.numberOfLines = 0
        detail.text = QueueSimulator.shared.speed.detail

        control.addAction(UIAction { [weak control, weak detail] _ in
            guard let control else { return }
            let speed = SimulationSpeed.allCases[control.selectedSegmentIndex]
            QueueSimulator.shared.speed = speed
            detail?.text = speed.detail
        }, for: .valueChanged)

        let section = UIStackView(arrangedSubviews: [heading, control, detail])
        section.axis = .vertical
        section.spacing = 8
        return section
    }

    // iOS shows its own "You have changed the icon" alert when this changes, which the app can't hide.
    private func makeIconSection() -> UIView {
        let heading = UILabel()
        heading.text = "Home screen icon"
        heading.font = .preferredFont(forTextStyle: .headline)

        let control = UISegmentedControl(items: AppIconChoice.allCases.map(\.title))
        control.selectedSegmentIndex = AppIconChoice.allCases.firstIndex(of: iconService.current) ?? 0
        control.accessibilityLabel = "Home screen icon"

        let detail = UILabel()
        detail.font = .preferredFont(forTextStyle: .footnote)
        detail.textColor = Theme.secondaryText
        detail.numberOfLines = 0
        detail.text = "Automatic follows your iPhone's light and dark appearance."

        control.addAction(UIAction { [weak self, weak control] _ in
            guard let self, let control else { return }
            let choice = AppIconChoice.allCases[control.selectedSegmentIndex]
            iconService.select(choice) { ok in
                if !ok { control.selectedSegmentIndex = AppIconChoice.allCases.firstIndex(of: self.iconService.current) ?? 0 }
            }
        }, for: .valueChanged)

        let section = UIStackView(arrangedSubviews: [heading, control, detail])
        section.axis = .vertical
        section.spacing = 8
        return section
    }
}
