---
tags:
  - Forms
  - Components
---

# RangeSlider

RangeSlider has two handles. The user chooses a range of values, not a single value.

## Usage

Call `Components.RangeSlider` with a scope and a table of properties:

```luau
C.RangeSlider(scope, {
	Min = 0,
	Max = 100,
	Value = NumberRange.new(20, 60),
	OnChanged = function(range)
		print(range.Min, range.Max)
	end,
})
```

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Theme` | `ThemeRef` | :x: | The contextual theme | Theme to use for this component instead of the one from `Theme.Provide`. |
| `LayoutOrder` | `UsedAs<number>` | :x: | `0` | Position in a parent `UIListLayout` or `UIGridLayout`. |
| `Size` | `UsedAs<UDim2>` | :x: | - | Size of the component. |
| `Value` | `UsedAs<NumberRange>` | :x: | `NumberRange.new(Min, Max)` | The range. A plain value is only the starting range. A `Value` stays in step with the control: the user's changes set it, and setting it changes the control. |
| `Min` | `number` | :x: | `0` | Lowest value. |
| `Max` | `number` | :x: | `1` | Highest value. |
| `Disabled` | `UsedAs<boolean>` | :x: | - | Stops the handles reacting to input. |
| `Id` | `string` | :x: | - | Key that identifies this component when state is kept across rebuilds. See [Persist](../../Guides/PersistingState.md). |

## Callbacks

| Name | Description |
| ---- | ----------- |
| `OnChanged: (NumberRange) -> ()` | Runs with the new range as the user drags. |

## See also

- [Slider](./Slider.md)
