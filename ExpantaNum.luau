--!optimize 2
--!native
--[[
	Original OmegaNum script: @FoundForces
	expantanum: prokingnoob2513 (limit: 10{{1}}1.79e308)
]]

--[[
Functions,

correct 
fromNumber 
toNumber 
toDisplay 
toString 
fromString 
toExpanta 
eq 
le 
me 
meeq 
leeq 
abs 
neg 
cmp 
max 
min 
log10 
isint
recip 
pow 
mod 
root 
mul 
floor 
ceil 
div 
add 
sub 
sqrt 
log 
exp 
maxabs 
pow10 
gamma 
fact 
rand 
exporand 
toBigNum 
toScientific 
toShortScientific 
short 
toEnt 
toShortEnt 
toEs 
toShortEs 
toHyperE (only works IF num < 10{9007199254740992}10)
toShortHyperE (only works IF num < 10{9007199254740992}10)
lambertw 
slog
pentlog
tetrate 
pentate 
arrow (only works IF x = 10)
lbencode (soon)
lbdecode (soon)

]]

local amoes = 5
local PrecisionDisplay = 3
local toScientific = 1e306
local maxCommas = 9 -- Max available: 22 numbers with commas. Optimal: 6-9 number
local maxArrows = 5 -- for toDisplay
local maxEs = 10
local maxHyperions = 10 -- for hyper-E notation

----------- END OF CONFIGURABLE DEFAULTS -------------

export type ExpantaNum = {
	sign: number, -- 1 = posiive, -1 = negative
	exponants: {number}, -- i1 = multi, i2 = exponant, i3 = tetrate, iN = 10{N-1}
	last: number, -- last index is 10{N}
	layer: number -- JJJJJ...JJJJexps J reps N times where Jn = 10{n}10
}
local maxAllowed = 1.797693015e308
local maxInt = 2^53-1
local NAN = 0/0
local INF = math.huge
local pi = math.pi
local ZERO: ExpantaNum = {1,{0},0,0}
local ONE: ExpantaNum = {1,{1},0,0}
local maxSuffix: ExpantaNum = {1,{maxInt,1},1,0}
local maxADD: ExpantaNum = {1,{maxInt,1},1,0}
local maxMUL: ExpantaNum = {1,{maxInt,2},1,0}
local maxScientific: ExpantaNum = {1,{300008,4},1,0}
local maxPOW: ExpantaNum = {1,{1,maxInt},1,0}
local maxTETR: ExpantaNum = {1,{10000000000,8,maxInt},2,0}
local maxPENT: ExpantaNum = {1,{10000000000,8,8,maxInt},3,0}
local maxOPS = 420 -- max N elements in array, 420 recommended for speed

local ExpantaNum = {}
local Number = {}
Number.__index = Number

--[[trunc = function (n)
	if math.ceil(n) == n then return n end
	if n < 0 then
		return -(math.floor(n))
	end
	return math.floor(n)
end]]

--[[
	Metatable creation function. Works as ExpantaNum.correct(x), but can be used with metamethods
]]

function ExpantaNum.new(val: number | string | {}): ExpantaNum
	local ExpantaNum = ExpantaNum.correct(val)

	return setmetatable(ExpantaNum, Number)
end

--[[
	Metamethods list:
		__unm fires ExpantaNum.neg(x) when -x is called
		__add fires ExpantaNum.add(x,y) when x+y is called
		__sub fires ExpantaNum.sub(x,y) when x-y is called
		__mul fires ExpantaNum.mul(x,y) when x*y is called
		__div fires ExpantaNum.div(x,y) when x/y is called
		__idiv fires ExpantaNum.floor(ExpantaNum.div(x,y)) when x//y is called
		__pow fires ExpantaNum.pow(x,y) when x^y is called
		__mod fires ExpantaNum.mod(x,y) when x%y is called
		__tostring works same as ExpantaNum.ToString(x) but fires when tostring(x) is called
	
	NOTE: These functions require metatables to work. Before doing them be sure that you used metatables functions to create/process the number
	
		__eq fires ExpantaNum.eq(x,y) when x==y is called
		__lt fires ExpantaNum.lt(x,y) when x<y is called
		__le fires ExpantaNum.le(x,y) when x<=y is called
		
	NOTE: Equation functions require two values with the same metamethod function. You won't be able to compare normal number and ExpantaNum table
]]

function Number.__add(x,y)
	local result = ExpantaNum.add(x,y)

	return setmetatable(result, Number)
end

function Number.__sub(x,y)
	local result = ExpantaNum.sub(x,y)

	return setmetatable(result, Number)
end

function Number.__mul(x,y)
	local result = ExpantaNum.mul(x,y)

	return setmetatable(result, Number)
end

function Number.__div(x,y)
	local result = ExpantaNum.div(x,y)

	return setmetatable(result, Number)
end

function Number.__idiv(x,y)
	local result = ExpantaNum.floor(ExpantaNum.div(x,y))

	return setmetatable(result, Number)
end

function Number.__pow(x,y)
	local result = ExpantaNum.pow(x,y)

	return setmetatable(result, Number)
end

function Number.__mod(x,y)
	local result = ExpantaNum.mod(x,y)

	return setmetatable(result, Number)
end

function Number.__unm(x)
	local result = ExpantaNum.neg(x)

	return setmetatable(result, Number)
end

--Causes printing problems (Prints string instead of table)
function Number.__tostring(x)
	local result = ExpantaNum.toString(x)

	return result
end

function Number.__eq(x,y)
	local isXValid = false

	if typeof(x) == "table" then
		if x[2] == y[2] then
			return true
		end

		if x[2] == x[2] then
			isXValid = true
		end
	end
	if isXValid then
		local newX = ExpantaNum.toExpanta(x)
		local newY = ExpantaNum.toExpanta(y)

		local result = ExpantaNum.cmp(newX,newY)

		return result == 0
	else
		return false
	end
end

function Number.__lt(x,y)
	local newX = ExpantaNum.toExpanta(x)
	local newY = ExpantaNum.toExpanta(y)

	local result = ExpantaNum.cmp(newX,newY)

	return result == -1
end

function Number.__le(x,y)
	local newX = ExpantaNum.toExpanta(x)
	local newY = ExpantaNum.toExpanta(y)

	local result = ExpantaNum.cmp(newX,newY)

	return result == -1 or result == 0
end

-- function __concat

--[[
	Just easy way to convert ExpantaNum table into required form
	
	Example of usage:
		local ExpantaNum = require(ReplicatedStorage.ExpantaNum)
		
		local number = ExpantaNum.new("[6,1]")
		
		print(number) --You'll get table {1,{1000000},0,0}
		print(number:ToNumber()) --You'll get number 1000000
]]

function Number:toNumber()
	local num = self

	return ExpantaNum.toNumber(num)
end

function Number:toString()
	local num = self

	return ExpantaNum.toString(num)
end

function Number:toEnt(toshort: boolean)
	local num = self

	if toshort then
		return ExpantaNum.toShortEnt(num)
	else
		return ExpantaNum.toEnt(num)
	end
end

function Number:toEs(toshort: boolean)
	local num = self

	if toshort then
		return ExpantaNum.toShortEs(num)
	else
		return ExpantaNum.toEs(num)
	end
end

function Number:toHyperE(toshort: boolean)
	local num = self

	if toshort then
		return ExpantaNum.toShortHyperE(num)
	else
		return ExpantaNum.toHyperE(num)
	end
end

function Number:toDisplay(toshort: boolean)
	local num = self

	return ExpantaNum.toDisplay(num,toshort)
end

function Number:ScientificNotation(toshort: boolean)
	local num = self

	if toshort then
		return ExpantaNum.toShortScientific(num)
	else
		return ExpantaNum.toScientific(num)
	end
end

function Number:Abbreviate()
	local num = self

	return ExpantaNum.abbreviate(num)
end

function Number:toExpanta()
	local num = self

	return ExpantaNum.toExpanta(num)
end

function Number:toBigNum()
	local num = self

	return ExpantaNum.toBigNum(num)
end

function Number:ConvertForLeaderboards()
	local num = self

	return ExpantaNum.lbencode(num)
end

function Number:ConvertFromLeaderboards()
	local num = self

	return ExpantaNum.lbdecode(num)
end

-- chaining functions inspired by alyanum
-- autofilled by ChatGPT </3
-- adding metatable to functions later

function Number:add(n) return setmetatable(ExpantaNum.add(self,n), Number) end
function Number:sub(n) return setmetatable(ExpantaNum.sub(self,n), Number) end
function Number:mul(n) return setmetatable(ExpantaNum.mul(self,n), Number) end
function Number:div(n) return setmetatable(ExpantaNum.div(self,n), Number) end
function Number:abs() return setmetatable(ExpantaNum.abs(self), Number) end
function Number:neg() return setmetatable(ExpantaNum.neg(self), Number) end
function Number:max(n) return setmetatable(ExpantaNum.max(self, n), Number) end
function Number:min(n) return setmetatable(ExpantaNum.min(self, n), Number) end

