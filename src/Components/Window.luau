--!strict
--[[
	Rounded app chrome shell (elevated Sheet colors) that hosts AppBar,
	NavigationRail, content, and overlay layers (NavigationDrawer, menus, dialogs).

	Uses CanvasGroup so UICorner actually clips chrome children (Frame + UICorner
	only rounds the background; AppBar/rail would otherwise square off the corners).
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)

local Children = Fusion.Children

-- Matches NavigationRail default horizontal height.
local HORIZONTAL_RAIL_HEIGHT = 52

local function isVerticalRail(
	rail: Instance?,
	explicit: ("Vertical" | "Horizontal")?
): boolean
	if explicit == "Horizontal" then
		return false
	end
	if explicit == "Vertical" then
		return true
	end
	if rail == nil or not rail:IsA("GuiObject") then
		return true
	end
	-- NavigationRail horizontal default size is UDim2.new(1, 0, 0, 72)
	local s = (rail :: GuiObject).Size
	if s.X.Scale >= 1 and s.Y.Scale == 0 and s.Y.Offset > 0 and s.Y.Offset <= 100 then
		return false
	end
	return true
end

return function(scope: Types.Scope, props: Types.WindowProps): Instance
	local theme = resolveTheme(props)
	local verticalRail = isVerticalRail(props.NavigationRail, props.RailOrientation)
	local hasAppBar = props.AppBar ~= nil
	local hasRail = props.NavigationRail ~= nil
	local appBarHeight = if hasAppBar then theme.Metrics.AppBarHeight else 0
	local railWidth = if hasRail and verticalRail then theme.Metrics.RailWidth else 0
	local railBottom = if hasRail and not verticalRail then HORIZONTAL_RAIL_HEIGHT else 0
	local radius = props.CornerRadius or theme.Metrics.RadiusPanel
	local elevated = if props.Elevated == nil then true else props.Elevated

	local overlayLayer = scope:Frame({
		Name = "OverlayLayer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 50,
	}) :: Frame

	if props.AppBar then
		scope:Hydrate(props.AppBar)({
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, appBarHeight),
			ZIndex = 10,
		})
	end

	if props.NavigationRail then
		scope:Hydrate(props.NavigationRail)({
			Position = if verticalRail
				then UDim2.fromOffset(0, appBarHeight)
				else UDim2.new(0, 0, 1, -railBottom),
			Size = if verticalRail
				then UDim2.new(0, railWidth, 1, -appBarHeight)
				else UDim2.new(1, 0, 0, railBottom),
			ZIndex = 5,
		})
	end

	local content = scope:Frame({
		Name = "Content",
		BackgroundTransparency = 1,
		Position = if verticalRail
			then UDim2.fromOffset(railWidth, appBarHeight)
			else UDim2.fromOffset(0, appBarHeight),
		Size = if verticalRail
			then UDim2.new(1, -railWidth, 1, -appBarHeight)
			else UDim2.new(1, 0, 1, -(appBarHeight + railBottom)),
		ZIndex = 1,
		ClipsDescendants = true,
		[Children] = props.Children,
	})

	local chrome: { any } = { content, overlayLayer }
	if props.AppBar then
		table.insert(chrome, 1, props.AppBar)
	end
	if props.NavigationRail then
		table.insert(chrome, props.NavigationRail)
	end

	-- CanvasGroup + CornerRadius clips descendants to the rounded rect (Sheet-equivalent fill).
	local window = scope:CanvasGroup({
		Name = "Window",
		BackgroundColor3 = if elevated then theme.Colors.SurfaceContainerHigh else theme.Colors.Surface,
		GroupTransparency = 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		ClipsDescendants = true,
		CornerRadius = radius,
		Outline = {
			Color = theme.Colors.OutlineVariant,
			Thickness = 1,
			Mode = Enum.ApplyStrokeMode.Border,
		},
		[Children] = chrome,
	}) :: CanvasGroup

	local overlays = props.Overlays
	if overlays then
		for _, overlay in overlays do
			overlay.Parent = overlayLayer
		end
	end

	Layer.bind(overlayLayer)

	return window
end
