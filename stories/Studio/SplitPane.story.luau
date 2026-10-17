--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local function pane(text: string): Instance
		return scope:Frame({
			BackgroundTransparency = 1,
			[StoryUtil.Fusion.Children] = C.Text(scope, { Text = text, Variant = "Label" }),
			Padding = { 8 },
		})
	end
	local vertical = C.SplitPane(scope, {
		Orientation = "Vertical",
		Panes = { pane("Output"), pane("Properties") },
		Ratios = { 0.6, 0.4 },
	})
	local split = C.SplitPane(scope, {
		Panes = { pane("Explorer"), vertical, pane("Preview") },
		Ratios = { 1, 2, 1 },
		Size = UDim2.fromScale(1, 1),
	})
	return StoryUtil.panel(scope, 320, split)
end)
