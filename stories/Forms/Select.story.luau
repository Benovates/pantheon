--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Select(scope, {
		Label = "Role",
		Layer = ctx.overlayLayer,
		Options = {
			{ Value = "mod", Label = "Moderator" },
			{ Value = "admin", Label = "Admin" },
		},
	})
end)
