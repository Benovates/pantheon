--!strict
--[[
	Material Design 2014 color system (MDC palette).
	Access: Material.Blue[500], Material.get("Blue 500"), Color = "Blue 500"
]]

export type MaterialShade = number | string
export type MaterialHue = { [MaterialShade]: Color3 }

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

local Material = {}

Material.Red = {
	[50] = hex("#ffebee"),
	[100] = hex("#ffcdd2"),
	[200] = hex("#ef9a9a"),
	[300] = hex("#e57373"),
	[400] = hex("#ef5350"),
	[500] = hex("#f44336"),
	[600] = hex("#e53935"),
	[700] = hex("#d32f2f"),
	[800] = hex("#c62828"),
	[900] = hex("#b71c1c"),
	["A100"] = hex("#ff8a80"),
	A100 = hex("#ff8a80"),
	["A200"] = hex("#ff5252"),
	A200 = hex("#ff5252"),
	["A400"] = hex("#ff1744"),
	A400 = hex("#ff1744"),
	["A700"] = hex("#d50000"),
	A700 = hex("#d50000"),
}

Material.Pink = {
	[50] = hex("#fce4ec"),
	[100] = hex("#f8bbd0"),
	[200] = hex("#f48fb1"),
	[300] = hex("#f06292"),
	[400] = hex("#ec407a"),
	[500] = hex("#e91e63"),
	[600] = hex("#d81b60"),
	[700] = hex("#c2185b"),
	[800] = hex("#ad1457"),
	[900] = hex("#880e4f"),
	["A100"] = hex("#ff80ab"),
	A100 = hex("#ff80ab"),
	["A200"] = hex("#ff4081"),
	A200 = hex("#ff4081"),
	["A400"] = hex("#f50057"),
	A400 = hex("#f50057"),
	["A700"] = hex("#c51162"),
	A700 = hex("#c51162"),
}

Material.Purple = {
	[50] = hex("#f3e5f5"),
	[100] = hex("#e1bee7"),
	[200] = hex("#ce93d8"),
	[300] = hex("#ba68c8"),
	[400] = hex("#ab47bc"),
	[500] = hex("#9c27b0"),
	[600] = hex("#8e24aa"),
	[700] = hex("#7b1fa2"),
	[800] = hex("#6a1b9a"),
	[900] = hex("#4a148c"),
	["A100"] = hex("#ea80fc"),
	A100 = hex("#ea80fc"),
	["A200"] = hex("#e040fb"),
	A200 = hex("#e040fb"),
	["A400"] = hex("#d500f9"),
	A400 = hex("#d500f9"),
	["A700"] = hex("#aa00ff"),
	A700 = hex("#aa00ff"),
}

Material.DeepPurple = {
	[50] = hex("#ede7f6"),
	[100] = hex("#d1c4e9"),
	[200] = hex("#b39ddb"),
	[300] = hex("#9575cd"),
	[400] = hex("#7e57c2"),
	[500] = hex("#673ab7"),
	[600] = hex("#5e35b1"),
	[700] = hex("#512da8"),
	[800] = hex("#4527a0"),
	[900] = hex("#311b92"),
	["A100"] = hex("#b388ff"),
	A100 = hex("#b388ff"),
	["A200"] = hex("#7c4dff"),
	A200 = hex("#7c4dff"),
	["A400"] = hex("#651fff"),
	A400 = hex("#651fff"),
	["A700"] = hex("#6200ea"),
	A700 = hex("#6200ea"),
}

Material.Indigo = {
	[50] = hex("#e8eaf6"),
	[100] = hex("#c5cae9"),
	[200] = hex("#9fa8da"),
	[300] = hex("#7986cb"),
	[400] = hex("#5c6bc0"),
	[500] = hex("#3f51b5"),
	[600] = hex("#3949ab"),
	[700] = hex("#303f9f"),
	[800] = hex("#283593"),
	[900] = hex("#1a237e"),
	["A100"] = hex("#8c9eff"),
	A100 = hex("#8c9eff"),
	["A200"] = hex("#536dfe"),
	A200 = hex("#536dfe"),
	["A400"] = hex("#3d5afe"),
	A400 = hex("#3d5afe"),
	["A700"] = hex("#304ffe"),
	A700 = hex("#304ffe"),
}

