--!strict
local Types = require(script.Parent.Parent.Types)
local Surface = require(script.Parent.Surface)

return function(scope: Types.Scope, props: Types.SurfaceProps?): Frame
	local p: Types.SurfaceProps = props or {}
	return Surface(scope, {
		Theme = p.Theme,
		Name = p.Name or "Sheet",
		Elevated = true,
		Size = p.Size,
		LayoutOrder = p.LayoutOrder,
		Visible = p.Visible,
		ZIndex = p.ZIndex,
	})
end
