--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

local OnEvent = Fusion.OnEvent

return function(scope: Types.Scope, props: Types.OverlayProps?): TextButton
	local p: Types.OverlayProps = props or {}
	local theme = resolveTheme(p)
	-- TextButton sinks clicks; AppSheet panel (Active) sits above and blocks dismiss.
	return scope:TextButton({
		Name = "Overlay",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Colors.Scrim,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = p.Size or UDim2.fromScale(1, 1),
		ZIndex = p.ZIndex or 50,
		Visible = p.Visible,
		Active = true,
		[OnEvent("Activated")] = p.OnClick,
	}) :: TextButton
end
