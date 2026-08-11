--!strict
--[[
	Indeterminate circular loading spinner (Progress Circular wrapper).
]]
local Types = require(script.Parent.Parent.Types)
local Progress = require(script.Parent.Progress)

return function(scope: Types.Scope, props: Types.SpinnerProps): Frame
	local px = props.SizePx or 32
	return Progress(scope, {
		Theme = props.Theme,
		Variant = "Circular" :: Types.ProgressVariant,
		Mode = "Indeterminate" :: Types.ProgressMode,
		Size = props.Size or UDim2.fromOffset(px, px),
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
	})
end