function Number:log10() return setmetatable(ExpantaNum.log10(self), Number) end
function Number:isint() return setmetatable(ExpantaNum.isint(self), Number) end
function Number:recip() return setmetatable(ExpantaNum.recip(self), Number) end
function Number:pow(n) return setmetatable(ExpantaNum.pow(self, n), Number) end
function Number:mod(n) return setmetatable(ExpantaNum.mod(self, n), Number) end
function Number:root(n) return setmetatable(ExpantaNum.root(self, n), Number) end
function Number:floor() return setmetatable(ExpantaNum.floor(self), Number) end
function Number:ceil() return setmetatable(ExpantaNum.ceil(self), Number) end

function Number:sqrt() return setmetatable(ExpantaNum.sqrt(self), Number) end
function Number:log(n) return setmetatable(ExpantaNum.log(self, n), Number) end
function Number:exp() return setmetatable(ExpantaNum.exp(self), Number) end
function Number:maxabs(n) return setmetatable(ExpantaNum.maxabs(self, n), Number) end
function Number:pow10() return setmetatable(ExpantaNum.pow10(self), Number) end
function Number:gamma() return setmetatable(ExpantaNum.gamma(self), Number) end
function Number:fact() return setmetatable(ExpantaNum.fact(self), Number) end

function Number:rand(n) return setmetatable(ExpantaNum.rand(self,n), Number) end
function Number:exporand(n) return setmetatable(ExpantaNum.exporand(self,n), Number) end
function Number:lambertw() return setmetatable(ExpantaNum.lambertw(self), Number) end

function Number:slog(n) return setmetatable(ExpantaNum.slog(self, n), Number) end
function Number:pentlog(n) return setmetatable(ExpantaNum.pentlog(self, n), Number) end
function Number:tetrate(n) return setmetatable(ExpantaNum.tetrate(self, n), Number) end
function Number:tetr(n) return setmetatable(ExpantaNum.tetrate(self, n), Number) end
function Number:pentate(n) return setmetatable(ExpantaNum.pentate(self, n), Number) end
function Number:pent(n) return setmetatable(ExpantaNum.pentate(self, n), Number) end
function Number:arrow(a, y) return setmetatable(ExpantaNum.arrow(self, a, y), Number) end

function Number:lt(o) return ExpantaNum.le(self, o) end
function Number:le(o) return ExpantaNum.leeq(self, o) end
function Number:mt(o) return ExpantaNum.me(self, o) end
function Number:me(o) return ExpantaNum.meeq(self, o) end

--[[
	Original ExpantaNum functions

	Some functions were a bit edited to fit metatables, but they work the same
	as the original ones.
]]

function fgamma(n)
	local C = {0.99999999999980993, 676.5203681218851, -1259.1392167224028,771.32342877765313, -176.61502916214059, 12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7}
	if math.floor(n) == n then
		return fact(n-1)
	end
	if (n > 0.5) then 
		n -= 1
		local x = C[1]
		for i=1,7 do
			x += C[i+1] / (n + i)
		end
		local t = n + 7.5
		return  x * t^(n+0.5 - 36) * math.exp(-t) * t^36 * 2.50662827463100050241576528
	end
	return 3.141592653589793238 / (math.sin(3.141592653589793238 * n) * fgamma(1 - n))
end

function f_lambertw(z)
	local tol = 1e-10
	local w,wn = nil
	if z > 1.79e308 then return z
	end
	if z == 0 then
		return z
	end
	if z == 1 then
		return 0.56714329040978387299997
	end
	if z < 10 then
		w = 0
	else
		w = math.log(z)-math.log(math.log(z))
	end
	for i=1,100 do
		wn = (z * math.exp(-w) + w * w)/(w + 1)
		if math.abs(wn - w) < tol*math.abs(wn) then
			return wn
		else
			w = wn
		end

	end
	warn("Failed at W")
	return 0/0
end

function Hlambertw(n)
	local tol = 1e-10
	n = ExpantaNum.correct(n)
	local wn;
	local w = ExpantaNum.log(n)
	for i=1,100 do
		wn = ExpantaNum.div(ExpantaNum.add(ExpantaNum.mul(n,ExpantaNum.exp(ExpantaNum.neg(w))),ExpantaNum.mul(w,w)),ExpantaNum.add(w,1))
		if ExpantaNum.le(ExpantaNum.abs(ExpantaNum.sub(wn,w)), ExpantaNum.mul(tol,ExpantaNum.abs(wn))) then
			return wn
		end
		w = wn
	end
	warn("Failed at hlam")
	return NAN
end

function ExpantaNum.correct(val: ExpantaNum): ExpantaNum
	-- keep it as it is
	if val == nil then 
		return ZERO 
	end
	if val ~= val then 
		return NAN 
	end
	if type(val) ~= 'table' then
		return ExpantaNum.toExpanta(val)
	end
	if type(val[2]) ~= "table" and #val == 4 then
		val = {math.sign(val[1]), {val[2] + math.log10(math.abs(val[1])),1}, 1, val[4]}
	end
	if type(val[2]) ~= "table" then
		val = {1,val,val[3],val[4]}
	end
	if #val[2] == 0 then
		return ZERO 
	end
	if (val[1] == 1 or val[1] == -1) and #val[2] == 1 and val[2][1] == 0 or  #val[2] == 2 and val[2][1] == 0  and val[2][2] == 0 then
		return {val[1],{0},0,0} 
	end
	if val[3] and val[3] < maxOPS then
		val[3] = #val[2]-1
	end
	-- {sign, {}, 0, 0}
	local qq = copytab(val)
	local sign = qq[1] or 1
	local array = qq[2] or {0}
	local last = qq[3] or 0
	local layer = qq[4] or 0
	local len = #array
	if qq[1] == 0 then return ZERO end

	local function remove0s()
		for i=len,1,-1 do
			if array[i] == 0 then
				table.remove(array)
				len -= 1
			else
				break
			end
		end
	end
	remove0s()

	if array[1] > maxInt then
		array[1] = math.log10(array[1])
		if len > 1 then
			array[2] += 1
		else
			table.insert(array, 1)
			if len < maxOPS then
				len += 1
			else
				-- move iN -> iN-1, iN-1 -> iN-2, ... , i3 -> i2 and then delete the last element
				for i=2,maxOPS,1 do array[i] = array[i+1] end
				table.remove(array)
				last += 1
			end
		end
	end

	-- handle 1,0,0,0,x
	if len > 2 then
		if array[2] < 3 then
			for i=1,array[2] do
				if array[i] >= math.log10(maxInt) then
					break
				elseif array[2] == 0 then
					break
				end
				array[i] = 10^array[i]
				array[2] -= 1
			end 
		end
		if array[2] == 0 then
			if array[1] == 1 then
				for i=2,len do
					if array[i] == 0 then
						continue
					elseif array[i] > 1 then
						break
					elseif array[i] == 1 and i == len then
						return setmetatable({sign, {10}, 0, layer} , Number)
					end
				end 
			end
			local LastZero = 2
			local OneEncountered = false
			for i=3,#array do
				if array[i] == 0 then
					LastZero = i
				elseif array[i] == 0 and OneEncountered then
					continue
				elseif array[i] == 1 and OneEncountered  then
					break
				elseif array[i] == 1  then
					OneEncountered = true
				else
					break
				end
			end
			if LastZero == len then
				return setmetatable({sign, {array[1]}, 0, layer} , Number)
			else
				local Mode = 1
				if array[1] == 1 then Mode = OneEncountered and 1 or 2 array[1] = 10 end
				array[LastZero] = array[1] - 2
				array[1] = 1e10
				for i=2,LastZero - 1 do
					array[i] = 8
				end
				array[LastZero + 1] -= Mode
				for i=#array,2,-1 do
					if array[i] == 0 then
						array[i] = nil
					else
						break
					end
				end
				-- Loop through LastZero
				--return {sign, array}
			end
		end
	end

	len = #array
	remove0s()

	if len > 1 then
		if array[1] < math.log10(maxInt) and array[2] > 0  then
			array[2] -= 1
			array[1] = 10^array[1]
			array[2] = (array[2] == 0) and nil or array[2] 
		end
		if array[1] < math.log10(maxInt) and array[2] > 0  then
			array[2] -= 1
			array[1] = 10^array[1]
			array[2] = (array[2] == 0) and nil or array[2] 
		end
	end
	for i=2,len do
		if array[i]>maxInt then
			array[1] = array[i]
			array[i+1] = (array[i+1] or 0)+1
			array[i]+=1
			for j=2,i do
				array[j] = 0
			end
			if array[1] > maxInt then
				array[1] = math.log10(array[1])
				array[2]+=1
			end
		end
	end

	-- Convert trailing zeros
	-- Remove trailing zeros
	-- loop until
	for i=1,#array do
		local cur = array[i]
		if cur == NAN then
			warn('correct() returning NAN')
			return qq
		end
		if cur==INF then
			return qq
		end
		if cur % 1 ~= 0 and i~=1 then
			array[i] = math.floor(cur)
		end
	end

	if not #array then qq[2] = {0} end
	-- if qq[3] > maxOPS then qq[3] -= 1 end do we need this

	-- if last > maxint then increase layer by 1 and reset last to 1
	if last > maxInt then
		layer += 1
		array = {math.log10(last), 1}
		last = 1
	end
	-- convert back if possible
	if layer > 0 then
		if (array[1] or 0) < math.log10(maxInt) and (array[2] or 0) == 1 then
			array[1] = 10^array[1]
			array[2] = 0
		end
		if array[1] < maxInt and (array[2] or 0) == 0 then
			layer -= 1
			last = array[1]
			array = {10}
			for i=2,math.min(maxOPS,last)-1,1 do
				table.insert(array, 0)
			end
			table.insert(array, 10)
			-- Extremely ineffecient vro!
		end
	end
	qq[2] = array
	qq[3] = last
	qq[4] = layer
	return setmetatable(qq, Number)
