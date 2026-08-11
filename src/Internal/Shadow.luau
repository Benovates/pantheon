--!strict
--[[
	Soft elevation shadow via layered translucent frames (Roblox has no CSS box-shadow).
]]
local Types = require(script.Parent.Parent.Types)

export type ShadowLevel = number

type ShadowLayer = {
	offset: number,
	transparency: number,
	size: number,
}

local LEVELS: { [number]: { ShadowLayer } } = {
	[0] = {},
	[1] = { { offset = 1, transparency = 0.88, size = 0 } },
	[2] = {
		{ offset = 2, transparency = 0.86, size = 1 },
		{ offset = 4, transparency = 0.92, size = 2 },
	},
	[3] = {
		{ offset = 2, transparency = 0.82, size = 1 },
		{ offset = 6, transparency = 0.9, size = 3 },
	},
	[4] = {
		{ offset = 3, transparency = 0.78, size = 2 },
		{ offset = 8, transparency = 0.88, size = 4 },
		{ offset = 14, transparency = 0.94, size = 6 },
	},
}

local Shadow = {}

function Shadow.apply(scope: Types.Scope, parent: GuiObject, level: number?, color: Color3?)
	local resolvedLevel = math.clamp(level or 2, 0, 4)
	local resolvedColor = color or Color3.new(0, 0, 0)
	-- Clear previous estuary shadows
	for _, child in parent:GetChildren() do
		if child.Name == "EstuaryShadow" then
			child:Destroy()
		end
	end
	local layers = LEVELS[resolvedLevel] or LEVELS[2]
	for i, layer in layers do
		local f = scope:New("Frame")({
			Name = "EstuaryShadow",
			BackgroundColor3 = resolvedColor,
			BackgroundTransparency = layer.transparency,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, layer.offset),
			Size = UDim2.new(1, layer.size * 2, 1, layer.size * 2),
			ZIndex = (parent.ZIndex or 1) - (#layers - i + 1),
		})
		local corner = parent:FindFirstChildOfClass("UICorner")
		if corner then
			local c = corner:Clone()
			c.Parent = f
		else
			scope:New("UICorner")({
				CornerRadius = UDim.new(0, 12),
				Parent = f,
			})
		end
		f.Parent = parent
	end
end

return Shadow
