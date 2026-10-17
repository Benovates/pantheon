---
tags:
  - Game
  - Components
---

# Leaderboard

Leaderboard is a player list in the style of the one in Roblox: translucent rows with a faded headshot, a display name that gives way to the username when you hover, and team headers that fold their players away. Players can join and leave with an animation, and the whole list can slide off the screen.

## Usage

Call `Pantheon.Game.Leaderboard` with a scope and a table of properties:

```luau
local Game = Pantheon.Game

Game.Leaderboard(scope, {
	Title = "Players",
	Self = localUserId,
	Sort = "Value",
	Teams = {
		{
			Name = "Red",
			Color = Color3.fromRGB(196, 40, 28),
			Players = {
				{ Id = 1, Name = "ada_l", DisplayName = "Ada", UserId = 1, Value = 4200 },
			},
		},
	},
})
```

## Rows

A row is a table with these fields:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `Id` | `any` | Identifies the row. Keep it between updates, so the row is not rebuilt. |
| `Name` | `string` | The username. It is shown as `@Name` when the row is hovered. |
| `DisplayName` | `string?` | The name shown at rest. It is `Name` when left out. |
| `UserId` | `number?` | The Roblox user id, for the headshot. |
| `Image` | `string?` | An asset ID for a picture, for a row that is not a Roblox user. It wins over `UserId`. |
| `Icon` | `string?` | An asset ID for a small icon at the end of the row. |
| `Value` | `number` or `string` | A stat shown at the end of the row. |

## Teams

`Teams` is a list of teams, each with a `Name`, a `Color` and its `Players`. The header takes the colour of the team and shows its name and how many players it has. Press a header and the rows of that team fold away. Give a team a `Collapsed` `Value` to fold it yourself. A team with an empty `Name` has no header, and `Players` is a shortcut for one such team.

## Motion

A row slides in from the edge and grows to its height when a player joins, and shrinks away when one leaves. Hovering a row fades the display name out while it slides to the left, and brings in `@username` the same way. With `Open` set to `false` the list slides off the edge of the screen.

## From the experience

`Game.Roster` builds the `Teams` for you from the players and teams of the experience. It follows players joining and leaving, team changes, and shows a friend or Premium icon. It uses `Players`, `Teams` and the `Hidden` attribute of a team to leave one out. Players with no team are put in "No Team", and without any teams there is one list without headers.

```luau
local roster = Game.Roster(scope, {
	Value = function(player)
		return player:GetAttribute("Kills")
	end,
})

Game.Leaderboard(scope, {
	Teams = roster.Teams,
	Self = roster.Self,
})
```

`Roster` takes `Value`, a function from a player to a stat, and `Icon`, a function from a player to an icon asset ID.

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Teams` | `any` | :x: | - | The teams, as a table or a state of one. See Teams. |
| `Players` | `any` | :x: | - | Players with no teams, as a table or a state of one. |
| `Title` | `string` | :x: | `"Players"` | Heading of the list. |
| `Self` | `any` | :x: | - | `Id` of the local player's row, which is lightly highlighted. A state is followed. |
| `Open` | `any` | :x: | `true` | Whether the list is on screen. A state is followed. When it is `false` the list slides off the edge. |
| `Width` | `number` | :x: | `220` | Width of the list in pixels. |
| `MaxHeight` | `number` | :x: | - | Height in pixels at which the list starts to scroll. |
| `RowHeight` | `number` | :x: | `42` | Height of a row in pixels. |
| `Sort` | `"None" \| "Value"` | :x: | `"None"` | `"Value"` sorts the players of each team by `Value`, highest first. |
| `Position` | `UDim2` | :x: | `UDim2.new(1, -8, 0, 8)` | Position of the list. It is at the top right by default. |
| `AnchorPoint` | `Vector2` | :x: | `Vector2.new(1, 0)` | Anchor point of the list. |
| `LayoutOrder` | `number` | :x: | `0` | Position in a parent layout. |

## Callbacks

| Name | Description |
| ---- | ----------- |
| `ValueFormat: (value: any) -> string` | Turns a `Value` into the text shown. The default adds thousands separators to numbers. |
| `OnPlayerClick: (row: Row) -> ()` | Runs with the row when a player is pressed. |

## See also

- [Hotbar](./Hotbar.md)
- [TopBar](./TopBar.md)
