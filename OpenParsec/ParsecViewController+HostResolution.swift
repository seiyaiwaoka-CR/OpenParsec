import UIKit
import GLKit

extension ParsecViewController {

	/// Resize the iPad-side render surface to match the host's native pixel
	/// dimensions and let the existing UIScrollView act as a pan/zoom viewport.
	///
	/// Call this after a host video config callback has populated
	/// `DataManager.model.resolutionX/Y`, or whenever the user toggles
	/// `SettingsHandler.renderAtHostResolution`.
	func applyRenderResolution() {
		guard let parsecGLK = self.glkView as? ParsecGLKViewController,
		      let gv = parsecGLK.glkView else { return }

		let viewportSize = self.view.bounds.size
		guard viewportSize.width > 0, viewportSize.height > 0 else { return }

		let hostW = CGFloat(DataManager.model.resolutionX)
		let hostH = CGFloat(DataManager.model.resolutionY)
		let useHostRes = SettingsHandler.renderAtHostResolution && hostW > 0 && hostH > 0

		let renderSize: CGSize
		let renderScale: CGFloat
		if useHostRes {
			renderSize = CGSize(width: hostW, height: hostH)
			renderScale = 1.0
		} else {
			renderSize = viewportSize
			renderScale = self.view.window?.screen.scale ?? UIScreen.main.scale
		}

		gv.frame = CGRect(origin: .zero, size: renderSize)
		gv.contentScaleFactor = renderScale
		self.contentView.frame = CGRect(origin: .zero, size: renderSize)
		self.scrollView.contentSize = renderSize

		self.glkView.updateSize(width: renderSize.width, height: renderSize.height)
		CParsec.setFrame(renderSize.width, renderSize.height, renderScale)

		if useHostRes {
			// Default to "fit" so the user sees the whole host desktop at first,
			// and let them zoom in. minZoom slightly below fit so a pinch-out
			// continues to feel natural.
			let fitScale = min(viewportSize.width / hostW, viewportSize.height / hostH)
			self.scrollView.minimumZoomScale = max(0.05, fitScale * 0.5)
			self.scrollView.maximumZoomScale = max(5.0, 1.0 / fitScale * 2.0)
			self.scrollView.zoomScale = fitScale
			self.scrollView.contentOffset = .zero
		} else {
			self.scrollView.minimumZoomScale = 1.0
			self.scrollView.maximumZoomScale = 5.0
			self.scrollView.zoomScale = 1.0
		}

		CParsec.updateHostVideoConfig()
	}
}
