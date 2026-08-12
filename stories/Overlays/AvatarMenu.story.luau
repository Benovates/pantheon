--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	local trigger = C.Button(scope, {
		Text = "Avatar menu",
		Variant = "Outlined",
		OnClick = function()
			open:set(true)
		end,
	})
	C.AvatarMenu(scope, {
		Layer = ctx.overlayLayer,
		Open = open,
		Target = trigger,
		Initials = "EU",
		Name = "Estuary User",
		Subtitle = "you@game.com",
		OnClose = function()
			open:set(false)
		end,
		Items = {
			{ Text = "Profile", OnClick = function() open:set(false) end },
			{ Text = "Settings", OnClick = function() open:set(false) end },
			{ Text = "Sign out", OnClick = function() open:set(false) end },
		},
	})
	return trigger
end)
