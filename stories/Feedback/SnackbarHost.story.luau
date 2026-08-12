--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local host = C.SnackbarHost(scope, { Layer = ctx.overlayLayer })
	return C.Button(scope, {
		Text = "Show toast",
		OnClick = function()
			host.Show("Saved successfully")
		end,
	})
end)
