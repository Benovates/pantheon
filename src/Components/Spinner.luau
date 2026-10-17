--!strict
--[[
	Indeterminate loading spinner.
	  Style "Morph" (default): Material 3 shape-morphing LoadingIndicator.
	  Style "Arc": spinning ring arc (set `Background` to the surface behind it).
	For a determinate ring use Progress { Variant = "Circular" }.
]]
local Types = require(script.Parent.Parent.Types)
local LoadingIndicator = require(script.Parent.LoadingIndicator)
local Progress = require(script.Parent.Progress)

return function(scope: Types.Scope, props: Types.SpinnerProps): Instance
	if props.Style == "Arc" then
		return Progress(scope, {
			Theme = props.Theme,
			Variant = "Circular" :: Types.ProgressVariant,
			Mode = "Indeterminate" :: Types.ProgressMode,
			Indicator = "Arc",
			Background = props.Background,
			SizePx = props.SizePx or 32,
			Size = props.Size,
			LayoutOrder = props.LayoutOrder,
			Visible = props.Visible,
			ZIndex = props.ZIndex,
		})
	end
	return LoadingIndicator(scope, {
		Theme = props.Theme,
		SizePx = props.SizePx or 32,
		Contained = props.Contained,
		Shapes = props.Shapes,
		Size = props.Size,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
	})
end
