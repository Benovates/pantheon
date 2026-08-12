--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	C.Dialog(scope, {
		Layer = ctx.overlayLayer,
		Title = "Dialog",
		Body = "Centered modal with actions.",
		Open = open,
		OnClose = function()
			open:set(false)
		end,
		Actions = {
			{ Text = "Cancel", OnClick = function() open:set(false) end },
			{ Text = "OK", Variant = "Primary", OnClick = function() open:set(false) end },
		},
	})
	return C.Button(scope, {
		Text = "Open dialog",
		OnClick = function()
			open:set(true)
		end,
	})
end)
