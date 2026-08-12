--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Combobox(scope, {
		Label = "Filterable role",
		Layer = ctx.overlayLayer,
		Options = {
			{ Value = "mod", Label = "Moderator" },
			{ Value = "admin", Label = "Admin" },
			{ Value = "user", Label = "User" },
		},
	})
end)
