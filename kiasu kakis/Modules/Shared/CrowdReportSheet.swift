import UIKit

// The "how long is the line?" choices, shown as an action sheet.
enum CrowdReportSheet {

    static func present(on controller: UIViewController?, venueName: String, onPick: @escaping (CrowdReportOption) -> Void) {
        let sheet = UIAlertController(title: "How long is the line at \(venueName)?",
                                      message: "Your report helps others decide. For now it is saved on this phone.",
                                      preferredStyle: .actionSheet)
        for option in CrowdReportOption.allCases {
            sheet.addAction(UIAlertAction(title: option.title, style: .default) { _ in onPick(option) })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // On iPad an action sheet needs something to point at.
        if let popover = sheet.popoverPresentationController, let view = controller?.view {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
        }
        controller?.present(sheet, animated: true)
    }
}
