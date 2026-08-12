--!strict
--[[
	Navigation rail / Tithe POS tab bar.
	Traveling selection pill (stretch). Vertical: icon-only + tooltip.
	Indicator lives in the tabs host so padding is not double-counted.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Icon = require(script.Parent.Icon)
local Badge = require(script.Parent.Badge)
local Tooltip = require(script.Parent.Tooltip)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.NavigationRailProps): Frame
	local theme = resolveTheme(props)
	local selected = scope:Value(peek(props.Selected) or (props.Items[1] and props.Items[1].Id) or "")
	local horizontal = props.Orientation == "Horizontal"
	local count = math.max(#props.Items, 1)

	local indicatorX = scope:Value(0)
	local indicatorY = scope:Value(0)
	local indicatorW = scope:Value(0)
	local indicatorH = scope:Value(0)
	local stretch = scope:Value(0)
	local stretchS = scope:Spring(stretch, theme.Motion.SpringSpeed * 1.55, 0.76)
	local xS = scope:Spring(indicatorX, theme.Motion.SpringSpeed * 0.8, 0.84)
	local yS = scope:Spring(indicatorY, theme.Motion.SpringSpeed * 0.8, 0.84)
	local wS = scope:Spring(indicatorW, theme.Motion.SpringSpeed * 0.8, 0.84)
	local hS = scope:Spring(indicatorH, theme.Motion.SpringSpeed * 0.8, 0.84)

	local tabs: { TextButton } = {}
	local host: Frame

	local function syncIndicator(animateStretch: boolean?)
		local id = peek(selected)
		local idx = 1
		for i, item in props.Items do
			if item.Id == id then
				idx = i
				break
			end
		end
		local tab = tabs[idx]
		if not tab or not host or host.Parent == nil then
			return
		end
		local relX = tab.AbsolutePosition.X - host.AbsolutePosition.X
		local relY = tab.AbsolutePosition.Y - host.AbsolutePosition.Y
		local w = tab.AbsoluteSize.X
		local h = tab.AbsoluteSize.Y
		if w < 1 or h < 1 then
			return
		end
		local insetX = if horizontal then 0 else 2
		local insetY = if horizontal then 0 else 2
		relX += insetX
		relY += insetY
		w = math.max(w - insetX * 2, 8)
		h = math.max(h - insetY * 2, 8)
		if animateStretch then
			local travel = if horizontal
				then math.abs(relX - peek(indicatorX))
				else math.abs(relY - peek(indicatorY))
			stretch:set(math.clamp(travel * 0.3, 6, 32))
			task.delay(0.12, function()
				stretch:set(0)
			end)
		end
		indicatorX:set(relX)
		indicatorY:set(relY)
		indicatorW:set(w)
		indicatorH:set(h)
	end

	for i, item in props.Items do
		local isSelected = scope:Computed(function(use)
			return use(selected) == item.Id
		end)
		local ix = Interaction.bind(scope, theme, {
			Disabled = false,
			StateColor = theme.Colors.OnSurface,
		})

		local icon = scope:Hydrate(Icon(scope, {
			Theme = theme,
			Name = item.Icon or "circle",
			IconSize = if horizontal then 22 else 24,
			Color = scope:Computed(function(use)
				return if use(isSelected) then theme.Colors.Primary else theme.Colors.OnSurfaceVariant
			end),
		}))({
			LayoutOrder = 1,
		})

		local iconWrap: Instance = icon
		if (item :: any).Badge then
			iconWrap = Badge(scope, {
				Theme = theme,
				Count = (item :: any).Badge,
				Content = icon,
			})
		end

		local kids: { any } = { iconWrap }
		if horizontal then
			table.insert(
				kids,
				scope:TextLabel({
					BackgroundTransparency = 1,
					FontFace = theme.Typography.Button.Font,
					TextSize = theme.Typography.Button.Size,
					TextColor3 = scope:Computed(function(use)
						return if use(isSelected) then theme.Colors.Primary else theme.Colors.OnSurfaceVariant
					end),
					Text = item.Label or item.Id,
					TextTruncate = Enum.TextTruncate.AtEnd,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 2,
				})
			)
		end

		local hoverT = ix.fillTransparency(1)
		local tab = scope:TextButton(P({
			Name = "RailTab",
			Text = "",
			AutoButtonColor = false,
			-- Grey hover pill when not selected; selection uses traveling indicator
			BackgroundColor3 = theme.Colors.OnSurface,
			BackgroundTransparency = scope:Computed(function(use)
				if use(isSelected) then
					return 1
				end
				return use(hoverT)
			end),
			Size = if horizontal then UDim2.new(1 / count, 0, 1, 0) else UDim2.new(1, 0, 0, 56),
			LayoutOrder = i,
			ZIndex = 2,
			ClipsDescendants = true,
			CornerRadius = theme.Metrics.RadiusSm,
			Padding = { if horizontal then 14 else 10, if horizontal then 12 else 6 },
			Layout = {
				Kind = "List",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = if horizontal then 8 else 4,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			[OnEvent("Activated")] = function()
				local prev = peek(selected)
				selected:set(item.Id)
				task.defer(function()
					syncIndicator(prev ~= item.Id)
				end)
				if item.OnClick then
					item.OnClick()
				end
				if props.OnChanged then
					props.OnChanged(item.Id)
				end
			end,
			[Children] = kids,
		})) :: TextButton

		if horizontal then
			local flex = Instance.new("UIFlexItem")
			flex.FlexMode = Enum.UIFlexMode.Fill
			flex.Parent = tab
		elseif item.Label or item.Id then
			Tooltip(scope, {
				Theme = theme,
				Layer = props.Layer,
				Target = tab,
				Text = item.Label or item.Id,
				Placement = "Right" :: Types.TooltipPlacement,
			})
		end

		ix.wire(tab)
		table.insert(tabs, tab)
	end

	host = scope:Frame({
		Name = "TabsHost",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			scope:Frame({
				Name = "Indicator",
				BackgroundColor3 = theme.Colors.PrimaryContainer,
				ZIndex = 1,
				Position = scope:Computed(function(use)
					local extra = use(stretchS)
					if horizontal then
						return UDim2.fromOffset(use(xS) - extra * 0.5, use(yS))
					end
					return UDim2.fromOffset(use(xS), use(yS) - extra * 0.5)
				end),
				Size = scope:Computed(function(use)
					local extra = use(stretchS)
					if horizontal then
						return UDim2.fromOffset(math.max(use(wS) + extra, 8), use(hS))
					end
					return UDim2.fromOffset(use(wS), math.max(use(hS) + extra, 8))
				end),
				CornerRadius = theme.Metrics.RadiusSm,
				Visible = scope:Computed(function(use)
					return use(wS) > 2 and use(hS) > 2
				end),
			}),
			scope:Frame({
				Name = "Tabs",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Layout = {
					Kind = "List",
					FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
					HorizontalFlex = if horizontal then Enum.UIFlexAlignment.Fill else nil,
					Padding = if horizontal then 4 else theme.Metrics.SpaceXs,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = tabs,
			}),
		},
	}) :: Frame

	local root = scope:Frame({
		Name = "NavigationRail",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size
			or (
				if horizontal
					then UDim2.new(1, 0, 0, 72)
					else UDim2.new(0, theme.Metrics.RailWidth, 1, 0)
			),
		LayoutOrder = props.LayoutOrder or 0,
		ClipsDescendants = true,
		Outline = if horizontal
			then {
				Color = theme.Colors.OutlineVariant,
				Thickness = 1,
				Mode = Enum.ApplyStrokeMode.Border,
			}
			else nil,
		Padding = {
			if horizontal then 4 else theme.Metrics.SpaceSm,
			if horizontal then 4 else theme.Metrics.SpaceSm,
		},
		[Children] = { host },
	}) :: Frame

	table.insert(
		scope,
		host:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			syncIndicator(false)
		end)
	)
	for _, tab in tabs do
		table.insert(
			scope,
			tab:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				syncIndicator(false)
			end)
		)
	end
	task.defer(function()
		syncIndicator(false)
		task.delay(0.05, function()
			syncIndicator(false)
		end)
	end)

	return root
end
