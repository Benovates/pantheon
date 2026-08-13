--!strict
--[[
	A named page inside Menu. Sibling pages slide on push/pop.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)

local Children = Fusion.Children
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.MenuPageProps): Instance
	local page = scope:Frame({
		Name = "MenuPage",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		Layout = {
			Kind = "List",
			Padding = 1,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = props.Children,
	}) :: Frame
	page:SetAttribute("EstuaryMenuPageId", props.Id)
	local function writeTitle()
		local title = if props.Title == nil then nil else peek(props.Title)
		if typeof(title) == "string" then
			page:SetAttribute("EstuaryMenuPageTitle", title)
		else
			page:SetAttribute("EstuaryMenuPageTitle", nil)
		end
	end
	writeTitle()
	if typeof(props.Title) == "table" then
		table.insert(scope, scope:Observer(props.Title):onChange(writeTitle))
	end
	return page
end
