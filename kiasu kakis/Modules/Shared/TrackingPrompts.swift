import UIKit

// Small pop-ups for following a number from a restaurant's own queue system.
enum TrackingPrompts {

    // "What's your number, and what number are they serving now?"
    static func askForNumbers(on controller: UIViewController?, venueName: String,
                              onSubmit: @escaping (_ yours: Int, _ nowServing: Int) -> Void) {
        let alert = UIAlertController(title: "Track your number at \(venueName)",
                                      message: "Type the digits only. You'll update the number now serving yourself, because the restaurant's system isn't connected to this app yet.",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Your number"; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = "Now serving"; $0.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Track", style: .default) { [weak controller] _ in
            let yours = Int(alert.textFields?[0].text ?? ""), serving = Int(alert.textFields?[1].text ?? "")
            guard let yours, let serving, yours > serving else {
                message(on: controller, title: "Check the numbers",
                        text: "Your number must be higher than the number now serving.")
                return
            }
            onSubmit(yours, serving)
        })
        controller?.present(alert, animated: true)
    }

    static func askForNowServing(on controller: UIViewController?, current: Int, onSubmit: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: "Now serving", message: "What number is on the board?", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Currently #\(current)"; $0.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            if let number = Int(alert.textFields?.first?.text ?? ""), number > current { onSubmit(number) }
        })
        controller?.present(alert, animated: true)
    }

    // "Open their queue page" or "Track my number", for places with their own system.
    static func chooseExternalAction(on controller: UIViewController?, venueName: String,
                                     onOpen: @escaping () -> Void, onTrack: @escaping () -> Void) {
        let sheet = UIAlertController(title: venueName, message: "This place runs its own queue.", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Open their queue page", style: .default) { _ in onOpen() })
        sheet.addAction(UIAlertAction(title: "Track my number here", style: .default) { _ in onTrack() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController, let view = controller?.view {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
        }
        controller?.present(sheet, animated: true)
    }

    static func message(on controller: UIViewController?, title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        controller?.present(alert, animated: true)
    }
}
