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
