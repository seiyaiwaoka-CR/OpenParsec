import UIKit
import Foundation

extension Notification.Name {
	static let externalDisplayHostReady = Notification.Name("OpenParsec.externalDisplayHostReady")
	static let externalDisplayHostGone = Notification.Name("OpenParsec.externalDisplayHostGone")
}

@available(iOS 13.0, *)
final class ExternalDisplayCoordinator {
	static let shared = ExternalDisplayCoordinator()

	private(set) var externalHost: ExternalDisplayHostViewController?
	private(set) var externalWindow: UIWindow?
	private(set) var externalScreen: UIScreen?
	private(set) weak var activeParsecVC: ParsecViewController?

	private var didInstallObservers = false

	var isExternalActive: Bool { externalHost != nil }

	private init() {}

	func bootstrap() {
		guard !didInstallObservers else { return }
		didInstallObservers = true

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleScreenDidConnect(_:)),
			name: UIScreen.didConnectNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleScreenDidDisconnect(_:)),
			name: UIScreen.didDisconnectNotification,
			object: nil
		)

		// Adopt any external screen already attached at launch.
		for screen in UIScreen.screens where screen !== UIScreen.main {
			attachToScreen(screen)
			break
		}
	}

	@objc private func handleScreenDidConnect(_ note: Notification) {
		guard let screen = note.object as? UIScreen, screen !== UIScreen.main else { return }
		attachToScreen(screen)
	}

	@objc private func handleScreenDidDisconnect(_ note: Notification) {
		guard let screen = note.object as? UIScreen, screen === externalScreen else { return }
		detachFromScreen()
	}

	private func attachToScreen(_ screen: UIScreen) {
		guard externalWindow == nil else { return }

		let window = UIWindow(frame: screen.bounds)
		window.screen = screen
		let host = ExternalDisplayHostViewController()
		window.rootViewController = host
		window.isHidden = false

		self.externalScreen = screen
		self.externalWindow = window
		self.externalHost = host

		NotificationCenter.default.post(name: .externalDisplayHostReady, object: nil)
		if SettingsHandler.externalDisplayAutoTransfer {
			tryAttachStream()
		}
	}

	private func detachFromScreen() {
		activeParsecVC?.restoreStreamFromExternal()
		externalWindow?.isHidden = true
		externalWindow = nil
		externalHost = nil
		externalScreen = nil
		NotificationCenter.default.post(name: .externalDisplayHostGone, object: nil)
	}

	func registerActiveParsec(_ vc: ParsecViewController?) {
		self.activeParsecVC = vc
		if vc != nil, isExternalActive, SettingsHandler.externalDisplayAutoTransfer {
			tryAttachStream()
		}
	}

	func tryAttachStream() {
		guard let host = externalHost, let parsec = activeParsecVC else { return }
		parsec.attachStreamToExternal(host: host)
	}

	func detachStream() {
		activeParsecVC?.restoreStreamFromExternal()
	}
}
