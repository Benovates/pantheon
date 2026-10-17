---
tags:
  - Modules
---

# Style

Style has two jobs: tokens that read from the current theme, and reusable defaults for components.

## Tokens

The tokens are tables that look up the current theme each time you read a field:

| Name | Reads from | Example |
| ---- | ---------- | ------- |
| `Color` | `theme.Colors` | `Style.Color.Primary` |
| `Font` | `theme.Fonts` | `Style.Font.Heading` |
| `Type` | `theme.Typography` | `Style.Type.Title.Size` |
| `Space` | spacing in `theme.Metrics` | `Style.Space.Md` |
| `Radius` | corner radii in `theme.Metrics` | `Style.Radius.Lg` |

## Layout presets

| Name | Description |
| ---- | ----------- |
| `Row: (gap: number?) -> Props` | A `Layout` table for a horizontal list with the items centred vertically. |
| `Column: (gap: number?) -> Props` | A `Layout` table for a vertical list. |

```luau
scope:Frame({
	Layout = Pantheon.Style.Row(8),
})
```

## Defining a style

A style is a set of default properties, either a table or a function of the theme. `define` makes one. Several specs are layered, and later ones win.

```luau
local Style = Pantheon.Style

local Primary = Style.define({ Variant = "Filled" })
local Danger = Primary:extend(function(theme)
	return { Color = theme.Colors.Error }
end)
```

A style has these methods:

| Name | Description |
| ---- | ----------- |
| `resolve: (self) -> Props` | The properties of the style, resolved against the current theme. |
| `extend: (self, spec) -> StyleDef` | A new style made of this one and `spec`. `spec` wins. |
| `apply: (self, props) -> Props` | `props` merged over the style, so `props` wins. |

## Styled components

`styled` makes a copy of a component that uses a style as its defaults. The properties you give when you call it win:

```luau
local PrimaryButton = Style.styled(Pantheon.Components.Button, Primary)

PrimaryButton(scope, { Text = "Run" })
```

## Functions

| Name | Description |
| ---- | ----------- |
| `define: (...Spec) -> StyleDef` | Makes a style. |
| `styled: (component, style) -> component` | Makes a component that has `style` as its defaults. |
| `merge: (...Props) -> Props` | Merges property tables from left to right. Later ones win, except children, which are joined. |
| `deepMerge: (base, over) -> Props` | Merges `over` into `base`. Plain tables merge field by field. Arrays, instances and states are replaced. |