end

function ExpantaNum.fromNumber(val: number): ExpantaNum
	if type(val) ~= 'number' then
		error('NAN input at fromNumber()')
	end
	if val == 0 then
		return ExpantaNum.new(ZERO)
	end
	if val < maxInt then
		return ExpantaNum.correct({math.sign(val), {math.abs(val)}, 0, 0})
	else
		return ExpantaNum.correct({math.sign(val), {math.log10(val), 1}, 1, 0})
	end
end

function ExpantaNum.toNumber(val): number
	val = ExpantaNum.correct(val)
	local array = val[2]
	local sign = val[1]
	if #array >=2 and (array[2]>=2 or (array[2] ==1 and array[1]>math.log10(maxAllowed))) then
		return INF*sign
	end
	return array[2] == 1 and 10^array[1]*sign or array[1]*sign
end

local function formatarrow(val, arrow)
	if type(val) == "number" then
		local t = ''
		if val > 4 then
			t = "10{"..ExpantaNum.toDisplay(val).."}"
		else
			t = '10'..string.rep("^",val-1)
		end
		if arrow then return "("..t..")^" end
		return t
	end
end

local function Decimal(val)
	local a = math.floor(val*10^PrecisionDisplay)
	a = a/10^PrecisionDisplay
	if (a*10) % 1 > .99 then a = math.ceil(a*10)/10 end
	if a % 1 > .99 then a = math.ceil(a) end
	return a
end