Material.Blue = {
	[50] = hex("#e3f2fd"),
	[100] = hex("#bbdefb"),
	[200] = hex("#90caf9"),
	[300] = hex("#64b5f6"),
	[400] = hex("#42a5f5"),
	[500] = hex("#2196f3"),
	[600] = hex("#1e88e5"),
	[700] = hex("#1976d2"),
	[800] = hex("#1565c0"),
	[900] = hex("#0d47a1"),
	["A100"] = hex("#82b1ff"),
	A100 = hex("#82b1ff"),
	["A200"] = hex("#448aff"),
	A200 = hex("#448aff"),
	["A400"] = hex("#2979ff"),
	A400 = hex("#2979ff"),
	["A700"] = hex("#2962ff"),
	A700 = hex("#2962ff"),
}

Material.LightBlue = {
	[50] = hex("#e1f5fe"),
	[100] = hex("#b3e5fc"),
	[200] = hex("#81d4fa"),
	[300] = hex("#4fc3f7"),
	[400] = hex("#29b6f6"),
	[500] = hex("#03a9f4"),
	[600] = hex("#039be5"),
	[700] = hex("#0288d1"),
	[800] = hex("#0277bd"),
	[900] = hex("#01579b"),
	["A100"] = hex("#80d8ff"),
	A100 = hex("#80d8ff"),
	["A200"] = hex("#40c4ff"),
	A200 = hex("#40c4ff"),
	["A400"] = hex("#00b0ff"),
	A400 = hex("#00b0ff"),
	["A700"] = hex("#0091ea"),
	A700 = hex("#0091ea"),
}

Material.Cyan = {
	[50] = hex("#e0f7fa"),
	[100] = hex("#b2ebf2"),
	[200] = hex("#80deea"),
	[300] = hex("#4dd0e1"),
	[400] = hex("#26c6da"),
	[500] = hex("#00bcd4"),
	[600] = hex("#00acc1"),
	[700] = hex("#0097a7"),
	[800] = hex("#00838f"),
	[900] = hex("#006064"),
	["A100"] = hex("#84ffff"),
	A100 = hex("#84ffff"),
	["A200"] = hex("#18ffff"),
	A200 = hex("#18ffff"),
	["A400"] = hex("#00e5ff"),
	A400 = hex("#00e5ff"),
	["A700"] = hex("#00b8d4"),
	A700 = hex("#00b8d4"),
}

Material.Teal = {
	[50] = hex("#e0f2f1"),
	[100] = hex("#b2dfdb"),
	[200] = hex("#80cbc4"),
	[300] = hex("#4db6ac"),
	[400] = hex("#26a69a"),
	[500] = hex("#009688"),
	[600] = hex("#00897b"),
	[700] = hex("#00796b"),
	[800] = hex("#00695c"),
	[900] = hex("#004d40"),
	["A100"] = hex("#a7ffeb"),
	A100 = hex("#a7ffeb"),
	["A200"] = hex("#64ffda"),
	A200 = hex("#64ffda"),
	["A400"] = hex("#1de9b6"),
	A400 = hex("#1de9b6"),
	["A700"] = hex("#00bfa5"),
	A700 = hex("#00bfa5"),
}

Material.Green = {
	[50] = hex("#e8f5e9"),
	[100] = hex("#c8e6c9"),
	[200] = hex("#a5d6a7"),
	[300] = hex("#81c784"),
	[400] = hex("#66bb6a"),
	[500] = hex("#4caf50"),
	[600] = hex("#43a047"),
	[700] = hex("#388e3c"),
	[800] = hex("#2e7d32"),
	[900] = hex("#1b5e20"),
	["A100"] = hex("#b9f6ca"),
	A100 = hex("#b9f6ca"),
	["A200"] = hex("#69f0ae"),
	A200 = hex("#69f0ae"),
	["A400"] = hex("#00e676"),
	A400 = hex("#00e676"),
	["A700"] = hex("#00c853"),
	A700 = hex("#00c853"),
}

Material.LightGreen = {
	[50] = hex("#f1f8e9"),
	[100] = hex("#dcedc8"),
	[200] = hex("#c5e1a5"),
	[300] = hex("#aed581"),
	[400] = hex("#9ccc65"),
	[500] = hex("#8bc34a"),
	[600] = hex("#7cb342"),
	[700] = hex("#689f38"),
	[800] = hex("#558b2f"),
	[900] = hex("#33691e"),
	["A100"] = hex("#ccff90"),
	A100 = hex("#ccff90"),
	["A200"] = hex("#b2ff59"),
	A200 = hex("#b2ff59"),
	["A400"] = hex("#76ff03"),
	A400 = hex("#76ff03"),
	["A700"] = hex("#64dd17"),
	A700 = hex("#64dd17"),
}

