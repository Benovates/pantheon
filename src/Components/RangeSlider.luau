--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local Slider = require(script.Parent.Slider)
local Persist = require(script.Parent.Parent.Internal.Persist)
local Bind = require(script.Parent.Parent.Internal.Bind)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.RangeSliderProps): Instance
	local minBound = props.Min or 0
	local maxBound = props.Max or 1
	local initial = peek(props.Value) or NumberRange.new(minBound, maxBound)
	local persistKey = Persist.key("RangeSlider", props.Id, typeof(props.Value) == "table")
	local lo = Persist.value(scope, persistKey, "lo", initial.Min)
	local hi = Persist.value(scope, persistKey, "hi", initial.Max)
	Bind.linkParts(scope, props.Value, { lo, hi }, function(low: number, high: number)
		return NumberRange.new(low, high)
	end, function(range: NumberRange)
		return { range.Min, range.Max }
	end, function(a: NumberRange, b: NumberRange)
		return a.Min == b.Min and a.Max == b.Max
	end)

	local function emit()
		if props.OnChanged then
			props.OnChanged(NumberRange.new(peek(lo), peek(hi)))
		end
	end

	return scope:Frame({
		Name = "RangeSlider",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Layout = { Kind = "List", Padding = 8 },
		[Children] = {
			Slider(scope, {
				Theme = props.Theme,
				Label = "Min",
				Min = minBound,
				Max = maxBound,
				Value = lo,
				Disabled = props.Disabled,
				OnChanged = function(v)
					lo:set(math.min(v, peek(hi)))
					emit()
				end,
			}),
			Slider(scope, {
				Theme = props.Theme,
				Label = "Max",
				Min = minBound,
				Max = maxBound,
				Value = hi,
				Disabled = props.Disabled,
				OnChanged = function(v)
					hi:set(math.max(v, peek(lo)))
					emit()
				end,
			}),
		},
	}) :: Frame
end
