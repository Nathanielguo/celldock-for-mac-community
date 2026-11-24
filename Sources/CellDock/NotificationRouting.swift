import Foundation

enum AppNotificationIdentifier {
    static let incomingCallCategory = "app.celldock.notification.incoming-call"
    static let missedCallCategory = "app.celldock.notification.missed-call"
    static let messageCategory = "app.celldock.notification.message"
    static let answerCallAction = "app.celldock.notification.answer-call"
    static let rejectCallAction = "app.celldock.notification.reject-call"
    static let openCallWindowAction = "app.celldock.notification.open-call-window"
    static let openMessageAction = "app.celldock.notification.open-message"
}

enum AppNotificationRoute: Equatable {
    case answerCall
    case rejectCall
    case openCallWindow
    case openMissedCall(String)
    case openMessage(String)
    case ignore
}

enum AppNotificationRouter {
    static func route(
        actionIdentifier: String,
        categoryIdentifier: String,
        messageID: String?,
        callRecordID: String?,
        defaultActionIdentifier: String,
        dismissActionIdentifier: String
    ) -> AppNotificationRoute {
        switch actionIdentifier {
        case AppNotificationIdentifier.answerCallAction:
            return .answerCall
        case AppNotificationIdentifier.rejectCallAction:
            return .rejectCall
        case AppNotificationIdentifier.openCallWindowAction:
            return callRecordID.map(AppNotificationRoute.openMissedCall) ?? .openCallWindow
        case AppNotificationIdentifier.openMessageAction:
            return messageID.map(AppNotificationRoute.openMessage) ?? .ignore
        case defaultActionIdentifier:
            if categoryIdentifier == AppNotificationIdentifier.incomingCallCategory {
                return .openCallWindow
            }
            if categoryIdentifier == AppNotificationIdentifier.missedCallCategory {
                return callRecordID.map(AppNotificationRoute.openMissedCall) ?? .openCallWindow
            }
            if categoryIdentifier == AppNotificationIdentifier.messageCategory, let messageID {
                return .openMessage(messageID)
            }
            return .ignore
        case dismissActionIdentifier:
            return .ignore
        default:
            return .ignore
        }
    }
}
