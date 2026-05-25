import Foundation
import SwiftUI

struct SettingsHandler {
	//public static var renderer:RendererType = .opengl
	@AppStorage("resolution") public static var resolution: ParsecResolution = .client
	@AppStorage("bitrate") public static var bitrate: Int = 0
	@AppStorage("decoder") public static var decoder: DecoderPref = .h264
	@AppStorage("cursorMode") public static var cursorMode: CursorMode = .touchpad
	@AppStorage("cursorScale") public static var cursorScale: Double = 0.5
	@AppStorage("mouseSensitivity") public static var mouseSensitivity: Double = 1.0
	@AppStorage("noOverlay") public static var noOverlay: Bool = false
	@AppStorage("cursorScale") public static var hideStatusBar: Bool = true
	@AppStorage("rightClickPosition") public static var rightClickPosition: RightClickPosition = .firstFinger
	@AppStorage("preferredFramesPerSecond") public static var preferredFramesPerSecond: Int = 60 // 0 = use device max (ProMotion)
	@AppStorage("decoderCompatibility") public static var decoderCompatibility: Bool = false // Enable for stutter issues on some devices
	@AppStorage("showKeyboardButton") public static var showKeyboardButton: Bool = true

	// Defaults to OFF: external display support is opt-in to keep the iPad-only
	// behavior identical to upstream when the user hasn't asked for it.
	// Key was renamed from `externalDisplayAutoTransfer` to force a reset for
	// anyone who had the buggy v1/v2 build installed.
	@AppStorage("externalDisplayEnabled_v2") public static var externalDisplayAutoTransfer: Bool = false

	// Render the remote stream at host-native resolution into a large
	// content area, with the iPad scroll view acting as a viewport you
	// can pan/zoom around. Default OFF (= upstream behavior: stream
	// scaled to the iPad screen).
	@AppStorage("renderAtHostResolution") public static var renderAtHostResolution: Bool = false

	// When ON (default), iPad captures the system pointer into the stream
	// so a connected USB mouse / trackpad drives the host cursor directly.
	// Turn OFF if you need the system pointer to interact with OpenParsec's
	// own overlay buttons (Parsec logo, keyboard, etc.) using a mouse.
	@AppStorage("pointerLockEnabled") public static var pointerLockEnabled: Bool = true

	@AppStorage("saveSessionSettings") public static var saveSessionSettings: Bool = true
	@AppStorage("savedZoomEnabled") public static var savedZoomEnabled: Bool = false
	@AppStorage("savedConstantFps") public static var savedConstantFps: Bool = false
	@AppStorage("savedMuted") public static var savedMuted: Bool = false

}
