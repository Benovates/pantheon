--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 8, SortOrder = Enum.SortOrder.LayoutOrder },
		[Children] = {
			C.Text(scope, { Text = "Display", Variant = "Display", LayoutOrder = 1 }),
			C.Text(scope, { Text = "Headline", Variant = "Headline", LayoutOrder = 2 }),
			C.Text(scope, { Text = "Title", Variant = "Title", LayoutOrder = 3 }),
			C.Text(scope, {
				Text = "Body copy for Cadence/Tithe surfaces.",
				Variant = "Body",
				LayoutOrder = 4,
			}),
			C.Text(scope, { Text = "Label", Variant = "Label", LayoutOrder = 5 }),
		},
	})
end)
