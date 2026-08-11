--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)
local Overlay = require(script.Parent.Overlay)
local ListItem = require(script.Parent.ListItem)
local IconButton = require(script.Parent.IconButton)
local Avatar = require(script.Parent.Avatar)
local Divider = require(script.Parent.Divider)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.NavigationDrawerProps): Frame
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
		theme.Motion.SpringSpeed * 0.85,
		theme.Motion.SpringDamping
	)

	local width = theme.Metrics.DrawerWidth
	local items = {}
	local drawerItems: { Types.ListItemProps } = props.Items or {}
	for i, item in drawerItems do
		item.LayoutOrder = i
		item.Theme = theme
		table.insert(items, ListItem(scope, item))
	end

	local panel = scope:Frame({
		Name = "DrawerPanel",
		BackgroundColor3 = theme.Colors.Surface,
		Size = UDim2.new(0, width, 1, 0),
		Position = scope:Computed(function(use)
			return UDim2.new(0, (use(openS) - 1) * width, 0, 0)
		end),
		ZIndex = 61,
		Layout = {
			Kind = "List",
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = {
			-- Tithe-style profile header sheet
			scope:Frame({
				Name = "Header",
				BackgroundColor3 = theme.Colors.SurfaceContainer,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Padding = { theme.Metrics.SpaceMd },
				Layout = {
					Kind = "List",
					Padding = theme.Metrics.SpaceSm,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = {
					scope:Frame({
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 40),
						LayoutOrder = 1,
						Layout = {
							Kind = "List",
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
						},
						[Children] = {
							scope:Hydrate(IconButton(scope, {
								Theme = theme,
								Name = "x",
								OnClick = props.OnClose,
							}))({
								Size = UDim2.fromOffset(40, 40),
							}),
						},
					}),
					scope:Frame({
						Name = "Profile",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Layout = {
							Kind = "List",
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = theme.Metrics.SpaceMd,
						},
						[Children] = {
							Avatar(scope, {
								Theme = theme,
								Image = props.AvatarImage,
								Initials = props.AvatarInitials or string.sub(peek(props.Title) or "M", 1, 1),
								AvatarSize = 56,
							}),
							scope:Frame({
								BackgroundTransparency = 1,
								AutomaticSize = Enum.AutomaticSize.XY,
								Layout = {
									Kind = "List",
									Padding = 4,
									SortOrder = Enum.SortOrder.LayoutOrder,
								},
								[Children] = {
									scope:TextLabel({
										BackgroundTransparency = 1,
										FontFace = theme.Typography.Title.Font,
										TextSize = theme.Typography.Title.Size,
										TextColor3 = theme.Colors.OnSurface,
										TextXAlignment = Enum.TextXAlignment.Left,
										Text = props.Title or "Menu",
										AutomaticSize = Enum.AutomaticSize.XY,
										LayoutOrder = 1,
									}),
									scope:TextLabel({
										BackgroundTransparency = 1,
										FontFace = theme.Typography.Body.Font,
										TextSize = theme.Typography.Label.Size,
										TextColor3 = theme.Colors.OnSurfaceVariant,
										TextXAlignment = Enum.TextXAlignment.Left,
										Text = props.Subtitle or "Navigate",
										AutomaticSize = Enum.AutomaticSize.XY,
										LayoutOrder = 2,
									}),
								},
							}),
						},
					}),
				},
			}),
			scope:Hydrate(Divider(scope, { Theme = theme }))({
				LayoutOrder = 2,
			}),
			scope:ScrollingFrame({
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, -140),
				LayoutOrder = 3,
				ScrollBarThickness = 4,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				Padding = { theme.Metrics.SpaceXs, theme.Metrics.SpaceSm },
				Layout = { Kind = "List", SortOrder = Enum.SortOrder.LayoutOrder, Padding = 2 },
				[Children] = {
					items,
					props.Children :: any,
				},
			}),
		},
	})

	local root = scope:Frame({
		Name = "NavigationDrawer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return use(openS) > 0.02
		end),
		ZIndex = props.ZIndex or 60,
		[Children] = {
			scope:Hydrate(Overlay(scope, {
				Theme = theme,
				OnClick = props.OnClose,
				ZIndex = 60,
			}))({
				BackgroundTransparency = scope:Computed(function(use)
					return 1 - use(openS) * 0.55
				end),
			}),
			panel,
		},
	}) :: Frame

	Layer.mount(scope, props, root)
	return root
end