function ExpantaNum.toDisplay(val,shorts): string
	val = ExpantaNum.correct(val)
	local sign, array, last, layer = val[1], val[2], val[3], val[4]
	local esign, layerstr = '', ''
	if array[1] == NAN then return 'NaN' end
	if array[1] > INF or layer > INF then return 'Infinity' end
	if sign == 0 then return '0' end
	if sign < 0 then esign = '-' end

	--- LAYER PART
	if layer >= maxInt then
		layerstr = "J^".. Decimal(10^(layer%1)) .. "e" .. layer//1 .. " "
	elseif layer >= 10 then
		if shorts then
			layerstr = "J^".. short(layer) .." "
		else
			layerstr = "J^".. layer .." "
		end
	elseif layer >= 1 then
		layerstr = string.rep("J", layer) -- Jn = 10{n}10
	end

	--- ARRAY PART
	if last == 0 then
		if shorts then
			return short(array[1]*sign)
		else
			return Decimal(array[1])*sign
		end
	elseif last == 1 then
		if shorts and array[2] == 1 then
			if array[1] < math.log10(maxAllowed) then
				return short(10^array[1]*sign)
			else
				return short(array)
			end
		end
		local base = 1
		if math.fmod(array[1],1) ~= 0 then
			base = 10^(array[1]-math.floor(array[1]))
			array[1] = math.floor(array[1])
		end
		if array[2] > amoes then
			if shorts then
				return esign .. layerstr .. '(10^)^' .. short(array[2]-1) .. " " .. base .. 'e' .. short(array[1])
			else
				return esign .. layerstr .. '(10^)^' .. array[2]-1 .. " " .. base .. 'e' .. array[1]
			end
		end
		if shorts then
			return esign .. layerstr .. string.rep("e", array[2]-1) .. short(base) .. 'e' .. short(array[1])
		else
			return esign .. layerstr .. string.rep("e", array[2]-1) .. Decimal(base) .. 'e' .. array[1]
		end
	elseif last > 1 then
		local str = ''
		for i = #array,math.max(#array-maxArrows,2),-1 do
			str ..= formatarrow(i, array[i] > 1)
			if array[i] > 1 then
				if shorts then str ..= short(array[i]) .. " "
				else str ..= array[i] .. " "
				end
			end
		end
		str ..= Decimal(10^(array[1]%1), PrecisionDisplay) .. 'e'
		if shorts then str ..= short(array[1]//1)
		else str ..= array[1]//1
		end
		return esign .. layerstr .. str
	end
end

function ExpantaNum.toString(val: ExpantaNum): string
	val = ExpantaNum.correct(val)
	val[2][1] *= val[1]
	local r = game.HttpService:JSONEncode(val[2]) .. ";" .. val[3] .. ";" .. val[4]
	return r
end

function ExpantaNum.fromString(str)
	if str == "[0];0;0" then
		return setmetatable(ZERO, Number)
	end
	if tonumber(str) then
		return ExpantaNum.new(tonumber(str))
	end
	if (string.find(str, 'e') or string.find(str, 'E')) and not string.find(str,"%[") then
		local subs = string.split(str, 'e')
		-- Fix problem with tetrate
		if subs[1] == "" then
			table.insert(subs, 1, "1")
			if subs[2] == "" then
				table.remove(subs, 2)
			end
		end
		if #subs == 2 then
			-- its scientific yk
			local n = false

			subs[1] = tonumber(subs[1])
			subs[2] = tonumber(subs[2])
			if subs[1] < 0 then
				subs[1] = math.abs(subs[1])
				n = true
			end
			local first = subs[2]+math.log10(subs[1])
			if n then first = -first end
			local second = 1
			local sign = math.sign(first)
			first = math.abs(first)
			return ExpantaNum.new({sign, {first, second}, 1, 0})
		else
			-- its a e chain!
			local second = #subs-1
			local first = subs[#subs]
			local sign = 1
			if subs[1] == '-' then
				sign = -1
			end
			return ExpantaNum.new({sign, {tonumber(first), second}, 1, 0})
		end
	end

	local t, s = {}, 1
	for part in string.gmatch(str, "([^;]+)") do table.insert(t, part) end
	if string.find(t[1], ',') or string.find(t[1],"%[") then
		t[1] = game.HttpService:JSONDecode(t[1])
		if t[1][1] < 0 then
			t[1][1] = math.abs(t[1][1])
			s = -1
		end
		local r = {math.sign(s or 1), t[1], tonumber(t[2]) or 0, tonumber(t[3]) or 0}
		return ExpantaNum.new(r)
	else
		return ExpantaNum.new(tonumber(str))
	end
end

function ExpantaNum.toExpanta(val)
	if type(val) == 'table' then
		if #val < 4 then
			val = {1, val, 0, 0}
		end
		return setmetatable(val, Number)
	end
	if type(val) == 'number' then
		return ExpantaNum.fromNumber(val)
	end
	if type(val) == 'string' then
		return ExpantaNum.fromString(val)
	end
end

function ExpantaNum.eq(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	return ExpantaNum.cmp(val, val2) == 0 
end

function ExpantaNum.le(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	return ExpantaNum.cmp(val, val2) == -1
end

function ExpantaNum.me(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	return ExpantaNum.cmp(val, val2) == 1 
end

function ExpantaNum.meeq(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	return ExpantaNum.cmp(val, val2) >= 0 
end

function ExpantaNum.leeq(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	return ExpantaNum.cmp(val, val2) <= 0 
end

function ExpantaNum.abs(val)
	val = ExpantaNum.correct(val)
	return {1, val[2], val[3], val[4]}
end

function ExpantaNum.neg(val)
	val = ExpantaNum.correct(val)
	return {-val[1], val[2], val[3], val[4]}
end

function ExpantaNum.cmp(val, val2): boolean -- 0 = eq, -1 = le, 1 = me
	val = ExpantaNum.correct(val)
	val2 = ExpantaNum.correct(val2)
	local V1Nan = val ~= val
	if V1Nan and val2 ~= val2 then return 0
	elseif V1Nan or val2 ~= val2 then return 1
	end
	if val[1] == INF and val2[1] ~= INF then return val[1] end
	if val[1] ~= INF and val2[1] == INF then return -val2[1] end
	if #val[2]==1 and val[2][1]==0 and #val2[2]==1 and val2[2][1]==0 then return 0 end
	if val[1] ~= val2[1] then return val[1] end

	if val[3] < val2[3] or val[4] < val2[4] then return -1 end
	if val[3] > val2[3] or val[4] > val2[4] then return 1 end

	local a = val[1]
	local z
	if #val[2] > #val2[2] then z=1 
	elseif #val[2] < #val2[2] then z=-1
	else
		for i=#val[2],1,-1 do
			if val[2][i] > val2[2][i] then
				z = 1
				break
			elseif val[2][i] < val2[2][i] then
				z = -1
				break
			end
		end
		z = z or 0
	end
	return z*a

end

function ExpantaNum.max(val, val2)
	val,val2 = ExpantaNum.new(val),ExpantaNum.new(val2)
	if ExpantaNum.me(val, val2) then
		return val
	else
		return val2
	end
end

function ExpantaNum.min(val, val2)
	val,val2 = ExpantaNum.new(val),ExpantaNum.new(val2)
	if ExpantaNum.me(val, val2) then
		return val2
	else
		return val
	end
end

function copytab(v: ExpantaNum)
	local new = {}
	new[1] = v[1]
	new[2] = {}
	new[3] = v[3]
	new[4] = v[4]
	for i,v in next, v[2] do
		new[2][i] = v
	end
	return new
end

function ExpantaNum.log10(val)
	val = ExpantaNum.new(val)
	if ExpantaNum.eq(val, ZERO) then
		return ExpantaNum.new(ZERO)
	end
	local val1 = copytab(val)
	if ExpantaNum.le(val1, 0) then return NAN end
	if ExpantaNum.eq(val1, 0) then return -INF end
	if ExpantaNum.leeq(val1, maxInt) then
		return ExpantaNum.new(ExpantaNum.fromNumber(math.log10(ExpantaNum.toNumber(val1))))
	end
	val1[2][2] -= 1
	return ExpantaNum.new(val1) 
end

function ExpantaNum.isint(val)
	val = ExpantaNum.correct(val)
	if val[1] == -1 then
		return ExpantaNum.isint(ExpantaNum.abs(val))
	end
	if ExpantaNum.meeq(val, maxInt) then
		return true
	end
	return math.fmod(ExpantaNum.toNumber(val),1) == 1
end

function ExpantaNum.recip(val)
	val = ExpantaNum.correct(val)
	if ExpantaNum.me(ExpantaNum.abs(val), "2e323") then return ZERO end
	return ExpantaNum.new(ExpantaNum.div(1, val))
end

function ExpantaNum.pow(val, val2)
	val,val2 = ExpantaNum.correct(val),ExpantaNum.correct(val2)
	local sign,sign2 = val[1],val2[1]
	local array,array2 = val[2],val2[2]
	if ExpantaNum.eq(val2, 0) then
		return {1, {1},0,0}
	end
	if ExpantaNum.eq(val2, 1) then
		return val
	end
	if ExpantaNum.le(val2, 0) then
		return ExpantaNum.recip(ExpantaNum.pow(val, ExpantaNum.neg(val2)))
	end
	if ExpantaNum.le(val, 0) and ExpantaNum.isint(val2) then
		if ExpantaNum.le(ExpantaNum.mod(val2, 2), 1) then
			return ExpantaNum.pow(ExpantaNum.abs(val), val2)
		end
		return ExpantaNum.neg(ExpantaNum.pow(ExpantaNum.abs(val), val2))
	end 
	if ExpantaNum.le(val, ZERO) then
		return NAN
	end
	if ExpantaNum.eq(val, 1) then
		return {1, {1},0,0}
	end
	if ExpantaNum.eq(val, ZERO) then
		return ZERO
	end
	if ExpantaNum.meeq(ExpantaNum.max(val,val2), maxPOW) then
		return ExpantaNum.max(val, val2)
	end
	if ExpantaNum.eq(val, 10) then
		if ExpantaNum.me(val2, 0) then
			if array2[2] then
				array2[2] = array2[2]+1
			else
				array2[2] = 1
			end
			return ExpantaNum.correct(val2)
		else
			return ExpantaNum.fromNumber(10^ExpantaNum.toNumber(val2))
		end
	end
	if ExpantaNum.le(val2, 1) then
		ExpantaNum.root(val,ExpantaNum.recip(val2))
	end
	local ni = ExpantaNum.toNumber(val)^ExpantaNum.toNumber(val2)
	if ni<= maxInt then
		return ExpantaNum.fromNumber(ni)
	end
	local f = ExpantaNum.log10(val)
	local exporrrrrrrrrr =  ExpantaNum.mul(f, val2)
	return ExpantaNum.pow(10, exporrrrrrrrrr)
end

function ExpantaNum.mod(val, val2)
	val = ExpantaNum.correct(val)
	val2 = ExpantaNum.correct(val2)
	local sign,sign2 = val[1],val2[1]
	if ExpantaNum.eq(val,ZERO) then
		return ZERO
	end
	if sign*sign2 == -1 then
		return ExpantaNum.neg(ExpantaNum.mod(ExpantaNum.abs(val), ExpantaNum.abs(val2)))
	end
	if sign == -1 then
		return ExpantaNum.mod(ExpantaNum.abs(val), ExpantaNum.abs(val2))
	end
	return ExpantaNum.sub(val, ExpantaNum.mul(ExpantaNum.floor(ExpantaNum.div(val, val2)), val2))
end

function ExpantaNum.root(val, val2)
	val,val2 = ExpantaNum.new(val),ExpantaNum.new(val2)
	if ExpantaNum.eq(val2, 1) then
		return val
	end
	if ExpantaNum.le(val2,ZERO) then
		return ExpantaNum.recip(ExpantaNum.root(val, ExpantaNum.neg(val2)))
	end
	if ExpantaNum.le(val2, 1) then
		return ExpantaNum.pow(val, ExpantaNum.recip(val2))
	end
	if ExpantaNum.le(val, ZERO)and ExpantaNum.isint(val2) and ExpantaNum.eq(ExpantaNum.mod(val2, 2), 1) then
		return ExpantaNum.neg(ExpantaNum.root(ExpantaNum.neg(val), val2))
	end
	if ExpantaNum.le(val, ZERO) then
		return NAN
	end
	if ExpantaNum.eq(val, 1) then
		return {1, {1}}
	end
	if ExpantaNum.eq(val, ZERO) then
		return ZERO
	end
	if ExpantaNum.me(ExpantaNum.max(val, val2), maxPOW) then
		if ExpantaNum.me(val, val2)  then
			return val
		else
			return ZERO
		end
	end
	return ExpantaNum.pow(10, ExpantaNum.div(ExpantaNum.log10(val), val2))
end

function ExpantaNum.mul(val,val1)
	local x = ExpantaNum.correct(val)
	local y = ExpantaNum.correct(val1)

	if x[1]*y[1]==-1 then
		return ExpantaNum.neg( ExpantaNum.mul( ExpantaNum.abs(x), ExpantaNum.abs(y) ) )
	end
	if x[1] == -1 then
		return ExpantaNum.mul(ExpantaNum.abs(x),ExpantaNum.abs(y))
	end
	if ExpantaNum.eq(x,ZERO) or ExpantaNum.eq(y,ZERO) then
		return ZERO
	end
	if ExpantaNum.eq(y,{1,{1},0,0}) then
		return x
	end
	if ExpantaNum.me(ExpantaNum.max(x,y),maxMUL) then
		return ExpantaNum.max(x, y)
	end
	local n = ExpantaNum.toNumber(x)*ExpantaNum.toNumber(y)
	if n <= maxAllowed then
		return ExpantaNum.correct(n)
	end
	return ExpantaNum.pow(10,ExpantaNum.add(ExpantaNum.log10(x),ExpantaNum.log10(y)))
end

function ExpantaNum.floor(x)
	if ExpantaNum.isint(x) then
		return x
	end
	return ExpantaNum.new(math.floor(ExpantaNum.toNumber(x)))
end

function ExpantaNum.round(x)
	if ExpantaNum.isint(x) then
		return x
	end
	return ExpantaNum.new(math.round(ExpantaNum.toNumber(x)))
end

function ExpantaNum.ceil(x)
	if ExpantaNum.isint(x) then
		return x
	end
	return ExpantaNum.new(math.ceil(ExpantaNum.toNumber(x)))
end

function ExpantaNum.div(val,val1)
	local x = ExpantaNum.correct(val)
	local y = ExpantaNum.correct(val1)
	if x[1]*y[1]==-1 then
		return ExpantaNum.neg(ExpantaNum.div(ExpantaNum.abs(x), ExpantaNum.abs(y)))
	end
	if x[1] == -1 then
		return ExpantaNum.div(ExpantaNum.abs(x),ExpantaNum.abs(y))
	end
	if ExpantaNum.eq(y, ZERO) then
		return NAN
	end
	if ExpantaNum.eq(y,{1,{1},0,0}) then
		return x
	end
	if ExpantaNum.eq(x,ZERO) then
		return ZERO
	end
	if ExpantaNum.me(ExpantaNum.max(x,y),maxMUL) then
		if ExpantaNum.me(x,y) then
			return x
		end
		return ZERO
	end
	local FILTER1 = ExpantaNum.toNumber(x)/ExpantaNum.toNumber(y)
	if FILTER1 <= maxAllowed then
		return ExpantaNum.correct(FILTER1)
	end
	local qq = ExpantaNum.pow(10, ExpantaNum.sub(ExpantaNum.log10(x),ExpantaNum.log10(y)) )
	local qqw = ExpantaNum.floor(qq)
	if ExpantaNum.le(ExpantaNum.sub(qq,qqw), 1e-9) then
		return qqw
	end
	return qq
end

function ExpantaNum.add(x,y)
	x = ExpantaNum.correct(x)
	y = ExpantaNum.correct(y) 
	if x[1] == -1 then
		return ExpantaNum.neg(ExpantaNum.add(ExpantaNum.neg(x), ExpantaNum.neg(y)))
	end
	if y[1] == -1 then
		return ExpantaNum.sub(x, ExpantaNum.neg(y))
	end
	if ExpantaNum.eq(x, ZERO) then
		return y
	end
	if ExpantaNum.eq(y, ZERO) then
		return x
	end
	local p = ExpantaNum.min(x,y)
	local q = ExpantaNum.max(x,y)
	local a = nil
	if ExpantaNum.me(q,maxADD) or ExpantaNum.me(ExpantaNum.div(q,p), maxInt) then
		a = q
	elseif q[2][2] == nil then
		a = ExpantaNum.correct(ExpantaNum.toNumber(x)+ExpantaNum.toNumber(y))
	elseif q[2][2] == 1 then
		local b = nil
		if p[2][2] then
			b = p[2][1]
		else
			b = math.log10(p[2][1])
		end
		a = ExpantaNum.correct({1,{b+math.log10(math.pow(10,q[2][1]-b)+1) , 1},1,0})
	end
	return a
end

function ExpantaNum.sub(x,y)
	x = ExpantaNum.correct(x)
	y = ExpantaNum.correct(y) 
	if x[1] == -1 then
		return ExpantaNum.neg(ExpantaNum.sub(ExpantaNum.neg(x),ExpantaNum.neg(y)))
	end
	if y[1] == -1 then
		return ExpantaNum.add(x, ExpantaNum.neg(y))
	end
	if ExpantaNum.eq(x,y) then
		return ZERO
	end
	if ExpantaNum.eq(y,ZERO) then
		return x
	end
	local p = ExpantaNum.min(x,y)
	local q = ExpantaNum.max(x,y)
	local FILTER2= ExpantaNum.me(y,x)
	local FILTER1;
	if ExpantaNum.me(q,maxADD) or ExpantaNum.me(ExpantaNum.div(q,p), maxADD) then
		FILTER1=q
		if FILTER2 then
			FILTER1 = ExpantaNum.neg(FILTER1)
		end
	elseif q[2][2] == nil then
		FILTER1 = ExpantaNum.correct(ExpantaNum.toNumber(x)-ExpantaNum.toNumber(y))
	elseif q[2][2] == 1 then
		local b = nil
		if p[2][2] then
			b = p[2][1]
		else
			b = math.log10(p[2][1])
		end
		local DIFF = q[2][1]-b
		if DIFF > 20 then
			FILTER1 = ExpantaNum.max(x,y)
			if FILTER2 then
				return ExpantaNum.neg(FILTER1)	
			end
			return FILTER1
		end
		FILTER1 = ExpantaNum.correct({1, {b+math.log10(math.pow(10,q[2][1]-b)-1) , 1}, 1, 0})
		if FILTER2 then
			FILTER1 = ExpantaNum.neg(FILTER1)	
		end
	end
	return FILTER1
end

function ExpantaNum.sqrt(x)
	return ExpantaNum.root(x,2)
end

function ExpantaNum.log(x,y)
	y = y or 2.7182818284590452353602874
	return ExpantaNum.new(ExpantaNum.log10(x))/ExpantaNum.log10(y)
end

function ExpantaNum.exp(x)
	return ExpantaNum.new(ExpantaNum.pow(2.7182818284590452353602874, x))
end

function ExpantaNum.maxabs(x,y)
	return ExpantaNum.max(ExpantaNum.abs(x),ExpantaNum.abs(y))
end

function ExpantaNum.pow10(x)
	return ExpantaNum.pow(10,x)
end

function ExpantaNum.gamma(x)
	x = ExpantaNum.correct(x)
	if ExpantaNum.me(x,maxPOW) then
		return x
	end
	if ExpantaNum.me(x,maxADD) then
		return ExpantaNum.exp(x)
	end
	if ExpantaNum.me(x,maxInt) then
		return ExpantaNum.exp(ExpantaNum.mul(x,ExpantaNum.sub(ExpantaNum.log(x),1)))
	end
	if ExpantaNum.leeq(x,171) then
		return ExpantaNum.correct(fgamma(ExpantaNum.toNumber(x)))
	end
	local q = x[2][1]
	if q>1 then
		local t=q-1
		local l=0.9189385332046727
		l+=(t+.5)*math.log(t)
		l-=t
		local n2 = t^2
		local np=t
		local lm=12*np
		local adj=1/lm
		local l2 = l+adj
		if (l2==l) then
			return ExpantaNum.exp(l)
		end
		l=l2
		np*=2
		lm=360*np
		adj=1/lm
		l2=l-adj
		if (l2==l) then
			return ExpantaNum.exp(l)
		end
		l=l2
		np*=n2
		lm=1260*np
		local lt=1/lm
		l+=lt
		np*=n2
		lm=1680*np
		lt=1/lm
		l-=lt
		return ExpantaNum.exp(l)	
	end
	return ExpantaNum.recip(x)
end

function fact(x) -- x!
	local amo = 1
	for i=1,x do
		amo *= i
	end
	return amo
end

function ExpantaNum.fact(x)
	x = ExpantaNum.correct(x)
	if ExpantaNum.leeq(x, 170) then
		x = ExpantaNum.toNumber(x)
		if x == math.floor(x) then
			return ExpantaNum.correct(fact(x))
		end
		return ExpantaNum.correct(fgamma(ExpantaNum.toNumber(x)+1))
	end
	return ExpantaNum.gamma(ExpantaNum.add(x,1))
end

function ExpantaNum.rand(min, max): ExpantaNum	
	local seed = math.random()
	local even = ExpantaNum.sub(max, min)
	even = ExpantaNum.mul(even, seed)
	return ExpantaNum.add(even, min)
end

function ExpantaNum.exporand(min, max): ExpantaNum
	return ExpantaNum.exp(ExpantaNum.rand(ExpantaNum.log(min), ExpantaNum.log(max)))
end

function ExpantaNum.toBigNum(val)
	val = ExpantaNum.correct(val)
	local b = {}
	if #val[2] == 1 then
		return errorcorrection({val[2][1]*val[1],0})
	end
	if val[2][2] == 1 then
		return errorcorrection({val[1],val[2][1]})
	end
	if val[2][2] == 2 and math.log10(val[2][1]) <= 308.2547155599167438988686282 then
		return {val[1], 10^val[2][1]}
	end
	return {val[1], INF}
end

function ExpantaNum.toScientific(x): string
	x = ExpantaNum.correct(x)
	if ExpantaNum.le(x, 1000) then
		return ExpantaNum.toNumber(x)
	end
	if ExpantaNum.me(x,maxScientific) then
		return ExpantaNum.toEs(x)
	end -- Corresation to the time i'm working on ExpantaNum, gonna sleep rn (31/12/25 9:00:00PM)
	if ExpantaNum.me(x, 'ee13.9') then
		return "1e" .. ExpantaNum.toScientific(ExpantaNum.log10(x))
	end
	local array = x[2]
	if array[2] == nil then
		local exp = math.log10(array[1])
		local b = 10^(exp-math.floor(exp))
		return Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
	end
	if array[2] == 1 then
		local exp = array[1]
		local b = 10^(exp-math.floor(exp))
		return Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
	end
end

function ExpantaNum.toShortScientific(x): string
	x = ExpantaNum.correct(x)
	if ExpantaNum.le(x,1000) then
		return ExpantaNum.toNumber(x)
	end
	if ExpantaNum.me(x,maxScientific) then
		return ExpantaNum.toEs(x)
	end
	local x1 = x[1]
	local x2 = x[2]

	return string.rep("e", x2[2]) .. short(ExpantaNum.toBigNum(x2[1]))
end

function ExpantaNum.short(x): string
	x = ExpantaNum.correct(x)
	if ExpantaNum.me(x,maxSuffix) then
		return ExpantaNum.toShortScientific(x)
	end
	return short(ExpantaNum.toBigNum(x))
end

function ExpantaNum.toEnt(x): string
	x = ExpantaNum.correct(x)
	if x[2][3] then
		if x[2][3] > 1 or x[2][1] > 308 or x[2][2] > 1 then
			return ExpantaNum.toShortHyperE(x)
		end
		x[2][2] = 10^x[2][1]
		x[2][3] = nil
	end
	local part = "E(" .. x[2][2] .. ")"
	if x[1] == -1 then
		part = "-" .. part
	end
	return part .. x[2][1]
end

function ExpantaNum.toShortEnt(x): string
	x = ExpantaNum.correct(x)
	if x[2][3] then
		if x[2][3] > 1 or x[2][1] > 308 or x[2][2] > 1 then
			return ExpantaNum.toShortHyperE(x)
		end
		x[2][2] = 10^x[2][1]
		x[2][3] = nil
	end
	local part = "E(" .. ExpantaNum.short(x[2][2]) .. ")"
	if x[1] == -1 then
		part = "-" .. part
	end
	return part .. ExpantaNum.short(x[2][1])
end

function ExpantaNum.toEs(x): string
	x = ExpantaNum.correct(x)
	if #x[2] > 2 then
		return ExpantaNum.toEnt(x)
	end
	if x[2][2] == nil then
		return ExpantaNum.short(x)
	end
	if x[2][2] > maxEs then
		return ExpantaNum.toEnt(x)
	end
	if x[1] == -1 then
		return "-" .. ExpantaNum.toEs(ExpantaNum.abs(x))
	end
	local estring = string.rep("e", x[2][2])
	return estring .. Decimal(x[2][1],4)
end

function ExpantaNum.toShortEs(x): string
	x = ExpantaNum.correct(x)
	if #x[2] > 2 then
		return ExpantaNum.toShortEnt(x)
	end
	if x[2][2] == nil then
		return ExpantaNum.short(x)
	end
	if x[2][2] > maxEs then
		return ExpantaNum.toShortEnt(x)
	end
	if x[1] == -1 then
		return "-" .. ExpantaNum.toShortEs(ExpantaNum.abs(x))
	end
	local estring = string.rep("e", x[2][2])
	return estring .. ExpantaNum.short(Decimal(x[2][1],4))
end

-- TODO: add support for hyper-E over 10{maxInt}10
function ExpantaNum.toHyperE(x): string
	x = ExpantaNum.correct(x)
	if x[1] == -1 then
		return "-" .. ExpantaNum.toHyperE(ExpantaNum.abs(x))
	end
	if ExpantaNum.le(x,maxInt) then
		return ExpantaNum.short(x)
	end
	if ExpantaNum.le(x,maxADD) then
		return "E" .. x[2][1]
	end

	local str = "E" .. Decimal(x[2][1],PrecisionDisplay) .. "#"
	if x[3] < maxHyperions then
		str ..= x[2][2]
		for i=3,#x[2] do
			str ..= "#" .. x[2][i]+1
		end
	else
		str ..= x[2][#x[2]] .. "##" .. x[3]-2
	end
	return str
end

function ExpantaNum.toShortHyperE(x): string
	x = ExpantaNum.correct(x)
	if x[1] == -1 then
		return "-" .. ExpantaNum.toShortHyperE(ExpantaNum.abs(x))
	end
	if ExpantaNum.le(x,maxInt) then
		return ExpantaNum.short(x)
	end
	if ExpantaNum.le(x,maxADD) then
		return "E" .. ExpantaNum.short(x[2][1])
	end

	local str = "E" .. ExpantaNum.short(Decimal(x[2][1],PrecisionDisplay)) .. "#"
	if x[3] < maxHyperions then
		str ..= ExpantaNum.short(x[2][2])
		for i=3,#x[2] do
			str ..= "#" .. ExpantaNum.short(x[2][i]+1)
		end
	else
		str ..= ExpantaNum.short(x[2][#x[2]]) .. "##" .. ExpantaNum.short(x[3]-2)
	end
	return str
end

function ExpantaNum.lambertw(x): ExpantaNum
	x = ExpantaNum.correct(x)
	if ExpantaNum.leeq(x,1e308) then
		return f_lambertw(ExpantaNum.toNumber(x))
	end
	if ExpantaNum.me(x, maxPOW) then
		return x
	end
	if ExpantaNum.me(x, maxMUL) then
		return ExpantaNum.log10(x)
	end
	return Hlambertw(x)
end

function ExpantaNum.slog(r,base): ExpantaNum
	r = ExpantaNum.correct(r)
	base = ExpantaNum.toExpanta(base)
	if r[1] == -1 then return {-1,{1},0,0} end
	if ExpantaNum.eq(r,ONE) then return ZERO end
	if ExpantaNum.eq(r,base) then return ONE end
	if ExpantaNum.le(base, math.exp(1/2.7182818284)) then return r end
	if ExpantaNum.me(ExpantaNum.max(r,base), maxTETR) then
		if ExpantaNum.me(r,base) then return r end
		return ZERO
	end
	if ExpantaNum.me(ExpantaNum.max(r,base), maxPOW) then
		if ExpantaNum.me(r,base) then
			r[2][3] -= 1
			return ExpantaNum.sub(r,r[2][2])
		end
		return ZERO
	end
	local q = 0
	local t = (r[2][2] or 0) - (base[2][2] or 0)
	if t>3 then
		local p = t-3
		q += p
		r[2][2] -= p
	end
	for i=1,99 do
		if r[1] == -1 then
			r = ExpantaNum.pow(base,r)
			q-=1
		else
			if ExpantaNum.leeq(r,ONE) then
				return ExpantaNum.toExpanta(q+ExpantaNum.toNumber(r)-1)	
			else 
				q += 1
				r = ExpantaNum.log(r,base)
			end
		end
	end
	if ExpantaNum.me(r, 10) then
		return q
	end
end

function ExpantaNum.pentlog(r,base): ExpantaNum
	r = ExpantaNum.correct(r)
	base = ExpantaNum.toExpanta(base)
	if r[1] == -1 then return {-1,{1},0,0} end
	if ExpantaNum.eq(r,ONE) then return ZERO end
	if ExpantaNum.eq(r,base) then return ONE end
	if ExpantaNum.le(base, math.exp(1/2.7182818284)) then return r end
	if ExpantaNum.me(ExpantaNum.max(r,base), maxPENT) then
		if ExpantaNum.me(r,base) then return r end
		return ZERO
	end
	if ExpantaNum.me(ExpantaNum.max(r,base), maxTETR) then
		if ExpantaNum.me(r,base) then
			r[2][4] -= 1
			return ExpantaNum.sub(r,r[2][3])
		end
		return ZERO
	end
	local q = 0
	local t = (r[2][3] or 0) - (base[2][3] or 0)
	if t>3 then
		local p = t-3
		q += p
		r[2][3] -= p
	end
	for i=1,99 do
		if r[1] == -1 then
			r = ExpantaNum.tetr(base,r)
			q -= 1
		else
			if ExpantaNum.leeq(r,ONE) then
				return ExpantaNum.toExpanta(q+ExpantaNum.toNumber(r)-1)	
			else 
				q += 1
				r = ExpantaNum.slog(r,base)
			end
		end
	end
	if ExpantaNum.me(r, 10) then
		return q
	end
end

function ExpantaNum.tetrate(x,y): ExpantaNum
	x = ExpantaNum.correct(x)
	y = ExpantaNum.correct(y)
	if ExpantaNum.le(y,-2) then
		return NAN
	end
	if ExpantaNum.eq(x,ZERO) then
		if ExpantaNum.eq(y,0) then
			return NAN
		end
		if ExpantaNum.eq(ExpantaNum.mod(y,2),0) then
			return ZERO
		end
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(x,1) then
		if ExpantaNum.eq(y, -1) then
			return NAN
		end
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(y, -1) then
		return ZERO
	end
	if ExpantaNum.eq(y, 0) then
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(y, 1) then
		return x
	end
	if ExpantaNum.eq(y,2) then
		return ExpantaNum.pow(x,x)
	end
	if ExpantaNum.eq(x,2) then
		if ExpantaNum.eq(y,3) then
			return ExpantaNum.fromNumber(16)
		end
		if ExpantaNum.eq(y,4) then
			return ExpantaNum.fromNumber(65536)
		end
	end
	local max = ExpantaNum.max(x,y)
	if ExpantaNum.me(max, {1,{10000000000, 8, maxInt},2,0}) then
		return max
	end
	if ExpantaNum.me(x, maxPOW) or ExpantaNum.me(y, maxInt) then
		if ExpantaNum.le(x, math.exp(1/2.7182818284)) then
			local nel = ExpantaNum.neg(ExpantaNum.log(x))
			return ExpantaNum.div(ExpantaNum.lambertw(nel), nel)
		end
		local q = copytab(ExpantaNum.add(ExpantaNum.slog(x,10),y))
		q[2][3] = (y[2][3] or 0)+1
		return ExpantaNum.correct(q)
	end
	local yo = ExpantaNum.toNumber(y)
	local fo = math.floor(yo)
	local ro = ExpantaNum.pow(x, yo-fo)
	local mo = maxADD
	local lo = NAN
	local count = 0
	for i=1,100 do
		if not(fo~=0 and ExpantaNum.le(ro,mo)) then break end
		count +=1
		if fo>0 then
			ro = ExpantaNum.pow(x,ro)
			if ExpantaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo -= 1
		else
			ro = ExpantaNum.log(ro,x)
			if ExpantaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo += 1
		end
	end
	if count == 100 or ExpantaNum.le(x,math.exp(1/2.7182818284)) then
		fo = 0
	end
	ro[2][2] = ro[2][2] and ro[2][2]+fo or fo
	return ExpantaNum.correct(ro)
end

function ExpantaNum.tetr(x,y)
	return ExpantaNum.tetrate(x,y) -- alias
end

function ExpantaNum.pentate(x,y): ExpantaNum
	x = ExpantaNum.correct(x)
	y = ExpantaNum.correct(y)
	if ExpantaNum.le(y,-2) then
		return NAN
	end
	if ExpantaNum.eq(x,ZERO) then
		if ExpantaNum.eq(y,0) then
			return NAN
		end
		if ExpantaNum.eq(ExpantaNum.mod(y,2),0) then
			return ZERO
		end
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(x,1) then
		if ExpantaNum.eq(y, -1) then
			return NAN
		end
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(y, -1) then
		return ZERO
	end
	if ExpantaNum.eq(y, 0) then
		return {1,{1},0,0}
	end
	if ExpantaNum.eq(y, 1) then
		return x
	end
	if ExpantaNum.eq(y,2) then
		return ExpantaNum.tetrate(x,x)
	end
	if ExpantaNum.eq(x,2) then
		if ExpantaNum.eq(y,3) then
			return ExpantaNum.fromNumber(65536)
		end
	end
	local max = ExpantaNum.max(x,y)
	if ExpantaNum.me(max, {1,{10000000000, 8, maxInt},2,0}) then
		return max
	end
	if ExpantaNum.me(x, maxPOW) or ExpantaNum.me(y, maxInt) then
		if ExpantaNum.le(x, math.exp(1/2.7182818284)) then
			local nel = ExpantaNum.neg(ExpantaNum.log(x))
			return ExpantaNum.div(ExpantaNum.lambertw(nel), nel)
		end
		local q = copytab(ExpantaNum.add(ExpantaNum.slog(x,10),y))
		q[2][3] = (y[2][3] or 0)
		q[2][4] = (y[2][4] or 0)+1
		return ExpantaNum.correct(q)
	end
	local yo = ExpantaNum.toNumber(y)
	local fo = math.floor(yo)
	local ro = ExpantaNum.pow(x, yo-fo)
	local mo = maxADD
	local lo = NAN
	local count = 0
	for i=1,100 do
		if not(fo~=0 and ExpantaNum.le(ro,mo)) then break end
		count +=1
		if fo>0 then
			ro = ExpantaNum.tetrate(x,ro)
			if ExpantaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo -= 1
		else
			ro = ExpantaNum.log(ro,x)
			if ExpantaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo += 1
		end
	end
	if count == 100 or ExpantaNum.le(x,math.exp(1/2.7182818284)) then
		fo = 0
	end
	ro[2][3] = ro[2][3] and ro[2][3]+fo or fo
	return ExpantaNum.correct(ro)
end

function ExpantaNum.pent(x,y)
	return ExpantaNum.pentate(x,y) -- alias
end

function ExpantaNum.arrow(x, y, z): ExpantaNum --oh ye (Note: a bit fixed for 0-3 arrows.)
	x = ExpantaNum.correct(x)
	local zInt = z
	z = ExpantaNum.correct(z)
	if y == 0 then
		return ExpantaNum.mul(x,z)
	end
	if ExpantaNum.eq(z,1) then 
		return x
	end
	if ExpantaNum.eq(x,0) then
		if y >= 2 and ExpantaNum.eq(z,0) then return NAN end
		if y == 1 and ExpantaNum.eq(z,0) then return ONE end
		return ZERO
	end
	if ExpantaNum.le(x,0) or ExpantaNum.le(z,0) then
		if y>=2 then
			return NAN
		end
		if y==1 then return ExpantaNum.pow(x,z) end
	end
	if ExpantaNum.eq(y, 1) then
		return ExpantaNum.pow(x,z)
	end
	if ExpantaNum.eq(y, 2) then
		return ExpantaNum.tetrate(x,z)
	end
	if ExpantaNum.eq(y, 3) then
		return ExpantaNum.pentate(x,z)
	end
	if ExpantaNum.eq(x, 10) then
		local arr = {10}
		for i=2,math.min(maxOPS,y)-2,1 do
			table.insert(arr, 0)
		end
		table.insert(arr, zInt)
		-- inaccurate compared to ExpantaNum.js
		return ExpantaNum.correct( {1,arr,y,0} )
	end
	return "unsupported"
end

function ExpantaNum.lbencode(onum: ExpantaNum, transferFromOmegaNum: boolean)
	onum = ExpantaNum.correct(onum)
	transferFromOmegaNum = transferFromOmegaNum and 10 or 1

	local approx = 6.267788e13 * transferFromOmegaNum
	local sign = onum[1]
	local amo = onum[3]
	local layer = onum[4]
	onum = onum[2]
	if onum[2] == 0 then return 0 end

	if layer == 0 then
		if amo == 0 then
			return sign * math.log10(onum[1] + 1) * approx
		elseif amo == 1 then
			if onum[2] < 4 then
				return sign * (math.log10(onum[1] + 1) * approx + onum[2] * 10^15 * transferFromOmegaNum)
			elseif onum[2] < 10000 then
				return sign * 4 * 10^15 * transferFromOmegaNum + (math.log10(onum[1] + 1) * math.floor(approx / 10^5 / transferFromOmegaNum) + onum[2] * 10^9 * transferFromOmegaNum)
			end
			return sign * 5 * 10^15 * transferFromOmegaNum + math.log10(onum[2] + math.log10(onum[1]) / 16 + 1) * approx
		elseif amo == 2 then
			if onum[3] < 3 then
				return sign * (onum[3] + 5) * 10^15 * transferFromOmegaNum + math.log10(onum[2] + math.log10(onum[1]) / 16 + 1) * approx
			elseif onum[3] < 10000 then
				return sign * 8 * 10^15 * transferFromOmegaNum + math.log10(onum[2] + math.log10(onum[1]) / 16 + 1) * math.floor(approx / 10^5 / transferFromOmegaNum) + onum[3] * 10^9 * transferFromOmegaNum
			end
			return sign * 9 * 10^15 * transferFromOmegaNum + math.log10(onum[3] + math.log10(onum[2] + 1) / 16 + 1) * approx
		elseif amo == 3 then
			return sign * 10 * 10^15 * transferFromOmegaNum + math.log10(onum[4] + math.log10(onum[3] + 1) / 16 + 1) * approx
		elseif amo == 4 then
			return sign * 11 * 10^15 * transferFromOmegaNum + math.log10(onum[5] + math.log10(onum[4] + 1) / 16 + 1) * approx
		elseif amo < 2^53 then
			return sign * 12 * 10^15 * transferFromOmegaNum + math.log10(amo + math.log10(onum[#onum] + 1) / 16 + 1) * approx
		end
	end

	if layer == 1 then
		return sign * 13 * 10^15 + math.log10(amo + math.log10(onum[#onum] + 1) / 16 + 1) * approx
	elseif layer < 2^53 then
		return sign * 14 * 10^15 + math.log10(layer + math.log10(amo + 1) / 16 + 1) * approx
	end

	return sign * math.log(layer, 2) * 10^15 + math.floor(math.log10(amo + 1) * approx)
end

--[[
function ExpantaNum.lbdecode(int)
	elseif mode == 8 then
		local arg3 = math.floor((int-8e16) / 1e10)
		local remainder = math.fmod(int, 1e10) * 1e6
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {arg1, math.floor(arrows), math.floor(arg3)}}
	elseif mode == 9 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {1, math.floor(arg1), math.floor(arrows)}}
	elseif mode == 10 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		local hixd = {sign, {1, 0, math.floor(arg1), math.floor(arrows)}}
		if hixd[2][4] == 0 then
			table.remove(hixd[2], 4)
		end
		return hixd
	else
		local zeros = mode - 10
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = maxInt^(math.fmod(arrows, 1))
		local xd = {1, 0}
		for i=1,zeros do
			table.insert(xd, 0)
		end
		table.insert(xd, math.floor(arg1))
		table.insert(xd, math.floor(arrows))
		if xd[zeros + 4] == 0 then
			table.remove(xd)
		end
		return {sign, xd}
	end
end
]]

function ExpantaNum.lbdecode(num: number, transferFromOmegaNum: boolean)
	num = num * (transferFromOmegaNum and 10 or 1)
	local approx = 6.267788e13
	local mode = num / 1e15
	local sign = math.sign(num)
	if mode >= 3 then
		num -= 1
	end
	
	if mode <= 1 then
		return {
			sign, {10 ^ (num / approx) - 1}, 0, 0
		}
	elseif mode <= 4 then
		return {
			sign, {
				10 ^ ((num % 1e15) / approx) - 1,
				math.floor(mode)
			}, 1, 0
		}
	elseif mode <= 5 then
		return {
			sign, {
				10 ^ ((num % 1e9) / math.floor(approx / 1e5)) - 1,
				math.floor((num - math.floor(mode) * 1e15) / 1e9)
			}, 1, 0
		}
	elseif mode <= 8 then
		local exp = 10 ^ ((num % 1e15) / approx) - 1
		local man = 10 ^ ((exp % 1) * 16)
		if mode <= 6 then
			return {
				sign, {
					man, math.floor(exp)
				}, 1, 0
			}
		end
		return {
			sign, {
				man,
				math.floor(exp),
				math.floor(mode - 5)
			}, 2, 0
		}
	end
end

----------------------------------------------bignum part ; )
function errorcorrection(bnum)	
	local signal = 1 -- + is 1, - is 0
	if bnum[1] == 0 then
		return {0, 0}
	end
	if bnum[1] < 0 then
		signal = 0
	end
	if signal == 0 then
		bnum[1] *= -1
	end
	local signal2 = 1
	if bnum[2] < 0 then
		signal2 = 0
		bnum[2] *= -1
	end
	if math.fmod(bnum[2], 1) > 0 and signal2 == 0 then
		bnum[1] = bnum[1] * (10^ (1 - math.fmod(bnum[2], 1)))
		bnum[2] = math.floor(bnum[2]) + 1
	elseif math.fmod(bnum[2], 1) > 0 and signal2 == 1  then
		bnum[1] = bnum[1] * (10^ math.fmod(bnum[2], 1))
		bnum[2] = math.floor(bnum[2])
	end
	if signal2 == 0 then
		bnum[2] = bnum[2] * -1		
	end
	local DgAmo = math.log10(bnum[1])
	DgAmo = math.floor(DgAmo)
	bnum[1] = bnum[1] / 10^DgAmo
	bnum[2] = bnum[2] + DgAmo	
	bnum[2] = math.floor(bnum[2])
	if signal == 0 then
		bnum[1] = bnum[1] * -1		
	end
	return bnum
end	

function bnumtostr(bnum)	
	return tostring(bnum[1]) .. "e" .. tostring(bnum[2])
end

function bnumtofloat(bnum)
	return tonumber(bnumtostr(bnum))
end

function commas(Value): string
	if Value < 1e3 then 
		return math.floor(Value * 10^PrecisionDisplay)/10^PrecisionDisplay
	end
	local Number
	local Formatted = math.floor(Value * 10^PrecisionDisplay) / 10^PrecisionDisplay
	if Value < 10^13 then
		while (Number ~= 0) do
			Formatted, Number = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		end 
		return Formatted
	elseif Value < 10^26 then
		local Formatted2 = math.floor(Value / 10^12)
		Formatted = math.fmod(Value, 10^12)
		while Number ~= 0 do  
			Formatted2, Number = string.gsub(Formatted2, "^(-?%d+)(%d%d%d)", '%1,%2')
		end 
		Number = nil
		while Number ~= 0 do   
			Formatted, Number = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		end 
		local TpFormatted = math.fmod(Value, 10^12)
		local String = Formatted2 .. ","
		if TpFormatted == 0 then
			String ..= "000,000,000,000"
		elseif TpFormatted < 10 then
			String ..= "000,000,000,00"
		elseif TpFormatted < 100 then
			String ..= "000,000,000,0"
		elseif TpFormatted < 1000 then
			String ..= "000,000,000,"
		elseif TpFormatted < 10000 then
			String ..= "000,000,00"
		elseif TpFormatted < 100000 then
			String ..= "000,000,0"
		elseif TpFormatted < 1000000 then
			String ..= "000,000,"
		elseif TpFormatted < 10000000 then
			String ..= "000,00"
		elseif TpFormatted < 100000000 then
			String ..= "000,0"
		elseif TpFormatted < 1000000000 then
			String ..= "000,"
		elseif TpFormatted < 10000000000 then
			String ..= "00"
		elseif TpFormatted < 100000000000 then
			String ..= "0"
		end
		if TpFormatted > 0 then
			String ..= Formatted
		end
		return String
	else
		return "unsupported"
	end
end
-- TODO: a
function short(bnum)
	local NOTbnum = {bnum}
	if #NOTbnum == 1 then
		bnum = ExpantaNum.toBigNum(bnum)
	end
	local SNumber0 = bnum[2]
	local SNumber1 = bnum[1]
	local leftover = math.fmod(SNumber0, 3)
	local SNumber = math.floor(SNumber0 / 3) - 1
	if SNumber < -1 then
		return math.floor(bnumtofloat(bnum)*10^PrecisionDisplay + 0.000000001)/(10^PrecisionDisplay)
	end
	local FirstOnes = {"", "U","D","T","Qd","Qn","Sx","Sp","Oc","No"}
	local SecondOnes = {"", "Dc","Vt","Tg","qg","Qg","sg","Sg","Og","Ng"}
	local ThirdOnes = {"", "Ce", "Du","Tr","Qa","Qi","Se","Si","Ot","Ni"}
	local MultOnes = {"", "Mi","Mc","Na","Pc","Fm","At","Zp","Yc", "Xo", "Ve", "Me", "Due", "Tre", "Te", "Pt", "He", "Hp", "Oct", "En", "Ic", "Mei", "Dui", "Tri", "Teti", "Pti", "Hei", "Hp", "Oci", "Eni", "Tra","TeC","MTc","DTc","TrTc","TeTc","PeTc","HTc","HpT","OcT","EnT","TetC","MTetc","DTetc","TrTetc","TeTetc","PeTetc","HTetc","HpTetc","OcTetc","EnTetc","PcT","MPcT","DPcT","TPCt","TePCt","PePCt","HePCt","HpPct","OcPct","EnPct","HCt","MHcT","DHcT","THCt","TeHCt","PeHCt","HeHCt","HpHct","OcHct","EnHct","HpCt","MHpcT","DHpcT","THpCt","TeHpCt","PeHpCt","HeHpCt","HpHpct","OcHpct","EnHpct","OCt","MOcT","DOcT","TOCt","TeOCt","PeOCt","HeOCt","HpOct","OcOct","EnOct","Ent","MEnT","DEnT","TEnt","TeEnt","PeEnt","HeEnt","HpEnt","OcEnt","EnEnt","Hect", "MeHect"}
	if bnum[2] == INF then
		if bnum[1] < 0 then
			return "-Infinity"
		else
			return "Infinity"
		end
	end
	-- suffix part
	if SNumber0 < maxCommas then
		return commas(bnumtofloat(bnum))
	elseif SNumber == 1 then
		return math.floor(SNumber1 * 10^leftover * 10^PrecisionDisplay + 0.000000001)/10^PrecisionDisplay .. "M"
	elseif SNumber == 2 then
		return math.floor(SNumber1 * 10^leftover * 10^PrecisionDisplay + 0.000000001)/10^PrecisionDisplay .. "B"
	end
	local txt = ""	
	local function suffixpart(n)	
		local Hundreds = math.floor(n/100)
		n = math.fmod(n, 100)
		local Tens = math.floor(n/10)
		n = math.fmod(n, 10)
		local Ones = math.floor(n/1)		
		txt = txt .. FirstOnes[Ones + 1]
		txt = txt .. SecondOnes[Tens + 1]
		txt = txt .. ThirdOnes[Hundreds + 1]		
	end
	local function suffixpart2(n,i)
		if n > 0 or i == 0 then
			n = n + 1
		end
		if n > 1000 then
			n = math.fmod(n, 1000)
		end
		local Hundreds = math.floor(n/100)
		n = math.fmod(n, 100)
		local Tens = math.floor(n/10)
		n = math.fmod(n, 10)
		local Ones = math.floor(n/1)		
		txt = txt .. FirstOnes[Ones + 1]
		txt = txt .. SecondOnes[Tens + 1]
		txt = txt .. ThirdOnes[Hundreds + 1]		
	end	
	if SNumber < 1000 then
		suffixpart(SNumber)
		return math.floor(SNumber1 * 10^leftover * 10^PrecisionDisplay + 0.000000001)/10^PrecisionDisplay .. txt
	end	
	for i = #MultOnes,0,-1 do
		if SNumber >= 10^(i*3) then
			suffixpart2(math.floor(SNumber / 10^(i*3))- 1,i)
			txt = txt .. MultOnes[i+1]
			if SNumber >= 10^(i*3)+1 and i >= 1 then
				txt = txt.."-"
			end	
			SNumber = math.fmod(SNumber, 10^(i*3))
		end
	end
	return math.floor(SNumber1 * 10^leftover * 10^PrecisionDisplay + 0.000000001)/10^PrecisionDisplay .. txt
end

-- Making it easier for SamirDevs to use this for OperatorSim lol.

function ExpantaNum.onflt(onum): number
	return ExpantaNum.toNumber(onum)
end

function ExpantaNum.flton(flt): ExpantaNum
	return ExpantaNum.toExpanta(flt)
end

function ExpantaNum.onstr(onum): ExpantaNum
	return ExpantaNum.toString(onum)
end

function ExpantaNum.stron(str): ExpantaNum
	return ExpantaNum.toExpanta(str)
end

function ExpantaNum.equal(onum1,onum2): boolean
	return ExpantaNum.eq(onum1,onum2)
end

function ExpantaNum.moreequal(onum1,onum2): boolean
	return ExpantaNum.meeq(onum1,onum2)
end

function ExpantaNum.lessequal(onum1,onum2): boolean
	return ExpantaNum.leeq(onum1,onum2)
end

function ExpantaNum.more(onum1,onum2): boolean
	return ExpantaNum.me(onum1,onum2)
end

function ExpantaNum.less(onum1,onum2): boolean
	return ExpantaNum.le(onum1,onum2)
end

function ExpantaNum.abbreviate(onum): string
	onum = ExpantaNum.correct(onum)
	if ExpantaNum.eq(onum,{1,{0},0,0}) then
		return "0"
	elseif ExpantaNum.le(onum, {1, {0.000000001},0,0}) then
		return "1 / " .. ExpantaNum.short(ExpantaNum.div(1, onum))
	elseif ExpantaNum.le(onum,maxSuffix) then
		return ExpantaNum.short(onum)
	elseif ExpantaNum.le(onum,maxScientific) then
		return ExpantaNum.toShortScientific(onum)
	elseif ExpantaNum.le(onum,{1,maxEs,1}) then
		return ExpantaNum.toShortEs(onum) 
	elseif ExpantaNum.le(onum,{1,1e306,1}) then
		return ExpantaNum.toShortEnt(onum)
	else
		return ExpantaNum.toShortHyperE(onum)
	end
end

return ExpantaNum

