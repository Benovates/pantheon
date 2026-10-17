--!strict
--[[
	Press-and-drag over a GuiObject, reporting the pointer as 0..1 within it.

	Built on ScrollInput.capture so the drag keeps following the pointer outside the
	element (and works in plugin widgets, where InputChanged on the element alone stops
	firing once the pointer leaves it).
]]
local Types = require(script.Parent.Parent.Parent.Types)
local ScrollInput = require(script.Parent.Parent.ScrollInput)

local Drag = {}

--- `onPoint(x, y)` runs on press and on every move, clamped to 0..1. `accept` can reject a
--- press, e.g. a ring that ignores presses in its hole. `onHold(true)` runs when a press is
--- accepted and `onHold(false)` when the drag ends. The connection lives in `scope`.
function Drag.bind(
	scope: Types.Scope,
	gui: GuiObject,
	onPoint: (x: number, y: number) -> (),
	accept: ((x: number, y: number) -> boolean)?,
	onHold: ((down: boolean) -> ())?
)
	local function normalised(position: Vector3): (number, number)
		local origin, size = gui.AbsolutePosition, gui.AbsoluteSize
		return math.clamp((position.X - origin.X) / math.max(size.X, 1), 0, 1),
			math.clamp((position.Y - origin.Y) / math.max(size.Y, 1), 0, 1)
	end

	table.insert(
		scope,
		gui.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local x, y = normalised(input.Position)
			if accept and not accept(x, y) then
				return
			end
			if onHold then
				onHold(true)
			end
			onPoint(x, y)
			ScrollInput.capture(gui, function(move: InputObject)
				return move.UserInputType == Enum.UserInputType.MouseMovement
					or move.UserInputType == Enum.UserInputType.Touch
			end, function(ended: InputObject)
				return ended.UserInputType == Enum.UserInputType.MouseButton1
					or ended.UserInputType == Enum.UserInputType.Touch
			end, function(position: Vector3)
				onPoint(normalised(position))
			end, function()
				if onHold then
					onHold(false)
				end
			end)
		end)
	)
end

return Drag
