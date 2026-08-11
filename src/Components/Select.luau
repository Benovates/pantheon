--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Layer = require(script.Parent.Parent.Internal.Layer)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local RunService = game:GetService("RunService")

return function(scope: Types.Scope, props: Types.SelectProps): Frame
	local theme = resolveTheme(props)
	local open = scope:Value(false)
	local openS = scope:Spring(
		scope:Computed(function(use)
			return if use(open) then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)
	local selected = scope:Value((peek(props.Value) or "") :: string)
	local filter = scope:Value("" :: string)
	local disabled = peek(props.Disabled) == true
	local hasLabel = props.Label ~= nil
	local closedHeight = (if hasLabel then 20 else 0) + 40

	local function labelFor(value: string): string
		for _, opt in props.Options do
			if opt.Value == value then
				return opt.Label
			end
		end
		return peek(props.Placeholder) or "Select…"
	end

	local menuChildren = scope:Computed(function(use)
		if use(openS) < 0.05 then
			return {}
		end
		local q = string.lower(tostring(use(filter)))
		local nodes = {}
		local order = 1
		for _, opt in props.Options do
			local hay = string.lower(opt.Label .. " " .. opt.Value)
			if q == "" or string.find(hay, q, 1, true) then
				local optValue = opt.Value
				local isSelected = tostring(use(selected)) == optValue
				local hover = scope:Value(0)
				local press = scope:Value(0)
				local hoverS = scope:Spring(hover, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
				local pressS = scope:Spring(press, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
				local base = if isSelected then theme.Colors.PrimaryContainer else theme.Colors.Surface
				local item = scope:TextButton({
					Text = opt.Label,
					FontFace = theme.Typography.Body.Font,
					TextSize = theme.Typography.Body.Size,
					TextColor3 = theme.Colors.OnSurface,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundColor3 = scope:Computed(function(u)
						local alpha = math.clamp(u(hoverS) * 0.08 + u(pressS) * 0.12, 0, 0.2)
						return Interaction.lerpColor(base, theme.Colors.OnSurface, alpha)
					end),
					Size = UDim2.new(1, 0, 0, 40),
					LayoutOrder = order,
					AutoButtonColor = false,
					ClipsDescendants = true,
					CornerRadius = theme.Metrics.RadiusSm,
					Padding = { theme.Metrics.SpaceXs, theme.Metrics.SpaceSm },
					[OnEvent("Activated")] = function()
						selected:set(optValue)
						open:set(false)
						if props.OnChanged then
							props.OnChanged(optValue)
						end
					end,
					[OnEvent("MouseEnter")] = function()
						hover:set(1)
					end,
					[OnEvent("MouseLeave")] = function()
						hover:set(0)
						press:set(0)
					end,
					[OnEvent("MouseButton1Down")] = function()
						press:set(1)
					end,
					[OnEvent("MouseButton1Up")] = function()
						press:set(0)
					end,
				})
				table.insert(nodes, item)
				order += 1
			end
		end
		return nodes
	end)

	local triggerIx = Interaction.bind(scope, theme, {
		Disabled = disabled,
		StateColor = theme.Colors.OnSurface,
	})

	local fieldKids: { any } = {}
	if hasLabel then
		table.insert(fieldKids, scope:TextLabel({
			BackgroundTransparency = 1,
			FontFace = theme.Typography.Label.Font,
			TextSize = theme.Typography.Label.Size,
			TextColor3 = theme.Colors.OnSurfaceVariant,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = props.Label,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 1,
		}))
	end

	local trigger = scope:TextButton({
		Name = "Trigger",
		Text = scope:Computed(function(use)
			local v = use(selected)
			return if v ~= "" then labelFor(v) else (peek(props.Placeholder) or "Select…")
		end),
		FontFace = theme.Typography.Body.Font,
		TextSize = theme.Typography.Body.Size,
		TextColor3 = theme.Colors.OnSurface,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = triggerIx.fill(theme.Colors.SurfaceContainer),
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 2,
		AutoButtonColor = false,
		Active = not disabled,
		ClipsDescendants = false,
		CornerRadius = theme.Metrics.RadiusSm,
		Padding = { theme.Metrics.SpaceSm, theme.Metrics.SpaceMd },
		Outline = {
			Color = theme.Colors.Outline,
			Thickness = 1,
			Mode = Enum.ApplyStrokeMode.Border,
		},
		[OnEvent("Activated")] = function()
			if not disabled then
				open:set(not peek(open))
			end
		end,
	}) :: TextButton
	triggerIx.wire(trigger)
	table.insert(fieldKids, trigger)

	-- Popover mounts to Layer when provided (does not push layout)
	local popover = scope:New("Frame")({
		Name = "SelectPopover",
		BackgroundColor3 = theme.Colors.Surface,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = scope:Computed(function(use)
			return use(openS) > 0.02
		end),
		BackgroundTransparency = scope:Computed(function(use)
			return 1 - use(openS)
		end),
		ZIndex = 200,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, theme.Metrics.RadiusSm) }),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.Colors.Outline,
				Thickness = 1,
			}),
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			scope:New("UISizeConstraint")({
				MinSize = Vector2.new(160, 0),
			}),
			menuChildren,
		},
	})

	local field = scope:Frame({
		Name = "Select",
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Size = props.Size or UDim2.new(1, 0, 0, closedHeight),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = scope:Computed(function(use)
			local base = props.ZIndex
			local n = if typeof(base) == "number" then base else 1
			return if use(open) then math.max(n, 200) else n
		end),
		[Children] = {
			scope:Frame({
				Name = "Field",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Layout = {
					Kind = "List",
					Padding = 4,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = fieldKids,
			}),
		},
	}) :: Frame

	local mounted = Layer.mount(scope, props, popover)
	if not mounted then
		popover.Parent = field
		popover.Size = UDim2.new(1, 0, 0, 0)
		popover.AutomaticSize = Enum.AutomaticSize.Y
		popover.Position = UDim2.fromOffset(0, closedHeight + 4)
	else
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function()
				if not peek(open) then
					return
				end
				local layer = Layer.resolve(props)
				if layer == nil then
					return
				end
				local tp = trigger.AbsolutePosition
				local ts = trigger.AbsoluteSize
				local lp = layer.AbsolutePosition
				popover.Position = UDim2.fromOffset(tp.X - lp.X, tp.Y - lp.Y + ts.Y + 4)
				popover.Size = UDim2.fromOffset(math.max(ts.X, 160), 0)
			end)
		)
	end

	return field
end
