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
