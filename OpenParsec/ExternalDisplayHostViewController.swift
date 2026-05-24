import UIKit

@available(iOS 13.0, *)
final class ExternalDisplayHostViewController: UIViewController {
	private let placeholderLabel = UILabel()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black

		placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
		placeholderLabel.text = "OpenParsec — waiting for stream…"
		placeholderLabel.textColor = .white
		placeholderLabel.font = .systemFont(ofSize: 24, weight: .medium)
		placeholderLabel.textAlignment = .center
		view.addSubview(placeholderLabel)
		NSLayoutConstraint.activate([
			placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	override var prefersHomeIndicatorAutoHidden: Bool { true }
	override var prefersStatusBarHidden: Bool { true }

	func showStreamView(_ streamView: UIView) {
		placeholderLabel.isHidden = true
		streamView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(streamView)
		NSLayoutConstraint.activate([
			streamView.topAnchor.constraint(equalTo: view.topAnchor),
			streamView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			streamView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			streamView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
		])
	}

	func clearStreamView() {
		for sub in view.subviews where sub !== placeholderLabel {
			sub.removeFromSuperview()
		}
		placeholderLabel.isHidden = false
	}
}
