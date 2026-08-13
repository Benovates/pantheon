--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Icon = require(script.Parent.Icon)
local MenuButton = require(script.Parent.MenuButton)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local function resolveExpanded(
	scope: Types.Scope,
	props: Types.MenuSectionProps,
	collapsible: boolean
): (any, (boolean) -> ())
	if not collapsible then
		local always = scope:Value(true)
		return always, function() end
	end
	if props.Expanded ~= nil then
		local expandedRef = props.Expanded
		local computed = scope:Computed(function(use)
			return (if typeof(expandedRef) == "table" then use(expandedRef) else expandedRef) == true
		end)
		local function setExpanded(nextValue: boolean)
			if typeof(expandedRef) == "table" and (expandedRef :: any).set then
				(expandedRef :: any):set(nextValue)
			end
			if props.OnExpandedChanged then
				props.OnExpandedChanged(nextValue)
			end
		end
		return computed, setExpanded
	end
	local expanded = scope:Value(props.DefaultExpanded ~= false)
	local function setExpanded(nextValue: boolean)
		expanded:set(nextValue)
		if props.OnExpandedChanged then
			props.OnExpandedChanged(nextValue)
		end
	end
	return expanded, setExpanded
end

return function(scope: Types.Scope, props: Types.MenuSectionProps): Instance
	local theme = resolveTheme(props)
	local compact = props.Compact ~= false
	local hPad = if compact then theme.Metrics.SpaceSm else theme.Metrics.SpaceMd
	local categoryIconSize = 16
	local titlePeek = if props.Title == nil then nil else peek(props.Title)
	local hasTitle = typeof(titlePeek) == "string" and titlePeek ~= ""
	local collapsible = if props.Collapsible ~= nil then props.Collapsible == true else false
	local expanded, setExpanded = resolveExpanded(scope, props, collapsible)
	local expandedS = scope:Spring(
		scope:Computed(function(use)
			return if use(expanded) then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)

	local sectionChildren: { any } = {}

	if hasTitle then
		local titleKids: { any } = {}
		if props.Icon ~= nil and props.Icon ~= "" then
			table.insert(
				titleKids,
				scope:Hydrate(Icon(scope, {
					Theme = theme,
					Name = props.Icon,
					IconSize = categoryIconSize,
					Color = theme.Colors.OnSurfaceVariant,
				}))({
					LayoutOrder = 1,
					ImageTransparency = 0.12,
				})
			)
		end
		table.insert(
			titleKids,
			scope:TextLabel({
				Name = "CategoryLabel",
				BackgroundTransparency = 1,
				FontFace = theme.Typography.Button.Font,
				TextSize = math.max(10, theme.Typography.Label.Size),
				TextColor3 = theme.Colors.OnSurfaceVariant,
				TextTransparency = 0.24,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = scope:Computed(function(use)
					local raw = props.Title
					local title = if typeof(raw) == "table" then use(raw) else raw
					return (if typeof(title) == "string" then title else tostring(title))
				end),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 2,
			})
		)
		if collapsible then
			table.insert(
				titleKids,
				scope:Frame({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = 3,
					Flex = { FlexMode = Enum.UIFlexMode.Fill },
				})
			)
			table.insert(
				titleKids,
				scope:Hydrate(Icon(scope, {
					Theme = theme,
					Name = "chevron-down",
					IconSize = 16,
					Color = theme.Colors.OnSurfaceVariant,
				}))({
					LayoutOrder = 4,
					ImageTransparency = 0.2,
					Rotation = scope:Computed(function(use)
						return (1 - use(expandedS)) * -90
					end),
				})
			)
		end

		local categoryHeader = if collapsible
			then scope:TextButton(P({
				Name = "Category",
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = 1,
				Active = true,
				Padding = { 0, hPad },
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = 6,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
				},
				[OnEvent("Activated")] = function()
					setExpanded(not peek(expanded))
				end,
				[Children] = titleKids,
			}))
			else scope:Frame({
				Name = "Category",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = 1,
				Padding = { 0, hPad },
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = 6,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = titleKids,
			})

		table.insert(sectionChildren, categoryHeader)
	end

	local itemNodes: { any } = {}
	local items = props.Items
	if items then
		for i, item in items do
			table.insert(
				itemNodes,
				MenuButton(scope, {
					Theme = theme,
					Text = item.Text,
					OnClick = item.OnClick,
					Disabled = item.Disabled,
					Leading = item.Leading,
					Trailing = item.Trailing,
					LeadingIcon = item.LeadingIcon,
					TrailingIcon = item.TrailingIcon,
					Color = item.Color,
					Page = item.Page,
					Compact = compact,
					OnClose = props.OnClose,
					LayoutOrder = i,
				})
			)
		end
	end
	if props.Children then
		table.insert(itemNodes, props.Children)
	end

	local itemsHost = scope:Frame({
		Name = "SectionItems",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Visible = if collapsible
			then scope:Computed(function(use)
				return use(expandedS) > 0.02
			end)
			else true,
		ClipsDescendants = collapsible,
		Layout = {
			Kind = "List",
			Padding = 1,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = itemNodes,
	})
	if collapsible then
		local scale = Instance.new("UIScale")
		scale.Parent = itemsHost
		table.insert(
			scope,
			scope:Observer(expandedS):onBind(function()
				local t = peek(expandedS)
				scale.Scale = 0.96 + 0.04 * t
			end)
		)
	end
	table.insert(sectionChildren, itemsHost)

	return scope:Frame({
		Name = "MenuSection",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		Layout = {
			Kind = "List",
			Padding = 0,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = sectionChildren,
	}) :: Frame
end
