lfs = require("lfs")
imagedim = require("imagedim")
lfsaddons = require("lfsaddons")
parallelism = require("parallelism")
function exe(str)
	os.execute(str)
end
function stitle(s)
	exe([[title vid2data.exe ]]..s)
end
function rtitle()
	stitle("")
end
function cls()
	exe("cls")
end
function pause()
	exe("pause")
end
local unallowedNames = {
["."] = true,
[".."] = true,
["desktop.ini"] = true,
}
function isAllowed(n)
	return not (unallowedNames[n] or false)
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
function makeDir(path)
	local snip = folderUP(path)
	local attr = getAttributes(snip)
	if attr and attr.mode == "directory" then
	else makeDir(snip)
	end
	return lfs.mkdir(path)
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

function incrementPathName(path,limit)
	incrementHistory[path] = incrementHistory[path] or 2
	local addednumber = ""
	local numbertotry = incrementHistory[path]
	limit = tonumber(limit) or 99999999
	while limit > 1 do
		local filesavepath = concatunderEXT(path, addednumber)
		if lfs.attributes(filesavepath) then
			if addednumber == "" then
				addednumber = "_(2)"
			else
				numbertotry = numbertotry+1
				addednumber = "_("..tostring(numbertotry)..")"
			end
		else
			local hcount = 0
			for _,_ in pairs(incrementHistory) do
				hcount = hcount+1
			end
			if hcount > 10000 then
				incrementHistory = {}
			end
			incrementHistory[path] = numbertotry
			return filesavepath
		end
		limit = limit - 1
	end
end
function secondsToReadable(sec)
	if not tonumber(sec) then
		return sec
	end
	local readable = ""
	local int
	local addS
	int = math.floor(sec/60/60/24)
	if int > 0 then
		if int ~= 1 then addS = "s" else addS = "" end
		readable = readable..(int).." day"..addS..", "
	end
	int = math.floor(sec/60/60)
	if int > 0 then
		if int%24 ~= 1 then addS = "s" else addS = "" end
		readable = readable..(int%24).." hour"..addS..", "
	end
	int = math.floor(sec/60)
	if int > 0 then
		if int%60 ~= 1 then addS = "s" else addS = "" end
		readable = readable..(int%60).." minute"..addS.." and "
	end
	int = math.floor(sec)
	if int > 0 then
		if int%60 ~= 1 then addS = "s" else addS = "" end
		readable = readable..(int%60).." second"..addS
	else
		readable = readable..(math.floor(sec*10)/10).." seconds"
	end
	return readable
end

