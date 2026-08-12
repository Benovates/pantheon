--!strict
--[[
	Central mouse-wheel / trackpad routing for ScrollArea instances.

	- Scroll via UserInputService (trackpad-safe on macOS).
	- Sink wheel via ContextActionService so camera doesn't zoom.
	- Nested scroll areas: only the deepest area under the pointer scrolls.
]]
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ACTION = "EstuaryUI_ScrollWheel"
-- ~1.5× a typical line; trackpad sends many small fractional deltas.
local WHEEL_LINE = 76

export type Registration = {
	root: GuiObject,
	horizontal: boolean,
	scrollBy: (delta: number) -> (),
}

local registrations: { Registration } = {}
local wheelBound = false
local sinkBound = false
local lastHandled: InputObject? = nil

local function instanceDepth(inst: Instance): number
	local d = 0
	local cur: Instance? = inst
	while cur do
		d += 1
		cur = cur.Parent
	end
	return d
end

local function contains(gui: GuiObject, pt: Vector2): boolean
	local pos = gui.AbsolutePosition
	local sz = gui.AbsoluteSize
	if sz.X <= 0 or sz.Y <= 0 then
		return false
	end
	return pt.X >= pos.X and pt.X <= pos.X + sz.X and pt.Y >= pos.Y and pt.Y <= pos.Y + sz.Y
end

local function pointerPosition(input: InputObject): Vector2
	-- Wheel events include screen-space pointer coords (preferred on trackpad).
	if input.Position.X ~= 0 or input.Position.Y ~= 0 then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	local loc = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	return Vector2.new(loc.X, loc.Y - inset.Y)
end

local function pickTarget(pt: Vector2): Registration?
	local best: Registration? = nil
	local bestDepth = -1
	local bestZ = -math.huge

	for _, reg in registrations do
		local root = reg.root
		if root.Parent == nil or not root.Visible then
			continue
		end
		if not contains(root, pt) then
			continue
		end

		local depth = instanceDepth(root)
		local z = root.ZIndex
		if depth > bestDepth or (depth == bestDepth and z > bestZ) then
			bestDepth = depth
			bestZ = z
			best = reg
		end
	end

	return best
end

local function wheelDelta(input: InputObject): number
	return -input.Position.Z * WHEEL_LINE
end

local function handleWheel(input: InputObject): boolean
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return false
	end
	if lastHandled == input then
		return true
	end

	local target = pickTarget(pointerPosition(input))
	if not target then
		return false
	end

	lastHandled = input
	target.scrollBy(wheelDelta(input))
	return true
end

local function onWheelSink(
	_actionName: string,
	state: Enum.UserInputState,
	input: InputObject
): Enum.ContextActionResult
	if state ~= Enum.UserInputState.Change then
		return Enum.ContextActionResult.Pass
	end
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return Enum.ContextActionResult.Pass
	end
	if pickTarget(pointerPosition(input)) then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function ensureWheelBound()
	if wheelBound then
		return
	end
	wheelBound = true
	UserInputService.InputChanged:Connect(function(input)
		handleWheel(input)
	end)
	RunService.PostSimulation:Connect(function()
		lastHandled = nil
	end)
end

local function ensureSinkBound()
	if sinkBound then
		return
	end
	sinkBound = true
	ContextActionService:BindActionAtPriority(
		ACTION,
		onWheelSink,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.UserInputType.MouseWheel
	)
end

local function unbindIfIdle()
	if #registrations > 0 then
		return
	end
	if sinkBound then
		ContextActionService:UnbindAction(ACTION)
		sinkBound = false
	end
end

local ScrollInput = {}

function ScrollInput.register(reg: Registration): () -> ()
	table.insert(registrations, reg)
	ensureWheelBound()
	ensureSinkBound()

	return function()
		local i = table.find(registrations, reg)
		if i then
			table.remove(registrations, i)
		end
		unbindIfIdle()
	end
end

--- Per-instance fallback for Gui InputChanged (some clients route trackpad here).
function ScrollInput.handleWheel(input: InputObject): boolean
	return handleWheel(input)
end

return ScrollInput
