--!strict
--[[
	Tithe-style avatar account sheet / popover — profile header + actions.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)
local Overlay = require(script.Parent.Overlay)
local Avatar = require(script.Parent.Avatar)
local Divider = require(script.Parent.Divider)
local Interaction = require(script.Parent.Parent.Internal.Interaction)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local RunService = game:GetService("RunService")

return function(scope: Types.Scope, props: Types.AvatarMenuProps): Frame
	local theme = resolveTheme(props)
	local openRef = props.Open
	local open = scope:Computed(function(use)
		if openRef == nil then
			return true
		end
		return (if typeof(openRef) == "table" then use(openRef) else openRef) == true
	end)
	local openS = scope:Spring(
		scope:Computed(function(use)
			return if use(open) then 1 else 0
		end),
		theme.Motion.SpringSpeed * 0.9,
		theme.Motion.SpringDamping
	)

	local width = 280
	local pos = scope:Value(UDim2.fromOffset(16, 72))

	local items = {}
	local menuItems: { Types.MenuItemProps } = props.Items or {}
	for i, item in menuItems do
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
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = i + 10,
			AutoButtonColor = false,
			Active = not item.Disabled,
			ClipsDescendants = true,
			CornerRadius = theme.Metrics.RadiusSm,
			Padding = { theme.Metrics.SpaceSm, theme.Metrics.SpaceMd },
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

	local panel = scope:Frame({
		Name = "AvatarMenuPanel",
		BackgroundColor3 = theme.Colors.Surface,
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = pos,
		BackgroundTransparency = scope:Computed(function(use)
			return 1 - use(openS)
		end),
		ZIndex = (props.ZIndex or 95) + 1,
		CornerRadius = theme.Metrics.RadiusPanel,
		Outline = { Color = theme.Colors.OutlineVariant, Thickness = 1, Mode = Enum.ApplyStrokeMode.Border },
		Padding = { theme.Metrics.SpaceMd },
		Layout = {
			Kind = "List",
			Padding = theme.Metrics.SpaceSm,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = {
			scope:Frame({
				Name = "Profile",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = theme.Metrics.SpaceMd,
				},
				[Children] = {
					Avatar(scope, {
						Theme = theme,
						Image = props.Image,
						Initials = props.Initials or "?",
						AvatarSize = 52,
					}),
					scope:Frame({
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.XY,
						Layout = {
							Kind = "List",
							Padding = 2,
							SortOrder = Enum.SortOrder.LayoutOrder,
						},
						[Children] = {
							scope:TextLabel({
								BackgroundTransparency = 1,
								FontFace = theme.Typography.Title.Font,
								TextSize = theme.Typography.Title.Size,
								TextColor3 = theme.Colors.OnSurface,
								TextXAlignment = Enum.TextXAlignment.Left,
								Text = props.Name or "Account",
								AutomaticSize = Enum.AutomaticSize.XY,
								LayoutOrder = 1,
							}),
							if props.Subtitle
								then scope:TextLabel({
									BackgroundTransparency = 1,
									FontFace = theme.Typography.Body.Font,
									TextSize = theme.Typography.Label.Size,
									TextColor3 = theme.Colors.OnSurfaceVariant,
									TextXAlignment = Enum.TextXAlignment.Left,
									Text = props.Subtitle,
									AutomaticSize = Enum.AutomaticSize.XY,
									LayoutOrder = 2,
								})
								else nil,
						},
					}),
				},
			}),
			scope:Hydrate(Divider(scope, { Theme = theme }))({
				LayoutOrder = 2,
			}),
			items,
		},
	})

	local scale = Instance.new("UIScale")
	scale.Parent = panel
	table.insert(
		scope,
		scope:Observer(openS):onBind(function()
			scale.Scale = 0.94 + 0.06 * peek(openS)
		end)
	)

	local function updatePosition()
		local target = props.Target
		local layer = Layer.resolve(props)
		if target == nil or layer == nil then
			return
		end
		local tp = target.AbsolutePosition
		local ts = target.AbsoluteSize
		local lp = layer.AbsolutePosition
		local x = tp.X - lp.X + ts.X - width
		local y = tp.Y - lp.Y + ts.Y + 8
		pos:set(UDim2.fromOffset(math.max(12, x), math.max(12, y)))
	end

	table.insert(
		scope,
		RunService.RenderStepped:Connect(function()
			if peek(open) then
				updatePosition()
			end
		end)
	)

	local root = scope:Frame({
		Name = "AvatarMenu",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return use(openS) > 0.02
		end),
		ZIndex = props.ZIndex or 95,
		[Children] = {
			scope:Hydrate(Overlay(scope, {
				Theme = theme,
				OnClick = props.OnClose,
				ZIndex = props.ZIndex or 95,
			}))({
				BackgroundTransparency = scope:Computed(function(use)
					return 1 - use(openS) * 0.4
				end),
			}),
			panel,
		},
	}) :: Frame

	Layer.mount(scope, props, root)
	return root
end
