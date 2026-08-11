--!strict
--[[
	Overlay layer: parent modals / menus / toasts to a top-level UI frame
	so they do not participate in content layout.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)

local layerContext = Fusion.Contextual(nil :: GuiObject?)
local rootLayer: GuiObject? = nil

local Layer = {}

function Layer.Provide<T...>(layer: GuiObject, callback: (T...) -> ...any, ...: T...): ...any
	rootLayer = layer
	return layerContext:is(layer):during(callback, ...)
end

function Layer.use(): GuiObject?
	return layerContext:now() or rootLayer
end

function Layer.resolve(props: { Layer: GuiObject? }?): GuiObject?
	if props and props.Layer ~= nil then
		return props.Layer
	end
	return Layer.use()
end

--[[
	Parent `instance` onto the resolved overlay layer when one exists.
	Returns true if mounted to a layer (caller should not also put it in layout).
]]
function Layer.mount(scope: Types.Scope, props: { Layer: GuiObject? }?, instance: Instance): boolean
	local layer = Layer.resolve(props)
	if layer == nil then
		return false
	end
	instance.Parent = layer
	table.insert(scope, function()
		if instance.Parent == layer then
			instance.Parent = nil
		end
	end)
	return true
end

Layer.Contextual = layerContext

return Layer
