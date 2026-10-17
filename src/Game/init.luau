--!strict
--[[
	In-game HUD components: translucent, scene-facing, and independent of the app theme.
	Same call shape as the main kit: Game.X(scope, props).
]]

return {
	Style = require(script.Style),
	TopBar = require(script.TopBar),
	Hotbar = require(script.Hotbar),
	--- Feed a Hotbar from the player's Roblox Backpack: `Game.Backpack(scope)`.
	Backpack = require(script.Backpack).new,
	Fuzzy = require(script.Fuzzy),
	--- A player list with teams, in the style of Roblox's.
	Leaderboard = require(script.Leaderboard),
	--- Feed a Leaderboard from the players and teams of the experience: `Game.Roster(scope)`.
	Roster = require(script.Roster).new,
}
