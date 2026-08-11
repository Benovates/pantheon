--!strict
--[[
	Cast Fusion/Iona instance prop bags.

	Luau free-infers tables with multiple Fusion SpecialKeys (OnEvent, Children, …)
	as one indexer and unifies their value types — so
	`[OnEvent]=fn` + `[Children]=kids` becomes "expected (() -> ())?, got {Instance}".

	Annotating the parameter as `{[any]: any}` gives the table literal an open
	expected type so both SpecialKeys typecheck.
]]
return function(props: { [any]: any }): { [any]: any }
	return props
end
