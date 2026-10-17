--!strict
--[[
	Colours and fonts shared by the Game components. They don't use the app theme.
]]
local Style = {
	Panel = Color3.fromRGB(24, 26, 31),
	PanelTransparency = 0.3,
	Edge = Color3.new(1, 1, 1),
	EdgeTransparency = 0.88,
	Text = Color3.fromRGB(245, 246, 248),
	TextDim = Color3.fromRGB(176, 181, 190),
	Accent = Color3.fromRGB(255, 255, 255),
	-- The equipped slot inverts: light fill, dark content.
	Equipped = Color3.fromRGB(250, 251, 252),
	OnEquipped = Color3.fromRGB(24, 26, 31),
	Radius = 8,
	Font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	FontBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
}

return Style
