--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local rail = C.NavigationRail(scope, {
		Orientation = "Vertical",
		Layer = ctx.overlayLayer,
		Items = {
			{ Id = "home", Icon = "home", Label = "Home" },
			{ Id = "lib", Icon = "library", Label = "Lib" },
			{ Id = "set", Icon = "settings", Label = "Settings" },
		},
	})
	return StoryUtil.panel(scope, 320, scope:Hydrate(rail)({
		Size = UDim2.new(0, ctx.theme.Metrics.RailWidth, 1, 0),
	}))
end)
