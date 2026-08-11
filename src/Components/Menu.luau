--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Layer = require(script.Parent.Parent.Internal.Layer)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

return function(scope: Types.Scope, props: Types.MenuProps): Frame
	local theme = resolveTheme(props)
	local open = if props.Open == nil then true else props.Open
	local openS = scope:Spring(
		scope:Computed(function(use)
			local o = open
			local isOpen = if typeof(o) == "table" then use(o) else o
			return if isOpen then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)

	local items = {}
	for i, item in props.Items do
		local ix = Interaction.bind(scope, theme, {
			Disabled = item.Disabled == true,
			StateColor = theme.Colors.OnSurface,
		})
		local btn = scope:TextButton({
			Text = item.Text,
			FontFace = theme.Typography.Body.Font,
			TextSize = theme.Typography.Body.Size,
			TextColor3 = if item.Disabled then theme.Colors.OnSurfaceVariant else theme.Colors.OnSurface,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = ix.fill(theme.Colors.Surface),
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			AutoButtonColor = false,
			Active = not item.Disabled,
			ClipsDescendants = true,
			CornerRadius = theme.Metrics.RadiusSm,
			Padding = { theme.Metrics.SpaceXs, theme.Metrics.SpaceSm },
			[OnEvent("Activated")] = function()
				if item.Disabled then
					return
				end
				if item.OnClick then
					item.OnClick()
				end
				if props.OnClose then
					props.OnClose()
				end
			end,
		})
		ix.wire(btn)
		table.insert(items, btn)
	end

	local menu = scope:Frame({
		Name = "Menu",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = scope:Computed(function(use)
			return use(openS) > 0.02
		end),
		BackgroundTransparency = scope:Computed(function(use)
			return 1 - use(openS)
		end),
		ZIndex = props.ZIndex or 80,
		LayoutOrder = props.LayoutOrder or 0,
		CornerRadius = theme.Metrics.RadiusSm,
		Outline = { Color = theme.Colors.Outline, Thickness = 1, Mode = Enum.ApplyStrokeMode.Border },
		Padding = { 4 },
		Layout = {
			Kind = "List",
			Padding = 2,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = items,
	}) :: Frame

	Layer.mount(scope, props, menu)
	return menu
end
