import UIKit

// The first screen after the system launch screen. Shows the food for this time of day while the app gets ready.
final class SplashViewController: UIViewController {

    private let food: SplashFood
    private let minimumDuration: TimeInterval
    private let onFinish: () -> Void

    private let foodImageView = UIImageView()
    private var eyesView: EyesView!
    private let nameLabel = UILabel()
    private let greetingLabel = UILabel()
    private let dotsStack = UIStackView()
    private var didSchedule = false

    private static let imageSize: CGFloat = 240

    init(food: SplashFood = .current,
         minimumDuration: TimeInterval = 1.4,
         onFinish: @escaping () -> Void) {
        self.food = food
        self.minimumDuration = minimumDuration
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Same colour as the system launch screen, so there is no flash between the two.
        view.backgroundColor = UIColor(named: "LaunchBackground")
        setUpFood()
        setUpLabels()
        setUpDots()
        layoutContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eyesView.startLooking()
        animateDots()
        guard !didSchedule else { return }
        didSchedule = true
        let delay = UIAccessibility.isReduceMotionEnabled ? min(minimumDuration, 0.6) : minimumDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.onFinish() }
    }

    // MARK: - Setup

    private func setUpFood() {
        foodImageView.image = UIImage(named: food.imageName)
        foodImageView.contentMode = .scaleAspectFit
        foodImageView.isAccessibilityElement = false
        foodImageView.translatesAutoresizingMaskIntoConstraints = false

        let size = Self.imageSize
        let layout = food.eyes
        eyesView = EyesView(radius: layout.radius * size, gap: layout.gap * size)
        eyesView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setUpLabels() {
        let nameColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFF6EA) : UIColor(hex: 0xBD091C) }
        let bodyColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFF6EA) : UIColor(hex: 0x2A1215) }

        let rounded = UIFont.systemFont(ofSize: 34, weight: .heavy).fontDescriptor.withDesign(.rounded)
            .map { UIFont(descriptor: $0, size: 34) } ?? .systemFont(ofSize: 34, weight: .heavy)
        nameLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: rounded)
        nameLabel.text = "kiasu kakis"
        nameLabel.textColor = nameColor
        nameLabel.adjustsFontForContentSizeCategory = true

        greetingLabel.font = .preferredFont(forTextStyle: .subheadline)
        greetingLabel.text = food.greeting
        greetingLabel.textColor = bodyColor
        greetingLabel.numberOfLines = 0
        greetingLabel.textAlignment = .center
        greetingLabel.adjustsFontForContentSizeCategory = true

        nameLabel.textAlignment = .center
    }

    private func setUpDots() {
        dotsStack.axis = .horizontal
        dotsStack.spacing = 10
        dotsStack.isAccessibilityElement = false
        let dotColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFF6EA) : UIColor(hex: 0xBD091C) }
        for _ in 0..<4 {
            let dot = UIView()
            dot.backgroundColor = dotColor
            dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([dot.widthAnchor.constraint(equalToConstant: 10),
                                         dot.heightAnchor.constraint(equalToConstant: 10)])
            dotsStack.addArrangedSubview(dot)
        }
    }

    private func layoutContent() {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, greetingLabel, dotsStack])
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 10
        textStack.setCustomSpacing(22, after: greetingLabel)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(foodImageView)
        view.addSubview(eyesView)
        view.addSubview(textStack)

        let size = Self.imageSize
        let layout = food.eyes
        NSLayoutConstraint.activate([
            foodImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            foodImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            foodImageView.widthAnchor.constraint(equalToConstant: size),
            foodImageView.heightAnchor.constraint(equalToConstant: size),

            // The eyes view is centred on the spot where the eyes go on the picture.
            eyesView.centerXAnchor.constraint(equalTo: foodImageView.leadingAnchor, constant: layout.centerX * size),
            eyesView.centerYAnchor.constraint(equalTo: foodImageView.topAnchor, constant: layout.centerY * size),

            textStack.topAnchor.constraint(equalTo: foodImageView.bottomAnchor, constant: 8),
            textStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            textStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // Four dots light up one after another, like a queue moving forward.
    private func animateDots() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let step = 0.25
        for (index, dot) in dotsStack.arrangedSubviews.enumerated() {
            let pulse = CAKeyframeAnimation(keyPath: "opacity")
            pulse.values = [0.25, 1, 0.25]
            pulse.keyTimes = [0, 0.3, 1]
            pulse.duration = step * 4
            pulse.repeatCount = .infinity
            pulse.beginTime = CACurrentMediaTime() + step * Double(index)
            pulse.fillMode = .backwards
            dot.layer.add(pulse, forKey: "pulse")
        }
    }
}
