--!strict
local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local function resolveTheme(props: { Theme: Types.ThemeRef? }?): Types.Theme
	return Theme.resolve(props)
end

return {
	resolveTheme = resolveTheme,
}
