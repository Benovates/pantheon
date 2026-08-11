--!strict
--[[
	Material alert / confirm prompt — full-screen modal Dialog.
]]
local Types = require(script.Parent.Parent.Types)
local Dialog = require(script.Parent.Dialog)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

return function(scope: Types.Scope, props: Types.DialogProps & {
	OnConfirm: (() -> ())?,
	ConfirmText: string?,
	CancelText: string?,
	Destructive: boolean?,
}): Frame
	local theme = resolveTheme(props)
	local actions = props.Actions
		or {
			{
				Text = props.CancelText or "Cancel",
				Variant = "Text" :: Types.ButtonVariant,
				OnClick = props.OnClose,
			},
			{
				Text = props.ConfirmText or "OK",
				Variant = (if props.Destructive then "Destructive" else "Primary") :: Types.ButtonVariant,
				OnClick = props.OnConfirm or props.OnClose,
			},
		}
	local iconColor = props.IconColor
	if iconColor == nil and props.Icon and props.Destructive then
		iconColor = theme.Colors.Error
	end
	return Dialog(scope, {
		Theme = props.Theme,
		Title = props.Title,
		Body = props.Body,
		Children = props.Children,
		Actions = actions,
		OnClose = props.OnClose,
		Open = props.Open,
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		Layer = props.Layer,
		Icon = props.Icon,
		IconColor = iconColor,
		IconSize = props.IconSize,
	})
end
