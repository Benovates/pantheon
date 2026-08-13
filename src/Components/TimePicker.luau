--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Slider = require(script.Parent.Slider)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.TimePickerProps): Instance
	local theme = resolveTheme(props)
	local total = peek(props.Value) or 0
	local hours = scope:Value(math.floor(total / 3600) % 24)
	local minutes = scope:Value(math.floor(total / 60) % 60)

	local function emit()
		if props.OnChanged then
			props.OnChanged(peek(hours) * 3600 + peek(minutes) * 60)
		end
	end

	return scope:Frame({
		Name = "TimePicker",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		CornerRadius = theme.Metrics.RadiusPanel,
		Padding = { theme.Metrics.SpaceMd },
		Layout = { Kind = "List", Padding = theme.Metrics.SpaceSm },
		[Children] = {
			scope:TextLabel({
				BackgroundTransparency = 1,
				FontFace = theme.Fonts.Heading,
				TextSize = 28,
				TextColor3 = theme.Colors.OnSurface,
				Text = scope:Computed(function(use)
					return string.format("%02d:%02d", use(hours), use(minutes))
				end),
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = 1,
			}),
			Slider(scope, {
				Label = "Hours",
				Min = 0,
				Max = 23,
				Step = 1,
				Value = hours,
				LayoutOrder = 2,
				OnChanged = function(v)
					hours:set(math.floor(v))
					emit()
				end,
			}),
			Slider(scope, {
				Label = "Minutes",
				Min = 0,
				Max = 59,
				Step = 1,
				Value = minutes,
				LayoutOrder = 3,
				OnChanged = function(v)
					minutes:set(math.floor(v))
					emit()
				end,
			}),
		},
	}) :: Frame
end
