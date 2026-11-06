import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            makeTab(title: "Explore", symbol: "map",
                    root: PlaceholderViewController(symbol: "map",
                                                    heading: "Find your next spot",
                                                    message: "Map-based queue discovery arrives in Milestone 2.")),
            makeTab(title: "My Queues", symbol: "ticket",
                    root: PlaceholderViewController(symbol: "ticket",
                                                    heading: "No active tickets",
                                                    message: "Join a demo queue from a venue and it will show up here.")),
            makeTab(title: "Saved", symbol: "bookmark",
                    root: PlaceholderViewController(symbol: "bookmark",
                                                    heading: "No saved venues yet",
                                                    message: "Bookmark venues to find them quickly later."))
        ]
    }

    private func makeTab(title: String, symbol: String, root: UIViewController) -> UINavigationController {
        root.title = title
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: nil)
        return nav
    }
}
