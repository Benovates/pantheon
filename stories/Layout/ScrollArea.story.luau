--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	local kids = {}
	for i = 1, 40 do
		table.insert(kids, C.Text(scope, {
			Text = "Scroll row " .. i,
			Variant = "Body",
			LayoutOrder = i,
		}))
	end
	local scroll = C.ScrollArea(scope, {
		Children = kids,
		Smooth = true,
		Inertia = true,
		AutoCanvas = true,
		ScrollBarRail = true,
	})
	return StoryUtil.panel(scope, 280, scope:Hydrate(scroll)({
		Size = UDim2.fromScale(1, 1),
	}))
end)
