--!strict
--[[
	CanvasGroup fade for appearing / disappearing chrome.

	When Flags.CanvasFade is on (default): wrap the target once and drive
	GroupTransparency from the caller's open progress. When off (or ReduceMotion):
	callers keep their previous BackgroundTransparency springs.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local Flags = require(script.Parent.Flags)
local resolveTheme = require(script.Parent.resolveTheme).resolveTheme

local peek = Fusion.peek
local Children = Fusion.Children

export type FadeKind = "In" | "Out"

export type FadeOpts = {
	Theme: Types.ThemeRef?,
	Kind: FadeKind?,
	OnFinished: (() -> ())?,
}

export type BindOpts = {
	Theme: Types.ThemeRef?,
}

local CanvasFade = {}

local function reduceMotion(opts: FadeOpts | BindOpts | nil): boolean
	local ok, theme = pcall(function()
		return resolveTheme(opts or {})
	end)
	if ok and theme and theme.Accessibility then
		return theme.Accessibility.ReduceMotion == true
	end
	return false
end

function CanvasFade.enabled(): boolean
	return Flags.CanvasFade == true
end

--- Flag on and motion allowed — wrap + opaque surfaces. Otherwise old transparency fades.
function CanvasFade.active(opts: FadeOpts | BindOpts | nil): boolean
	return CanvasFade.enabled() and not reduceMotion(opts)
end

local function readProgress(use: (any) -> any, ref: any): number
	local v = if typeof(ref) == "table" then use(ref) else ref
	if typeof(v) == "number" then
		return v
	end
	return if v then 1 else 0
end

--- Panel fill when fading: opaque under CanvasGroup, 1−progress otherwise.
function CanvasFade.surfaceTransparency(scope: Types.Scope, progress: any, opts: BindOpts?): any
	return scope:Computed(function(use)
		if CanvasFade.active(opts) then
			return 0
		end
		return 1 - readProgress(use, progress)
	end)
end

--- Visible from open progress (and optional extra). The wrap uses the same threshold.
function CanvasFade.shown(scope: Types.Scope, progress: any, extra: ((any) -> boolean)?, _opts: BindOpts?): any
	return scope:Computed(function(use)
		if extra and not extra(use) then
			return false
		end
		return readProgress(use, progress) > 0.02
	end)
end

local ZERO_POS = UDim2.fromScale(0, 0)
local FILL = UDim2.fromScale(1, 1)

local function existingWrap(target: GuiObject): CanvasGroup?
	if target:GetAttribute("EstuaryFadeWrap") == true then
		local parent = target.Parent
		if parent and parent:IsA("CanvasGroup") and parent.Name == "FadeWrap" then
			return parent
		end
	end
	return nil
end

local function wrapTarget(scope: Types.Scope, target: GuiObject, progress: any): CanvasGroup
	local found = existingWrap(target)
	if found then
		return found
	end

	local auto = target.AutomaticSize
	local group = scope:CanvasGroup({
		Name = "FadeWrap",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = target.Size,
		AutomaticSize = auto,
		Position = target.Position,
		AnchorPoint = target.AnchorPoint,
		LayoutOrder = target.LayoutOrder,
		ZIndex = target.ZIndex,
		GroupTransparency = scope:Computed(function(use)
			return 1 - readProgress(use, progress)
		end),
		Visible = scope:Computed(function(use)
			return readProgress(use, progress) > 0.02
		end),
		-- Fusion owns this parent; never assign target.Parent directly.
		[Children] = { target },
	}) :: CanvasGroup
	target:SetAttribute("EstuaryFadeWrap", true)
	target.Position = UDim2.fromScale(0.5, 0.5)
	target.AnchorPoint = Vector2.new(0.5, 0.5)
	if auto == Enum.AutomaticSize.None then
		target.Size = FILL
	end

	table.insert(
		scope,
		target:GetPropertyChangedSignal("Position"):Connect(function()
			local pos = target.Position
			if pos == ZERO_POS then
				return
			end
			group.Position = pos
			target.Position = ZERO_POS
		end)
	)
	table.insert(
		scope,
		target:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
			local a = target.AnchorPoint
			if a == Vector2.zero then
				return
			end
			group.AnchorPoint = a
			target.AnchorPoint = Vector2.zero
		end)
	)
	table.insert(
		scope,
		target:GetPropertyChangedSignal("LayoutOrder"):Connect(function()
			group.LayoutOrder = target.LayoutOrder
		end)
	)
	table.insert(
		scope,
		target:GetPropertyChangedSignal("ZIndex"):Connect(function()
			group.ZIndex = target.ZIndex
		end)
	)
	if auto == Enum.AutomaticSize.None then
		table.insert(
			scope,
			target:GetPropertyChangedSignal("Size"):Connect(function()
				local size = target.Size
				if size == FILL then
					return
				end
				group.Size = size
				target.Size = FILL
			end)
		)
	end

	return group
end

--- Wrap `target` in a CanvasGroup using Fusion Children. Put the returned
--- instance in the tree (not `target`) so Fusion never fights a reparent.
function CanvasFade.host(scope: Types.Scope, target: GuiObject, open: any, opts: BindOpts?): GuiObject
	if not CanvasFade.active(opts) then
		return target
	end
	return wrapTarget(scope, target, open)
end

--- Same as host(). Do not call after Fusion has already parented `target`.
function CanvasFade.bind(scope: Types.Scope, target: GuiObject, open: any, opts: BindOpts?): GuiObject
	return CanvasFade.host(scope, target, open, opts)
end

local function restore(target: GuiObject, group: CanvasGroup)
	local parent = group.Parent
	if target.Parent == group then
		target.Parent = parent
	end
	target:SetAttribute("EstuaryFadeWrap", nil)
	target.LayoutOrder = group.LayoutOrder
	target.ZIndex = group.ZIndex
	target.Size = group.Size
	target.AutomaticSize = group.AutomaticSize
	target.Position = group.Position
	target.AnchorPoint = group.AnchorPoint
	group:Destroy()
end

--- One-shot fade. Falls back to Visible when the flag is off.
function CanvasFade.play(scope: Types.Scope, target: GuiObject, opts: FadeOpts?): CanvasGroup?
	local options: FadeOpts = opts or {}
	local kind: FadeKind = options.Kind or "In"
	local finish = options.OnFinished
	local instant = not CanvasFade.active(options)

	if instant then
		if kind == "Out" then
			target.Visible = false
		else
			target.Visible = true
		end
		if finish then
			task.defer(finish)
		end
		return nil
	end

	local parent = target.Parent
	if parent == nil then
		if finish then
			task.defer(finish)
		end
		return nil
	end

	local theme = resolveTheme(options)
	local from = if kind == "Out" then 0 else 1
	local to = if kind == "Out" then 1 else 0
	local goal = scope:Value(from)
	local sprung = scope:Spring(goal, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)

	local group = scope:CanvasGroup({
		Name = "FadeWrap",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = target.Size,
		AutomaticSize = target.AutomaticSize,
		Position = target.Position,
		AnchorPoint = target.AnchorPoint,
		LayoutOrder = target.LayoutOrder,
		ZIndex = target.ZIndex,
		Visible = true,
		GroupTransparency = sprung,
		[Children] = {},
	}) :: CanvasGroup
	group.Parent = parent
	target:SetAttribute("EstuaryFadeWrap", true)
	target.Parent = group
	target.Position = ZERO_POS
	target.AnchorPoint = Vector2.zero
	if target.AutomaticSize == Enum.AutomaticSize.None then
		target.Size = FILL
	end

	local done = false
	local function settle()
		if done then
			return
		end
		done = true
		restore(target, group)
		if kind == "Out" then
			target.Visible = false
		end
		if finish then
			finish()
		end
	end

	goal:set(to)
	table.insert(
		scope,
		scope:Observer(sprung):onChange(function()
			if math.abs(peek(sprung) - to) < 0.03 then
				settle()
			end
		end)
	)
	task.delay(1.2, settle)
	table.insert(scope, settle)

	return group
end

function CanvasFade.fadeIn(scope: Types.Scope, target: GuiObject, opts: FadeOpts?): CanvasGroup?
	return CanvasFade.play(scope, target, {
		Theme = if opts then opts.Theme else nil,
		Kind = "In",
		OnFinished = if opts then opts.OnFinished else nil,
	})
end

function CanvasFade.fadeOut(scope: Types.Scope, target: GuiObject, opts: FadeOpts?): CanvasGroup?
	return CanvasFade.play(scope, target, {
		Theme = if opts then opts.Theme else nil,
		Kind = "Out",
		OnFinished = if opts then opts.OnFinished else nil,
	})
end

return CanvasFade
