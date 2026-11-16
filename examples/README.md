# Field Supply examples

## Static layout comparison

`LayoutDemo.luau` returns `create(parent) -> ScreenGui`. Its native scale-based layout works without runtime callbacks and is the recommended ViewportBoard demo. All illustrations are original geometric UI; it contains no external assets.

Build `rojo build examples/layout.project.json -o FieldSupplyLayout.rbxm`. Insert the ModuleScript in `ServerStorage`, then run this in Studio's Command Bar:

```lua
local gui = require(game.ServerStorage.FieldSupplyLayout)(game.StarterGui)
game:GetService("Selection"):Set({gui})
```

In ViewportBoard, name the state `Field Supply`. To demonstrate an intentional fixed-width defect before the first snapshot:

```lua
game.StarterGui.FieldSupplyLayout.Page.Content.Column.Catalog.Size = UDim2.fromOffset(690, 446)
```

Snapshot and pin the baseline, then fix the width and snapshot again:

```lua
game.StarterGui.FieldSupplyLayout.Page.Content.Column.Catalog.Size = UDim2.new(1, -48, 0, 446)
```

The phone baseline clips the right column; the current layout fits all four products. Click either preview to inspect. The source is a demo UI, so delete it when finished.

## Interactive runtime fixture

`FieldSupplyDemo.luau` is a standalone ModuleScript returning `create(parent) -> ScreenGui`. It uses only native Roblox UI and original geometric illustrations; there are no external assets or dependencies.

```lua
local create = require(path.To.FieldSupplyDemo)
local gui = create(game.Players.LocalPlayer.PlayerGui)
```

To build the complete test fixture, run `rojo build examples/demo.project.json -o FieldSupplyDemo.rbxm` from the repository root. Insert the resulting folder into `StarterPlayerScripts` in a test place and press Play. The included LocalScript creates the example in PlayerGui. It is not part of the plugin build.

- The returned ScreenGui is named `FieldSupplyDemo`; its root frame is `FieldSupply`.
- Default: responsive cream/charcoal/sage equipment shop. Below 680 available content pixels, the catalog changes from three columns to two; item details move below the grid in the vertical scroll area.
- Click an item to update its illustration and detail panel. Categories filter the grid. `ADD TO LOADOUT` toggles a local demonstration state; it does not purchase or persist anything.
- `gui:SetAttribute("BrokenLayout", true)` enables a single intentional defect: the catalog stays 690 pixels wide with a desktop arrangement. It visibly clips on a phone. Set the attribute back to `false` to restore responsive layout. This is the only intentionally incorrect layout state.
- `gui:GetAttribute("SelectedItem")` exposes the selected item name for demo automation.
- Destroy the returned ScreenGui to clean up. All callbacks attach to owned instances and are also disconnected on `Destroying`; no RunService connections or per-frame loops are created.

## Suggested clip

Use a wide preview and select Trail lantern, then Wayfinder compass. Switch to a portrait-phone preview, enable `BrokenLayout`, briefly show the clipped grid, then set it false. Scroll to the detail panel and add the selected item to the loadout. Return to the desktop preview.

Runtime layout connections do not survive `Instance:Clone()`. A preview tool that clones this tree sees its current layout state. Instantiate this module for each live preview surface, or run its fixture layout function against the active source size before making each static snapshot. Do not imply arbitrary user scripts execute automatically inside preview clones.

Art: Alpine field pack, Trail lantern, Summit flask, Ranger optics, Wayfinder compass, Utility cord. Every shape is created in code specifically for this fixture.
