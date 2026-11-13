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
    private let sheet = QueueSheetView()
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
    private var sheetTop: NSLayoutConstraint!
    private var sheetStop: SheetStop = .peek
    // Where the sheet goes back to after a place summary is closed.
    private var listStop: SheetStop = .peek
    private var sheetPanStart: CGFloat = 0
    private var isDraggingSheet = false

    private enum SheetStop { case peek, half, full, detail, empty }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.background
        setUpMap()
        setUpTopOverlay()
        setUpSheet()
        setUpLocateButton()
        setUpSearchAreaButton()
        setUpResultsList()
        searchBar.accessibilityLabel = "Search places"
        view.enableDynamicType()
        locationManager.delegate = self
        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The map gets the whole screen. The venue details page brings the bar back when it is pushed.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        presenter.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sheet.bottomInset = coveredBottom
        if !isDraggingSheet { sheetTop.constant = top(for: sheetStop) }
        updateLocateVisibility()
    }

    // The tab bar can cover more than the safe area reports, so use whichever is larger.
    private var coveredBottom: CGFloat {
        var covered = view.safeAreaInsets.bottom
        if let tabBar = tabBarController?.tabBar, !tabBar.isHidden {
            let frame = view.convert(tabBar.bounds, from: tabBar)
            covered = max(covered, view.bounds.maxY - frame.minY)
        }
        return covered
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
        // The Cancel button beside the field already clears the text and closes the keyboard, so a second cross inside the field is redundant.
        searchBar.searchTextField.clearButtonMode = .never
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
            chipStack.centerYAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerYAnchor),
            scroll.frameLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: chipStack.heightAnchor),
            scroll.frameLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        infoButton.accessibilityLabel = "About and settings"
        infoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        infoButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
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

    private func setUpSheet() {
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)
        sheetTop = sheet.topAnchor.constraint(equalTo: view.topAnchor, constant: 10_000)
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetTop
        ])
        sheet.onSelectRow = { [weak self] index in self?.presenter.didSelectQueueRow(at: index) }
        sheet.onTapJoin = { [weak self] in self?.presenter.didTapSheetJoin() }
        sheet.onTapDetails = { [weak self] in self?.presenter.didTapPreview() }
        sheet.onTapSave = { [weak self] in self?.presenter.didTapSheetSave() }
        sheet.onTapEmptyAction = { [weak self] in self?.presenter.didTapNearestQueue() }
        sheet.onClose = { [weak self] in self?.closeSummary() }

        // Dragging the header moves the sheet. Tapping it opens or closes the list.
        sheet.headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(sheetPanned(_:))))
        sheet.headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sheetHeaderTapped)))
        sheet.headerView.isAccessibilityElement = true
        sheet.headerView.accessibilityLabel = "Queues in this area"
        sheet.headerView.accessibilityTraits = .header
        sheet.headerView.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Show more of the list") { [weak self] _ in self?.moveSheet(toward: .full); return true },
            UIAccessibilityCustomAction(name: "Show less of the list") { [weak self] _ in self?.moveSheet(toward: .peek); return true }
        ]
    }

    // MARK: - Sheet positions

    private func visibleHeight(for stop: SheetStop) -> CGFloat {
        let height = view.bounds.height
        let bottom = coveredBottom
        switch stop {
        case .peek: return sheet.peekHeight + bottom
        case .half: return height * 0.5
        case .full: return height - topOverlay.frame.maxY - 8
        case .detail: return sheet.detailHeight(width: view.bounds.width) + bottom
        case .empty: return sheet.emptyHeight(width: view.bounds.width) + bottom
        }
    }

    private func top(for stop: SheetStop) -> CGFloat { view.bounds.height - visibleHeight(for: stop) }

    private func setSheetStop(_ stop: SheetStop, animated: Bool) {
        sheetStop = stop
        if stop == .peek || stop == .half || stop == .full { listStop = stop }
        sheetTop.constant = top(for: stop)
        let changes = { self.view.layoutIfNeeded(); self.updateLocateVisibility() }
        guard animated, !UIAccessibility.isReduceMotionEnabled else { changes(); return }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4,
                       options: [.allowUserInteraction, .beginFromCurrentState], animations: changes)
    }

    // The locate button rides on top of the sheet, and hides when the sheet is too tall for it.
    private func updateLocateVisibility() {
        let visible = view.bounds.height - sheetTop.constant
        locateButton.alpha = visible > view.bounds.height * 0.62 ? 0 : 1
    }

    private func availableStops() -> [SheetStop] {
        switch sheet.mode {
        case .detail: return [.detail]
        case .list: return sheet.listModel?.empty != nil ? [.empty] : [.peek, .half, .full]
        }
    }

    private func moveSheet(toward stop: SheetStop) {
        guard sheet.mode == .list, sheet.listModel?.empty == nil else { return }
        setSheetStop(stop, animated: true)
    }

    @objc private func sheetHeaderTapped() {
        guard sheet.mode == .list, sheet.listModel?.empty == nil else { return }
        setSheetStop(sheetStop == .peek ? .half : .peek, animated: true)
    }

    @objc private func sheetPanned(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            isDraggingSheet = true
            sheetPanStart = sheetTop.constant
        case .changed:
            let stops = availableStops()
            let highest = stops.map { top(for: $0) }.min() ?? 0
            let lowest = stops.map { top(for: $0) }.max() ?? 0
            let proposed = sheetPanStart + pan.translation(in: view).y
            // A little give past the ends, so it feels like it is attached to the finger.
            let limited = proposed < highest ? highest - (highest - proposed) * 0.2
                : proposed > lowest ? lowest + (proposed - lowest) * (sheet.mode == .detail ? 1 : 0.2) : proposed
            sheetTop.constant = limited
            view.layoutIfNeeded()
            updateLocateVisibility()
        case .ended, .cancelled:
            isDraggingSheet = false
            let velocity = pan.velocity(in: view).y
            let projected = sheetTop.constant + velocity * 0.15
            if sheet.mode == .detail {
                // Pulled down far enough (or flicked down): close the summary.
                if projected - top(for: .detail) > 90 { closeSummary() } else { setSheetStop(.detail, animated: true) }
                return
            }
            let nearest = availableStops().min { abs(top(for: $0) - projected) < abs(top(for: $1) - projected) } ?? .peek
            setSheetStop(nearest, animated: true)
        default: break
        }
    }

    private func closeSummary() {
        mapView.selectedAnnotations.forEach { mapView.deselectAnnotation($0, animated: true) }
        presenter.didDeselectVenue()
    }

    private func setUpLocateButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "location.fill")
        config.baseBackgroundColor = Theme.surface
        config.baseForegroundColor = Theme.brandText
        config.cornerStyle = .capsule
        locateButton.configuration = config
        locateButton.accessibilityLabel = "Show my location"
        locateButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        locateButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        locateButton.addTarget(self, action: #selector(locateTapped), for: .touchUpInside)
        locateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locateButton)
        NSLayoutConstraint.activate([
            locateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locateButton.bottomAnchor.constraint(equalTo: sheet.topAnchor, constant: -12)
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
        searchAreaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        view.addSubview(searchAreaButton)
        NSLayoutConstraint.activate([
            searchAreaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchAreaButton.topAnchor.constraint(equalTo: topOverlay.bottomAnchor, constant: 12)
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
        resultsFooter.textColor = Theme.secondaryText
        resultsFooter.textAlignment = .center
        resultsFooter.numberOfLines = 0
        resultsFooter.adjustsFontForContentSizeCategory = true

        resultsEmptyLabel.font = .preferredFont(forTextStyle: .headline)
        resultsEmptyLabel.textColor = Theme.secondaryText
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
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
                return attributes
            }
            let button = RoomyButton(configuration: config)
            button.tag = index
            // Runs whenever the button needs restyling, including when light/dark mode changes.
            button.configurationUpdateHandler = { [weak self] button in
                guard let self else { return }
                let selected = button.tag == self.selectedChipIndex
                button.configuration?.baseBackgroundColor = selected ? Theme.brand : Theme.surface
                button.configuration?.baseForegroundColor = selected ? .white : .label
                button.accessibilityTraits = selected ? [.button, .selected] : .button
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
        if let preview {
            let wasDetail = sheet.mode == .detail
            sheet.showDetail(preview)
            if !wasDetail || sheetStop != .detail { setSheetStop(.detail, animated: true) }
        } else if sheet.mode == .detail {
            sheet.showListAgain()
            setSheetStop(sheet.listModel?.empty != nil ? .empty : listStop, animated: true)
        }
    }

    func showQueueList(_ model: QueueListViewModel) {
        sheet.showList(model)
        guard sheet.mode == .list else { return }
        if model.empty != nil, sheetStop != .empty {
            setSheetStop(.empty, animated: true)
        } else if model.empty == nil, sheetStop == .empty {
            setSheetStop(listStop, animated: true)
        } else if !isDraggingSheet {
            // A live update can change how tall the empty state is, so keep the position in step.
            sheetTop.constant = top(for: sheetStop)
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
        // The pill appears without the user touching anything, so say it out loud for VoiceOver.
        if status == .zoomIn || status == .failed, let title = config?.title {
            UIAccessibility.post(notification: .announcement, argument: title)
        }
    }

    private func setSearchAreaVisible(_ visible: Bool) {
        if visible { searchAreaButton.isHidden = false }
        UIView.animate(withDuration: Motion.duration(0.2), animations: {
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
        content.secondaryTextProperties.color = Theme.secondaryText
        content.image = UIImage(systemName: row.symbolName)
        content.imageProperties.tintColor = Theme.brandText
        cell.contentConfiguration = content
        cell.accessibilityLabel = [row.title, row.subtitle].joined(separator: ", ")
        cell.backgroundColor = Theme.surface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectSuggestion(at: indexPath.row)
    }
}
