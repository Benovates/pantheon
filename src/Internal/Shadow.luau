--!strict
--[[
	Material Design elevation shadow (umbra / penumbra / ambient).

	Port of AmaranthineCodices/roact-material Shadow — 9-slice blur image,
	Fusion/Iona + springed elevation changes.
	https://github.com/AmaranthineCodices/roact-material/blob/master/src/Components/Shadow.lua
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.resolveTheme).resolveTheme

local Children = Fusion.Children
local peek = Fusion.peek

export type ShadowLevel = number

export type ShadowProps = {
	Theme: Types.ThemeRef?,
	--- Material elevation (0, 1, 2, 3, 4, 6, 8, 9, 12, 16). Defaults to 2.
	Elevation: Types.UsedAs<number>?,
	Color: Types.UsedAs<Color3>?,
	Size: Types.UsedAs<UDim2>?,
	Position: Types.UsedAs<UDim2>?,
	AnchorPoint: Types.UsedAs<Vector2>?,
	ZIndex: Types.UsedAs<number>?,
	Visible: Types.UsedAs<boolean>?,
	LayoutOrder: Types.UsedAs<number>?,
}

type LayerSpec = {
	Transparency: number,
	Blur: number,
	Offset: UDim2?,
}

type ElevationSpec = {
	Umbra: LayerSpec,
	Penumbra: LayerSpec,
	Ambient: LayerSpec,
}

local SHADOW_IMAGE = "rbxassetid://1316045217"
local SLICE_CENTER = Rect.new(10, 10, 118, 118)
local ZERO = UDim2.new(0, 0, 0, 0)
local CENTER = UDim2.new(0.5, 0, 0.5, 0)

local SHADOW_SETTINGS: { [number]: ElevationSpec } = {
	[0] = {
		Umbra = { Transparency = 1, Blur = 0 },
		Penumbra = { Transparency = 1, Blur = 0 },
		Ambient = { Transparency = 1, Blur = 0 },
	},
	[1] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 2 },
		Penumbra = { Transparency = 1 - 0.12, Blur = 2, Offset = UDim2.new(0, 0, 0, 2) },
		Ambient = { Transparency = 1 - 0.2, Blur = 3, Offset = UDim2.new(0, 0, 0, 1) },
	},
	[2] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 4 },
		Penumbra = { Transparency = 1 - 0.12, Blur = 4, Offset = UDim2.new(0, 0, 0, 3) },
		Ambient = { Transparency = 1 - 0.2, Blur = 5, Offset = UDim2.new(0, 0, 0, 1) },
	},
	[3] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 3, Offset = UDim2.new(0, 0, 0, 3) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 4, Offset = UDim2.new(0, 0, 0, 3) },
		Ambient = { Transparency = 1 - 0.2, Blur = 8, Offset = UDim2.new(0, 0, 0, 1) },
	},
	[4] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 4, Offset = UDim2.new(0, 0, 0, 2) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 5, Offset = UDim2.new(0, 0, 0, 4) },
		Ambient = { Transparency = 1 - 0.2, Blur = 10, Offset = UDim2.new(0, 0, 0, 1) },
	},
	[6] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 10, Offset = UDim2.new(0, 0, 0, 6) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 18, Offset = UDim2.new(0, 0, 0, 1) },
		Ambient = { Transparency = 1 - 0.2, Blur = 5, Offset = UDim2.new(0, 0, 0, 3) },
	},
	[8] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 10, Offset = UDim2.new(0, 0, 0, 8) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 14, Offset = UDim2.new(0, 0, 0, 3) },
		Ambient = { Transparency = 1 - 0.2, Blur = 15, Offset = UDim2.new(0, 0, 0, 4) },
	},
	[9] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 12, Offset = UDim2.new(0, 0, 0, 9) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 16, Offset = UDim2.new(0, 0, 0, 3) },
		Ambient = { Transparency = 1 - 0.2, Blur = 6, Offset = UDim2.new(0, 0, 0, 5) },
	},
	[12] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 17, Offset = UDim2.new(0, 0, 0, 12) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 22, Offset = UDim2.new(0, 0, 0, 5) },
		Ambient = { Transparency = 1 - 0.2, Blur = 8, Offset = UDim2.new(0, 0, 0, 7) },
	},
	[16] = {
		Umbra = { Transparency = 1 - 0.14, Blur = 24, Offset = UDim2.new(0, 0, 0, 16) },
		Penumbra = { Transparency = 1 - 0.12, Blur = 30, Offset = UDim2.new(0, 0, 0, 6) },
		Ambient = { Transparency = 1 - 0.2, Blur = 10, Offset = UDim2.new(0, 0, 0, 8) },
	},
}

local ELEVATION_KEYS = { 0, 1, 2, 3, 4, 6, 8, 9, 12, 16 }

local function resolveElevation(raw: number): number
	local n = math.floor(raw + 0.5)
	if SHADOW_SETTINGS[n] ~= nil then
		return n
	end
	local best = 2
	local bestDist = math.huge
	for _, key in ELEVATION_KEYS do
		local dist = math.abs(key - n)
		if dist < bestDist then
			bestDist = dist
			best = key
		end
	end
	return best
