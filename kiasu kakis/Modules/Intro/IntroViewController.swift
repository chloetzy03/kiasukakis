import UIKit

// Three short cards shown the first time the app opens. It replaces a wall-of-text alert.
final class IntroViewController: UIViewController, UIScrollViewDelegate {

    private struct Page {
        let symbol: String
        let title: String
        let text: String
    }

    private static let pages = [
        Page(symbol: "map.fill", title: "See the wait",
             text: "Pins show how long each queue is. Green is short, red is long."),
        Page(symbol: "ticket.fill", title: "Join from your phone",
             text: "Tap a place and join. No standing in line."),
        Page(symbol: "bell.fill", title: "Walk in when we alert you",
             text: "We tell you when you're next. This is a prototype: the places are real, but the queues are simulated.")
    ]

    var onFinish: (() -> Void)?

    private let scroll = UIScrollView()
    private let pageControl = UIPageControl()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private var pageIndex = 0 { didSet { updateControls() } }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        buildPages()
        buildControls()
        updateControls()
    }

    private func buildPages() {
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = self
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let row = UIStackView()
        row.axis = .horizontal
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        for page in Self.pages { row.addArrangedSubview(makePage(page)) }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -130),
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        for page in row.arrangedSubviews {
            page.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor).isActive = true
        }
    }

    private func makePage(_ page: Page) -> UIView {
        let tile = UIView()
        tile.backgroundColor = Theme.brand
        tile.layer.cornerRadius = 36
        tile.isAccessibilityElement = false
        let icon = UIImageView(image: UIImage(systemName: page.symbol))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(icon)
        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: 140),
            tile.heightAnchor.constraint(equalToConstant: 140),
            icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 72),
            icon.heightAnchor.constraint(equalToConstant: 72)
        ])

        let title = UILabel()
        title.text = page.title
        title.font = UIFont.preferredFont(forTextStyle: .title1).withTraits(.traitBold)
        title.textAlignment = .center
        title.numberOfLines = 0
        let text = UILabel()
        text.text = page.text
        text.font = .preferredFont(forTextStyle: .body)
        text.textColor = Theme.secondaryText
        text.textAlignment = .center
        text.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [tile, title, text])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.setCustomSpacing(32, after: tile)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.enableDynamicType()

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32)
        ])
        return container
    }

    private func buildControls() {
        pageControl.numberOfPages = Self.pages.count
        pageControl.currentPageIndicatorTintColor = Theme.brand
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Theme.brand
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        nextButton.configuration = config
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addAction(UIAction { [weak self] _ in self?.nextTapped() }, for: .touchUpInside)

        var skipConfig = UIButton.Configuration.plain()
        skipConfig.title = "Skip"
        skipConfig.baseForegroundColor = Theme.secondaryText
        skipButton.configuration = skipConfig
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addAction(UIAction { [weak self] _ in self?.finish() }, for: .touchUpInside)

        view.addSubview(pageControl)
        view.addSubview(nextButton)
        view.addSubview(skipButton)
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func updateControls() {
        pageControl.currentPage = pageIndex
        let last = pageIndex == Self.pages.count - 1
        var config = nextButton.configuration
        config?.title = last ? "Get started" : "Next"
        nextButton.configuration = config
        skipButton.isHidden = last
    }

    private func nextTapped() {
        if pageIndex == Self.pages.count - 1 { finish(); return }
        let target = CGPoint(x: scroll.bounds.width * CGFloat(pageIndex + 1), y: 0)
        scroll.setContentOffset(target, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    private func finish() {
        dismiss(animated: true) { [onFinish] in onFinish?() }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        pageIndex = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
