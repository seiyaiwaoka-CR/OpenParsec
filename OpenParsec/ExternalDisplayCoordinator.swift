import UIKit
import Foundation

extension Notification.Name {
	static let externalDisplayHostReady = Notification.Name("OpenParsec.externalDisplayHostReady")
	static let externalDisplayHostGone = Notification.Name("OpenParsec.externalDisplayHostGone")
}

@available(iOS 13.0, *)
final class ExternalDisplayCoordinator {
	static let shared = ExternalDisplayCoordinator()

	private(set) weak var externalHost: ExternalDisplayHostViewController?
	private(set) weak var externalWindow: UIWindow?
	private(set) weak var activeParsecVC: ParsecViewController?

	var isExternalActive: Bool { externalHost != nil }

	private init() {}

	func registerActiveParsec(_ vc: ParsecViewController?) {
		self.activeParsecVC = vc
		if vc != nil, isExternalActive, SettingsHandler.externalDisplayAutoTransfer {
			tryAttachStream()
		}
	}

	func registerExternalHost(_ host: ExternalDisplayHostViewController, window: UIWindow) {
		self.externalHost = host
		self.externalWindow = window
		NotificationCenter.default.post(name: .externalDisplayHostReady, object: nil)
		if SettingsHandler.externalDisplayAutoTransfer {
			tryAttachStream()
		}
	}

	func unregisterExternalHost() {
		activeParsecVC?.restoreStreamFromExternal()
		self.externalHost = nil
		self.externalWindow = nil
		NotificationCenter.default.post(name: .externalDisplayHostGone, object: nil)
	}

	func tryAttachStream() {
		guard let host = externalHost, let parsec = activeParsecVC else { return }
		parsec.attachStreamToExternal(host: host)
	}

	func detachStream() {
		activeParsecVC?.restoreStreamFromExternal()
	}
}
