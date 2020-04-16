--复制一张表
function table_copy(t)
    local m = {}
    for k, v in pairs(t) do
        m[k] = v
    end
    return m
end


--转为字符串
function table_tostring(t, maxlayer, name)
	local tableDict = {}
	local layer = 0
	maxlayer = maxlayer or 999
	local function cmp(t1, t2)
		return tostring(t1) < tostring(t2)
	end
	local function table_r (t, name, indent, full, layer)
		local id = not full and name or type(name)~="number" and tostring(name) or '['..name..']'
		local tag = indent .. id .. ' = '
		if string.len(tag) > 10000 then
			error("############### log long 10000")
			return table.concat(out, '\n')
		end

		local out = {}  -- result
		if type(t) == "table" and layer < maxlayer then
			if tableDict[t] ~= nil then
				table.insert(out, tag .. '{} -- ' .. tableDict[t] .. ' (self reference)')
			else
				tableDict[t]= full and (full .. '.' .. id) or id
				if next(t) then -- Table not empty
					table.insert(out, tag .. '{')
					local keys = {}
					for key,value in pairs(t) do
						table.insert(keys, key)
					end
					table.sort(keys, cmp)
					for i, key in ipairs(keys) do
						local value = t[key]
						table.insert(out,table_r(value,key,indent .. '   ',tableDict[t], layer + 1))
					end
					table.insert(out,indent .. '}')
				else table.insert(out,tag .. '{}') end
			end
		else
			local val = type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t)
			table.insert(out, tag .. val)
		end
		return table.concat(out, '\n')
	end
	return table_r(t,name or 'Table', '', '', layer)
end

--输出table
function table_print(t, name, maxlayer)
	print(table_tostring(t, maxlayer, name))
end

--table的key个数
function table_count(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

--获得表的key
function table_key(t, v)
	for k1, v1 in pairs(t) do
		if v1 == v then
			return k1
		end
	end
end

--获得取反表
function table_negative(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[k] = -v
	end
	return ret
end

--获得区间值
function table_in_range(t,value,default)
	for _,r in ipairs(t) do
		if r[1] <= value then
			return r[2]
		end
	end
	return default
end