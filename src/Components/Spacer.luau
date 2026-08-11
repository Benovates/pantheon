--!strict
local Types = require(script.Parent.Parent.Types)

return function(scope: Types.Scope, props: Types.BaseProps?): Frame
	local p: Types.BaseProps = props or {}
	return scope:Frame({
		Name = "Spacer",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.new(1, 0, 0, 16),
		LayoutOrder = p.LayoutOrder or 0,
	}) :: Frame
end
