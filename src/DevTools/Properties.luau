--!strict
--[[
	Which properties the details pane lists for an instance, and how each is edited.
]]
local Properties = {}

export type Spec = { name: string, readOnly: boolean? }

local function plain(...: string): { Spec }
	local list: { Spec } = {}
	for _, name in { ... } do
		table.insert(list, { name = name })
	end
	return list
end

local function readOnly(...: string): { Spec }
	local list: { Spec } = {}
	for _, name in { ... } do
		table.insert(list, { name = name, readOnly = true })
	end
	return list
end

local function join(...: { Spec }): { Spec }
	local out: { Spec } = {}
	for _, list in { ... } do
		for _, spec in list do
			table.insert(out, spec)
		end
	end
	return out
end

local GUI_OBJECT = plain(
	"Visible",
	"Active",
	"ZIndex",
	"LayoutOrder",
	"Position",
	"Size",
	"AnchorPoint",
	"Rotation",
	"AutomaticSize",
	"ClipsDescendants",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderSizePixel"
)
local GUI_READ = readOnly("AbsolutePosition", "AbsoluteSize")

--- Properties by class, for the most specific class that matches first.
local BY_CLASS: { { class: string, specs: { Spec } } } = {
	{
		class = "TextLabel",
		specs = plain(
			"Text",
			"TextColor3",
			"TextTransparency",
			"TextSize",
			"TextXAlignment",
			"TextYAlignment",
			"TextWrapped",
			"RichText"
		),
	},
	{
		class = "TextButton",
		specs = plain(
			"Text",
			"TextColor3",
			"TextTransparency",
			"TextSize",
			"TextXAlignment",
			"AutoButtonColor"
		),
	},
	{
		class = "TextBox",
		specs = plain(
			"Text",
			"PlaceholderText",
			"TextColor3",
			"TextSize",
			"ClearTextOnFocus",
			"TextEditable"
		),
	},
	{
		class = "ImageLabel",
		specs = plain("Image", "ImageColor3", "ImageTransparency", "ScaleType"),
	},
	{
		class = "ImageButton",
		specs = plain("Image", "ImageColor3", "ImageTransparency", "ScaleType"),
	},
	{
		class = "ScrollingFrame",
		specs = join(
			plain("CanvasSize", "ScrollBarThickness", "AutomaticCanvasSize"),
			readOnly("CanvasPosition")
		),
	},
	{ class = "CanvasGroup", specs = plain("GroupTransparency", "GroupColor3") },
}

local MODIFIERS: { [string]: { Spec } } = {
	UICorner = plain("CornerRadius"),
	UIStroke = plain("Color", "Thickness", "Transparency", "ApplyStrokeMode", "Enabled"),
	UIPadding = plain("PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"),
	UIListLayout = plain(
		"FillDirection",
		"Padding",
		"SortOrder",
		"HorizontalAlignment",
		"VerticalAlignment",
		"Wraps"
	),
	UIGridLayout = plain("CellSize", "CellPadding", "FillDirection", "SortOrder"),
	UIGradient = plain("Rotation", "Offset", "Enabled"),
	UIScale = plain("Scale"),
	UIAspectRatioConstraint = plain("AspectRatio", "AspectType", "DominantAxis"),
	UISizeConstraint = plain("MinSize", "MaxSize"),
	UIFlexItem = plain("FlexMode", "GrowRatio", "ShrinkRatio"),
}

--- The properties to list for `instance`, in order.
function Properties.specsFor(instance: Instance): { Spec }
	if instance:IsA("GuiObject") then
		local specs = table.clone(GUI_OBJECT)
		for _, entry in BY_CLASS do
			if instance:IsA(entry.class) then
				for _, spec in entry.specs do
					table.insert(specs, spec)
				end
				break
			end
		end
		for _, spec in GUI_READ do
			table.insert(specs, spec)
		end
		return specs
	end
	for class, specs in MODIFIERS do
		if instance:IsA(class) then
			return specs
		end
	end
	return {}
end

return Properties
