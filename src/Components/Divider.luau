--!strict
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

return function(scope: Types.Scope, props: Types.DividerProps?): Frame
	local p: Types.DividerProps = props or {}
	local theme = resolveTheme(p)
	local vertical = p.Vertical == true
	return scope:Frame({
		Name = "Divider",
		BackgroundColor3 = theme.Colors.OutlineVariant,
		BorderSizePixel = 0,
		Size = p.Size or (if vertical then UDim2.new(0, 1, 1, 0) else UDim2.new(1, 0, 0, 1)),
		LayoutOrder = p.LayoutOrder or 0,
	}) :: Frame
end
