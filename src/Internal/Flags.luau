--!strict
--[[
	Library feature flags.

		EstuaryUI.Flags.CanvasFade = false  -- restore BackgroundTransparency fades
]]
export type FlagName = "CanvasFade"

local Flags = {
	--- Wrap appearing chrome in a CanvasGroup and spring GroupTransparency.
	--- Off → previous per-component transparency springs.
	CanvasFade = false,
}

return Flags
