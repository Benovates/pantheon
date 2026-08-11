--!strict
local HSV = {}

function HSV.fromColor3(c: Color3): (number, number, number)
	return Color3.toHSV(c)
end

function HSV.toColor3(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h, s, v)
end

return HSV
