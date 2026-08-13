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

function Layer.asGui(inst: Instance?): GuiObject?
	if inst ~= nil and inst:IsA("GuiObject") then
		return inst
	end
	return nil
end

function Layer.resolve(props: { Layer: Instance? }?): GuiObject?
	if props and props.Layer ~= nil then
		local layer = props.Layer
		if layer:IsA("GuiObject") then
			return layer
		end
		return nil
	end
	return Layer.use()
end

--- Set the fallback overlay layer (e.g. Window chrome) for mounts without an explicit Layer prop.
function Layer.bind(layer: Instance?)
	if layer ~= nil and layer:IsA("GuiObject") then
		rootLayer = layer
	else
		rootLayer = nil
	end
end

--[[
	Parent `instance` onto the resolved overlay layer when one exists.
	Returns true if mounted to a layer (caller should not also put it in layout).
]]
function Layer.mount(scope: Types.Scope, props: { Layer: Instance? }?, instance: Instance): boolean
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
