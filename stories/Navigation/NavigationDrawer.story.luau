--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	C.NavigationDrawer(scope, {
		Layer = ctx.overlayLayer,
		Open = open,
		Title = "Cadence",
		Subtitle = "estuary-ui catalog",
		AvatarInitials = "EU",
		OnClose = function()
			open:set(false)
		end,
		Items = {
			{ Title = "Forms", OnClick = function() end },
			{ Title = "Navigation", OnClick = function() end },
			{ Title = "Data", OnClick = function() end },
		},
	})
	return C.Button(scope, {
		Text = "Open drawer",
		LeadingIcon = "menu",
		OnClick = function()
			open:set(true)
		end,
	})
end)
