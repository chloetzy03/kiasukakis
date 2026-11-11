import UIKit
import MapKit
import CoreLocation

// The View: shows what the presenter tells it and forwards taps. It holds no business logic.
final class ExploreViewController: UIViewController {

    var presenter: ExplorePresenterProtocol!

    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let chipStack = UIStackView()
    private let infoButton = UIButton(type: .infoLight)
    private let topOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let offlineLabel = UILabel()
    private let previewCard = VenuePreviewCardView()
    private let emptyLabel = UILabel()
    private let locateButton = UIButton(type: .system)
    private let searchAreaButton = UIButton(type: .system)
    private let resultsTable = UITableView(frame: .zero, style: .plain)
    private let resultsFooter = UILabel()
    private let resultsEmptyLabel = UILabel()
    private var suggestionRows: [SuggestionRowViewModel] = []
    private let locationManager = CLLocationManager()
    private static let singaporeBounds = SingaporeBounds()
    private var annotations: [String: VenueAnnotation] = [:]
    private var selectedChipIndex = 0
    private var previewHiddenConstraint: NSLayoutConstraint!
    private var previewShownConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.background
        setUpMap()
        setUpTopOverlay()
        setUpPreviewCard()
        setUpLocateButton()
        setUpSearchAreaButton()
        setUpEmptyLabel()
        setUpResultsList()
        locationManager.delegate = self
        presenter.viewDidLoad()
    }

    // MARK: - Layout

    private func setUpMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.pointOfInterestFilter = .excludingAll
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 1.2950, longitude: 103.8500),
                                             span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)),
                          animated: false)
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setUpTopOverlay() {
        searchBar.placeholder = "Search places"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        chipStack.spacing = 8
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(chipStack)
        NSLayoutConstraint.activate([
            chipStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            chipStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            chipStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            chipStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            chipStack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        scroll.heightAnchor.constraint(equalToConstant: 36).isActive = true

        infoButton.accessibilityLabel = "About Kiasu Kakis"
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        infoButton.setContentHuggingPriority(.required, for: .horizontal)
        let searchRow = UIStackView(arrangedSubviews: [searchBar, infoButton])
        searchRow.alignment = .center
        searchRow.isLayoutMarginsRelativeArrangement = true
        searchRow.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)

        offlineLabel.text = "You're offline. Showing venues saved on this device."
        offlineLabel.font = .preferredFont(forTextStyle: .caption1)
        offlineLabel.textColor = .white
        offlineLabel.backgroundColor = .systemGray
        offlineLabel.textAlignment = .center
        offlineLabel.numberOfLines = 0
        offlineLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [searchRow, scroll, offlineLabel])
        stack.axis = .vertical
        stack.spacing = 4

        let container = topOverlay
        container.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.contentView.addSubview(stack)
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }

    private func setUpPreviewCard() {
        previewCard.translatesAutoresizingMaskIntoConstraints = false
        previewCard.alpha = 0
        previewCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previewTapped)))
        view.addSubview(previewCard)
        previewShownConstraint = previewCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        previewHiddenConstraint = previewCard.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 20)
        NSLayoutConstraint.activate([
            previewCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewHiddenConstraint
        ])
    }

    private func setUpLocateButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "location.fill")
        config.baseBackgroundColor = Theme.surface
        config.baseForegroundColor = Theme.brandText
        config.cornerStyle = .capsule
        locateButton.configuration = config
        locateButton.accessibilityLabel = "Show my location"
        locateButton.addTarget(self, action: #selector(locateTapped), for: .touchUpInside)
        locateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locateButton)
        NSLayoutConstraint.activate([
            locateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locateButton.bottomAnchor.constraint(equalTo: previewCard.topAnchor, constant: -12),
            locateButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setUpSearchAreaButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Searching…"
        config.image = UIImage(systemName: "mappin.and.ellipse")
        config.imagePadding = 6
        config.baseBackgroundColor = Theme.brand
        config.cornerStyle = .capsule
        searchAreaButton.configuration = config
        searchAreaButton.addTarget(self, action: #selector(retrySearchTapped), for: .touchUpInside)
        searchAreaButton.translatesAutoresizingMaskIntoConstraints = false
        searchAreaButton.alpha = 0
        searchAreaButton.isHidden = true
        view.addSubview(searchAreaButton)
        NSLayoutConstraint.activate([
            searchAreaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchAreaButton.topAnchor.constraint(equalTo: topOverlay.bottomAnchor, constant: 12)
        ])
    }

    private func setUpEmptyLabel() {
        emptyLabel.font = .preferredFont(forTextStyle: .headline)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // The list of search results. It sits on top of the map while the user is searching.
    private func setUpResultsList() {
        resultsTable.translatesAutoresizingMaskIntoConstraints = false
        resultsTable.backgroundColor = Theme.background
        resultsTable.dataSource = self
        resultsTable.delegate = self
        resultsTable.keyboardDismissMode = .onDrag
        resultsTable.isHidden = true
        resultsTable.register(UITableViewCell.self, forCellReuseIdentifier: "suggestion")

        resultsFooter.font = .preferredFont(forTextStyle: .caption1)
        resultsFooter.textColor = .secondaryLabel
        resultsFooter.textAlignment = .center
        resultsFooter.numberOfLines = 0
        resultsFooter.adjustsFontForContentSizeCategory = true

        resultsEmptyLabel.font = .preferredFont(forTextStyle: .headline)
        resultsEmptyLabel.textColor = .secondaryLabel
        resultsEmptyLabel.textAlignment = .center
        resultsEmptyLabel.numberOfLines = 0
        resultsEmptyLabel.adjustsFontForContentSizeCategory = true

        view.addSubview(resultsTable)
        NSLayoutConstraint.activate([
            resultsTable.topAnchor.constraint(equalTo: topOverlay.bottomAnchor),
            resultsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func infoTapped() { presenter.didTapInfo() }

    @objc private func retrySearchTapped() { presenter.didTapRetrySearch() }

    @objc private func previewTapped() { presenter.didTapPreview() }

    @objc private func chipTapped(_ sender: UIButton) {
        presenter.didSelectCategory(at: sender.tag)
        updateChips(selectedIndex: sender.tag)
    }

    @objc private func locateTapped() {
        Task { @MainActor in
            do {
                let location = try await LocationService.shared.currentLocation()
                mapView.showsUserLocation = true
                if Self.singaporeBounds.contains(location.coordinate) {
                    mapView.setRegion(MKCoordinateRegion(center: location.coordinate,
                                                         latitudinalMeters: 1000, longitudinalMeters: 1000),
                                      animated: true)
                } else {
                    showOutsideSingaporeAlert(at: location.coordinate)
                }
            } catch LocationError.denied {
                showLocationOffAlert()
            } catch {
                showMessage(title: "Couldn't find you", message: "Your location isn't available right now. Please try again.")
            }
        }
    }

    // The app only has Singapore data, so a location elsewhere (like the simulator's default in California) is confusing.
    private func showOutsideSingaporeAlert(at coordinate: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "You're outside Singapore",
                                      message: "Kiasu Kakis only has places in Singapore.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stay in Singapore", style: .cancel))
        alert.addAction(UIAlertAction(title: "Go to my location", style: .default) { [weak self] _ in
            self?.mapView.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000),
                                    animated: true)
        })
        present(alert, animated: true)
    }

    private func showLocationOffAlert() {
        let alert = UIAlertController(title: "Location is off",
                                      message: "You can still search and browse the map. To see your location, turn it on in Settings.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        })
        present(alert, animated: true)
    }

    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateChips(selectedIndex: Int) {
        selectedChipIndex = selectedIndex
        for case let button as UIButton in chipStack.arrangedSubviews { button.setNeedsUpdateConfiguration() }
    }
}

// MARK: - ExploreViewProtocol

extension ExploreViewController: ExploreViewProtocol {

    func showCategories(_ titles: [String], selectedIndex: Int) {
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, title) in titles.enumerated() {
            var config = UIButton.Configuration.filled()
            config.title = title
            config.cornerStyle = .capsule
            config.buttonSize = .small
            let button = UIButton(configuration: config)
            button.tag = index
            // Runs whenever the button needs restyling, including when light/dark mode changes.
            button.configurationUpdateHandler = { [weak self] button in
                guard let self else { return }
                let selected = button.tag == self.selectedChipIndex
                button.configuration?.baseBackgroundColor = selected ? Theme.brand : Theme.surface
                button.configuration?.baseForegroundColor = selected ? .white : .label
            }
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipStack.addArrangedSubview(button)
        }
        updateChips(selectedIndex: selectedIndex)
    }

    func showPins(_ pins: [VenuePinViewModel], selectedID: String?) {
        // Update pins in place. Removing and re-adding them all would flicker, and would drop the selection,
        // which matters now that wait times change every few seconds.
        let newIDs = Set(pins.map(\.id))
        let removed = annotations.filter { !newIDs.contains($0.key) }
        mapView.removeAnnotations(Array(removed.values))
        removed.keys.forEach { annotations[$0] = nil }

        var added: [VenueAnnotation] = []
        for pin in pins {
            if let existing = annotations[pin.id] {
                guard existing.pin != pin else { continue }
                existing.pin = pin
                (mapView.view(for: existing) as? WaitPinView)?.configure(with: pin)
            } else {
                let annotation = VenueAnnotation(pin: pin)
                annotations[pin.id] = annotation
                added.append(annotation)
            }
        }
        mapView.addAnnotations(added)

        if let selectedID, let selected = annotations[selectedID],
           !mapView.selectedAnnotations.contains(where: { $0 === selected }) {
            mapView.selectAnnotation(selected, animated: false)
        }
    }

    func showPreview(_ preview: VenuePreviewViewModel?) {
        if let preview { previewCard.configure(with: preview) }
        previewHiddenConstraint.isActive = preview == nil
        previewShownConstraint.isActive = preview != nil
        UIView.animate(withDuration: 0.25) {
            self.previewCard.alpha = preview == nil ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }

    func showAreaStatus(_ status: AreaStatus) {
        var config = searchAreaButton.configuration
        config?.showsActivityIndicator = status == .searching
        config?.image = status == .searching ? nil : UIImage(systemName: "mappin.and.ellipse")
        switch status {
        case .hidden, .searching: config?.title = "Searching…"
        case .zoomIn: config?.title = "Zoom in to find places"
        case .failed: config?.title = "Couldn't search. Tap to retry"
        }
        searchAreaButton.configuration = config
        setSearchAreaVisible(status != .hidden)
    }

    private func setSearchAreaVisible(_ visible: Bool) {
        if visible { searchAreaButton.isHidden = false }
        UIView.animate(withDuration: 0.2, animations: {
            self.searchAreaButton.alpha = visible ? 1 : 0
        }, completion: { _ in
            self.searchAreaButton.isHidden = !visible && self.searchAreaButton.alpha == 0
        })
    }

    func showSuggestions(_ model: SuggestionsViewModel?) {
        guard let model else {
            resultsTable.isHidden = true
            suggestionRows = []
            return
        }
        suggestionRows = model.rows
        var footer: [String] = []
        if model.isLoading { footer.append("Searching…") }
        if model.showsGoogleAttribution { footer.append("Powered by Google") }
        resultsFooter.text = footer.joined(separator: "\n")
        resultsFooter.frame = CGRect(x: 0, y: 0, width: resultsTable.bounds.width, height: footer.isEmpty ? 0 : 52)
        resultsTable.tableFooterView = footer.isEmpty ? UIView(frame: .zero) : resultsFooter
        resultsEmptyLabel.text = model.emptyMessage
        resultsTable.backgroundView = model.emptyMessage == nil ? nil : resultsEmptyLabel
        resultsTable.isHidden = false
        resultsTable.reloadData()
    }

    func clearSearchText() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func focusMap(on region: MKCoordinateRegion) {
        mapView.setRegion(region, animated: true)
    }

    func showOfflineBanner(_ isVisible: Bool) {
        offlineLabel.isHidden = !isVisible
    }

    func showEmptyState(_ message: String?) {
        emptyLabel.text = message
        emptyLabel.isHidden = message == nil
    }
}

// MARK: - Map

final class VenueAnnotation: NSObject, MKAnnotation {
    var pin: VenuePinViewModel
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude) }
    var title: String? { pin.name }
    init(pin: VenuePinViewModel) { self.pin = pin }
}

