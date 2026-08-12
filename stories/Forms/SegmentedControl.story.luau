--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.SegmentedControl(scope, {
		Items = {
			{ Id = "day", Label = "Day" },
			{ Id = "week", Label = "Week" },
			{ Id = "month", Label = "Month" },
		},
	})
end)
