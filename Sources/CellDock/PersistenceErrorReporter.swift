import Foundation

extension Notification.Name {
    static let cellDockPersistenceError = Notification.Name(
        "app.celldock.mac.persistence-error"
    )
}

enum PersistenceErrorReporter {
    static func report(context: String, error: Error) {
        let message = "\(context)：\(error.localizedDescription)"
        NSLog("CellDock persistence error: %@", message)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .cellDockPersistenceError,
                object: message
            )
        }
    }
}
