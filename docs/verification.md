# Verification

A 22-second 720×1080 H.264 clip was recorded from the actual Studio plugin at 30 fps. It shows the original Field Supply example's clipped phone baseline, the revised layout, and the comparison board. These are native layout-property snapshots; no screenshot-mode result is implied. Selected frames were visually reviewed.

Verified 17 November 2026 using Luau 0.747, Rojo 7.7.0 and Windows Studio 0.747.0.7471481.

## Portable checks

`tests/run.luau`: **19 passed**. Covers successful restoration, permission/snapshot failures without mutation, selection/settling/capture failures, cancellation before/during a batch and restoration, failed progress callbacks, partial-result disposal, board ownership transfer/replacement/deletion, capacity and name validation. The actual Native restoration functions also run against a fake simulator that resets resolution/DPI on device changes and restricts orientation setters to mobile devices.

The strict `Board` and `Batch` modules pass `luau-analyze`. All shipped Luau files compile. Rojo builds the plugin. These checks establish orchestration and syntax, not rendering or universal API availability.

## Real Studio layout checks

The production `App.start(plugin)` ran in a real DockWidgetPluginGui with 43 dynamically discovered device presets. Its default selection was iPhone 17 Pro (402 × 874), iPad A16 (820 × 1180), and HD 1080 (1920 × 1080).

`tests/Studio.spec.luau`: **10 passed**, against the actual engine and Layout module:

- Scripts and audio removed; video paused/muted; native dragging disabled.
- Global overlap ordering preserves a high-ZIndex descendant above a peer branch.
- Sibling ordering preserves complete parent branches.
- Disabled ScreenGui remains disabled.
- Retained snapshot properties remain independent of later source edits.
- ViewportFrame cameras remain owned and independent through template, retained and rendered copies; ObjectValue references are removed.
- Virtual canvas scales proportionally into its preview host.
- A selected TextBox root cannot be edited.
- Non-archivable descendants fail without changing source properties.
- The 800-instance cap rejects oversized trees.

Five additional production-App scenarios passed in Studio: cancellation preserves prior results; closing during capture cancels cleanly; recapture destroys replaced trees; deletion destroys retained trees; unsupported screenshots leave both simulator and board unchanged.

The original declarative Field Supply fixture was captured with a 690-pixel catalog, pinned, then captured with scale-based catalog width. Visual inspection showed the phone baseline clipping the right column while the current preview displayed all four products. A real mouse click opened the enlarged phone preview; Close restored the comparison board. Dark-theme controls and empty/error states were inspected. Light-theme colors use Studio's native palette but were not visually retested in this session.

The Studio runner accepts `(modulesFolder, hostGuiObject)` and restores the original selection and destroys its fixtures even on failure. It needs plugin security for Selection and a rendered host inside a test widget. It is excluded from the release plugin.

## Experimental screenshot limitation

Both the production code in a plugin harness and a separately installed local `.rbxm` plugin returned **`Feature not supported yet.`** from `StudioCaptureService:RequestScreenshotPermissionAsync()`. No permission prompt appeared; `CanCaptureScreenshot()` returned false. No screenshot request bypass was attempted. Native screenshot pixels, capture dimensions, EditableImage allocation and a successful screenshot batch remain unverified.

Separate simulator probes confirmed mobile-only orientation setters; landscape-canonical resolution getters in portrait; resolution/DPI reset on device switching; orientation readable in default mode; and scaling/resolution/DPI getters unavailable in default mode. The screenshot adapter handles those observed constraints, but its success path requires a future supported capture environment before release claims can change.

No pixel-difference automation, exhaustive device compatibility, long-duration memory profiling, accessibility certification or hardware performance testing is claimed.
