--!strict
--[[
	Runtime detection of newer Roblox UI capabilities, so components can use them when
	the engine has them and fall back cleanly when it doesn't.

	  IndividualCorners   UICorner.TopLeftRadius… (live since June 2026)
	  GradientTypes       UIGradient.Type = "Radial" | "Conical"   (Studio beta)
	  GradientTiling      UIGradient.TileMode / Scale              (Studio beta)
	  ShadowText          UIShadow.Mode = "Text"                   (Studio beta)
	  ShadowInset         UIShadow.Inset                           (Studio beta)
	  ShadowKnockout      UIShadow.ShowBehindParent                (Studio beta)

	Beta features can't be published yet; if an experience somehow runs where they're
	missing, detection reports false and callers take their fallback path.
	Set `Pantheon.Flags.BetaUI = false` to force every beta path off (e.g. to compare).
]]
local Flags = require(script.Parent.Flags)

local cache: { [string]: boolean } = {}

--- Create a throwaway instance and try assigning a property; true if it took.
local function probe(className: string, property: string, value: any): boolean
	local ok = pcall(function()
		local inst = Instance.new(className);
		(inst :: any)[property] = value
		inst:Destroy()
	end)
	return ok
end

local function detect(
	name: string,
	className: string,
	property: string,
	value: any,
	beta: boolean
): boolean
	if beta and Flags.BetaUI == false then
		return false
	end
	local cached = cache[name]
	if cached == nil then
		cached = probe(className, property, value)
		cache[name] = cached
	end
	return cached
end

local Features = {}

function Features.individualCorners(): boolean
	return detect("IndividualCorners", "UICorner", "TopLeftRadius", UDim.new(0, 4), false)
end

function Features.gradientTypes(): boolean
	return detect("GradientTypes", "UIGradient", "Type", "Conical", true)
end

function Features.gradientTiling(): boolean
	return detect("GradientTiling", "UIGradient", "TileMode", "Repeat", true)
end

function Features.shadowText(): boolean
	return detect("ShadowText", "UIShadow", "Mode", "Text", true)
end

function Features.shadowInset(): boolean
	return detect("ShadowInset", "UIShadow", "Inset", true, true)
end

function Features.shadowKnockout(): boolean
	return detect("ShadowKnockout", "UIShadow", "ShowBehindParent", false, true)
end

return Features
