---
tags:
  - Pickers
  - Components
---

# TimePicker

TimePicker chooses a time of day with a number box for the hours and one for the minutes.

## Usage

Call `Components.TimePicker` with a scope and a table of properties:

```luau
C.TimePicker(scope, {
	Value = 9 * 3600 + 30 * 60, -- (1)!
	OnChanged = function(seconds)
		print("Picked", seconds)
	end,
})
```

1.  Times are a number of seconds after midnight. `9 * 3600 + 30 * 60` is 09:30.

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Theme` | `ThemeRef` | :x: | The contextual theme | Theme to use for this component instead of the one from `Theme.Provide`. |
| `LayoutOrder` | `UsedAs<number>` | :x: | `0` | Position in a parent `UIListLayout` or `UIGridLayout`. |
| `Size` | `UsedAs<UDim2>` | :x: | - | Size of the component. |
| `Value` | `UsedAs<number>?, -- seconds from midnight` | :white_check_mark: | `0` | The time in seconds after midnight. A plain value is only the starting time. A `Value` is followed, and is set when the hours or minutes change. |
| `Id` | `string` | :x: | - | Key that identifies this component when state is kept across rebuilds. See [Persist](../../Guides/PersistingState.md). |

## Callbacks

| Name | Description |
| ---- | ----------- |
| `OnChanged: (number) -> ()` | Runs with the time in seconds after midnight when the hours or minutes change. |

## See also

- [DatePicker](./DatePicker.md)
