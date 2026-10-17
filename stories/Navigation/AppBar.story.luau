--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.AppBar(scope, {
		Title = "pantheon catalog",
		Leading = C.IconButton(scope, { Name = "menu" }),
		Actions = {
			C.IconButton(scope, { Name = "moon" }),
		},
	})
end)
