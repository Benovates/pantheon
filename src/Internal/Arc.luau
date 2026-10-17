--!strict
--[[
	Radial ring fill, drawn with UIStroke + UIGradient masks (Roblox UI has no arc
	primitive).

	The ring is two clipped halves (right: 0–180°, left: 180–360°, clockwise from
	12 o'clock). Each half's stroke carries a UIGradient with a hard step at the
	middle; rotating the gradient sweeps a radial edge through the ring's centre,
	so the cut is exactly radial. Moving the arc is just two `Rotation` writes.

	  Mode "Head": ring is filled from 12 o'clock clockwise to `Angle`.
	  Mode "Tail": ring is filled from `Angle` clockwise back round to 12 o'clock.

	Only one radial edge per layer is possible, which is why there is no
	free-floating From/To arc here: a "Head" layer plus a "Tail" layer cover every
	determinate look (arc + track, with an optional gap).
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local Features = require(script.Parent.Features)
local Flags = require(script.Parent.Flags)

local Children = Fusion.Children

export type ArcProps = {
	--- Outer diameter in pixels.
	Diameter: number,
	Thickness: number,
	Color: Types.UsedAs<Color3>,
	Mode: ("Head" | "Tail")?,
	--- Degrees clockwise from 12 o'clock, 0–360.
	Angle: Types.UsedAs<number>?,
	--- Free arc [From, To] in degrees clockwise from 12 o'clock (To may pass 360). Only
	--- drawn when `Arc.supportsFreeArc()`; callers should have a Head/Tail fallback.
	From: Types.UsedAs<number>?,
	To: Types.UsedAs<number>?,
	--- Round end caps (circles at both ends of the filled arc).
	Caps: boolean?,
	Name: string?,
	ZIndex: number?,
}

-- Left side of the gradient opaque, right side transparent.
local HEAD_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.5001, 1),
	NumberSequenceKeypoint.new(1, 1),
})
local TAIL_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 1),
	NumberSequenceKeypoint.new(0.5001, 0),
	NumberSequenceKeypoint.new(1, 0),
})

local function readNumber(use: any, v: any): number
	if typeof(v) == "table" then
		return use(v) :: number
	end
	return v :: number
end

