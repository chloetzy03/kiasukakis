import UIKit
import MapKit
import CoreLocation

// The View: shows what the presenter tells it and forwards taps. It holds no business logic.
final class ExploreViewController: UIViewController {

    var presenter: ExplorePresenterProtocol!

    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let chipStack = UIStackView()
    private let demoLabel = UILabel()
    private let offlineLabel = UILabel()
    private let previewCard = VenuePreviewCardView()
    private let emptyLabel = UILabel()
    private let locateButton = UIButton(type: .system)
    private let searchAreaButton = UIButton(type: .system)
    private let locationManager = CLLocationManager()
    private var annotations: [String: VenueAnnotation] = [:]
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

        demoLabel.text = "Demo venues and wait times are fictional"
        demoLabel.font = .preferredFont(forTextStyle: .caption2)
        demoLabel.textColor = .secondaryLabel
        demoLabel.textAlignment = .center

        offlineLabel.text = "You're offline. Showing demo data stored on this device."
        offlineLabel.font = .preferredFont(forTextStyle: .caption1)
        offlineLabel.textColor = .white
        offlineLabel.backgroundColor = .systemGray
        offlineLabel.textAlignment = .center
        offlineLabel.numberOfLines = 0
        offlineLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [searchBar, scroll, demoLabel, offlineLabel])
        stack.axis = .vertical
        stack.spacing = 4

        let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
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
        config.baseForegroundColor = Theme.brand
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
        config.title = "Search this area"
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePadding = 6
        config.baseBackgroundColor = Theme.brand
        config.cornerStyle = .capsule
        searchAreaButton.configuration = config
        searchAreaButton.addTarget(self, action: #selector(searchAreaTapped), for: .touchUpInside)
        searchAreaButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchAreaButton)
        NSLayoutConstraint.activate([
            searchAreaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchAreaButton.centerYAnchor.constraint(equalTo: locateButton.centerYAnchor)
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
        for case let button as UIButton in chipStack.arrangedSubviews {
            var config = button.configuration
            let selected = button.tag == selectedIndex
            config?.baseBackgroundColor = selected ? Theme.brand : .secondarySystemBackground
            config?.baseForegroundColor = selected ? .white : .label
            button.configuration = config
        }
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
        config?.title = isSearching ? "Searching…" : "Search this area"
        searchAreaButton.configuration = config
        searchAreaButton.isEnabled = !isSearching
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
        let id = "VenuePin"
        let marker = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        marker.annotation = annotation
        marker.markerTintColor = annotation.pin.color
        marker.glyphText = annotation.pin.glyph
        marker.titleVisibility = .hidden
        marker.canShowCallout = false
        marker.displayPriority = .required
        return marker
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
