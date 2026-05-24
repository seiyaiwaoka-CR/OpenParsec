# F4: Metal renderer revival + dual-drawable mirroring (design)

**Status:** designed, not implemented. Requires on-device iteration that
the F0–F3 autonomous run could not perform.

## Why this is a separate phase

The F1–F2 external display path **reparents** the existing `GLKView` from
the iPad scene onto the external display. That works for "one or the other"
but it cannot show the stream on both displays simultaneously, because a
single `GLKView` / `EAGLContext` can only be attached to one window at a
time.

True mirroring needs the render pipeline to produce frames into an
intermediate texture and then blit to multiple drawables. Metal makes this
natural; OpenGL ES on iOS does not (and is itself deprecated).

The Parsec SDK already exposes `ParsecClientMetalRenderFrame` (see
`Frameworks/ParsecSDK.framework/Headers/parsec.h:1275`), and OpenParsec
already has commented-out `ParsecMetalRenderer.swift` /
`ParsecMetalViewController.swift` skeletons. F4 is to wake those up and
extend them for two drawables.

## SDK contract (parsec.h)

```c
typedef void ParsecMetalCommandQueue;   // cast to id<MTLCommandQueue>
typedef void ParsecMetalTexture;        // cast to id<MTLTexture>

ParsecStatus
ParsecClientMetalRenderFrame(
    Parsec *ps, uint8_t stream,
    ParsecMetalCommandQueue *cq,
    ParsecMetalTexture **target,        // INOUT: SDK may set this in preRender
    ParsecPreRenderCallback pre,
    const void *opaque,
    uint32_t timeout);
```

The `**target` indirection means the SDK can replace your texture during
the pre-render callback (e.g. if the host resolution changed and a larger
backing texture is needed). The renderer must respect the new pointer.

## Bridging problem (the only real C code addition)

Swift exposes `MTLCommandQueue` / `MTLTexture` as protocol-typed Swift
references that do not bridge to raw `void *` cleanly. The Parsec SDK
wants `void *` for `cq` and `void **` for `target`. The existing dead
code calls a `createTextureRef` helper that has to be added to the
bridging header.

Add to `OpenParsec/audio.h` (or a new `metal_bridge.h`):

```c
#ifndef METAL_BRIDGE_H
#define METAL_BRIDGE_H

#include <stddef.h>

// Returns a void* alias to the id<MTLTexture> at *texturePtr.
// The returned pointer is owned by the underlying Metal object;
// caller must not free.
void *parsec_metal_texture_ref(void *texturePtr);

// Returns a void* alias to the id<MTLCommandQueue>.
void *parsec_metal_queue_ref(void *queuePtr);

#endif
```

Implementation (`OpenParsec/metal_bridge.m`, Objective-C so ARC handles
the `__bridge` cast):

```objc
#import <Metal/Metal.h>
#import "metal_bridge.h"

void *parsec_metal_texture_ref(void *texturePtr) {
    id<MTLTexture> *p = (id<MTLTexture> *)texturePtr;
    return (__bridge void *)(*p);
}

void *parsec_metal_queue_ref(void *queuePtr) {
    id<MTLCommandQueue> *p = (id<MTLCommandQueue> *)queuePtr;
    return (__bridge void *)(*p);
}
```

Then `ParsecSDKBridge.swift` wraps it:

```swift
static func renderMetalFrame(
    queue: MTLCommandQueue,
    targetTexture: inout MTLTexture,
    timeout: UInt32 = 16
) -> ParsecStatus {
    var queueLocal: MTLCommandQueue? = queue
    var textureLocal: MTLTexture? = targetTexture
    return withUnsafeMutablePointer(to: &queueLocal) { qPtr in
        withUnsafeMutablePointer(to: &textureLocal) { tPtr in
            let q = parsec_metal_queue_ref(qPtr)
            let t = parsec_metal_texture_ref(tPtr)
            // The SDK takes target by **; pass &t after casting.
            var targetVoid: UnsafeMutableRawPointer? = t
            return ParsecClientMetalRenderFrame(
                _parsec, UInt8(DEFAULT_STREAM),
                q, &targetVoid, nil, nil, timeout)
        }
    }
}
```

