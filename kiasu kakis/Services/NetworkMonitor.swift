import Foundation
import Network

protocol NetworkMonitoring: AnyObject {
    var onStatusChange: ((Bool) -> Void)? { get set }
    func start()
}

// Reports whether the device currently has an internet connection.
final class NetworkMonitor: NetworkMonitoring {

    var onStatusChange: ((Bool) -> Void)?
    private let monitor = NWPathMonitor()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            DispatchQueue.main.async { self?.onStatusChange?(isOnline) }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    deinit { monitor.cancel() }
}
