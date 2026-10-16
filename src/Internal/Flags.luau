--!strict
--[[
	Library feature flags.

		EstuaryUI.Flags.CanvasFade = false  -- restore BackgroundTransparency fades
]]
export type FlagName = "CanvasFade" | "LifetimeChecks"

local Flags = {
	--- Wrap appearing chrome in a CanvasGroup and spring GroupTransparency.
	--- Off → previous per-component transparency springs.
	CanvasFade = false,
	--- Run Fusion's scope-lifetime diagnostics (slow: scans whole scopes on every `use`).
	LifetimeChecks = false,
}

return Flags
