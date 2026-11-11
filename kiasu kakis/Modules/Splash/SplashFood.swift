import UIKit

// The food shown on the splash screen. It changes with the time of day.
enum SplashFood: CaseIterable {
    case toast, bowl, boba, chilli, dumpling

    // Where the eyes sit on the picture, as fractions of the image (0...1), measured on the 1024 px artwork.
    struct EyeLayout {
        let centerX: CGFloat
        let centerY: CGFloat
        let gap: CGFloat      // distance from the middle to each eye
        let radius: CGFloat
    }

    static func food(forHour hour: Int) -> SplashFood {
        switch hour {
        case 5..<11: return .toast
        case 11..<15: return .bowl
        case 15..<18: return .boba
        case 18..<22: return .chilli
        default: return .dumpling
        }
    }

    // In debug builds, launch with `-SplashHour 12` to preview another time of day.
    static var current: SplashFood {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "SplashHour") != nil {
            return food(forHour: UserDefaults.standard.integer(forKey: "SplashHour"))
        }
        #endif
        return food(forHour: Calendar.current.component(.hour, from: Date()))
    }

    var imageName: String {
        switch self {
        case .toast: return "FoodToast"
        case .bowl: return "FoodBowl"
        case .boba: return "FoodBoba"
        case .chilli: return "FoodChilli"
        case .dumpling: return "FoodDumpling"
        }
    }

    var greeting: String {
        switch self {
        case .toast: return "Good morning. Save your spot."
        case .bowl: return "Lunch crowd? We got you."
        case .boba: return "Boba run? Check the queue first."
        case .chilli: return "Dinner rush. Be first in line."
        case .dumpling: return "Late-night craving? We got you."
        }
    }

    var eyes: EyeLayout {
        switch self {
        case .toast: return EyeLayout(centerX: 515 / 1024, centerY: 470 / 1024, gap: 80 / 1024, radius: 56 / 1024)
        case .bowl: return EyeLayout(centerX: 512 / 1024, centerY: 630 / 1024, gap: 86 / 1024, radius: 58 / 1024)
        case .boba: return EyeLayout(centerX: 512 / 1024, centerY: 590 / 1024, gap: 86 / 1024, radius: 58 / 1024)
        case .chilli: return EyeLayout(centerX: 585 / 1024, centerY: 500 / 1024, gap: 72 / 1024, radius: 52 / 1024)
        case .dumpling: return EyeLayout(centerX: 512 / 1024, centerY: 630 / 1024, gap: 88 / 1024, radius: 60 / 1024)
        }
    }
}
