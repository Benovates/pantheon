--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Chip = require(script.Parent.Chip)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.TabsProps): ScrollingFrame
	local theme = resolveTheme(props)
	local selected = scope:Value(peek(props.Selected) or (props.Items[1] and props.Items[1].Id) or "")

	local chips = scope:Computed(function(use)
		local current = use(selected)
		local nodes = {}
		for i, item in props.Items do
			table.insert(nodes, Chip(scope, {
				Theme = theme,
				Text = item.Label,
				Selected = item.Id == current,
				LayoutOrder = i,
				OnClick = function()
					selected:set(item.Id)
					if props.OnChanged then
						props.OnChanged(item.Id)
					end
				end,
			}))
		end
		return nodes
	end)

	return scope:New("ScrollingFrame")({
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, 44),
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, theme.Metrics.SpaceXs),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			chips,
		},
	}) :: ScrollingFrame
end
