--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.ListItem(scope, {
		Title = "Notifications",
		Subtitle = "Push & email",
		OnClick = function() end,
	})
end)
