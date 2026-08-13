--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local HSV = require(script.Parent.Parent.Internal.Picker.HSV)
local Slider = require(script.Parent.Slider)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.ColorPickerProps): Instance
	local theme = resolveTheme(props)
	local initial = peek(props.Value) or Color3.fromRGB(0, 105, 92)
	local h0, s0, v0 = HSV.fromColor3(initial)
	local h = scope:Value(h0)
	local s = scope:Value(s0)
	local v = scope:Value(v0)

	local function current(): Color3
		return HSV.toColor3(peek(h), peek(s), peek(v))
	end

	local function emit()
		if props.OnChanged then
			props.OnChanged(current())
		end
	end

	return scope:Frame({
		Name = "ColorPicker",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		CornerRadius = theme.Metrics.RadiusPanel,
		Padding = { theme.Metrics.SpaceMd },
		Layout = { Kind = "List", Padding = theme.Metrics.SpaceSm },
		[Children] = {
			scope:Frame({
				Name = "Preview",
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundColor3 = scope:Computed(function(use)
					return HSV.toColor3(use(h), use(s), use(v))
				end),
				CornerRadius = theme.Metrics.RadiusSm,
				LayoutOrder = 1,
			}),
			Slider(scope, {
				Label = "Hue",
				Min = 0,
				Max = 1,
				Step = 0.01,
				Value = h,
				LayoutOrder = 2,
				OnChanged = function(n)
					h:set(n)
					emit()
				end,
			}),
			Slider(scope, {
				Label = "Saturation",
				Min = 0,
				Max = 1,
				Step = 0.01,
				Value = s,
				LayoutOrder = 3,
				OnChanged = function(n)
					s:set(n)
					emit()
				end,
			}),
			Slider(scope, {
				Label = "Value",
				Min = 0,
				Max = 1,
				Step = 0.01,
				Value = v,
				LayoutOrder = 4,
				OnChanged = function(n)
					v:set(n)
					emit()
				end,
			}),
		},
	}) :: Frame
end
