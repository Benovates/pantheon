--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

-- Toasts stack, newest in front. Move the pointer over the stack to spread it out.
return StoryUtil.story(function(scope, C, ctx)
	local toasts = C.SnackbarHost(scope, { Layer = ctx.overlayLayer })
	local count = 0
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Layout = { Kind = "List", FillDirection = Enum.FillDirection.Horizontal, Padding = 8 },
		[StoryUtil.Fusion.Children] = {
			C.Button(scope, {
				Text = "Plain toast",
				LayoutOrder = 1,
				OnClick = function()
					count += 1
					toasts.Show(`Saved draft {count}`)
				end,
			}),
			C.Button(scope, {
				Text = "With action and close",
				Variant = "Tonal",
				LayoutOrder = 2,
				OnClick = function()
					count += 1
					toasts.Show(`Message {count} archived`, "Undo", nil, {
						Icon = "archive",
						Dismissible = true,
						Duration = 6,
					})
				end,
			}),
			C.Button(scope, {
				Text = "Custom element",
				Variant = "Outlined",
				LayoutOrder = 3,
				OnClick = function()
					toasts.Show("Uploading", nil, nil, {
						Duration = math.huge,
						Dismissible = true,
						Trailing = function(inner)
							return C.Spinner(inner, { SizePx = 18 })
						end,
					})
				end,
			}),
		},
	})
end)
