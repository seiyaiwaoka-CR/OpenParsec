import UIKit

@available(iOS 13.0, *)
final class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }

		let window = UIWindow(windowScene: windowScene)
		let host = ExternalDisplayHostViewController()
		window.rootViewController = host
		window.isHidden = false
		self.window = window

		ExternalDisplayCoordinator.shared.registerExternalHost(host, window: window)
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		ExternalDisplayCoordinator.shared.unregisterExternalHost()
		self.window = nil
	}
}
