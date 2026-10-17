---
tags:
  - Pickers
  - Components
---

# CurveEditor

CurveEditor edits a `NumberSequence`, the curve used by particles, beams and trails. It is a plot with keypoints you can drag, and number fields for the selected keypoint.

## Usage

Call `Components.CurveEditor` with a scope and a table of properties:

```luau
local curve = scope:Value(NumberSequence.new(0, 1))

C.CurveEditor(scope, {
	Value = curve, -- (1)!
	Min = 0,
	Max = 1,
	ShowEnvelope = true,
})
```

1.  A `Value` and the editor follow each other. Assign `curve:get()` to a `ParticleEmitter.Size`, for example.

## Editing

- Drag a keypoint to move it. The first keypoint stays at time `0` and the last at time `1`, and a keypoint cannot pass its neighbours.
- Double click the plot to add a keypoint. It starts on the curve, so the curve does not change.
- Select a keypoint and press the trash button, or focus it and press Delete, to remove it. The first and last keypoints cannot be removed.
- The fields under the plot edit the selected keypoint: `T` is its time, `V` its value and `±` its envelope, when `ShowEnvelope` is on.
- A focused keypoint moves with the arrow keys.

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Id` | `string` | :x: | - | Key that identifies this component when state is kept across rebuilds. See [Persist](../../Guides/PersistingState.md). |

## See also

- [GradientPicker](./GradientPicker.md)
- [NumberField](../Forms/NumberField.md)
