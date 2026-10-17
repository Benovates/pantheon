---
tags:
  - Modules
---

# GroupFade

GroupFade fades an instance and everything under it by driving the transparency of each element. It does this without a `CanvasGroup`, which would draw the group to a texture, use more memory, make text softer and clip anything that spills outside it, such as shadows and strokes.

Every element gets the same multiplier, so an opaque panel, its text, icons, strokes and shadows fade together:

```
transparency = 1 - (1 - base) × alpha
```

## Functions

| Name | Description |
| ---- | ----------- |
| `bind: (scope: Scope, root: Instance, alpha: State<number>) -> ()` | Fades `root` and its descendants with `alpha`. `0` is invisible and `1` is shown. Instances added to `root` later are included. The binding ends when the scope is cleaned up. |

```luau
local reveal = scope:Spring(scope:Value(0), 20, 1)
Pantheon.GroupFade.bind(scope, panel, reveal)
```

## How it works

Each time `alpha` changes, GroupFade compares the transparency of each element with the value it wrote last time. If they differ, something else changed it, for example a hover effect, and the new value becomes the base. Then it writes the faded value. When `alpha` reaches `1` it puts the exact base values back and stops tracking, so a group that is fully visible costs nothing.

An element can opt out by setting the attribute `PantheonNoFade` to `true`.

!!! warning

    Do not bind two GroupFades to instances where one is inside the other. They would see each other's writes as changes made by something else and the base values would drift.
