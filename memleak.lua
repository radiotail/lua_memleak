local pairs = pairs
local print = print
local type  = type
local tostring = tostring
local stringFormat = string.format

MemLeak = {
	memCache1 = nil,
	memCache2 = nil,
	nowCache  = nil,
	relation  = {},
	parentsValue = {},
	output	  = io.stdout,
}

local MemLeak = MemLeak

function MemLeak:cacheMemory()
	if self.memCache1 and self.memCache2 then
		self:prints("You had two caches, please differ them!")
		return
	end
	
	local markedMap = {}
	markedMap.markedTable = {}
	markedMap.markedFunction = {}
	markedMap.markedUserdata = {}
	
	local stage = 0
	if not self.memCache1 then
		self.memCache1 = markedMap
		stage = 1
	elseif not self.memCache2 then
		self.memCache2 = markedMap
		stage = 2
	end
	
	self.nowCache = markedMap
	
	self:searchRegistry()
	self:searchGlobe()
	
	self:prints("cache stage: ", stage, " time: ", os.time())
	print("cacheMemory over!")
end

function MemLeak:getCacheByIndex(index)
	if index == 1 then
		return self.memCache1
	elseif index == 2 then
		return self.memCache2
	end
end

function MemLeak:clearCache()
	self.memCache1 = nil
	self.memCache2 = nil
	self.nowCache  = nil
	self.relation  = {}
	self.parentsValue = {}
end

function MemLeak:markedCount(index)
	local marked = self:getCacheByIndex(index)
	if marked then
		self:prints("error index!", index)
		return
	end
	
	local count = 0
	
	local tb1 = marked.markedTable
	for k, v in pairs(tb1) do
		count = count + 1
	end

	tb1 = marked.markedFunction
	for k, v in pairs(tb1) do
		count = count + 1
	end
	
	tb1 = marked.markedFunction
	for k, v in pairs(tb1) do
		count = count + 1
	end
	
	self:prints("object count: ", count)
end

function MemLeak:differCache()
	local marked1 = self:getCacheByIndex(1)
	if not marked1 then
		self:prints("you don't have cache1")
		return
	end
	
	local marked2 = self:getCacheByIndex(2)
	if not marked2 then
		self:prints("you don't have cache2")
		return
	end
	
	self:prints("\nnew objects list: ")
	local count = 0
	local differs = {}
	local tb1, tb2 = marked1.markedTable, marked2.markedTable
	local func1, func2 = marked1.markedFunction, marked2.markedFunction
	local user1, user2 = marked1.markedUserdata, marked2.markedUserdata

	for k, v in pairs(tb2) do
		if not tb1[k] then
			self:printResult(k, v)
			self:findDiffersParents(differs, tb1, func1, user1, k, v)
			count = count + 1
		end
	end
	
	for k, v in pairs(func2) do
		if not func1[k] then
			self:printResult(k, v)
			self:findDiffersParents(differs, tb1, func1, user1, k, v)
			count = count + 1
		end
	end
	
	for k, v in pairs(user2) do
		if not user1[k] then
			self:printResult(k, v)
			self:findDiffersParents(differs, tb1, func1, user1, k, v)
			count = count + 1
		end
	end
	
	self:prints("object count: ", count)
	self:prints("\n")
	
	self:prints("parents list: ")
	for key, value in pairs(differs) do
		self:printResult(key, value)
	end
	self:prints("\n")
	
	self:printRelation()
	self:flushOutput()
	self:clearCache()
	
	print("differCache over!")
end

function MemLeak:findDiffersParents(differs, tb, func, user, key, value)
	local parents = value[3]
	local parentKey, parentValue
	for i = 1, #parents do
		parentKey = parents[i]
		parentValue = tb[parentKey]
		if not differs[parentKey] then
			if not parentValue then
				parentValue = func[parentKey]
			elseif not parentValue then
				parentValue = user[parentKey]
			elseif parentValue then
				differs[parentKey] = parentValue
				self:findDiffersParents(differs, tb, func, user, parentKey, parentValue)
			end
		end
	end
end

function MemLeak:showCache(index)
	local marked = self:getCacheByIndex(index)
	if not marked then
		self:prints("error index!", index)
		return
	end
	
	self:prints("show cache index: ", index)
	local count = 0
	for k, v in pairs(marked.markedTable) do
		self:printResult(k, v)
		count = count + 1
	end
	
	for k, v in pairs(marked.markedFunction) do
		self:printResult(k, v)
		count = count + 1
	end
	
	for k, v in pairs(marked.markedUserdata) do
		self:printResult(k, v)
		count = count + 1
	end
	
	self:prints("object count: ", count)
end

function MemLeak:filter(object, varType, parent, desc)
	if object == self or 
		object == self.nowCache or 	
		object == self.relation or
		object == self.parentsValue or
		object == self.memCache1 or 
		object == self.memCache2 then
		
		return true
	end
end

