--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	C.ConfirmDialog(scope, {
		Layer = ctx.overlayLayer,
		Title = "Delete item?",
		Body = "This cannot be undone.",
		Icon = "triangle-alert",
		Open = open,
		ConfirmText = "Delete",
		OnClose = function()
			open:set(false)
		end,
		OnConfirm = function()
			open:set(false)
		end,
	})
	return C.Button(scope, {
		Text = "Open confirm dialog",
		Variant = "Outlined",
		OnClick = function()
			open:set(true)
		end,
	})
end)
