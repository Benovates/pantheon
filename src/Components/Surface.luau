--!strict
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

return function(scope: Types.Scope, props: Types.SurfaceProps?): Instance
	local p: Types.SurfaceProps = props or {}
	local theme = resolveTheme(p)
	local elevated = p.Elevated == true
	return scope:Frame({
		Name = p.Name or "Surface",
		BackgroundColor3 = if elevated then theme.Colors.SurfaceContainerHigh else theme.Colors.Surface,
		BorderSizePixel = 0,
		Size = p.Size,
		LayoutOrder = p.LayoutOrder or 0,
		Visible = p.Visible,
		ZIndex = p.ZIndex,
		CornerRadius = theme.Metrics.RadiusPanel,
	}) :: Frame
end
