--!strict
local Types = require(script.Parent.Parent.Types)
local Select = require(script.Parent.Select)

return function(scope: Types.Scope, props: Types.SelectProps): Frame
	local nextProps = table.clone(props) :: any
	nextProps.Filterable = true
	return Select(scope, nextProps)
end
