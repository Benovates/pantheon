--!strict
local Calendar = {}

Calendar.MONTHS_SHORT = {
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Oct",
	"Nov",
	"Dec",
}

Calendar.MONTHS_LONG = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

function Calendar.daysInMonth(year: number, month: number): number
	local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if month == 2 then
		local leap = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
		return if leap then 29 else 28
	end
	return days[month] or 30
end

function Calendar.parseISO(iso: string): (number?, number?, number?)
	local y, m, d = string.match(iso, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not y then
		return nil, nil, nil
	end
	return tonumber(y), tonumber(m), tonumber(d)
end

function Calendar.formatISO(year: number, month: number, day: number): string
	return string.format("%04d-%02d-%02d", year, month, day)
end

function Calendar.weekday(year: number, month: number, day: number): number
	-- Sakamoto; 0=Sunday
	local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
	local y = year
	if month < 3 then
		y -= 1
	end
	return (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + t[month] + day) % 7
end

return Calendar
