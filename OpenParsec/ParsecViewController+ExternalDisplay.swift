import UIKit

@available(iOS 13.0, *)
extension ParsecViewController {

	private struct ExternalDisplayState {
		static var streamingExternally: Bool = false
	}

	var isStreamingExternally: Bool {
		ExternalDisplayState.streamingExternally
	}

	func registerForExternalDisplay() {
		ExternalDisplayCoordinator.shared.registerActiveParsec(self)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(externalHostReadyNotification),
			name: .externalDisplayHostReady,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(externalHostGoneNotification),
			name: .externalDisplayHostGone,
			object: nil
		)
	}

	func unregisterFromExternalDisplay() {
		NotificationCenter.default.removeObserver(self, name: .externalDisplayHostReady, object: nil)
		NotificationCenter.default.removeObserver(self, name: .externalDisplayHostGone, object: nil)
		if ExternalDisplayCoordinator.shared.activeParsecVC === self {
			restoreStreamFromExternal()
			ExternalDisplayCoordinator.shared.registerActiveParsec(nil)
		}
	}

	@objc private func externalHostReadyNotification() {
		guard SettingsHandler.externalDisplayAutoTransfer else { return }
		ExternalDisplayCoordinator.shared.tryAttachStream()
	}

	@objc private func externalHostGoneNotification() {
		restoreStreamFromExternal()
	}

	func attachStreamToExternal(host: ExternalDisplayHostViewController) {
		guard !ExternalDisplayState.streamingExternally else { return }
		guard let parsecGLK = self.glkView as? ParsecGLKViewController else { return }
		guard let externalScreen = ExternalDisplayCoordinator.shared.externalScreen,
		      let externalWindow = ExternalDisplayCoordinator.shared.externalWindow else { return }

		let glkVC = parsecGLK.glkViewController
		let glkView = parsecGLK.glkView

		glkVC.willMove(toParent: nil)
		glkView?.removeFromSuperview()
		glkVC.view.removeFromSuperview()
		glkVC.removeFromParent()

		host.addChild(glkVC)
		host.showStreamView(glkVC.view)
		glkVC.didMove(toParent: host)

		// Force layout so glkView.frame reflects external window bounds before we call setFrame.
		externalWindow.layoutIfNeeded()
		host.view.layoutIfNeeded()

		// Use the external screen's pixel-accurate size, not the freshly-created window bounds.
		let extSize = externalScreen.bounds.size
		let extScale = externalScreen.scale
		glkView?.frame = CGRect(origin: .zero, size: extSize)
		glkView?.contentScaleFactor = extScale
		self.glkView.updateSize(width: extSize.width, height: extSize.height)
		CParsec.setFrame(extSize.width, extSize.height, extScale)
		CParsec.updateHostVideoConfig()

		self.u?.isHidden = true

		ExternalDisplayState.streamingExternally = true

		if #available(iOS 15.0, *) {
			PictureInPictureManager.shared.stopPiP()
		}
	}

	func restoreStreamFromExternal() {
		guard ExternalDisplayState.streamingExternally else { return }
		guard let parsecGLK = self.glkView as? ParsecGLKViewController else { return }

		let glkVC = parsecGLK.glkViewController
		let glkView = parsecGLK.glkView

		glkVC.willMove(toParent: nil)
		glkView?.removeFromSuperview()
		glkVC.view.removeFromSuperview()
		glkVC.removeFromParent()

		self.addChild(glkVC)
		self.contentView.addSubview(glkVC.view)
		if let glkView = glkView, glkVC.view !== glkView {
			self.contentView.addSubview(glkView)
		}
		glkVC.didMove(toParent: self)

		let size = self.view.bounds.size
		let scale = self.view.window?.screen.scale ?? UIScreen.main.scale
		glkView?.frame = CGRect(origin: .zero, size: size)
		glkView?.contentScaleFactor = scale
		self.glkView.updateSize(width: size.width, height: size.height)
		CParsec.setFrame(size.width, size.height, scale)
		CParsec.updateHostVideoConfig()

		self.u?.isHidden = false

		ExternalDisplayState.streamingExternally = false

		ExternalDisplayCoordinator.shared.externalHost?.clearStreamView()
	}
}
