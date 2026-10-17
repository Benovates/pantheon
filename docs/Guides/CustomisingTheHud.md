# Customising the HUD

This guide shows how to change the [Hotbar](../Game/Hotbar.md). Each section is a separate change. Start with this bar:

```luau
local items = scope:Value({})

Pantheon.Game.Hotbar(scope, {
	Items = items,
	Slots = 9,
	Capacity = 27,
})
```

## Change the number of slots

`Slots` is the number of slots on the bar. You can have up to 10, one for each number key. `Capacity` is the total number of slots. The slots after the first `Slots` appear only in the inventory panel.

```luau
Pantheon.Game.Hotbar(scope, {
	Items = items,
	Slots = 6, -- (1)!
	Capacity = 24,
	Columns = 6, -- (2)!
	ExpandedRows = 3, -- (3)!
})
```

1.  The bar has 6 slots. The keys `1` to `6` equip them.
2.  The panel has 6 slots in each row.
3.  The panel shows 3 rows. It scrolls if there are more.

## Change the size

`SlotSize` is the width and height of a slot, in pixels. The panel uses the same size.

```luau
Pantheon.Game.Hotbar(scope, {
	Items = items,
	SlotSize = 64,
})
```

## Keep the default Roblox backpack

The bar hides the default Roblox backpack. To show both, set `DisableDefault` to `false`.

```luau
Pantheon.Game.Hotbar(scope, {
	Items = items,
	DisableDefault = false,
})
```

## Handle the keys yourself

Set `BindKeys` to `false` to turn off the number keys and the backtick key. Then equip slots and open the panel from your own code:

```luau
local selected = scope:Value(nil)
local expanded = scope:Value(false)

Pantheon.Game.Hotbar(scope, {
	Items = items,
	Selected = selected,
	Expanded = expanded,
	BindKeys = false,
})

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Tab then -- (1)!
		expanded:set(not peek(expanded))
	end
end)
```

1.  This opens and closes the panel with the Tab key. You can use any key.

!!! warning

    If you turn off `BindKeys`, keyboard players cannot equip a slot unless you set `Selected` yourself. They can still click a slot.

## Search by your own fields

The search matches any string field of an item. To let players search one field by name, add a scope:

```luau
Pantheon.Game.Hotbar(scope, {
	Items = items,
	SearchScopes = {
		rarity = function(item)
			return item.Rarity
		end,
	},
})
```

A player can now type `rarity:epic` to match only the rarity.
