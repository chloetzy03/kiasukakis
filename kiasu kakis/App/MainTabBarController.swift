import UIKit

final class MainTabBarController: UITabBarController {

    private enum Tab: Int { case explore, myQueues, saved }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            makeTab(title: "Explore", symbol: "map", root: ExploreRouter.createModule()),
            makeTab(title: "My Queues", symbol: "ticket", root: MyQueuesRouter.createModule()),
            makeTab(title: "Saved", symbol: "bookmark", root: SavedRouter.createModule())
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showPrototypeNoticeIfNeeded()
    }

    // Shown once, the first time the app opens.
    private func showPrototypeNoticeIfNeeded() {
        let key = "hasSeenPrototypeNotice"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        let alert = UIAlertController(title: "Welcome to Kiasu Kakis",
                                      message: "This is a prototype. Venues, wait times and queues are simulated for demonstration. Real places found on the map come from Apple Maps and have no queue data.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    // Jumps to My Queues and opens the given ticket.
    func showTicket(_ ticketID: UUID) {
        selectedIndex = Tab.myQueues.rawValue
        guard let nav = viewControllers?[Tab.myQueues.rawValue] as? UINavigationController else { return }
        nav.popToRootViewController(animated: false)
        nav.pushViewController(TicketDetailRouter.createModule(ticketID: ticketID), animated: false)
    }

    private func makeTab(title: String, symbol: String, root: UIViewController) -> UINavigationController {
        root.title = title
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: nil)
        return nav
    }
}
