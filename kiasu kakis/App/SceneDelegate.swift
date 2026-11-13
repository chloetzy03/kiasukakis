import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

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
    }
}
