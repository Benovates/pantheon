--!strict
--[[
	Colour-space conversions for the picker. All channel values are plain numbers so the
	maths is testable without Roblox types; the Color3 wrappers are thin.

	sRGB (0..1) ⇄ HSL, CIE L*a*b* (D65), hex.
]]
local ColorSpaces = {}

-- HSL
--- h, s, l all 0..1.
function ColorSpaces.rgbToHsl(r: number, g: number, b: number): (number, number, number)
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local l = (max + min) / 2
	if max == min then
		return 0, 0, l
	end
	local d = max - min
	local s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
	local h
	if max == r then
		h = (g - b) / d + (if g < b then 6 else 0)
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	return h / 6, s, l
end

local function hueToChannel(p: number, q: number, t: number): number
	if t < 0 then
		t += 1
	elseif t > 1 then
		t -= 1
	end
	if t < 1 / 6 then
		return p + (q - p) * 6 * t
	elseif t < 1 / 2 then
		return q
	elseif t < 2 / 3 then
		return p + (q - p) * (2 / 3 - t) * 6
	end
	return p
end

function ColorSpaces.hslToRgb(h: number, s: number, l: number): (number, number, number)
	if s <= 0 then
		return l, l, l
	end
	local q = if l < 0.5 then l * (1 + s) else l + s - l * s
	local p = 2 * l - q
	return hueToChannel(p, q, h + 1 / 3), hueToChannel(p, q, h), hueToChannel(p, q, h - 1 / 3)
end

-- CIE L*a*b* (D65)
local WHITE_X, WHITE_Y, WHITE_Z = 0.95047, 1.0, 1.08883
local EPSILON = 216 / 24389 -- 0.008856
local KAPPA = 24389 / 27 -- 903.3

local function toLinear(c: number): number
	return if c <= 0.04045 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
end

local function fromLinear(c: number): number
	c = math.clamp(c, 0, 1)
	return if c <= 0.0031308 then c * 12.92 else 1.055 * c ^ (1 / 2.4) - 0.055
end

local function labF(t: number): number
	return if t > EPSILON then t ^ (1 / 3) else (KAPPA * t + 16) / 116
end

local function labFInverse(t: number): number
	local cubed = t * t * t
	return if cubed > EPSILON then cubed else (116 * t - 16) / KAPPA
end

--- L 0..100, a / b roughly −128..127.
function ColorSpaces.rgbToLab(r: number, g: number, b: number): (number, number, number)
	local lr, lg, lb = toLinear(r), toLinear(g), toLinear(b)
	local x = (0.4124564 * lr + 0.3575761 * lg + 0.1804375 * lb) / WHITE_X
	local y = (0.2126729 * lr + 0.7151522 * lg + 0.0721750 * lb) / WHITE_Y
	local z = (0.0193339 * lr + 0.1191920 * lg + 0.9503041 * lb) / WHITE_Z
	local fx, fy, fz = labF(x), labF(y), labF(z)
	return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
end

--- Out-of-gamut colours are clamped into sRGB.
function ColorSpaces.labToRgb(l: number, a: number, b: number): (number, number, number)
	local fy = (l + 16) / 116
	local fx = fy + a / 500
	local fz = fy - b / 200
	local x = labFInverse(fx) * WHITE_X
	local y = (if l > KAPPA * EPSILON then fy * fy * fy else l / KAPPA) * WHITE_Y
	local z = labFInverse(fz) * WHITE_Z
	local lr = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
	local lg = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
	local lb = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
	return fromLinear(lr), fromLinear(lg), fromLinear(lb)
end

-- Hex
function ColorSpaces.toHex(r: number, g: number, b: number): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(r * 255 + 0.5),
		math.floor(g * 255 + 0.5),
		math.floor(b * 255 + 0.5)
	)
end

--- Accepts "#RGB", "#RRGGBB", with or without "#". Returns { r, g, b } (0..1), or nil when
--- it isn't a colour.
function ColorSpaces.parseHex(text: string): { number }?
	local hex = string.gsub(string.gsub(text, "%s+", ""), "^#", "")
	if #hex == 3 then
		hex = string.gsub(hex, ".", "%0%0")
	end
	if #hex ~= 6 or string.find(hex, "[^%x]") then
		return nil
	end
	local n = tonumber(hex, 16)
	if n == nil then
		return nil
	end
	return { (n // 65536) / 255, ((n // 256) % 256) / 255, (n % 256) / 255 }
end

return ColorSpaces