function padNum(str)
	local fulldigits = [[00000000]]
	str = str:gsub(" ","")
	return (fulldigits:sub(#str+1,#fulldigits))..str
end

function splitImage(tw,th,ow,oh)
	local cells = {}
	local wsplits = ow/tw
	local wfull = math.floor(wsplits)
	local wextra = 1-(wsplits-wfull)
	local wpadding = (tw*wextra)/wfull
	local hsplits = oh/th
	local hfull = math.floor(hsplits)
	local hextra = 1-(hsplits-hfull)
	local hpadding = (th*hextra)/hfull
	if wsplits == 1 then
		wfull = 0
	end
	if hsplits == 1 then
		hfull = 0
	end
	for i=0,wfull do
		for j=0,hfull do
			local cell = {}
			cell.w = tw
			cell.h = th
			cell.x = i*tw
			if i>0 then
				cell.x = cell.x-wpadding*(i)
			end
			cell.y = j*th
			if j>0 then
				cell.y = cell.y-hpadding*(j)
			end
			table.insert(cells,cell)
		end
	end
	return cells
end


function GPTsplitImage(tw,th,ow,oh)
    local cells = {}
    local wsplits = math.ceil(ow/tw)
    local hsplits = math.ceil(oh/th)
    for j=0,hsplits-1 do
        local y = j*th
        if j>0 then
            y = y - (th*(j-1))/(hsplits-1)
        end
        for i=0,wsplits-1 do
            local x = i*tw
            if i>0 then
                x = x - (tw*(i-1))/(wsplits-1)
            end
            local cell = {w=tw, h=th, x=x, y=y}
            table.insert(cells, cell)
        end
    end
    return cells
end





function splitstring(str,pat)
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


function printsettingstosconsole(config)
	if not config.folder then
		print("Selected Video: "..(config.vfile or "none"))
		print("Key frames only: "..(config.keyframesonly or "n"))
		print("Remove blurred frames: "..(config.removeblur or "n"))
	else
		print("Selected Folder: "..(config.vfile or "none"))
	end
	print("Custom name: "..(config.cfilename or "none"))
	print("Custom caption: "..(config.caption or "none"))
	print("Delete after slicing: "..(config.delimg or "n"))
	if config.WaH then
		if type(config.width) == "number" then
			print("Output width and height: "..tostring(config.width).."x"..tostring(config.height))
			
		else
			print("Output width and height: "..tostring(config.WaH))
		end
		
	else
		print("Output width and height: 512x512")
	end
	
end

captioncommands = {
	["--end"] = function(st,to)
		st = st..to
		return st
	end,
	["--start"] = function(st,to)
		st = to..st
		return st
	end,
	["--keep"] = function(st,to)
		return to
	end,
}

local supportedImageFiles = {["png"] = true, ["jpg"] = true, ["jpeg"] = true}
function isSupportedImage(extension)
	return supportedImageFiles[extension]
end




local function removeBlur(config)
	if config.removeblur == "y" then
		local blurlogf = io.open("log.txt","r")
		local framec = "0"
		local blur = "0"
		for line in blurlogf:lines() do
			if line:find("frame") then
				local ptss = line:find("pts")
				framec = (line:sub(7,ptss-2)):gsub(" ","")
				blur = "0"
			end
			
			if line:find("lavfi.blur=") then
				local _,skipstr = line:find("lavfi.blur=")
				blur = (line:sub(skipstr+1,#line)):gsub(" ","")
			end
			if framec ~= "0" and blur ~= "0" and blur ~= "nan" then
				local filename = padNum(framec)..".png"
				local blurnum = tonumber(blur)
				print(filename,blur,blurnum)
				if blurnum > (tonumber(config.removeblur) or 0) then
					
					os.remove(framesFolder.."\\"..filename)
					print(filename)
					print(blur)
				end
				
			end
		end
		blurlogf:close()
	end
	os.remove("log.txt")
end

function removeBl(config)
	local OK, er = pcall(removeBlur,config)
	if not OK then
		print(er)
		pause()
	end
end


function upscaleMedia(imagename,factor,suffix)
	local factor = tostring(factor or 2)
	suffix = suffix or "_d"..factor
	local outputname = incrementPathName(concatunderEXT(imagename,suffix))
	exe([[ffmpeg -i "]]..imagename..[[" -vf scale="iw*]]..factor..[[:ih*]]..factor..[[" -sws_flags lanczos+full_chroma_inp "]]..outputname..[["]])
	return outputname
end

function upscaleMediaByPx(imagename,width,height,suffix)
	--require("functions")
	suffix = suffix or "_d"..tostring(width)..[[x]]..tostring(height)
	local outputname = incrementPathName(concatunderEXT(imagename,suffix))
	io.popen([[ffmpeg -i "]]..imagename..[[" -vf scale=]]..tostring(width)..[[:]]..tostring(height)..[[ -sws_flags lanczos+full_chroma_inp "]]..outputname..[[" 2>&1]]):close()
	return outputname
end
function cropImage(pathtofile,newfilename,xpos,ypos,cwidth,cheight)
	exe([[ffmpeg -i "]]..pathtofile..[[" -vf "crop=]]..tostring(cwidth)..[[:]]..tostring(cheight)..[[:]]..tostring(xpos)..[[:]]..tostring(ypos)..[[" "]]..newfilename..[["]])
end

function repairImage(imagename,suffix)
	suffix = suffix or "_repaired"
	local outputname = incrementPathName(concatunderEXT(imagename,suffix))..".png"
	exe([[ffmpeg -i "]]..imagename..[[" -vf copy "]]..outputname..[["]])
	return outputname
end

function sliceImageAndProcessCaption(x,y,w,h,config,outputName,width,height,filepath)
	local tempoutputName = incrementPathName(outputName)
	if w < 1 then
		w = (width+w)-x
	end
	if h < 1 then
		h = (height+h)-y
	end
	cropImage(filepath,tempoutputName,x,y,w,h)
	local editcaption = false
	if config.captionfunction then
		editcaption = getcaptionfile(madetemp or filepath)
		--print(file)
		--print(editcaption)
		--pause()
	end
	makecaptionfile(tempoutputName,editcaption,config)
end

function makecaptionfile(imagefilepath,caption,config)
	if config.caption ~= "" then
		local txtfilepath = imagefilepath:sub(1,#imagefilepath-(#getEXT(imagefilepath))).."txt"
		local captionfile = io.open(txtfilepath,"w")
		local newcaption = config.caption
		if caption and config.captionfunction then
			if captioncommands[newcaption] then
				newcaption = captioncommands[config.captionfunction]("",caption)
			else
				newcaption = captioncommands[config.captionfunction](newcaption,caption)
			end
			
		end
		captionfile:write(newcaption)
		captionfile:close()
	end
end