local function halvesArc(scope: Types.Scope, props: ArcProps): Frame
	local W = props.Diameter
	local T = props.Thickness
	local head = props.Mode ~= "Tail"
	local angle: any = props.Angle

	local function circle(half: number): Frame
		local lo = half * 180
		return scope:New("Frame")({
			Name = "Ring",
			BackgroundTransparency = 1,
			Position = if half == 0 then UDim2.new(-1, T, 0, T) else UDim2.fromOffset(T, T),
			Size = UDim2.new(2, -2 * T, 1, -2 * T),
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				scope:New("UIStroke")({
					Thickness = T,
					Color = props.Color,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					[Children] = {
						scope:New("UIGradient")({
							Transparency = if head then HEAD_SEQUENCE else TAIL_SEQUENCE,
							Rotation = scope:Computed(function(use)
								return math.clamp(readNumber(use, angle), lo, lo + 180)
							end),
						}),
					},
				}),
			},
		}) :: Frame
	end

	local function half(index: number): Frame
		return scope:New("Frame")({
			Name = if index == 0 then "Right" else "Left",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = if index == 0 then UDim2.fromScale(0.5, 0) else UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(0.5, 1),
			[Children] = { circle(index) },
		}) :: Frame
	end

	local kids: { any } = { half(0), half(1) }

	if props.Caps then
		-- Caps sit on the stroke midline at the arc's two ends.
		local function cap(name: string, degrees: (use: any) -> number): Frame
			return scope:New("Frame")({
				Name = name,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = props.Color,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(T, T),
				Visible = scope:Computed(function(use)
					local a = readNumber(use, angle)
					return a > 0.5 and a < 359.5
				end),
				Position = scope:Computed(function(use)
					local rad = math.rad(degrees(use))
					local s, c = math.sin(rad), math.cos(rad)
					return UDim2.new(0.5 + 0.5 * s, -(T / 2) * s, 0.5 - 0.5 * c, (T / 2) * c)
				end),
				[Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
			}) :: Frame
		end
		local function at(deg: number)
			return function()
				return deg
			end
		end
		local function atAngle(use: any): number
			return readNumber(use, angle)
		end
		table.insert(kids, cap("Start", if head then at(0) else atAngle))
		table.insert(kids, cap("End", if head then atAngle else at(360)))
	end

	return scope:New("Frame")({
		Name = props.Name or "Arc",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(W, W),
		ZIndex = props.ZIndex,
		[Children] = kids,
	}) :: Frame
end

--- Opaque sequence for [a, b] degrees (b may exceed 360) on a conical gradient.
local EPS = 1e-4

--- Turn opaque intervals (in 0..1 gradient space, sorted, non-overlapping) into a
--- NumberSequence with hard edges. Keypoint times must strictly increase, so every
--- time is nudged past the previous one and clamped into [0, 1].
local function sequenceFromIntervals(intervals: { { number } }): NumberSequence
	local pts: { NumberSequenceKeypoint } = {}
	local last = -1
	local function add(t: number, v: number)
		t = math.max(t, last + EPS)
		if t > 1 then
			return
		end
		last = t
		table.insert(pts, NumberSequenceKeypoint.new(t, v))
	end

	local value = 1 -- current transparency as we sweep 0 → 1
	for _, iv in intervals do
		local s, e = iv[1], iv[2]
		if e - s > EPS then
			if s <= EPS then
				add(0, 0)
			else
				if last < 0 then
					add(0, 1)
				end
				add(s, 1)
				add(s + EPS, 0)
			end
			if e >= 1 - EPS then
				value = 0
			else
				add(e, 0)
				add(e + EPS, 1)
				value = 1
			end
		end
	end
	if #pts == 0 then
		return NumberSequence.new(1)
	end
	pts[1] = NumberSequenceKeypoint.new(0, pts[1].Value)
	if pts[#pts].Time < 1 then
		table.insert(pts, NumberSequenceKeypoint.new(1, value))
	else
		pts[#pts] = NumberSequenceKeypoint.new(1, pts[#pts].Value)
	end
	return NumberSequence.new(pts)
end

local function conicalSequence(a: number, b: number): NumberSequence
	local sweep = b - a
	if sweep <= 0 then
		return NumberSequence.new(1)
	end
	if sweep >= 360 then
		return NumberSequence.new(0)
	end
	-- Gradient position of an angle; counter-clockwise gradients run the other way.
	local function position(deg: number): number
		local f = (deg % 360) / 360
		return if Flags.ConicalClockwise then f else (1 - f) % 1
	end
	local pa, pb = position(a), position(b)
	local lo, hi = pa, pb
	if not Flags.ConicalClockwise then
		lo, hi = pb, pa
	end
	if lo <= hi then
		return sequenceFromIntervals({ { lo, hi } })
	end
	-- Wraps through 0: opaque [0, hi] and [lo, 1].
	return sequenceFromIntervals({ { 0, hi }, { lo, 1 } })
end

--- One ring, one conical gradient: exact radial ends on both sides, no clipping.
local function conicalArc(scope: Types.Scope, props: ArcProps): Frame
	local W = props.Diameter
	local T = props.Thickness
	local from: any = props.From
	local to: any = props.To
	if from == nil then
		from = 0
	end
	if to == nil then
		to = props.Angle
	end
	if props.Mode == "Tail" and props.From == nil and props.To == nil then
		-- Tail(angle) = fill from angle round to 12 o'clock.
		from, to = props.Angle, 360
	end

	local ring = scope:New("Frame")({
		Name = "Ring",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(T, T),
		Size = UDim2.new(1, -2 * T, 1, -2 * T),
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			scope:New("UIStroke")({
				Thickness = T,
				Color = props.Color,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				[Children] = {
					scope:New("UIGradient")({
						Type = "Conical",
						Rotation = Flags.ConicalRotation,
						Transparency = scope:Computed(function(use)
							return conicalSequence(readNumber(use, from), readNumber(use, to))
						end),
					}),
				},
			}),
		},
	}) :: Frame

	local kids: { any } = { ring }
	if props.Caps then
		local function cap(name: string, degrees: any): Frame
			return scope:New("Frame")({
				Name = name,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = props.Color,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(T, T),
				Visible = scope:Computed(function(use)
					local sweep = readNumber(use, to) - readNumber(use, from)
					return sweep > 0.5 and sweep < 359.5
				end),
				Position = scope:Computed(function(use)
					local rad = math.rad(readNumber(use, degrees))
					local s, c = math.sin(rad), math.cos(rad)
					return UDim2.new(0.5 + 0.5 * s, -(T / 2) * s, 0.5 - 0.5 * c, (T / 2) * c)
				end),
				[Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
			}) :: Frame
		end
		table.insert(kids, cap("Start", from))
		table.insert(kids, cap("End", to))
	end

	return scope:New("Frame")({
		Name = props.Name or "Arc",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(W, W),
		ZIndex = props.ZIndex,
		[Children] = kids,
	}) :: Frame
end

local Arc = {}

--- True when a free [From, To] arc can be drawn (needs conical gradients).
function Arc.supportsFreeArc(): boolean
	return Features.gradientTypes()
end

function Arc.create(scope: Types.Scope, props: ArcProps): Frame
	if Features.gradientTypes() then
		return conicalArc(scope, props)
	end
	return halvesArc(scope, props)
end

return setmetatable(Arc, {
	__call = function(_, scope: Types.Scope, props: ArcProps): Frame
		return Arc.create(scope, props)
	end,
})
