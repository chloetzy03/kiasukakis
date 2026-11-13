import Foundation

// Extra buttons that only make sense when presenting the prototype, such as skipping ahead in a queue.
// They are off by default so real users never see them. The switch is in About & Settings.
enum DemoControls {
    private static let key = "showDemoControls"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
