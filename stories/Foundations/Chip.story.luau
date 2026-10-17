--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = 8,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = {
			C.Chip(scope, { Text = "Chip", Selected = true, LayoutOrder = 1 }),
			C.Chip(scope, { Text = "Filter", LeadingIcon = "filter", LayoutOrder = 2 }),
		},
	})
end)
