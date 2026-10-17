--!strict
--[[
	Set per-corner radii on a GuiObject's UICorner (creating one if needed). Used by
	containers like Window to round the chrome they host (app bar, rail) to match their
	own corners: ClipsDescendants only clips to a rectangle, not a rounded one.

	Needs individual corner radii (live since June 2026); on older engines it does nothing
	and the child keeps whatever rounding it already had.
]]
local Features = require(script.Parent.Features)

local Corners = {}

function Corners.apply(
	inst: Instance?,
	topLeft: number,
	topRight: number,
	bottomLeft: number,
	bottomRight: number
)
	if inst == nil or not inst:IsA("GuiObject") or not Features.individualCorners() then
		return
	end
	local corner = inst:FindFirstChildOfClass("UICorner")
	if corner == nil then
		corner = Instance.new("UICorner");
		(corner :: UICorner).Parent = inst
	end
	local c = corner :: any
	c.TopLeftRadius = UDim.new(0, topLeft)
	c.TopRightRadius = UDim.new(0, topRight)
	c.BottomLeftRadius = UDim.new(0, bottomLeft)
	c.BottomRightRadius = UDim.new(0, bottomRight)
end

local WINDOW_RADIUS = "PantheonWindowRadius"

--- Corner radius of the nearest enclosing Window (0 if none). Windows publish theirs as an
--- attribute so floating UI that fills the window (scrims, sheets) can match its rounding.
function Corners.windowRadius(inst: Instance?): number
	local current = if inst then inst.Parent else nil
	while current do
		local r = current:GetAttribute(WINDOW_RADIUS)
		if typeof(r) == "number" then
			return r
		end
		current = current.Parent
	end
	return 0
end

Corners.WindowRadiusAttribute = WINDOW_RADIUS

--- Call `apply(radius)` now and whenever `inst` is re-parented (it may be built before the
--- window that will end up containing it). Returns a disconnect function.
function Corners.followWindow(inst: Instance, apply: (radius: number) -> ()): () -> ()
	local last = -1
	local function sync()
		local r = Corners.windowRadius(inst)
		if r ~= last then
			last = r
			apply(r)
		end
	end
	local conn = inst.AncestryChanged:Connect(sync)
	task.defer(sync)
	return function()
		conn:Disconnect()
	end
end

return Corners
