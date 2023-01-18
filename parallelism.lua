
local parallelism = {}

local randomgen = {}
randomgen.history = {}


function randomgen.seed(seed)
	randomgen.state = seed
end
randomgen.seed(os.time())
function randomgen.release(state)
	randomgen.history[state] = nil
end

function randomgen.random()
	local x = math.sin(randomgen.state) * 10000
	randomgen.state = x - math.floor(x)	
	return randomgen.state
end

local function file_exists(path)
	local file = io.open(path, "rb")
	if file then
		file:close()
		return true
	end
	
	-- File does not exist, but maybe it's a directory.
	local success, _, code = os.rename(path, path)
	if success or code == 13 then
		-- It's a directory or something we can't delete, so it must exist.
		return true
	end
	
	return false
end
function string_findlast(str,pat)
	local sspot,lspot = str:find(pat)
	local lastsspot, lastlspot = sspot, lspot
	while sspot do
		lastsspot, lastlspot = sspot, lspot
		sspot, lspot = str:find(pat,lastlspot+1)
	end
	return lastsspot, lastlspot
end
function getEXT(file)
	local extstart = string_findlast(file,"%.")
	if extstart then--and extstart > ((file:find("\\")) or 0) then
		return (file:sub(extstart+1,#file))
	end
	return ""
end
function concatunderEXT(name,con)
	local dot = string_findlast(name,"%.")
	if dot then
		return (name:sub(1,dot-1))..con..(name:sub(dot,#name))
	else
		return name..con
	end
end





local incrementHistory = {}

local function incrementName(path)
	incrementHistory[path] = incrementHistory[path] or 1
	local addednumber = ""
	local numbertotry = incrementHistory[path]
	numbertotry = numbertotry+1
	addednumber = tostring(numbertotry)
	incrementHistory[path] = numbertotry
	return path..addednumber
end

local function generate_random_filename()
	local charset = {}  -- table to store the characters in the filename
	-- populate the `charset` with numbers, uppercase letters, and lowercase letters
	for i = 48, 57 do  -- ASCII values for digits 0 to 9
		charset[#charset+1] = string.char(i)
	end
	for i = 65, 90 do  -- ASCII values for uppercase letters A to Z
		charset[#charset+1] = string.char(i)
	end
	for i = 97, 122 do  -- ASCII values for lowercase letters a to z
		charset[#charset+1] = string.char(i)
	end
	-- create the filename by selecting random characters from the `charset`
	local filename = ""
	for i = 1, 20 do  -- filename will be 20 characters long
		local index = math.ceil(randomgen.random()*#charset)  -- select a random index from the `charset`
		filename = filename .. charset[index]  -- add the character to the filename
	end
	return incrementName(filename)
end




local function copy_file(src, dest)
	local ok, src_file = pcall(io.open, src, 'rb')
	if not ok then
		return false, src_file
	end
	local ok, dest_file = pcall(io.open, dest, 'wb')
	if not ok then
		src_file:close()
		return false, dest_file
	end
	while true do
		local chunk = src_file:read(1024)
		if chunk == nil then break end
		dest_file:write(chunk)
	end
	src_file:close()
	dest_file:close()
	return true
end

local function get_temp_file()
	return generate_random_filename()
end

local os_temp_dir = os.getenv('TEMP') or os.getenv('TMP') or '.'
local function get_temp_file_path()
	local temppath = os_temp_dir .. "\\" .. get_temp_file()
	if file_exists(temppath) then
		return get_temp_file_path()
	end
	return temppath
end



local function string_findlast(str,pat)
	local sspot,lspot = str:find(pat)
	local lastsspot, lastlspot = sspot, lspot
	while sspot do
		lastsspot, lastlspot = sspot, lspot
		sspot, lspot = str:find(pat,lastlspot+1)
	end
	return lastsspot, lastlspot
end

local function folderUP(path,num)	
	num = num or 1
	local look = string_findlast(path,[[\]])
	if look then 
		local upafolder = path:sub(1,look-1)
		if num > 1 then
			return folderUP(upafolder,num-1)
		else
			return upafolder
		end
	else
		return ""
	end
end

local function endOfPath(f)
	local prevPath = folderUP(f)
	local cutspot = #prevPath
	if cutspot == 0 then
		cutspot = -1
	end
	return f:sub(cutspot+2,#f)
end


local function is_executable_running(executable_path)
	local handle = io.popen("ps -W")
	local result = handle:read("*a")
	handle:close()
	local processes = {}
	for process in string.gmatch(result, "[^\n]+") do
		processes[(process:sub(65,#process))] = true
	end
	return processes[executable_path] == true
end

local function table_to_string(t, name, indent)

	local table_insert = table.insert
	local table_remove = table.remove
	local table_concat = table.concat
	local string_format = string.format
	local cart
	local autoref
	local function isemptytable(t) return next(t) == nil end
	local function basicSerialize (o)
		local so = tostring(o)
		if type(o) == "function" then
			local info = debug.getinfo(o, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return string_format("%q", so .. ", C function")
			else
				-- the information is defined through lines
				return string_format("%q", so .. ", defined in (" ..
				info.linedefined .. "-" .. info.lastlinedefined ..
				")" .. info.source)
			end
		elseif type(o) == "number" or type(o) == "boolean" then
			return so
		else
			return string_format("%q", so)
		end
	end
	local function addtocart (value, name, indent, saved, field)
		indent = indent or ""
		saved = saved or {}
		field = field or name
		local item = indent .. field
		if type(value) ~= "table" then
			table_insert(cart, item .. " = " .. basicSerialize(value) .. ";")
		else
			if saved[value] then
				table_insert(cart, item .. " = {}; -- " .. saved[value] .. " (self reference)")
				table_insert(autoref, name .. " = " .. saved[value] .. ";")
			else
				saved[value] = name
				if isemptytable(value) then
					table_insert(cart, item .. " = {};")
				else
					table_insert(cart, item .. " = {")
					for k, v in pairs(value) do
						k = basicSerialize(k)
						local fname = string_format("%s[%s]", name, k)
						field = string_format("[%s]", k)
						-- three spaces between levels
						addtocart(v, fname, indent .. "\t", saved, field)
					end
					table_insert(cart, indent .. "};")
				end
			end
		end
	end
	name = name or "__"..type(t).."__"
	if type(t) ~= "table" then
		return name .. " = " .. basicSerialize(t)
	end
	cart, autoref = {}, {}
	addtocart(t, name, indent)
	for _, line in ipairs(autoref) do
		table_insert(cart, line)
	end
	table_insert(cart, "")
	return ( table_concat(cart, "\n"))
end


local print_table_to_string_code = [[local function print_table_to_string(t, name, indent)

	local table_insert = table.insert
	local table_remove = table.remove
	local table_concat = table.concat
	local string_format = string.format

	if type(t) ~= "table" then
		print("__table__ = {"..tostring(t).."}") return
	end
	local cart
	local autoref
	local function isemptytable(t) return next(t) == nil end
	local function basicSerialize (o)
		local so = tostring(o)
		if type(o) == "function" then
			local info = debug.getinfo(o, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return string_format("%q", so .. ", C function")
			else
				-- the information is defined through lines
				return string_format("%q", so .. ", defined in (" ..
				info.linedefined .. "-" .. info.lastlinedefined ..
				")" .. info.source)
			end
		elseif type(o) == "number" or type(o) == "boolean" then
			return so
		else
			return string_format("%q", so)
		end
	end
	local function addtocart (value, name, indent, saved, field)
		indent = indent or ""
		saved = saved or {}
		field = field or name
		local item = indent .. field
		if type(value) ~= "table" then
			table_insert(cart, item .. " = " .. basicSerialize(value) .. ";")
		else
			if saved[value] then
				table_insert(cart, item .. " = {}; -- " .. saved[value] .. " (self reference)")
				table_insert(autoref, name .. " = " .. saved[value] .. ";")
			else
				saved[value] = name
				if isemptytable(value) then
					table_insert(cart, item .. " = {};")
				else
					table_insert(cart, item .. " = {")
					for k, v in pairs(value) do
						k = basicSerialize(k)
						local fname = string_format("%s[%s]", name, k)
						field = string_format("[%s]", k)
						-- three spaces between levels
						addtocart(v, fname, indent .. "\t", saved, field)
					end
					table_insert(cart, indent .. "};")
				end
			end
		end
	end
	name = name or "__"..type(t).."__"
	if type(t) ~= "table" then
		return name .. " = " .. basicSerialize(t)
	end
	cart, autoref = {}, {}
	addtocart(t, name, indent)
	for _, line in ipairs(autoref) do
		table_insert(cart, line)
	end
	table_insert(cart, "")
	print( table_concat(cart, "\n"))
end
]]



local function splitstring(str,pat)
	local listowords = {}
	while str:find(pat) do
		local found, foundend = str:find(pat)
		table.insert(listowords,str:sub(1,found-1))
		if foundend < #str then
			str = str:sub(foundend+1,#str)
		else
			str = false
			break
		end
	end
	if str then
		table.insert(listowords,str)
	end
	return listowords
end

local function space2quote(str)
	return str:gsub(" ",'" "')
end



local function getVariableNames(code)
	local variableNames = {}
	local _,fend = code:find("function")
	local _,pstart = code:find("%(",fend)
	local _,pend = code:find("%)",pstart)
	local snip = code:sub(pstart+1,pend-1)
	snup = snip:gsub(" ","")
	local vars = splitstring(snip,",")
	for _,var in pairs(vars) do
		table.insert(variableNames, var)
	end
	return variableNames
end


local function searchlib(name, path)
  local error_message = string.format("no file '%s' in path '%s'", name, path)
  for pattern in string.gmatch(path, "[^;]+") do
    local file_path = string.gsub(pattern, "%?", name)
    local file = io.open(file_path)
    if file then
      file:close()
      return file_path:sub(3,#file_path)
    end
  end
  return nil, error_message
end



local function extract_required_libraries(script)
	local required_libraries = {}
	local balance = 0
	local library_start, library_end
	local escape_next_char = false
	local in_long_form = false
	local in_interpolation = false
	local in_comment = false
	for i = 1, #script do
		local c = script:sub(i, i)
		if escape_next_char then
		escape_next_char = false
		elseif c == "\\" then
		escape_next_char = true
		elseif in_comment then
		if c == "\n" then
			in_comment = false
		end
		elseif in_long_form then
		if c == "]" then
			in_long_form = false
		end
		elseif in_interpolation then
		if c == "}" then
			in_interpolation = false
		end
		elseif c == '"' or c == "'" then
		if balance == 0 then
			library_start = i + 1
		else
			library_end = i - 1
			local library_name = script:sub(library_start, library_end)
			local library_path = searchlib(library_name, package.path)
			required_libraries[#required_libraries + 1] = library_path
		end
		balance = 1 - balance
		elseif c == "[" then
		in_long_form = true
		elseif c == "{" then
		in_interpolation = true
		elseif c == "-" and script:sub(i, i + 1) == "--" then
		in_comment = true
		end
	end
	return required_libraries
end





local function getFunctionCode(function_or_string_of_function)
	local function findvars(fcode)
		local codestring = false
		if type(fcode) == "table" then
			codestring = table.concat(fcode, "\n")
		elseif type(fcode) == "function" then
			return
		end
		local vars = getVariableNames((codestring or fcode))
		table.remove(fcode)
		table.remove(fcode,1)
		return table.concat(fcode, "\n"), vars
	end
	local code,vars = findvars(function_or_string_of_function)
	if code then
		return code, vars
	end
	local info = debug.getinfo(function_or_string_of_function, "S")
	if info.source:sub(1, 1) == "@" then
		local file = assert(io.open(info.source:sub(2), "r"))
		local source = file:read("*all")
		file:close()
		local lines = {}
		local alllines = splitstring(source,"\n")
		local linenum = 1
		for i,line in ipairs(alllines) do
			if i >= info.linedefined and linenum <= info.lastlinedefined then
				table.insert(lines, line)
			end
			linenum = linenum+1
		end
		return findvars(lines)
	else
		return info.source
	end
end


local function swapReturns(code)
	local returnPos, returnPosEnd = code:find("%s(return)%s")
	if not returnPos then
		return code:gsub("return_placeholder","return")
	end
	if returnPos then
		local before = code:sub(1, returnPos - 1)
		local after = code:sub(returnPosEnd + 1)
		local inside = ""
		local newlinePos = after:find("\n")
		if not newlinePos then
			newlinePos = #after+1
		end
		if newlinePos then
			after = after:sub(newlinePos + 1)
			inside = code:sub(returnPosEnd + 1, returnPosEnd + newlinePos - 1)
		end
		local modifiedCode = before .. "print_table_to_string(" .. inside .. ") return_placeholder\n"..after
		return swapReturns(modifiedCode)
	else
		return code
	end
end


function modify_executable_references(code, number)
	-- Find all string values in the code
	local strings = {}
	for str in string.gmatch(code, "'([^']*)'") do
		strings[#strings + 1] = str
	end
	for str in string.gmatch(code, '"([^"]*)"') do
		strings[#strings + 1] = str
	end
	for str in string.gmatch(code, "%[%[(.-)%]]") do
		strings[#strings + 1] = str
	end
	-- Replace all occurrences of ".exe" with the desired number
	for _, str in ipairs(strings) do
	code = string.gsub(code, str, string.gsub(str, ".exe", tostring(number) .. ".exe"))
	end
	
	return code
end


local threadFunctions = {}

function threadFunctions:isRunning()
	if is_executable_running(self.path_to_lua_executable..".exe") then
		return true
	else	
		return false
	end
end

function threadFunctions:remove()
	os.remove(self.path_to_lua_executable..".exe")
	os.remove(self.path_to_lua_executable..".lua")
end

function threadFunctions:getExecutableName()
	return endOfPath(self.path_to_lua_executable..".exe")
end

function threadFunctions:start()
	self.handle = io.popen(self.execute_command)
	return self.handle
end
function threadFunctions:stop()
	os.execute([[taskkill /F /IM "]]..(self:getExecutableName())..[["]])
end

function threadFunctions:getResults(force)
	if self.result then
		return self.result
	end
	if not force and self:isRunning() then
		return nil
	end
	local result = self.handle:read("*all")
	self.handle:close()
	local tmpfile = self.processing_node.tempdir.."\\"..get_temp_file()
	local tfile = assert(io.open(tmpfile, "w"))
	tfile:write("local " .. result.." return __table__")
	tfile:close()
	local result
	local OK, value = pcall(dofile,tmpfile)
	if OK then
		result = value
	else
		result = value
	end
	os.remove(tmpfile)
	self.result = result
	return result
end


local nodeFunctions = {}

function nodeFunctions:add_requirement(name_of_exe)
	table.insert(self.requirements,name_of_exe)
end
function nodeFunctions:isRunning()
	for i,thread in ipairs(self.threads) do
		if thread:isRunning() then
			return true
		end
	end
	return false
end

function nodeFunctions:clear(allthreads)
for _,thread in ipairs(self.threads) do
	thread:remove()
end
self.threads = {}
self.results = {}


end
function nodeFunctions:remove()

	for _,thread in ipairs(self.threads) do
		thread:remove()
	end
	os.remove(self.tempdir.."\\"..[[lua5.1.dll]])
	--for _,library_path in pairs(self.libraries) do
	--	os.remove(self.tempdir.."\\"..library_path)
	--end
	for path_to_exe,_ in pairs(self.execache) do
		os.remove(path_to_exe)
	end
	os.execute([[rmdir "]]..self.tempdir..[["]])
	self = nil
end


function nodeFunctions:getResults(force)
	self.results = self.results or {}
	for i,thread in ipairs(self.threads) do
		self.results[i] = self.results[i] or thread:getResults(force)
	end
	if self.results and #self.results == #self.threads then		
		return self.results
	else
		return false
	end
end



function nodeFunctions:stop(num)
	for i,thread in ipairs(self.threads) do
		if type(num) == "table" then
			for j=1,#num do
				if num[j] == i then
					thread:stop()
				end
			end
		elseif type(num) == "number" then
			if num == i then
				thread:stop()
			end
		elseif not num then
			thread:stop()
		end
	end
	if not num then
		self:remove()
	end
end

local function storeThread(name,execute_command)
	local thread = {}
	thread.execute_command = execute_command
	thread.path_to_lua_executable = name
	thread.__index = thread
	for k,v in pairs(threadFunctions) do
		if thread[k] == nil then
			thread[k] = v
		end
	end
	return thread
end


local function prepareExecutable(code,processing_node)
	local tmpFile = get_temp_file()
	local file = assert(io.open(processing_node.tempdir.."\\"..tmpFile .. ".lua", "w"))
	file:write(code)
	file:close()
	local ok,err = copy_file("lua.exe", processing_node.tempdir.."\\"..tmpFile..[[.exe]])
	if not ok then
		return false, err
	end
	local command = (space2quote(processing_node.tempdir.."\\"..tmpFile..[[.exe]])..[[ ]]..space2quote(processing_node.tempdir.."\\"..tmpFile..[[.lua]])..[[ 2>&1]])
	return processing_node.tempdir.."\\"..tmpFile, command
end

function nodeFunctions:newThread(function_or_string_of_function, ...)
	local pass_to_thread = {...}
	local function format_variable(value,variable_name)
		local vtype = type(value)
		local formatted_variable = "local "
		if vtype == "table" then
			formatted_variable = formatted_variable..table_to_string(value, variable_name)	
		elseif vtype == "string" then
			formatted_variable = formatted_variable..variable_name.." = ".."[["..value.."]]"
		else
			formatted_variable = formatted_variable..variable_name.." = "..tostring(value)
		end
		return formatted_variable
	end
	local code_to_run, function_params = getFunctionCode(function_or_string_of_function)
	for param_index,variable_name in ipairs(function_params) do
		if pass_to_thread[param_index] then	
			code_to_run = format_variable(pass_to_thread[param_index],variable_name).."\n"..code_to_run
		end
	end
	--self.libraries = extract_required_libraries(code_to_run)
	--for _,library_path in pairs(self.libraries) do
	--	--print(lib)
	--	copy_file(library_path, self.tempdir.."\\"..library_path)
	--end
	if self.multiply_executable then
		for _,name_of_exe in ipairs(self.requirements) do
			local incremented_path = concatunderEXT(name_of_exe,#self.threads)
			if not file_exists(incremented_path) then
				copy_file(name_of_exe, incremented_path)
				self.execache[incremented_path] = true
			end
			
		end
		code_to_run = modify_executable_references(code_to_run,#self.threads)
	end
	
	code_to_run = swapReturns(code_to_run)
	code_to_run = print_table_to_string_code.."\n"..code_to_run
	local newthread = storeThread(prepareExecutable(code_to_run,self))
	newthread.processing_node = self
	table.insert(self.threads, newthread)
	return newthread
end


function nodeFunctions:run(function_or_string_of_function, ...)
	local new_thread = self:newThread(function_or_string_of_function, ...)
	new_thread:start()
	return new_thread
end

local function make_processing_node()
	local processing_node = {}
	processing_node.tempdir = get_temp_file_path()
	os.execute([[mkdir "]]..processing_node.tempdir..[["]])
	copy_file("lua5.1.dll", processing_node.tempdir.."\\"..[[lua5.1.dll]])
	processing_node.multiply_executable = false
	processing_node.requirements = {}
	processing_node.threads = {}
	processing_node.execache = {}
	processing_node.__index = processing_node
	for k,v in pairs(nodeFunctions) do
		if processing_node[k] == nil then
			processing_node[k] = v
		end
	end
	return processing_node
end






parallelism.new = make_processing_node


return parallelism
