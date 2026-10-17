--!strict
--[[
	Lucide icon wrapper: <Icon name="search" size={24} color={...} />
]]
local Packages = script.Parent.Parent.Parent
local Lucide = require(Packages.Lucide)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

return function(scope: Types.Scope, props: Types.IconProps): Instance
	local theme = resolveTheme(props)
	local size = props.IconSize or 24
	local assetSize = props.AssetSize or 48
	local color = props.Color or theme.Colors.OnSurface

	local image = props.Image
	local rectOffset = Vector2.zero
	local rectSize = Vector2.zero

	if not image and props.Name and props.Name ~= "" then
		local ok, asset = pcall(function()
			return Lucide.GetAsset(props.Name, assetSize)
		end)
		if ok and asset then
			image = asset.Url
			rectOffset = asset.ImageRectOffset
			rectSize = asset.ImageRectSize
		else
			warn(`[Pantheon.Icon] unknown Lucide icon '{props.Name}'`)
			image = ""
		end
	end

	return scope:ImageLabel({
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = image or "",
		ImageColor3 = color,
		ImageRectOffset = rectOffset,
		ImageRectSize = rectSize,
		Size = props.Size or UDim2.fromOffset(size, size),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		ScaleType = Enum.ScaleType.Fit,
		AspectRatio = {
			Ratio = 1,
		},
	}) :: ImageLabel
end