(There is a subtle pitfall here: the `**target` parameter wants the
SDK to be able to *replace* the texture, so you may also need to read
back `targetVoid` after the call and translate it back to an
`MTLTexture` via `Unmanaged<AnyObject>.fromOpaque(...).takeUnretainedValue()`.)

## Renderer architecture for mirroring

Replace the current "render directly into the on-screen drawable"
pattern with a two-step pipeline:

```
Parsec frame  ─► offscreen MTLTexture (rgba8, host resolution)
                            │
                            ├─► blit ─► iPad CAMetalLayer drawable
                            └─► blit ─► External CAMetalLayer drawable
```

Concrete plan:

1. **`ParsecMetalRenderer.swift`** (uncomment + rewrite)
   - Owns one `MTLDevice`, one `MTLCommandQueue`, one offscreen
     `MTLTexture` (`renderTarget`)
   - Each frame: `CParsec.renderMetalFrame(queue, &renderTarget, ...)`
   - Then for each registered output layer:
     `MTLBlitCommandEncoder.copy(from: renderTarget, to: drawable.texture)` and `commandBuffer.present(drawable)`
2. **`ParsecMetalOutputView.swift`** (new)
   - Thin `UIView` subclass with `layerClass = CAMetalLayer.self`
   - Registers itself with the renderer on `didMoveToWindow`
3. **Wire into `ParsecViewController`**
   - Replace the GLKView path: VC owns one `ParsecMetalOutputView` on
     the iPad scene, and `ExternalDisplayHostViewController` owns
     another. Both register with the shared `ParsecMetalRenderer`.
4. **Display link**
   - Use one `CADisplayLink` on the iPad scene (whose refresh rate is
     usually ≥ the external) to drive frame production. After each
     render, schedule blits to all registered output layers in the
     same command buffer.

## PiP integration

The existing `PictureInPictureManager` is wired against a GLKView's
EAGLContext and reads pixels via OpenGL into an
`AVSampleBufferDisplayLayer`. For Metal, the rewrite is:

- After each `renderMetalFrame`, blit `renderTarget` to a
  `CVPixelBuffer`-backed Metal texture (via `CVMetalTextureCache`)
- Enqueue the `CMSampleBuffer` to the `AVSampleBufferDisplayLayer`
- Keep the rest of `PictureInPictureManager` unchanged

This is ~80 lines of glue but it has to be tuned against actual frame
timing — guessing at it without device iteration produces stutter.

## Settings & coexistence

Add a `SettingsHandler.renderer: RendererType` (`opengl` | `metal`)
that defaults to `.opengl` for safety, and only Metal users get
mirroring. The existing `SettingsView` already has commented-out UI
for this — uncomment and wire to a new `ParsecPlayground` impl.

## Risks / why this needs device iteration

1. **`**target` aliasing** — Swift/ObjC bridging at the `void**`
   boundary is hard to get right without a debugger. First-attempt
   crashes are almost guaranteed.
2. **Texture format mismatch** — the SDK may hand back a texture in
   a pixel format the blit destination doesn't accept; need to add
   a shader pass instead of straight blit.
3. **Cross-display vsync** — iPad screen and external can have
   different refresh rates (e.g. 120 Hz iPad, 60 Hz monitor). Naive
   shared display link causes tearing on the slower one.
4. **PiP timing** — pulling sample buffers in the middle of the
   Metal render loop sometimes causes the AV layer to drop frames.
   Requires queue tuning.

All four are solvable, all four are observable only by running on
hardware.

## Recommended path forward

1. Land F1–F2 (this branch) on device first; confirm the simple
   reparenting path works as expected.
2. Open a `feat/metal-mirror` branch from this one and tackle Metal
   in three commits:
   a. Bridge shim + uncommented Metal renderer (no mirroring,
      replaces GLK path behind a setting)
   b. PiP for Metal path
   c. Dual-drawable mirroring
3. Test each on iPad before stacking the next.

Estimated effort with device: 5–8 working days.
