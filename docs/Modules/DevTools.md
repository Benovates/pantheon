---
tags:
  - Modules
---

# DevTools

DevTools is a panel for looking at a running interface, in the style of React DevTools. It shows the tree of the interface, lets you edit the properties of an element, and shows what changes while the interface runs. It reads the interface of the local player, so it works on any Roblox UI, not only Pantheon's.

```luau
Pantheon.Flags.DevTools = true
local unmount = Pantheon.DevTools.mount()
```

Press F8 to open and close the panel. `mount` returns a function that removes the tools.

!!! note

    DevTools does nothing, and warns, unless `Flags.DevTools` is `true` when you call `mount`. This keeps it out of a released experience by default.

## The panel

The panel is docked at the bottom of the screen. Drag its top edge to change the height.

### Components

The left side is a tree of the interface, an [Explorer](../Components/Layout/Explorer.md) over the `PlayerGui`. Type in the search box to filter it. Pointing at a row outlines that element on screen, with its name and size.

The right side is the selected element:

- **Name.** Editable.
- **Path.** Press an ancestor to select it.
- **Properties.** Each has an editor that suits its type: a switch for a boolean, a number field for a number, a text field for text and colours, number fields for a `UDim2`, a `UDim` or a `Vector2`, and a button that steps through the items of an enum. The values follow the element while it changes, and what you edit is written to it at once.
- **Attributes.** The attributes of the element.
- **Children.** Press one to select it.

The pointer button in the header lets you click an element on screen to select it. Escape leaves it. The tree opens up to the element you picked.

### Profiler

Press Record, use the interface, and the Profiler lists the elements that changed most, with how many changes there were and how many each second. Changes to the layout, such as `AbsoluteSize`, are not counted. Press an entry to select the element. This shows what is animating or being rewritten more often than it should.

### Highlight updates

The lightning button in the header makes an element flash each time one of its properties changes, as the highlight of React DevTools does. A hot spot flashes all the time. At most thirty elements flash at once.

### Settings

Switches for `Flags.CanvasFade`, `Flags.LifetimeChecks` and `Flags.BetaUI`. Components read flags when they are built, so rebuild the interface to see the effect.

## Functions

| Name | Description |
| ---- | ----------- |
| `mount: (props: Props?) -> () -> ()` | Builds the tools. Returns a function that removes them. |

## Props

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `Parent` | `Instance?` | The `PlayerGui` | Where the `ScreenGui` of the tools is placed. |
| `Hotkey` | `Enum.KeyCode?` | `Enum.KeyCode.F8` | Opens and closes the panel. |
| `Theme` | `ThemeRef?` | A dark theme | Theme of the tools. By default they have a dark theme of their own, so they look the same in any app. |
| `Open` | `boolean?` | `false` | Open the panel when it is mounted. |
| `Height` | `number?` | `340` | Height of the panel in pixels. |
