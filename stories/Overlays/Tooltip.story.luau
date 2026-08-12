--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local target = C.IconButton(scope, { Name = "moon" })
	C.Tooltip(scope, {
		Layer = ctx.overlayLayer,
		Target = target,
		Text = "Switch theme",
		Placement = "Auto",
	})
	return target
end)
