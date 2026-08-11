--!strict
--[[
	Field validators — return (ok, message?).
]]
export type Validator = (value: any) -> (boolean, string?)

local Validators = {}

function Validators.required(message: string?): Validator
	local msg = message or "Required"
	return function(value)
		if value == nil or value == "" then
			return false, msg
		end
		if type(value) == "table" and #value == 0 then
			return false, msg
		end
		return true, nil
	end
end

function Validators.minLength(n: number, message: string?): Validator
	local msg = message or (`At least {n} characters`)
	return function(value)
		local s = tostring(value or "")
		if #s < n then
			return false, msg
		end
		return true, nil
	end
end

function Validators.maxLength(n: number, message: string?): Validator
	local msg = message or (`At most {n} characters`)
	return function(value)
		local s = tostring(value or "")
		if #s > n then
			return false, msg
		end
		return true, nil
	end
end

function Validators.email(message: string?): Validator
	local msg = message or "Enter a valid email"
	return function(value)
		local s = tostring(value or "")
		if s == "" then
			return true, nil
		end
		if not string.find(s, "^[%w%._%+%-]+@[%w%.%-]+%.%w+$") then
			return false, msg
		end
		return true, nil
	end
end

function Validators.pattern(pat: string, message: string?): Validator
	local msg = message or "Invalid format"
	return function(value)
		local s = tostring(value or "")
		if s == "" then
			return true, nil
		end
		if not string.find(s, pat) then
			return false, msg
		end
		return true, nil
	end
end

function Validators.numberRange(minV: number?, maxV: number?, message: string?): Validator
	local msg = message or "Out of range"
	return function(value)
		local n = tonumber(value)
		if n == nil then
			return false, msg
		end
		if minV ~= nil and n < minV then
			return false, msg
		end
		if maxV ~= nil and n > maxV then
			return false, msg
		end
		return true, nil
	end
end

function Validators.all(list: { Validator }): Validator
	return function(value)
		for _, v in list do
			local ok, err = v(value)
			if not ok then
				return false, err
			end
		end
		return true, nil
	end
end

function Validators.run(list: { Validator }?, value: any): (boolean, string?)
	if list == nil or #list == 0 then
		return true, nil
	end
	return Validators.all(list)(value)
end

return Validators
