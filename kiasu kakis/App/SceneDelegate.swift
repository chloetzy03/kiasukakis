import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    // A tapped alert can arrive before the main screen exists (cold launch), so remember it until then.
    private var pendingTicketID: UUID?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        LegacyDataMigration().runIfNeeded()
        // List rows use the warm card colour instead of pure white.
        UITableViewCell.appearance().backgroundColor = Theme.surface
        window.rootViewController = SplashViewController { [weak self] in self?.showMainScreen() }
        window.tintColor = Theme.brandText
        window.makeKeyAndVisible()
        self.window = window
        LocalTicketNotifier.shared.onOpenTicket = { [weak self] id in self?.openTicket(id) }
    }

    // The simulated queues only run while the app is on screen. Coming back also catches up the user's tickets.
    func sceneDidBecomeActive(_ scene: UIScene) {
        _ = QueueService.shared   // Make sure it is listening before the first tick.
        QueueSimulator.shared.start()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        QueueSimulator.shared.stop()
    }

    private func showMainScreen() {
        guard let window else { return }
        let duration = UIAccessibility.isReduceMotionEnabled ? 0 : 0.35
        UIView.transition(with: window, duration: duration, options: .transitionCrossDissolve) {
            window.rootViewController = MainTabBarController()
        }
        if let id = pendingTicketID { openTicket(id) }
    }

    private func openTicket(_ id: UUID) {
        guard let tabs = window?.rootViewController as? MainTabBarController else { pendingTicketID = id; return }
        pendingTicketID = nil
        tabs.showTicket(id)
    }
}
