--!nonstrict
--[[
	Fusion 0.3's `checkLifetime.bOutlivesA` is a debug diagnostic run on every
	`use()` / Spring / Observer binding. When both objects share a scope it scans
	that scope backwards, so cost grows with scope size: in a Script Profiler
	capture `whichLivesLonger` was ~75% of all RenderStepped script time.

	We wrap it so it only runs when `Flags.LifetimeChecks` is true:

		EstuaryUI.Flags.LifetimeChecks = true  -- re-enable Fusion's lifetime warnings

	Fusion exposes no switch for this, so we patch the table field its own
	modules call through. Fails soft: if the layout changes, nothing is patched.
]]
local Flags = require(script.Parent.Flags)

local patched = false

local function findCheckLifetime(): any?
	local index = script.Parent.Parent.Parent:FindFirstChild("_Index")
	if index == nil then
		return nil
	end
	for _, pkg in index:GetChildren() do
		if string.sub(pkg.Name, 1, 14) == "elttob_fusion@" then
			local fusion = pkg:FindFirstChild("fusion")
			local memory = fusion and fusion:FindFirstChild("Memory")
			local module = memory and memory:FindFirstChild("checkLifetime")
			if module and module:IsA("ModuleScript") then
				return require(module)
			end
		end
	end
	return nil
end

local function apply()
	if patched then
		return
	end
	local ok, checkLifetime = pcall(findCheckLifetime)
	if not ok or type(checkLifetime) ~= "table" or type(checkLifetime.bOutlivesA) ~= "function" then
		return
	end
	patched = true
	local original = checkLifetime.bOutlivesA
	checkLifetime.bOutlivesA = function(...)
		if Flags.LifetimeChecks then
			return original(...)
		end
		return nil
	end
end

return { apply = apply }
