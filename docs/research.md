# Design and API research

Reviewed 17 November 2026. The implementation is original; no source or art was copied from the projects below.

## Existing workflows

- [Roblox Device Simulator](https://create.roblox.com/docs/studio/device-simulator) already handles device sizes, orientations, physical scaling, keyboard simulation and controller emulation. ViewportBoard adds saved layout comparisons using its device presets; it does not implement a new emulator.
- [Roblox Player Emulator](https://create.roblox.com/docs/studio/testing-modes) already supports localization, pseudolocalization and text expansion. These are not reimplemented.
- [KSA Accessibility Preflight](https://github.com/KSAGlory/KSA-Accessibility-Preflight) checks several accessibility properties. [GameShip UI QA](https://create.roblox.com/store/asset/74306114545525) scans responsive UI risks. ViewportBoard deliberately offers human visual review rather than unsupported automated conclusions.
- [DataDelve architecture](https://github.com/pinehappi/DataDelve/blob/main/ARCHITECTURE.md), its [entry point](https://github.com/pinehappi/DataDelve/blob/main/src/main.server.luau) and [theme source](https://github.com/pinehappi/DataDelve/blob/main/src/UI/Theme/init.luau) were inspected for plugin lifecycle, controller/view separation and Studio-native theme integration. DataDelve is GPL-3.0; none of its implementation or assets are included here.

## Native interfaces

- [Selection](https://create.roblox.com/docs/reference/engine/classes/Selection), [UIScale](https://create.roblox.com/docs/reference/engine/classes/UIScale), and [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject): selected GUI trees, virtual-canvas scaling, interaction and native layout behavior. Layout snapshots strip executable descendants, disable interaction and normalize Global/Sibling draw ordering into the plugin canvas.
- [VideoFrame](https://create.roblox.com/docs/reference/engine/classes/VideoFrame): pause/mute preview media; a clone is a property snapshot rather than an immutable image of a video frame.
- [StudioDeviceSimulatorService](https://create.roblox.com/docs/reference/engine/classes/StudioDeviceSimulatorService): dynamic device IDs; independent orientation, DPI, resolution and scaling state; mutations unavailable in Play Server; selecting a device resets session resolution/DPI overrides.
- [StudioCaptureService](https://create.roblox.com/docs/reference/engine/classes/StudioCaptureService): user-approved viewport capture, UI inclusion and asynchronous screenshot object creation.
- [StudioScreenshotCapture](https://create.roblox.com/docs/reference/engine/classes/StudioScreenshotCapture): wait for `BufferStatus`, retrieve RGBA with `GetBuffer`, inspect errors, resize through `ScaleAsync`, then destroy the capture object.
- [EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage): copy RGBA pixels into bounded images and display through `Content.fromObject` in an `ImageLabel`/`ImageButton`. Explicit `Destroy` releases retained memory.
- [Studio plugin documentation](https://create.roblox.com/docs/studio/plugins): native dock widgets, toolbar entry, theme conventions and plugin ownership.

An actual Studio 0.747 probe found that orientation can be set only while a phone or tablet is active. The adapter therefore restores orientation through a discovered mobile preset before returning to an original desktop/default device. Non-mobile device rows do not expose rotation. The resolution getter uses landscape-canonical dimensions, even in portrait orientation. Default-mode scaling cannot be read until a device is activated, so the batch saves that preserved mode immediately after its first activation and before changing scaling. It restores the mode before stopping simulation.

## Scope choices

The documented screenshot permission method returned `Feature not supported yet.` in Studio 0.747.0.7471481, including in a separately installed local plugin. API documentation alone did not establish availability. The supported v0.1 workflow therefore uses static native layout trees. The screenshot adapter remains explicitly experimental and cannot proceed without permission. Layout mode does not mutate the simulator, run scripts or reproduce safe-area behavior.

The first release has no cloud service, filesystem bridge, package framework or persistent screenshot database. A capture batch is atomic at the board level: a successful batch replaces current images only after restoration succeeds. Each image belongs to exactly one current/baseline set. Pinning moves ownership; it does not allocate duplicate images.

The board is bounded to three states, two sets per state and six captures per set. Each layout source is capped at 800 instances, plus at most one owned camera per ViewportFrame (below 57,600 retained instances at the theoretical maximum, plus bounded visible preview copies and the in-progress batch). External media resources are subject to Roblox's own allocation behavior. Experimental screenshot previews have a 512-pixel longest edge: worst-case retained raw RGBA is 36 MiB, excluding transient capture buffers. Failed batches preserve the existing board.

Studio testing showed that `ViewportFrame.CurrentCamera` is not retained by a plain `Clone()`. The layout cloner therefore rebuilds an owned camera at every snapshot/render stage, preserving its pose and field-of-view mode. This also prevents an external source camera from changing an existing baseline. Nonvisual ObjectValue references are stripped.

The UI uses Studio theme colors, SourceSans typography, 4-pixel radii and ordinary rows. Fixed control heights are intentional for a resizable desktop plugin, with proportional widths and scrolling content. No external artwork or font dependency is required.