function MemLeak:isMarked(object, varType, parent, desc)
	local marked
	local markedMap = self.nowCache
	if varType == "table" then
		if self:filter(object, varType, parent, desc) then
			return true
		end
		marked = markedMap.markedTable
	elseif varType == "function" then
		marked = markedMap.markedFunction
	elseif varType == "userdata" then
		marked = markedMap.markedUserdata
	end
	
	local keyString = tostring(object)
	local parentString = tostring(parent)
	local tb = marked[keyString]
	if not tb then
		local parents = {parentString}
		marked[keyString] = {1, varType, parents, desc}
	else
		tb[1] = tb[1] + 1
		local parents = tb[3]
		parents[#parents + 1] = parentString
		return true
	end
	
	return false
end

function MemLeak:searchObject(object, parent, desc)
	local varType = type(object)
	
	if varType == "table" then
		self:searchTable(object, parent, desc)
	elseif varType == "function" then
		self:searchFunction(object, parent, desc)
	elseif varType == "userdata" then
		self:searchUserdata(object, parent, desc)
	end
end

function MemLeak:fixTableDesc(object)
	local fixdesc = ""
	-- add your own custom	
	return fixdesc
end

function MemLeak:searchTable(object, parent, desc)
	local fixdesc = self:fixTableDesc(object)
	desc = desc..fixdesc
	
	if self:isMarked(object, "table", parent, desc) then return end
	
	local meta = debug.getmetatable(object)
	if meta then
		self:searchObject(meta, object, "[metatable]")
	end

	local keytype
	for key, value in pairs(object) do
		keytype = type(key)
		if keytype == "string" then
			desc = key
		elseif keytype == "number" then
			desc = tostring(key)
		else
			self:searchObject(key, object, "[key]")
			desc = "[value]"
		end
		self:searchObject(value, object, desc)
	end
end

function MemLeak:fixFunctionDesc(func)
	local info = debug.getinfo(func)
	local fixdesc = stringFormat(":[%s:%d]", info.short_src, info.linedefined)
	return fixdesc
end

function MemLeak:searchFunction(func, parent, desc)
	local fixdesc = self:fixFunctionDesc(func)
	desc = desc..fixdesc
	if self:isMarked(func, "function", parent, desc) then return end

	local i = 1
	while true do
		local name, value = debug.getupvalue(func, i)
		if not name then break end
		if name == "" then
			name = "[upvalue]"
		end
		
		self:searchObject(value, func, name)
		i = i + 1
	end
end

function MemLeak:fixUserdataDesc(object, desc)
	local fixdesc = ""
	-- add your own custom	
	return fixdesc
end

function MemLeak:searchUserdata(object, parent, desc)
	local fixdesc = self:fixUserdataDesc(object, desc)
	desc = desc..fixdesc
	
	if self:isMarked(object, "userdata", parent, desc) then return end
	
	local meta = debug.getmetatable(object)
	if meta then
		self:searchObject(meta, object, "[metatable]")
	end
end

function MemLeak:memCount()
	self:prints(collectgarbage("count"))
end

function MemLeak:memCollect()
	self:prints("before collect: ", collectgarbage("count"))
	self:prints(collectgarbage("collect"))
	self:prints("after collect: ", collectgarbage("count"))
end

function MemLeak:searchGlobe()
	self:searchTable(_G, 0, "[globe]")
end

function MemLeak:searchRegistry()
	local registry = debug.getregistry()
	self:searchTable(registry, 0, "[registry]")
end

function MemLeak:prints(...)
	local outStr = ""
	for i = 1, arg.n do
		local temp = arg[i] or ""
		outStr = outStr..tostring(arg[i]).."\t"
	end
	outStr = outStr.."\n"
	self.output:write(outStr)
end

function MemLeak:setOutput(output)
	if not output then
		self:prints("error output!")
		return
	end
	self.output = output
end

function MemLeak:closeOutput()
	self.output:close()
end

function MemLeak:flushOutput()
	self.output:flush()
end

function MemLeak:printResult(key, value)
	local ref, varType, parents, desc = value[1], value[2], value[3], value[4]
	local str2 = ""
	for i = 1, #parents do
		self:intoRelation(key, parents[i])
		str2 = parents[i].."\t"..str2
	end
	local str1 = stringFormat("object:%s\tdesc:%s\ttype:%s\tref:%s\tparent:%s", key, desc, varType, ref, str2)
	self:prints(str1)
end

function MemLeak:intoRelation(object, parent)
	local parentsValue = self.parentsValue
	
	local value = parentsValue[parent]
	if not value then
		parentsValue[parent] = 1
	else
		parentsValue[parent] = value + 1
	end
end

function MemLeak:printRelation()
	local parentsValue = self.parentsValue
	self:prints("value count list:")
	for k, v in pairs(parentsValue) do
		self:prints("parent:"..k, "value count:", v)
	end
	self:prints("\n")
end

function MemLeak:createOutfile(filename)
	local file = assert(io.open(filename, "w"))
	self:setOutput(file)
end

function MemLeak:init(filename)
	self:createOutfile(filename)
end

------------------------------------------------
-- test
-- MemLeak:init([[memleak.log]]) -- init MemLeak op
-- MemLeak:cacheMemory() -- cache memory1

-- local aaaaaaaaa = {}
-- bbbbbbbbbb = {}

-- MemLeak:cacheMemory() -- cache memory2
-- MemLeak:differCache()    -- differ memory cache
---------------------------------------------------------
