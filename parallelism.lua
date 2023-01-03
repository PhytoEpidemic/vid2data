
local parallelism = {}


function copy_and_verify_file(src, dest)
  -- Open the source file for reading in binary mode
  local ok, src_file = pcall(io.open, src, 'rb')
  if not ok then
    return false, src_file
  end

  -- Open the destination file for writing in binary mode
  local ok, dest_file = pcall(io.open, dest, 'wb')
  if not ok then
    src_file:close()
    return false, dest_file
  end

  -- Read the contents of the source file in chunks and write them to the destination file
  while true do
    local chunk = src_file:read(1024)
    if chunk == nil then break end
    dest_file:write(chunk)
  end

  -- Close both files
  src_file:close()
  dest_file:close()

  -- Open the source file and destination file for reading in binary mode
  ok, src_file = pcall(io.open, src, 'rb')
  if not ok then
    return false, src_file
  end
  ok, dest_file = pcall(io.open, dest, 'rb')
  if not ok then
    src_file:close()
    return false, dest_file
  end

  -- Compare the contents of the two files by reading and comparing chunks
  while true do
    local src_chunk = src_file:read(1024)
    local dest_chunk = dest_file:read(1024)
    if src_chunk ~= dest_chunk then
      -- The files are different, so delete the destination file and return false
      src_file:close()
      dest_file:close()
	  os.remove(dest)
      return false, 'File copy verification failed: file contents do not match'
    end
    if src_chunk == nil then break end
  end

  -- Close both files
  src_file:close()
  dest_file:close()

  -- The files are the same, so return true
  return true
end


