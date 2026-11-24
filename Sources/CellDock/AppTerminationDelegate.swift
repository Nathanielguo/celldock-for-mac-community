import AppKit
import Foundation

@MainActor
final class AppTerminationDelegate: NSObject, NSApplicationDelegate {
    private var menuBarPanelController: MenuBarPanelController?
    private weak var appState: AppState?
    private var didFinishLaunching = false
    private var didShowInitialCommunicationWindow = false

    func configure(appState: AppState) {
        self.appState = appState
        menuBarPanelController = MenuBarPanelController(appState: appState)
        if didFinishLaunching {
            menuBarPanelController?.start()
            showInitialCommunicationWindowIfNeeded()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppAppearanceMode.storedPreference.apply()
        didFinishLaunching = true
        menuBarPanelController?.start()
        showInitialCommunicationWindowIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarPanelController?.stop()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppTerminationCoordinator.shared.beginTermination(of: sender)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            CommunicationWindowController.shared.handleApplicationReopen()
        }
        return true
    }

    private func showInitialCommunicationWindowIfNeeded() {
        guard !didShowInitialCommunicationWindow, let appState else { return }
        didShowInitialCommunicationWindow = true
        DispatchQueue.main.async {
            appState.showMessagesWindow()
        }
    }
}

final class AppTerminationCoordinator {
    static let shared = AppTerminationCoordinator()

    var cleanup: ((@escaping (Bool) -> Void) -> Void)?
    private var terminationPending = false

    private init() {}

    func beginTermination(of application: NSApplication) -> NSApplication.TerminateReply {
        guard !terminationPending else { return .terminateLater }
        guard let cleanup else { return .terminateNow }
        terminationPending = true
        var replied = false
        let reply: (Bool) -> Void = { shouldTerminate in
            DispatchQueue.main.async {
                guard !replied else { return }
                replied = true
                self.terminationPending = false
                application.reply(toApplicationShouldTerminate: shouldTerminate)
            }
        }
        cleanup(reply)
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { reply(false) }
        return .terminateLater
    }
}
