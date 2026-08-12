--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	C.AppSheet(scope, {
		Layer = ctx.overlayLayer,
		Open = open,
		Title = "Quick sheet",
		OnClose = function()
			open:set(false)
		end,
		Children = {
			C.Text(scope, { Text = "iOS-style app sheet with grabber + scrim.", Variant = "Body" }),
			C.StarRating(scope, { Value = 5 }),
		},
	})
	return C.Button(scope, {
		Text = "Open app sheet",
		LeadingIcon = "panel-bottom",
		OnClick = function()
			open:set(true)
		end,
	})
end)
