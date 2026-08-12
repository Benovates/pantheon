--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Tabs(scope, {
		Items = {
			{ Id = "one", Label = "One" },
			{ Id = "two", Label = "Two" },
			{ Id = "three", Label = "Three" },
		},
	})
end)
