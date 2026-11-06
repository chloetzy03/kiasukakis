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
    private var userIsMovingMap = false
    private let offlineLabel = UILabel()
    private let previewCard = VenuePreviewCardView()
    private let emptyLabel = UILabel()
    private let locateButton = UIButton(type: .system)
    private let searchAreaButton = UIButton(type: .system)
    private let locationManager = CLLocationManager()
    private var annotations: [String: VenueAnnotation] = [:]
    private var selectedChipIndex = 0
    private var previewHiddenConstraint: NSLayoutConstraint!
    private var previewShownConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        setUpMap()
        setUpTopOverlay()
        setUpPreviewCard()
        setUpLocateButton()
        setUpSearchAreaButton()
        setUpEmptyLabel()
        locationManager.delegate = self
        presenter.viewDidLoad()
    }

    // MARK: - Layout

    private func setUpMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.pointOfInterestFilter = .excludingAll
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 1.2950, longitude: 103.8500),
                                             span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)),
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
        searchBar.placeholder = "Search venues"
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
        config.baseBackgroundColor = .systemBackground
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
        config.title = "Find places here"
        config.image = UIImage(systemName: "mappin.and.ellipse")
        config.imagePadding = 6
        config.baseBackgroundColor = Theme.brand
        config.cornerStyle = .capsule
        searchAreaButton.configuration = config
        searchAreaButton.addTarget(self, action: #selector(searchAreaTapped), for: .touchUpInside)
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

    // MARK: - Actions

    @objc private func infoTapped() { presenter.didTapInfo() }

    @objc private func searchAreaTapped() { presenter.didTapSearchArea(in: mapView.region) }

    @objc private func previewTapped() { presenter.didTapPreview() }

    @objc private func chipTapped(_ sender: UIButton) {
        presenter.didSelectCategory(at: sender.tag)
        updateChips(selectedIndex: sender.tag)
    }

    @objc private func locateTapped() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
            if let coordinate = mapView.userLocation.location?.coordinate {
                mapView.setCenter(coordinate, animated: true)
            }
        default:
            let alert = UIAlertController(title: "Location is off",
                                          message: "You can still search and browse the map. To see your location, turn it on in Settings.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            })
            present(alert, animated: true)
        }
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
                button.configuration?.baseBackgroundColor = selected ? Theme.brand : .secondarySystemBackground
                button.configuration?.baseForegroundColor = selected ? .white : .label
            }
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipStack.addArrangedSubview(button)
        }
        updateChips(selectedIndex: selectedIndex)
    }

    func showPins(_ pins: [VenuePinViewModel], selectedID: String?) {
        mapView.removeAnnotations(Array(annotations.values))
        annotations = Dictionary(uniqueKeysWithValues: pins.map { ($0.id, VenueAnnotation(pin: $0)) })
        mapView.addAnnotations(Array(annotations.values))
        if let selectedID, let selected = annotations[selectedID] {
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

    func showSearching(_ isSearching: Bool) {
        var config = searchAreaButton.configuration
        config?.showsActivityIndicator = isSearching
        config?.title = isSearching ? "Searching…" : "Find places here"
        searchAreaButton.configuration = config
        searchAreaButton.isEnabled = !isSearching
        if !isSearching { setSearchAreaVisible(false) }
    }

    private func setSearchAreaVisible(_ visible: Bool) {
        if visible { searchAreaButton.isHidden = false }
        UIView.animate(withDuration: 0.2, animations: {
            self.searchAreaButton.alpha = visible ? 1 : 0
        }, completion: { _ in
            self.searchAreaButton.isHidden = !visible
        })
    }

    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
    let pin: VenuePinViewModel
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

    // The "Find places here" button only appears after the user moves the map.
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let recognizers = mapView.subviews.first?.gestureRecognizers ?? []
        userIsMovingMap = recognizers.contains { $0.state == .began || $0.state == .ended }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if userIsMovingMap { setSearchAreaVisible(true) }
        userIsMovingMap = false
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
}

extension ExploreViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: mapView.showsUserLocation = true
        default: mapView.showsUserLocation = false
        }
    }
}
