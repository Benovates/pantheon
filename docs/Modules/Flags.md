---
tags:
  - Modules
---

# Flags

Flags are switches for how the library behaves. Set them before you build your interface:

```luau
Pantheon.Flags.LifetimeChecks = true
```

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `CanvasFade` | `boolean` | `false` | Wrap chrome that appears, such as dialogs, in a `CanvasGroup` and fade its `GroupTransparency`. When it is off, the transparency of each element is faded instead. |
| `LifetimeChecks` | `boolean` | `false` | Run the lifetime checks of Fusion. They scan a whole scope on every `use`, so they are slow, and Pantheon turns them off. Turn them on to find a scope that outlives what it uses. |
| `ReactiveTheme` | `boolean` | `false` | Let components follow a theme state, so changing the mode updates colours in place instead of needing a rebuild. Experimental. |
| `BetaUI` | `boolean` | `true` | Use UI features that are in Studio betas, such as conical and radial gradients and text shadows, when the engine has them. Set it to `false` to force the fallbacks. See [Features](Features.md). |
| `ConicalRotation` | `number` | `-90` | Degrees added to the rotation of a conical gradient so that position `0` is at 12 o'clock. A conical gradient starts at 3 o'clock, so `-90` puts the start at the top. Change it if an arc or the colour wheel looks turned. |
| `ConicalClockwise` | `boolean` | `true` | Whether a conical gradient sweeps clockwise. |

The storyboard has a calibration ring that fills from 12 o'clock to 3 o'clock. If it is turned or mirrored, adjust `ConicalRotation` and `ConicalClockwise`.
