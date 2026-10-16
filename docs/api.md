# estuary-ui API

Version `0.2` (unpublished). Cadence/Tithe MD3 language · Fusion 0.3 · Iona 0.2.

## Root exports

| Export | Role |
| --- | --- |
| `Theme.create(mode?)` | Build light/dark token table |
| `Theme.Provide(theme, fn, …)` | Fusion Contextual inject for `fn` |
| `Theme.use()` / `Theme.resolve(props)` | Read current theme |
| `Components.*` | Widget constructors `(scope, props)` |
| `scoped()` | `Fusion.scoped(Fusion, Iona)` |
| `Fusion` / `Iona` | Re-exports |

## Conventions

- Always wrap app UI in `Theme.Provide`.
- Props bags only; `UsedAs<T>` for reactive fields.
- Optional `props.Theme` overrides contextual theme.
- No raw `Instance.new` in public components.

## Component catalog

### Foundations / theme tokens

`Primary`, `OnPrimary`, `PrimaryContainer`, `OnPrimaryContainer`, `Background`, `Surface`, `SurfaceDim`, `SurfaceBright`, `OnSurface`, `OnSurfaceVariant`, `SurfaceContainer`, `SurfaceContainerHigh`, `Outline`, `OutlineVariant`, `Error`, `Success`, `Warning`, `Info`, metrics (`DrawerWidth`, `AppBarHeight`, …), icons, audio stubs.

### Containment

`Surface`, `Sheet`, `Card`, `Overlay`, `Dialog`, `ConfirmDialog`, `Menu`, `Tooltip`

### Forms

`Text`, `TextField`, `Checkbox`, `Switch`, `RadioGroup`, `Select`, `Combobox`, `Slider`, `RangeSlider`, `Chip`, `Icon`, `IconButton`, `Form`

### Feedback

`Alert`, `Snackbar`, `SnackbarHost` (returns `{ Instance, Show }`), `Progress`, `Badge`, `Tabs`

### Navigation / layout

`AppBar`, `NavigationDrawer`, `NavigationRail`, `Breadcrumbs`, `Pagination`, `Divider`, `Spacer`, `Container`

### Pickers

`DatePicker` (ISO `YYYY-MM-DD`), `TimePicker` (seconds from midnight), `ColorPicker` (`Color3`)

### Data

`VirtualList` (windowed rows), `DataTable` (sort/filter + virtual body), `ListItem`, `Avatar`, `EmptyState`

## Demo

```bash
rojo serve demo.project.json
```

Storyboard: light/dark toggle, sectioned gallery for shipped components.

## Style (typed theme tokens)

Tokens are plain, type-checked values read from the theme given to `Theme.Provide`; there are no strings or new syntax.

```luau
local S = EstuaryUI.Style

EstuaryUI.Theme.Provide(theme, function()
	scope:Frame({
		BackgroundColor3 = S.Color.SurfaceContainer,
		Padding = { S.Space.Md, S.Space.Lg },
		CornerRadius = { S.Radius.Lg },
		Layout = S.Row(S.Space.Sm),
		[Children] = { ... },
	})
end)
```

- `S.Color.*` (theme.Colors), `S.Font.*`, `S.Type.*` (typography scales)
- `S.Space.Xs2|Xs|Sm|Md|Lg|Xl`, `S.Radius.None|Xs2|Xs|Sm|Md|Lg|Xl|Xl2|Xl3|Panel|Pill`
- `S.Row(gap)` / `S.Column(gap)` layout presets; `S.merge(a, b, …)` composes reusable prop bags
- Values are read when the expression runs, so rebuild the tree (or wrap in a Computed) on theme change.

### Component styles

```luau
local S = EstuaryUI.Style

local Primary = S.define({ Variant = "Filled" })
local Danger = Primary:extend(function(theme) -- theme-aware
	return { Color = theme.Colors.Error }
end)

local PrimaryButton = S.styled(EstuaryUI.Components.Button, Primary)
local DangerButton = S.styled(EstuaryUI.Components.Button, Danger)

PrimaryButton(scope, { Text = "Save" })
DangerButton(scope, { Text = "Delete", Variant = "Outlined" }) -- call-site props override
```

- Precedence: base style < `extend`ed styles < props passed at the call site.
- Keyed tables such as `Layout` / `Shadow` deep-merge; arrays (`Padding = {…}`), Instances and states replace.
- `style:apply(props)` returns a plain prop bag for use with `scope:Frame` etc.

## `scope:Apply` (Hydrate replacement)

Fusion's `Hydrate` is slated for deprecation. Estuary scopes (`EstuaryUI.scoped()`) provide their own `Apply`, built only on Fusion's public API (`Observer`, `peek`, SpecialKeys):

```luau
scope:Apply(existingInstance)({
	LayoutOrder = 1,
	Visible = someState,
	[OnEvent("Activated")] = onClick,
	[Children] = { ... },
})
```

`scope:Hydrate` remains as an alias to the same implementation, so Iona and older code keep working. `EstuaryUI.Apply(scope, instance)(props)` is also available standalone.
