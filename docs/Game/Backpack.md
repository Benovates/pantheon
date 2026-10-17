---
tags:
  - Game
  - Components
---

# Backpack

Backpack feeds a [Hotbar](./Hotbar.md) from the Roblox backpack of a player, so a game does not need its own inventory. It follows the tools in the backpack and the tool the character is holding.

## Usage

Call `Game.Backpack` with a scope and optional settings. It returns the properties to give to a Hotbar:

```luau
local Game = Pantheon.Game

local inventory = Game.Backpack(scope, { Capacity = 27 })

Game.Hotbar(scope, {
	Items = inventory.Items,
	Selected = inventory.Selected,
	OnSelect = inventory.OnSelect,
	OnMove = inventory.OnMove,
	Capacity = 27,
})
```

## Behaviour

- A tool takes the first free slot when it arrives.
- Equipping a slot with the bar equips that tool, and unequipping calls `UnequipTools`. If you equip or unequip a tool another way, `Selected` follows.
- A tool moves between the backpack and the character when it is equipped. The bar only forgets a tool once it is in neither.
- The item for a tool has the `Name` of the tool, its `ToolTip` as the `Description`, its `TextureId` as the `Image`, and the tool itself as `Tool`. The name, tooltip and texture are watched, so a change shows on the bar.

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Player` | `Player` | :x: | `Players.LocalPlayer` | The player to follow. |
| `Capacity` | `number` | :x: | `30` | Number of slots the tools can fill. Tools that do not fit are not shown. |

## Returned table

| Name | Type | Description |
| ---- | ---- | ----------- |
| `Items` | `Value<{ [number]: item }>` | The tools as Hotbar items. |
| `Selected` | `Value<number?>` | The slot of the tool that is held. |
| `OnSelect` | `(slot: number?) -> ()` | Equips the tool in a slot, or unequips when it is `nil`. |
| `OnMove` | `(from: number, to: number) -> ()` | Swaps two slots. |

## See also

- [Hotbar](./Hotbar.md)
