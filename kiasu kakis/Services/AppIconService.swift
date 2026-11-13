import UIKit

// The home-screen icon choices. "Automatic" is the main icon, which iOS switches between light and dark itself.
enum AppIconChoice: CaseIterable {
    case automatic, light, dark

    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    // Names must match the alternate icon sets in the asset catalog.
    var assetName: String? {
        switch self {
        case .automatic: return nil
        case .light: return "IconLight"
        case .dark: return "IconDark"
        }
    }
}

protocol AppIconChanging {
    var current: AppIconChoice { get }
    var isSupported: Bool { get }
    func select(_ choice: AppIconChoice, completion: @escaping (Bool) -> Void)
}

struct AppIconService: AppIconChanging {

    var isSupported: Bool { UIApplication.shared.supportsAlternateIcons }

    var current: AppIconChoice {
        let name = UIApplication.shared.alternateIconName
        return AppIconChoice.allCases.first { $0.assetName == name } ?? .automatic
    }

    func select(_ choice: AppIconChoice, completion: @escaping (Bool) -> Void) {
        UIApplication.shared.setAlternateIconName(choice.assetName) { error in
            DispatchQueue.main.async { completion(error == nil) }
        }
    }
}
