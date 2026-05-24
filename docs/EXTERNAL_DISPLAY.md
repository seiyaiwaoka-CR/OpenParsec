# External Display Support (Experimental)

This branch (`feat/external-display`) adds support for streaming the Parsec
session onto an external display connected to an iPad over USB-C / HDMI,
while the iPad screen continues to act as the trackpad / keyboard input
surface.

## Behavior

| State | Stream is rendered on | Input source | Cursor overlay |
|---|---|---|---|
| No external display | iPad screen | iPad touch / USB peripherals | iPad |
| External display connected, auto-transfer ON (default) | **External display** | iPad touch / USB peripherals | Hidden on iPad (rendered by host on external) |
| External display disconnected | iPad screen | iPad touch / USB peripherals | iPad |

- Resolution: the host is reconfigured to match the external display's native
  size on attach (via `CParsec.updateHostVideoConfig`), and reverts to the iPad
  size on detach.
- PiP: suspended while streaming externally (PiP's GL context is tied to the
  on-iPad GLKView).
- Direct touch mode: still functional, but tap coordinates map to the iPad
  screen rect, not the external. Touchpad mode (the default) is recommended
  while using an external display.

## Settings

Settings → Misc → **Auto-Transfer to External Display** (default: ON)

Turn OFF to keep the stream on the iPad even when an external display is
connected (the external display will show a "waiting for stream…" placeholder).

## Requirements

- iOS / iPadOS **16.0** or later
  (uses `UIWindowSceneSessionRoleExternalDisplayNonInteractive`)
- USB-C iPad with an HDMI adapter, OR a Lightning-to-HDMI adapter for older
  iPads, OR a wired display that the iPad's external-display system can drive

## Architecture (for reviewers)

Four new files plus small edits to existing scene plumbing:

```
OpenParsec/
├── ExternalDisplayCoordinator.swift           # singleton broker
├── ExternalDisplayHostViewController.swift    # UIVC on the external UIWindow
├── ExternalDisplaySceneDelegate.swift         # handles the external scene
└── ParsecViewController+ExternalDisplay.swift # attach/restore GLKView
```

Touch points in existing files:

- `Info.plist` — `UIApplicationSupportsMultipleScenes=true`, declares
  `UIWindowSceneSessionRoleExternalDisplayNonInteractive` with
  `ExternalDisplaySceneDelegate`.
- `AppDelegate.swift` — picks the right scene configuration by role.
- `ParsecViewController.swift` — registers/unregisters with the coordinator on
  appear/disappear; skips local resize logic when streaming externally in
  `viewWillTransition`.
- `SettingsHandler.swift` / `SettingsView.swift` — adds the toggle.

The mechanism is: detach the `GLKViewController` from the iPad VC's
contentView, reparent it onto the external display's root VC, and call
`CParsec.setFrame` + `CParsec.updateHostVideoConfig` with the external bounds.
The reverse runs on detach.

## Known limitations

- iPad < 16.0 is not supported in this revision (legacy
  `UIWindowSceneSessionRoleExternalDisplay` is not declared).
- Pure mirroring (stream visible on both iPad and external simultaneously)
  is not implemented; the GL view can only be attached to one window at a
  time without a textured intermediate. The dormant Metal renderer path
  would be the more natural place to add dual-drawable mirroring later.
- Direct touch coordinate mapping is not adjusted for external display
  resolution. Stick with Touchpad mode while external is active.

## End-user setup (sideload path)

For someone running this build via AltStore on Windows + iPad:

1. **Windows**: install Parsec Host from https://parsec.app, sign in, enable
   "host" mode in the host settings.
2. **Windows**: install AltServer for Windows + iTunes (or Apple Devices).
3. **iPad** (USB connected to PC): install AltStore via AltServer.
4. **iPad**: in AltStore → Sources → add this fork's AltStore JSON
   (or sideload the `.ipa` artifact from the GitHub Actions run for
   `feat/external-display` directly via AltStore's "+" button).
5. **iPad**: trust the developer profile under Settings → General → VPN &
   Device Management.
6. **iPad**: launch OpenParsec, sign in with the same Parsec account, connect
   to the Windows host.
7. **iPad**: plug an HDMI adapter into the USB-C port and connect to an
   external display. The stream should jump to the external automatically.
