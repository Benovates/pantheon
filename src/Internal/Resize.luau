--!strict
--[[
	Resize geometry, with plain numbers so it can be tested without Roblox types.

	Dragging an edge moves that edge and keeps the opposite side where it was. Corners move two
	edges. An optional aspect ratio is locked: a corner follows whichever axis the pointer moved
	further (relative to the window's size), a left/right edge sets the height from the new width,
	a top/bottom edge sets the width from the new height. Min and max apply to both dimensions
	(through the ratio when there is one), then an optional grid snaps the size.
]]
local Resize = {}

export type Edges = { left: boolean?, right: boolean?, top: boolean?, bottom: boolean? }

export type Limits = {
	minWidth: number,
	minHeight: number,
	maxWidth: number,
	maxHeight: number,
	--- width / height; the size keeps this ratio when set.
	ratio: number?,
	--- Snap the size to multiples of this many px.
	grid: number?,
}

--- Rect (x, y, width, height) after dragging `edges` by (dx, dy).
function Resize.compute(
	edges: Edges,
	x: number,
	y: number,
	w: number,
	h: number,
	dx: number,
	dy: number,
	limits: Limits
): (number, number, number, number)
	local left, top, right, bottom = x, y, x + w, y + h
	if edges.left then
		left += dx
	end
	if edges.right then
		right += dx
	end
	if edges.top then
		top += dy
	end
	if edges.bottom then
		bottom += dy
	end
	local width, height = right - left, bottom - top

	local ratio = limits.ratio
	if ratio then
		local horizontal = edges.left or edges.right
		local vertical = edges.top or edges.bottom
		if horizontal and vertical then
			if math.abs(width - w) / math.max(w, 1) >= math.abs(height - h) / math.max(h, 1) then
				height = width / ratio
			else
				width = height * ratio
			end
		elseif horizontal then
			height = width / ratio
		else
			width = height * ratio
		end
		-- Clamp on the width, through the ratio, so both axes' limits hold.
		local lowest = math.max(limits.minWidth, limits.minHeight * ratio)
		local highest = math.max(math.min(limits.maxWidth, limits.maxHeight * ratio), lowest)
		width = math.clamp(width, lowest, highest)
		height = width / ratio
	else
		width = math.clamp(width, limits.minWidth, math.max(limits.maxWidth, limits.minWidth))
		height = math.clamp(height, limits.minHeight, math.max(limits.maxHeight, limits.minHeight))
	end

	local grid = limits.grid
	if grid and grid > 0 then
		width = math.max(math.floor(width / grid + 0.5) * grid, limits.minWidth)
		height = if ratio
			then width / ratio
			else math.max(math.floor(height / grid + 0.5) * grid, limits.minHeight)
	end

	-- The side opposite a dragged edge stays put.
	local newX = if edges.left then (x + w) - width else x
	local newY = if edges.top then (y + h) - height else y
	return newX, newY, width, height
end

return Resize