Material.Lime = {
	[50] = hex("#f9fbe7"),
	[100] = hex("#f0f4c3"),
	[200] = hex("#e6ee9c"),
	[300] = hex("#dce775"),
	[400] = hex("#d4e157"),
	[500] = hex("#cddc39"),
	[600] = hex("#c0ca33"),
	[700] = hex("#afb42b"),
	[800] = hex("#9e9d24"),
	[900] = hex("#827717"),
	["A100"] = hex("#f4ff81"),
	A100 = hex("#f4ff81"),
	["A200"] = hex("#eeff41"),
	A200 = hex("#eeff41"),
	["A400"] = hex("#c6ff00"),
	A400 = hex("#c6ff00"),
	["A700"] = hex("#aeea00"),
	A700 = hex("#aeea00"),
}

Material.Yellow = {
	[50] = hex("#fffde7"),
	[100] = hex("#fff9c4"),
	[200] = hex("#fff59d"),
	[300] = hex("#fff176"),
	[400] = hex("#ffee58"),
	[500] = hex("#ffeb3b"),
	[600] = hex("#fdd835"),
	[700] = hex("#fbc02d"),
	[800] = hex("#f9a825"),
	[900] = hex("#f57f17"),
	["A100"] = hex("#ffff8d"),
	A100 = hex("#ffff8d"),
	["A200"] = hex("#ffff00"),
	A200 = hex("#ffff00"),
	["A400"] = hex("#ffea00"),
	A400 = hex("#ffea00"),
	["A700"] = hex("#ffd600"),
	A700 = hex("#ffd600"),
}

Material.Amber = {
	[50] = hex("#fff8e1"),
	[100] = hex("#ffecb3"),
	[200] = hex("#ffe082"),
	[300] = hex("#ffd54f"),
	[400] = hex("#ffca28"),
	[500] = hex("#ffc107"),
	[600] = hex("#ffb300"),
	[700] = hex("#ffa000"),
	[800] = hex("#ff8f00"),
	[900] = hex("#ff6f00"),
	["A100"] = hex("#ffe57f"),
	A100 = hex("#ffe57f"),
	["A200"] = hex("#ffd740"),
	A200 = hex("#ffd740"),
	["A400"] = hex("#ffc400"),
	A400 = hex("#ffc400"),
	["A700"] = hex("#ffab00"),
	A700 = hex("#ffab00"),
}

Material.Orange = {
	[50] = hex("#fff3e0"),
	[100] = hex("#ffe0b2"),
	[200] = hex("#ffcc80"),
	[300] = hex("#ffb74d"),
	[400] = hex("#ffa726"),
	[500] = hex("#ff9800"),
	[600] = hex("#fb8c00"),
	[700] = hex("#f57c00"),
	[800] = hex("#ef6c00"),
	[900] = hex("#e65100"),
	["A100"] = hex("#ffd180"),
	A100 = hex("#ffd180"),
	["A200"] = hex("#ffab40"),
	A200 = hex("#ffab40"),
	["A400"] = hex("#ff9100"),
	A400 = hex("#ff9100"),
	["A700"] = hex("#ff6d00"),
	A700 = hex("#ff6d00"),
}

Material.DeepOrange = {
	[50] = hex("#fbe9e7"),
	[100] = hex("#ffccbc"),
	[200] = hex("#ffab91"),
	[300] = hex("#ff8a65"),
	[400] = hex("#ff7043"),
	[500] = hex("#ff5722"),
	[600] = hex("#f4511e"),
	[700] = hex("#e64a19"),
	[800] = hex("#d84315"),
	[900] = hex("#bf360c"),
	["A100"] = hex("#ff9e80"),
	A100 = hex("#ff9e80"),
	["A200"] = hex("#ff6e40"),
	A200 = hex("#ff6e40"),
	["A400"] = hex("#ff3d00"),
	A400 = hex("#ff3d00"),
	["A700"] = hex("#dd2c00"),
	A700 = hex("#dd2c00"),
}

Material.Brown = {
	[50] = hex("#efebe9"),
	[100] = hex("#d7ccc8"),
	[200] = hex("#bcaaa4"),
	[300] = hex("#a1887f"),
	[400] = hex("#8d6e63"),
	[500] = hex("#795548"),
	[600] = hex("#6d4c41"),
	[700] = hex("#5d4037"),
	[800] = hex("#4e342e"),
	[900] = hex("#3e2723"),
}

