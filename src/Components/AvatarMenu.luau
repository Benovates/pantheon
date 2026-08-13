--!strict
--[[
	Tithe-style avatar account sheet / popover — profile header + Menu actions.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)
local Overlay = require(script.Parent.Overlay)
local Avatar = require(script.Parent.Avatar)
local Menu = require(script.Parent.Menu)

local Children = Fusion.Children
local peek = Fusion.peek
local RunService = game:GetService("RunService")

return function(scope: Types.Scope, props: Types.AvatarMenuProps): Instance
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

	local header = scope:Frame({
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Layout = {
			Kind = "List",
			Padding = theme.Metrics.SpaceSm,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		Padding = { 0, 0, 4, 0 },
		[Children] = {
			scope:Frame({
				Name = "Profile",
				BackgroundTransparency = 0,
				BackgroundColor3 = theme.Colors.SurfaceDim,
				CornerRadius = theme.Metrics.RadiusPanel - 4 / 2,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = theme.Metrics.SpaceSm,
				},
				Padding = { theme.Metrics.SpaceMd, 0 },
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
		},
	})

	local menu = Menu(scope, {
		Theme = theme,
		Embedded = true,
		Open = open,
		OnClose = props.OnClose,
		Items = props.Items or {},
		Sections = props.Sections,
		Header = header,
		MaxHeight = props.MaxHeight,
		Size = UDim2.fromOffset(width, 0),
		ZIndex = (props.ZIndex or 95) + 1,
	})

	scope:Hydrate(menu)({
		Name = "AvatarMenuPanel",
		Position = pos,
	})

	local scale = Instance.new("UIScale")
	scale.Parent = menu
	table.insert(
		scope,
		scope:Observer(openS):onBind(function()
			scale.Scale = 0.94 + 0.06 * peek(openS)
		end)
	)

	local function updatePosition()
		local target = Layer.asGui(props.Target)
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
					return 1 - (use(openS) :: number) * 0.4
				end),
			}),
			menu,
		},
	}) :: Frame

	Layer.mount(scope, props, root)
	return root
end
