# estuary-ui

Cadence/Tithe **design system** for Roblox — Fusion + Iona + Lucide, with spring motion.

**Not published to Wally yet.** Path-link `src`; Iona via `../iona`; `wally install` for Fusion + Lucide.

## Quick start

```bash
rokit install
wally install
rojo serve demo.project.json
```

```luau
local EstuaryUI = require(Packages.EstuaryUI)
local scope = EstuaryUI.scoped()
local theme = EstuaryUI.Theme.create("Light") -- Montserrat typography

EstuaryUI.Theme.Provide(theme, function()
  EstuaryUI.Components.Button(scope, { Text = "Run", Variant = "Outlined" })
  EstuaryUI.Components.Icon(scope, { Name = "search", IconSize = 24 })
end)
```

## Highlights

- **Theme.Provide** + root fallback (safe inside Fusion `Computed` re-evals)
- **Lucide** icons via `Components.Icon` / `IconButton` (`Name = "bell"`)
- **State layers** tint the control fill (no padded hover overlay); color-only press
- **ScrollArea** — smooth scroll, inertia, keyboard, custom scrollbar, AutoCanvas
- **Select** popover (does not push layout); rounded menu items; raised ZIndex when open
- **TextField** — placeholder, helper, error, multiline + corner `Resize`, animated stroke
- **Progress** — Determinate / Material-like Indeterminate (dual indicators) / Buffering
- **Dialog / Prompt** — scrim modal with spring enter; `ConfirmDialog` for destructive
- **Typography** — Montserrat Medium body (no Regular); Display/Headline/Title/Label/Mono
- **Drawer / Menu** — spring slide / fade animations