Material.Grey = {
	[50] = hex("#fafafa"),
	[100] = hex("#f5f5f5"),
	[200] = hex("#eeeeee"),
	[300] = hex("#e0e0e0"),
	[400] = hex("#bdbdbd"),
	[500] = hex("#9e9e9e"),
	[600] = hex("#757575"),
	[700] = hex("#616161"),
	[800] = hex("#424242"),
	[900] = hex("#212121"),
}

Material.BlueGrey = {
	[50] = hex("#eceff1"),
	[100] = hex("#cfd8dc"),
	[200] = hex("#b0bec5"),
	[300] = hex("#90a4ae"),
	[400] = hex("#78909c"),
	[500] = hex("#607d8b"),
	[600] = hex("#546e7a"),
	[700] = hex("#455a64"),
	[800] = hex("#37474f"),
	[900] = hex("#263238"),
}

Material.Black = hex("#000000")
Material.White = hex("#ffffff")

Material.Gray = Material.Grey
Material.BlueGray = Material.BlueGrey

local HUES: { [string]: MaterialHue } = {
	red = Material.Red,
	pink = Material.Pink,
	purple = Material.Purple,
	deeppurple = Material.DeepPurple,
	indigo = Material.Indigo,
	blue = Material.Blue,
	lightblue = Material.LightBlue,
	cyan = Material.Cyan,
	teal = Material.Teal,
	green = Material.Green,
	lightgreen = Material.LightGreen,
	lime = Material.Lime,
	yellow = Material.Yellow,
	amber = Material.Amber,
	orange = Material.Orange,
	deeporange = Material.DeepOrange,
	brown = Material.Brown,
	grey = Material.Grey,
	bluegrey = Material.BlueGrey,
	gray = Material.Grey,
	bluegray = Material.BlueGrey,
	deeppurple = Material.DeepPurple,
	lightblue = Material.LightBlue,
	lightgreen = Material.LightGreen,
	deeporange = Material.DeepOrange,
	bluegrey = Material.BlueGrey,
}

HUES["red"] = Material.Red
HUES["pink"] = Material.Pink
HUES["purple"] = Material.Purple
HUES["deeppurple"] = Material.DeepPurple
HUES["indigo"] = Material.Indigo
HUES["blue"] = Material.Blue
HUES["lightblue"] = Material.LightBlue
HUES["cyan"] = Material.Cyan
HUES["teal"] = Material.Teal
HUES["green"] = Material.Green
HUES["lightgreen"] = Material.LightGreen
HUES["lime"] = Material.Lime
HUES["yellow"] = Material.Yellow
HUES["amber"] = Material.Amber
HUES["orange"] = Material.Orange
HUES["deeporange"] = Material.DeepOrange
HUES["brown"] = Material.Brown
HUES["grey"] = Material.Grey
HUES["bluegrey"] = Material.BlueGrey

local function normalizeHue(name: string): string
	local key = string.lower(name)
	key = string.gsub(key, "[%s_-]+", "")
	return key
end

local function normalizeShade(shade: any): string
	if typeof(shade) == "number" then
		return tostring(math.floor(shade))
	end
	local s = string.upper(tostring(shade))
	s = string.gsub(s, "^A", "A")
	return s
end

function Material.getHue(name: string): MaterialHue?
	return HUES[normalizeHue(name)]
end

function Material.get(hueOrSwatch: string, shade: MaterialShade?): Color3?
	local rawName = hueOrSwatch
	local shadeKey: string? = if shade ~= nil then normalizeShade(shade) else nil

	-- Parse "Blue 500", "blue.500", "Blue-A200", "deepPurple500"
	if shadeKey == nil then
		local huePart, shadePart = string.match(rawName, "^([%a][%a%s_-]-)%s*[%.%s_-]?([Aa]?%d%d%d?)$")
		if huePart and shadePart then
			rawName = huePart
			shadeKey = normalizeShade(shadePart)
		end
	end

	local hue = Material.getHue(rawName)
	if not hue then
		return nil
	end

	-- Default shade 500 when only hue given
	local key = shadeKey or "500"
	local value: Color3? = hue[key]
	if value == nil then
		local n = tonumber(key)
		if n ~= nil then
			value = (hue :: any)[n]
		end
	end
	if value == nil and string.sub(key, 1, 1) == "A" then
		value = hue[key] or hue[string.upper(key)]
	end
	return value
end

Material.Hues = HUES

return Material
