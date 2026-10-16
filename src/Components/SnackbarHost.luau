--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)
local Snackbar = require(script.Parent.Snackbar)

local Children = Fusion.Children

export type HostApi = {
	Instance: Frame,
	Show: (message: string, actionText: string?, onAction: (() -> ())?) -> (),
}

return function(scope: Types.Scope, props: Types.SnackbarHostProps?): HostApi
	local p: Types.SnackbarHostProps = props or {}
	local theme = resolveTheme(p)
	local current = scope:Value(nil :: { message: string, actionText: string?, onAction: (() -> ())? }?)

	-- Use Fusion New (not Iona Frame) so [Children] Computed is never flattened.
	local host = scope:New("Frame")({
		Name = "SnackbarHost",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = p.ZIndex or 100,
		[Children] = scope:Computed(function(use, inner)
			-- `inner` is destroyed on each recompute, so dismissed snackbars free their springs.
			local item = use(current)
			if not item then
				return {} :: { Instance }
			end
			return {
				Snackbar(inner, {
					Theme = theme,
					Message = item.message,
					ActionText = item.actionText,
					OnAction = item.onAction,
				}),
			}
		end),
	}) :: Frame

	Layer.mount(scope, p, host)

	local token = 0
	local function show(message: string, actionText: string?, onAction: (() -> ())?)
		token += 1
		local mine = token
		current:set({ message = message, actionText = actionText, onAction = onAction })
		task.delay(3, function()
			if token == mine then
				current:set(nil)
			end
		end)
	end

	return {
		Instance = host,
		Show = show,
	}
end