extension ExploreViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? VenueAnnotation else { return nil }
        let pinView = (mapView.dequeueReusableAnnotationView(withIdentifier: WaitPinView.reuseID) as? WaitPinView)
            ?? WaitPinView(annotation: annotation, reuseIdentifier: WaitPinView.reuseID)
        pinView.annotation = annotation
        pinView.configure(with: annotation.pin)
        return pinView
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        presenter.didChangeRegion(mapView.region)
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let annotation = annotation as? VenueAnnotation else { return }
        presenter.didSelectVenue(id: annotation.pin.id)
    }

    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        guard annotation is VenueAnnotation else { return }
        // Skip while another pin is being selected so the card doesn't flicker.
        DispatchQueue.main.async { [weak self] in
            if self?.mapView.selectedAnnotations.isEmpty == true { self?.presenter.didDeselectVenue() }
        }
    }
}

// MARK: - Search + location

extension ExploreViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.didChangeSearch(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        presenter.didChangeSearch("")
    }
}

extension ExploreViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: mapView.showsUserLocation = true
        default: mapView.showsUserLocation = false
        }
    }
}

// A rough box around Singapore.
struct SingaporeBounds {
    func contains(_ c: CLLocationCoordinate2D) -> Bool {
        (1.15...1.48).contains(c.latitude) && (103.55...104.10).contains(c.longitude)
    }
}

// MARK: - Search results list

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { suggestionRows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion", for: indexPath)
        let row = suggestionRows[indexPath.row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = row.title
        content.secondaryText = row.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.image = UIImage(systemName: row.symbolName)
        content.imageProperties.tintColor = Theme.brandText
        cell.contentConfiguration = content
        cell.backgroundColor = Theme.surface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectSuggestion(at: indexPath.row)
    }
}
