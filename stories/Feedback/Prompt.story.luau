--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	C.Prompt(scope, {
		Layer = ctx.overlayLayer,
		Title = "Discard changes?",
		Body = "Your edits will be lost. This action cannot be undone.",
		Icon = "triangle-alert",
		Open = open,
		ConfirmText = "Discard",
		Destructive = true,
		OnClose = function()
			open:set(false)
		end,
		OnConfirm = function()
			open:set(false)
		end,
	})
	return C.Button(scope, {
		Text = "Open prompt",
		Variant = "Outlined",
		OnClick = function()
			open:set(true)
		end,
	})
end)
