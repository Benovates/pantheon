--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.AppBar(scope, {
		Title = "estuary-ui catalog",
		Leading = C.IconButton(scope, { Name = "menu" }),
		Actions = {
			C.IconButton(scope, { Name = "moon" }),
		},
	})
end)
