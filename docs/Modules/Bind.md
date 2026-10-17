---
tags:
  - Modules
---

# Bind

Bind keeps a control's own state in step with a state you give it. It is how `Checkbox`, `Slider`, `Select` and most other controls follow a `Value`. See [Common properties](../Guides/CommonProperties.md) for what this means for the player of a component.

A control keeps its value in a `Value` of its own. When you give it a state, `link` makes the two equal. Setting your state moves the control, and the user changing the control sets your state, as long as it is a `Value`. A `Computed` cannot be set, so it only moves the control.

## Functions

| Name | Description |
| ---- | ----------- |
| `link: (scope: Scope, prop: any, internal: Value, options: Options?) -> ()` | Links `internal` to `prop`. Nothing happens when `prop` is not a state. |
| `linkParts: (scope: Scope, prop: any, parts: { Value }, join: (...any) -> any, split: (value: any) -> { any }?, equals: ((a, b) -> boolean)?) -> ()` | Like `link`, for a value kept in several `Value`s, such as a range in two ends or a date in year, month and day. `join` builds your value from the parts and `split` takes it apart. When `split` returns `nil`, the parts are kept. |
| `isState: (value: any) -> boolean` | Whether `value` is a Fusion state. |
| `isWritable: (value: any) -> boolean` | Whether `value` is a state that can be set. |
| `listEquals: (a: any, b: any) -> boolean` | Equality for lists of strings or numbers. |

## Options

| Name | Description |
| ---- | ----------- |
| `toInternal` | Converts your state's value to the form the control keeps. |
| `toProp` | Converts the control's value to the form your state holds. |
| `equals` | Compares two values. Needed for tables, since the default is `==`. |

```luau
local selected = scope:Value("a")
Bind.link(scope, props.Selected, selected)
```
