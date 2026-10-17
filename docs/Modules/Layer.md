---
tags:
  - Modules
---

# Layer

Layer says where floating content is mounted. See [Overlay layers](../Guides/OverlayLayers.md).

## Functions

| Name | Description |
| ---- | ----------- |
| `Provide: (layer: GuiObject, callback: (...) -> ..., ...) -> ...` | Makes `layer` the current layer while `callback` runs. It is also remembered as the fallback layer. |
| `bind: (layer: Instance?) -> ()` | Sets the fallback layer, used by components that are created when there is no current layer. A [Window](../Components/Navigation/Window.md) calls it for its own overlay layer. Pass `nil` to clear it. |
| `use: () -> GuiObject?` | The current layer, or the fallback layer. |
| `resolve: (props: { Layer: Instance? }?) -> GuiObject?` | The `Layer` of `props` if it is a `GuiObject`, and `use()` otherwise. |
| `mount: (scope: Scope, props, instance: Instance) -> boolean` | Parents `instance` to the resolved layer, and removes it again when the scope is cleaned up. It returns `false`, and leaves `instance` alone, when there is no layer. |
| `asGui: (instance: Instance?) -> GuiObject?` | `instance` if it is a `GuiObject`. |

## Properties

| Name | Description |
| ---- | ----------- |
| `Contextual` | The Fusion `Contextual` that holds the current layer. |