function get_temp_file_path()
  -- Get the path to the default temporary directory
  local temp_dir = os.getenv('TEMP') or os.getenv('TMP') or '.'

  -- Generate a temporary file name using the os.tmpname function
  local temp_name = os.tmpname():gsub("\\",""):gsub("%.","")

  -- Return the full path to the temporary file
  return temp_dir .. "\\" .. temp_name
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
function startswith(st,pat)
	return st:sub(1,#pat) == pat
end
function endswith(st,pat)
	return st:sub(#st-(#pat-1),#st) == pat
end
function folderUP(path,num)	
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

function endOfPath(f)
	local prevPath = folderUP(f)
	local cutspot = #prevPath
	if cutspot == 0 then
		cutspot = -1
	end
	return f:sub(cutspot+2,#f)
end


function is_executable_running(executable_path)
  -- Use the `ps -W` command to get a list of all running processes
  local handle = io.popen("ps -W")
  local result = handle:read("*a")
  handle:close()

  -- Split the result into a list of process names
  local processes = {}
  for process in string.gmatch(result, "[^\n]+") do
    processes[(process:sub(65,#process))] = true
	--print(endOfPath(process:sub(65,#process))== executable_path)
  end
	--print(executable_path)
  -- Check if the executable is in the list of processes
  return processes[executable_path] == true
end

function table_to_string(t, name, indent)

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
function table_save(tab,path)
	local File = io.open(path, "w")
	if not File then
		return false
	end
	File:write("local "..table_tostring(tab,"table").."return table")
	File:close()
	return true
end


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


local function runCode(code,node)
	-- Generate a unique file name for the temporary file
	local tmpFile = os.tmpname():gsub("\\",""):gsub("%.","")
	-- Write the code to a temporary file
	local file = assert(io.open(node.tempdir.."\\"..tmpFile .. ".lua", "w"))
	--print("tofile",code)
	file:write(code)
	file:close()
	local ok,err = copy_and_verify_file("lua.exe", node.tempdir.."\\"..tmpFile..[[.exe]])
	if not ok then
		return false, err
	end
	-- Generate a command to run the code and redirect the output to the temporary file
	
	local command = (space2quote(node.tempdir.."\\"..tmpFile..[[.exe]])..[[ ]]..space2quote(node.tempdir.."\\"..tmpFile..[[.lua]])..[[ 2>&1]])
	
	-- Run the command
	--print(command)
	
	
	
	-- Return the path to the temporary file
	return node.tempdir.."\\"..tmpFile, io.popen(command)
end

local function getVariableNames(code)
	-- Extract the variable names from the code
	local variableNames = {}

	local _,fend = code:find("function")
	local _,pstart = code:find("%(",fend)
	local _,pend = code:find("%)",pstart)
	--print("test",code,pstart,pend)
	local snip = code:sub(pstart+1,pend-1)
	snup = snip:gsub(" ","")
	local vars = splitstring(snip,",")
	for _,var in pairs(vars) do
		table.insert(variableNames, var)
	end


	for _,n in pairs(variableNames) do
		--print(n)
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



function extract_required_libraries(script)
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





local function getFunctionCode(fn)
  -- Get the debug information for the function
  
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
	local code,vars = findvars(fn)
	if code then
		return code, vars
	end
	local info = debug.getinfo(fn, "S")
	
  -- Check if the function is defined in a file
  --print(info.source)
  if info.source:sub(1, 1) == "@" then
    -- Read the source code of the file
    local file = assert(io.open(info.source:sub(2), "r"))
    local source = file:read("*all")
    file:close()

    -- Extract the code of the function from the source code
    local lines = {}
	local alllines = splitstring(source,"\n")
    local linenum = 1
	for i,line in ipairs(alllines) do
		--print(info.linedefined,info.lastlinedefined, linenum, line)
		if i == info.linedefined then

		end
		if i >= info.linedefined and linenum <= info.lastlinedefined then
			table.insert(lines, line)
		end


	  linenum = linenum+1
    end
    return findvars(lines)
  else
    -- Return the source of the function if it is not defined in a file
    return info.source
  end
end


local function swapReturns(code)
    -- Find the position of the "return" keyword
    local returnPos, returnPosEnd = code:find("%s(return)%s")
    if not returnPos then
        return code:gsub("return_placeholder","return")
    end

    -- Check if the "return" keyword was found
    if returnPos then
        -- Extract the part of the code before the "return" keyword
        local before = code:sub(1, returnPos - 1)

        -- Extract the part of the code after the "return" keyword
        local after = code:sub(returnPosEnd + 1)
        local inside = ""
        local newlinePos = after:find("\n")
		if not newlinePos then
			newlinePos = #after+1
		end
        if newlinePos then
            -- There is a newline character after the "return" keyword
            after = after:sub(newlinePos + 1)
            inside = code:sub(returnPosEnd + 1, returnPosEnd + newlinePos - 1)
        end

        -- Trim leading and trailing whitespace from the part of the code after the "return" keyword
        --after = after:match("^%s*(.-)%s*$")

        -- Check if there are any characters after the "return" keyword
        
        -- Build the modified code with the value after the "return" keyword as the argument to "print_table_to_string()"
        local modifiedCode = before .. "print_table_to_string(" .. inside .. ") return_placeholder\n"..after
        return swapReturns(modifiedCode)
    else
        -- Return the original code if the "return" keyword was not found
        return code
    end
end

local threadFunctions = {}

function threadFunctions:isRunning()
	if is_executable_running(self.processName..".exe") then
		return true
	else
		
		return false
	end
	
end

function threadFunctions:cleanUP()
	--self:stopThread()
	os.remove(self.processName..".exe")
	os.remove(self.processName..".lua")

end

function threadFunctions:stopThread()

	os.execute([[taskkill /F /IM "]]..endOfPath(self.processName)..[[.exe"]])
end

function threadFunctions:getResults(force)
	if self.result then
		return self.result
	end
	if not force and self:isRunning() then
		return nil
	end
	--print("uh")
	local result = self.handle:read("*all")
	self.handle:close()
	local tmpfile = get_temp_file_path()
	local tfile = assert(io.open(tmpfile, "w"))
	tfile:write("local " .. result.." return __table__")
	tfile:close()
	
	
	local result
	-- Parse the result from the file
	local OK, value = pcall(dofile,tmpfile)
	if OK then
		result = value
	else
		result = value
	end
	-- Delete the temporary file
	os.remove(tmpfile)
	self.result = result
	return result
end

--threadFunctions.__index = threadFunctions
local function storeThread(name,handle)
	local thread = {}
	thread.handle = handle
	thread.processName = name
	thread.__index = thread
	for k,v in pairs(threadFunctions) do
		if thread[k] == nil then
			thread[k] = v
		end
	end
	return thread--table.insert(parallelism.threads, thread)
end

local nodeFunctions = {}

function nodeFunctions:isRunning()
	for i,thread in ipairs(self.threads) do
		if thread:isRunning() then
			return true
		end
	end
	return false
end

function nodeFunctions:clear(allthreads)

self.threads = {}
self.results = {}


end
function nodeFunctions:cleanUP(allthreads)
	if allthreads then
		for _,thread in ipairs(self.threads) do
			thread:cleanUP()
		end
	end
	os.remove(self.tempdir.."\\"..[[lua5.1.dll]])
	--for _,library_path in pairs(self.libraries) do
	--	os.remove(self.tempdir.."\\"..library_path)
	--end
	
	os.execute([[rmdir "]]..self.tempdir..[["]])
	
	
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



function nodeFunctions:stopThread(num)
	for i,thread in ipairs(self.threads) do
		if type(num) == "table" then
			for j=1,#num do
				if num[j] == i then
					thread:stopThread()
				end
			end
		elseif type(num) == "number" then
			if num == i then
				thread:stopThread()
			end
		elseif not num then
			thread:stopThread()
		end
	end
	if not num then
		self:cleanUP()
	end

end
local function makeNode()
	local node = {}
	node.tempdir = get_temp_file_path()
	os.execute([[mkdir "]]..node.tempdir..[["]])
	copy_and_verify_file("lua5.1.dll", node.tempdir.."\\"..[[lua5.1.dll]])
	node.threads = {}
	node.__index = node
	for k,v in pairs(nodeFunctions) do
		if node[k] == nil then
			node[k] = v
		end
	end
	return node
end


local function map(fn, tbl, node)
	local node = node or makeNode()
	
	-- Start a new process for each element in the table
	local function makeThread(elem)
		local function prepVar(var,name)
			
			local vtype = type(var)
			if vtype == "table" then
				var = table_to_string(var, name)	
			elseif vtype == "string" then
			
				var = name.." = ".."[["..var.."]]"
				
			else
				var = name.." = "..tostring(var)
			end
			return var
		end
		
		local code, varnames = getFunctionCode(fn)
		
		for v,name in ipairs(varnames) do
		--print(v,name)
			
		end
		if type(elem) == "table" then
			for j,value in pairs(elem) do
				
			end
			for v,name in ipairs(varnames) do
	
				if elem[v] then
					
					
					
					code = "local "..prepVar(elem[v],name).."\n"..code
	
				end
			end
		elseif type(elem) ~= "table" and elem ~= nil then
			for n,v in pairs(varnames) do
				--print(n.." -in- "..v)
			end
			if varnames[1] then
				code = "local "..prepVar(elem,varnames[1]).."\n"..code
				--print(code)
			end
			
		end
		
		--node.libraries = extract_required_libraries(code)
		--for _,library_path in pairs(node.libraries) do
		--	--print(lib)
		--	copy_and_verify_file(library_path, node.tempdir.."\\"..library_path)
		--end
		
		code = swapReturns(code)
		code = print_table_to_string_code.."\n"..code
		--print("---------code")
		--print(code)
	
		table.insert(node.threads, storeThread(runCode(code,node)))
	end
	if type(tbl) == "table" then
	
		for i, elem in ipairs(tbl) do
			makeThread(elem)
			
		end
	else
		makeThread(tbl)
	end
	
	
	
	
	return node
end
--print(is_executable_running("lua.exe"))


parallelism.run = map
return parallelism