end

local function readUsed<T>(use: (any) -> any, value: Types.UsedAs<T>?, fallback: T): T
	if value == nil then
		return fallback
	end
	if typeof(value) == "table" then
		local resolved = use(value)
		if resolved == nil then
			return fallback
		end
		return resolved :: T
	end
	return value :: T
end

local Shadow = {}

function Shadow.create(scope: Types.Scope, props: ShadowProps?): Frame
	local p: ShadowProps = props or {}
	local theme = resolveTheme(p)

	local elevation = scope:Computed(function(use)
		return resolveElevation(readUsed(use, p.Elevation, 2))
	end)

	local color = scope:Computed(function(use)
		return readUsed(use, p.Color, Color3.new(0, 0, 0))
	end)

	-- ~0.1s settle (matches roact-material TweenInfo)
	local speed = theme.Motion.SpringSpeed * 2.4
	local damp = 1

	local function layerSpring(pick: (ElevationSpec) -> (number, number, UDim2))
		local transparency = scope:Spring(
			scope:Computed(function(use)
				local t = pick(SHADOW_SETTINGS[use(elevation)])
				return t
			end),
			speed,
			damp
		)
		local blur = scope:Spring(
			scope:Computed(function(use)
				local _, b = pick(SHADOW_SETTINGS[use(elevation)])
				return b
			end),
			speed,
			damp
		)
		local offsetX = scope:Spring(
			scope:Computed(function(use)
				local _, _, off = pick(SHADOW_SETTINGS[use(elevation)])
				return off.X.Offset
			end),
			speed,
			damp
		)
		local offsetY = scope:Spring(
			scope:Computed(function(use)
				local _, _, off = pick(SHADOW_SETTINGS[use(elevation)])
				return off.Y.Offset
			end),
			speed,
			damp
		)
		return transparency, blur, offsetX, offsetY
	end

	local umbraT, umbraBlur, umbraOX, umbraOY = layerSpring(function(spec)
		return spec.Umbra.Transparency, spec.Umbra.Blur, spec.Umbra.Offset or ZERO
	end)
	local penumbraT, penumbraBlur, penumbraOX, penumbraOY = layerSpring(function(spec)
		return spec.Penumbra.Transparency, spec.Penumbra.Blur, spec.Penumbra.Offset or ZERO
	end)
	local ambientT, ambientBlur, ambientOX, ambientOY = layerSpring(function(spec)
		return spec.Ambient.Transparency, spec.Ambient.Blur, spec.Ambient.Offset or ZERO
	end)

	local function makeLayer(
		name: string,
		transparency: any,
		blur: any,
		offsetX: any,
		offsetY: any,
		z: number
	): ImageLabel
		return scope:ImageLabel({
			Name = name,
			BackgroundTransparency = 1,
			Image = SHADOW_IMAGE,
			ImageColor3 = color,
			ImageTransparency = transparency,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = scope:Computed(function(use)
				return CENTER + UDim2.fromOffset(use(offsetX), use(offsetY))
			end),
			Size = scope:Computed(function(use)
				local b = use(blur) :: number
				return UDim2.new(1, b, 1, b)
			end),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = SLICE_CENTER,
			Active = false,
			ZIndex = z,
		}) :: ImageLabel
	end

	return scope:Frame({
		Name = "Shadow",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		ZIndex = p.ZIndex or 0,
		Visible = p.Visible,
		LayoutOrder = p.LayoutOrder,
		Active = false,
		[Children] = {
			makeLayer("Umbra", umbraT, umbraBlur, umbraOX, umbraOY, 1),
			makeLayer("Penumbra", penumbraT, penumbraBlur, penumbraOX, penumbraOY, 2),
			makeLayer("Ambient", ambientT, ambientBlur, ambientOX, ambientOY, 3),
		},
	}) :: Frame
end

--- Parent a shadow under `parent` (replaces any previous Estuary shadow roots).
function Shadow.apply(scope: Types.Scope, parent: GuiObject, level: number?, color: Color3?): Frame
	for _, child in parent:GetChildren() do
		if child.Name == "Shadow" or child.Name == "EstuaryShadow" or child.Name == "ShadowRoot" then
			-- Only remove our elevation roots, not unrelated UI named Shadow.
			if child:IsA("Frame") and child:FindFirstChild("Umbra") then
				child:Destroy()
			elseif child.Name == "EstuaryShadow" then
				child:Destroy()
			end
		end
	end
	local shadow = Shadow.create(scope, {
		Elevation = level or 2,
		Color = color,
		ZIndex = math.max((parent.ZIndex or 1) - 1, 0),
	})
	shadow.Parent = parent
	return shadow
end

Shadow.Image = SHADOW_IMAGE
Shadow.Settings = SHADOW_SETTINGS
Shadow.Elevations = ELEVATION_KEYS

-- Callable: Shadow(scope, props)
return setmetatable(Shadow, {
	__call = function(_, scope: Types.Scope, props: ShadowProps?): Frame
		return Shadow.create(scope, props)
	end,
})
