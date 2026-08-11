--!strict
--[[
	iOS-style UISegmentedControl — traveling selection pill with stretch.
	Indicator is measured against the segments host (no padding double-count).
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Icon = require(script.Parent.Icon)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local INSET = 3

return function(scope: Types.Scope, props: Types.SegmentedControlProps): Frame
	local theme = resolveTheme(props)
	local disabled = peek(props.Disabled) == true
	local initialId = peek(props.Selected) or (props.Items[1] and props.Items[1].Id) or ""
	local selected = scope:Value(initialId)

	local indicatorX = scope:Value(0)
	local indicatorW = scope:Value(0)
	local stretch = scope:Value(0)
	local stretchS = scope:Spring(stretch, theme.Motion.SpringSpeed * 1.55, 0.76)
	local xS = scope:Spring(indicatorX, theme.Motion.SpringSpeed * 0.8, 0.84)
	local wS = scope:Spring(indicatorW, theme.Motion.SpringSpeed * 0.8, 0.84)

	local segments: { TextButton } = {}
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
		local seg = segments[idx]
		if not seg or not host or host.Parent == nil then
			return
		end
		-- Measure in host space (indicator is a child of host — no UIPadding here)
		local relX = seg.AbsolutePosition.X - host.AbsolutePosition.X
		local w = seg.AbsoluteSize.X
		if w < 1 then
			return
		end
		if animateStretch then
			local travel = math.abs(relX - peek(indicatorX))
			stretch:set(math.clamp(travel * 0.3, 6, 32))
			task.delay(0.12, function()
				stretch:set(0)
			end)
		end
		indicatorX:set(relX)
		indicatorW:set(w)
	end

	for i, item in props.Items do
		local isOn = scope:Computed(function(use)
			return use(selected) == item.Id
		end)
		local selectedS = scope:Spring(scope:Computed(function(use)
			return if use(isOn) then 1 else 0
		end), theme.Motion.SpringSpeed, theme.Motion.SpringDamping)

		local ix = Interaction.bind(scope, theme, {
			Disabled = disabled,
			StateColor = theme.Colors.OnSurface,
		})

		local kids: { any } = {}
		if item.Icon then
			table.insert(
				kids,
				scope:Hydrate(Icon(scope, {
					Theme = theme,
					Name = item.Icon,
					IconSize = 16,
					Color = scope:Computed(function(use)
						return Interaction.lerpColor(
							theme.Colors.OnSurfaceVariant,
							theme.Colors.Primary,
							use(selectedS)
						)
					end),
				}))({
					LayoutOrder = 1,
				})
			)
		end
		table.insert(
			kids,
			scope:TextLabel({
				BackgroundTransparency = 1,
				FontFace = theme.Typography.Label.Font,
				TextSize = theme.Typography.Label.Size,
				Text = item.Label,
				TextColor3 = scope:Computed(function(use)
					return Interaction.lerpColor(
						theme.Colors.OnSurfaceVariant,
						theme.Colors.Primary,
						use(selectedS)
					)
				end),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 2,
			})
		)

		local hoverT = ix.fillTransparency(1)
		local seg = scope:TextButton(P({
			Name = "Segment_" .. item.Id,
			Text = "",
			AutoButtonColor = false,
			Active = not disabled,
			-- Hover pill on inactive segments; selected fill comes from traveling indicator
			BackgroundColor3 = theme.Colors.OnSurface,
			BackgroundTransparency = scope:Computed(function(use)
				if use(isOn) then
					return 1
				end
				return use(hoverT)
			end),
			Size = UDim2.new(1, 0, 1, 0),
			LayoutOrder = i,
			ZIndex = 2,
			ClipsDescendants = true,
			CornerRadius = theme.Metrics.RadiusPill,
			Padding = { theme.Metrics.Space2xs, theme.Metrics.SpaceXs },
			Layout = {
				Kind = "List",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = 4,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			[OnEvent("Activated")] = function()
				if disabled then
					return
				end
				local prev = peek(selected)
				selected:set(item.Id)
				task.defer(function()
					syncIndicator(prev ~= item.Id)
				end)
				if props.OnChanged then
					props.OnChanged(item.Id)
				end
			end,
			[Children] = kids,
		})) :: TextButton

		local flex = Instance.new("UIFlexItem")
		flex.FlexMode = Enum.UIFlexMode.Fill
		flex.Parent = seg
		ix.wire(seg)
		table.insert(segments, seg)
	end

	host = scope:Frame({
		Name = "SegmentsHost",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			scope:Frame({
				Name = "Indicator",
				BackgroundColor3 = theme.Colors.Surface,
				ZIndex = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = scope:Computed(function(use)
					local extra = use(stretchS)
					return UDim2.new(0, use(xS) - extra * 0.5, 0.5, 0)
				end),
				Size = scope:Computed(function(use)
					return UDim2.new(0, math.max(use(wS) + use(stretchS), 8), 1, 0)
				end),
				CornerRadius = theme.Metrics.RadiusPill,
			}),
			scope:Frame({
				Name = "Segments",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = 2,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = segments,
			}),
		},
	}) :: Frame

	local track = scope:Frame({
		Name = "SegmentedControl",
		BackgroundColor3 = theme.Colors.SurfaceContainerHigh,
		Size = props.Size or UDim2.new(1, 0, 0, 36),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		ClipsDescendants = true,
		CornerRadius = theme.Metrics.RadiusPill,
		Padding = { INSET, INSET },
		[Children] = { host },
	}) :: Frame

	table.insert(
		scope,
		host:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			syncIndicator(false)
		end)
	)
	for _, seg in segments do
		table.insert(
			scope,
			seg:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
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

	return track
end
