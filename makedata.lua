lfs = require("lfs")
imagedim = require("imagedim")
lfsaddons = require("lfsaddons")
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
	os.execute("cls")
end
function pause()
	os.execute("pause")
end
local unallowedNames = {
["."] = true,
[".."] = true,
["desktop.ini"] = true,
}
local function isAllowed(n)
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
local function makeDir(path)
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

local config = {}

function printset()
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

local captioncommands = {
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

rtitle()
print("Drag and drop your video file or folder of images")
config.vfile = (io.read():gsub('"',""))
local framesFolder = incrementPathName(config.vfile..[[_frames]])
if lfs.attributes(config.vfile).mode == "directory" then
	framesFolder = config.vfile
	config.folder = true
end
if not config.folder then
	cls()
	printset()
	print("Keep key frames only? [y/n]")
	config.keyframesonly = (io.read():gsub('"',""))
	cls()
	printset()
	print("Remove blurred frames?[0-20] (threshold blur level for removal. Lower number will remove more frames)")
	config.removeblur = (io.read():gsub('"',""))
end

cls()
printset()
print("Add custom file name?")
config.cfilename = (io.read():gsub('"',""))
cls()
printset()
print("Add custom caption file?")
config.caption = (io.read():gsub('"',""))
if captioncommands[(splitstring(config.caption," ")[1])] then
	config.captionfunction = captioncommands[(splitstring(config.caption," ")[1])]
	local newcaption = splitstring(config.caption," ")
	if #newcaption > 1 then
		table.remove(newcaption,1)
	end
	config.caption = table.concat(newcaption," ")
end

cls()
printset()
print("Delete after slicing?")
config.delimg = (io.read():gsub('"',""))
cls()
printset()
print("Custom width and height (default 512x512, format WIDTHxHEIGHT or WIDTH,HEIGHT)(type a single number for 1:1 aspect ratio)?")
config.WaH = string.lower((io.read():gsub('"',"")):gsub(" ",""):gsub(",","x"))
if startswith(config.WaH,"crop") then
	local params = splitstring(config.WaH:sub(#"crop"+1,#config.WaH),"x")
	config.xpos = tonumber(params[1]) or 1
	config.ypos = tonumber(params[2]) or 1
	config.width = tonumber(params[3]) or 512
	config.height = tonumber(params[4]) or 512



elseif startswith(config.WaH,"avg") then
	config.width = {}
	config.height = {}


elseif config.WaH ~= "" then
	local splits = splitstring(config.WaH,"x")
	if #splits == 1 then
		if tonumber(splits[1]) then
			config.width = tonumber(splits[1])
			config.height = tonumber(splits[1])
		else
			config.width = 512
			config.height = 512
		end
	elseif #splits == 2 then
		if tonumber(splits[1]) then
			config.width = tonumber(splits[1])
		else
			config.width = 512
		end
		if tonumber(splits[2]) then
			config.height = tonumber(splits[2])
		else
			config.height = 512
		end
	else
		config.width = 512
		config.height = 512
	end
else
	config.width = 512
	config.height = 512
end


cls()
printset()
print("Are you ready?")
local gonow = (io.read():gsub('"',""))
if gonow ~= "y" then
	os.exit()
end
local programstarttime = os.time()
print("")
exe([[mkdir "]]..framesFolder..[["]])
--exe([[mkdir "]]..framesFolder..[[mp"]])
if config.keyframesonly == "y" then
	config.keyframesonly = [[ -skip_frame nokey]]
else
	config.keyframesonly = ""
end
if not config.folder then
	exe([[ffmpeg.exe]]..config.keyframesonly..[[ -i "]]..config.vfile..[[" -vf mpdecimate,setpts=N/FRAME_RATE/TB,blurdetect=block_width=128:block_height=128:block_pct=95,blackdetect=d=0,metadata=print:file=log.txt "]]..framesFolder..[[/%08d.png"]])
end
function removeBl()
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
local OK, er = pcall(removeBl)
if not OK then
	print(er)
	pause()
end
if config.delimg ~= "y" then
	config.delimg = incrementPathName(framesFolder.."\\output")
	exe([[mkdir "]]..config.delimg..[["]])
end
function upscaleMedia(imagename,factor,suffix)
	local factor = tostring(factor or 2)
	suffix = suffix or "_d"..factor
	local outputname = incrementPathName(concatunderEXT(imagename,suffix))
	os.execute([[ffmpeg -i "]]..imagename..[[" -vf scale="iw*]]..factor..[[:ih*]]..factor..[[" -sws_flags lanczos+full_chroma_inp "]]..outputname..[["]])
	return outputname
end

function upscaleMediaByPx(imagename,width,height,suffix)
	suffix = suffix or "_d"..tostring(width)..[[x]]..tostring(height)
	local outputname = incrementPathName(concatunderEXT(imagename,suffix))
	os.execute([[ffmpeg -i "]]..imagename..[[" -vf scale=]]..tostring(width)..[[:]]..tostring(height)..[[ -sws_flags lanczos+full_chroma_inp "]]..outputname..[["]])
	return outputname
end
function cropImage(pathtofile,newfilename,xpos,ypos,cwidth,cheight)
	os.execute([[ffmpeg -i "]]..pathtofile..[[" -vf "crop=]]..tostring(cwidth)..[[:]]..tostring(cheight)..[[:]]..tostring(xpos)..[[:]]..tostring(ypos)..[[" "]]..newfilename..[["]])
end

function splitframes()
	
	local imagecount = 0
	local imageDimensions = {}
	local vidw, vidh = false, false
	local showtimer = os.time()
	print("Loading image info...")
	for file in lfs.dir(framesFolder) do
		if isAllowed(file) then
			if showtimer ~= os.time() then
				showtimer = os.time()
				cls()
				print("Loading image info...")
				print("Folder: "..framesFolder)
				print("images loaded: "..tostring(imagecount))
			end
			
			if isSupportedImage(getEXT(file)) then
				local filepath = framesFolder.."\\"..file
				local width, height = vidw, vidh
				
				if config.folder and not vidw then
					width, height = imagedim.GetImageWidthHeight(filepath)
				elseif not vidw then
					width, height = imagedim.GetImageWidthHeight(filepath)
					vidw, vidh = width, height
					
				else
					width, height = vidw, vidh 
				end
				imageDimensions[filepath] = {width, height}
				imagecount = imagecount+1
			end
			
			
			
		end
	end
	if startswith(config.WaH,"avg") then
		local avgx, avgy = 0, 0
		local total = 0
		for _,dim in pairs(imageDimensions) do
			avgx = avgx+dim[1]
			avgy = avgy+dim[2]
			total = total+1
		end
		config.width = math.floor(avgx/total)
		config.height = math.floor(avgy/total)
	end
	local starttime = os.time()
	local progress = 0
	local function makecaptionfile(imagefilepath,caption,captionfunction)
		if config.caption ~= "" then
			local txtfilepath = imagefilepath:sub(1,#imagefilepath-(#getEXT(imagefilepath))).."txt"
			local captionfile = io.open(txtfilepath,"w")
			local newcaption = config.caption
			if caption and captionfunction then
				if captioncommands[newcaption] then
					newcaption = captionfunction("",caption)
				else
					newcaption = captionfunction(newcaption,caption)
				end
				
			end
			captionfile:write(newcaption)
			captionfile:close()
		end
	end
	local function getcaptionfile(imagefilepath)
		if config.caption ~= "" then
			local txtfilepath = imagefilepath:sub(1,#imagefilepath-(#getEXT(imagefilepath))).."txt"
			--print(txtfilepath)
			--pause()
			local captionfile = io.open(txtfilepath,"r")
			local caption = false
			if captionfile then
				caption = captionfile:read("*all")
				captionfile:close()
			end
			
			return caption
		end
	end
	for filepath,imageinfo in pairs(imageDimensions) do
			
			if progress%math.ceil(imagecount/1000)==0 then
				local currenttime = os.time()
				local percentagecomplete = progress/imagecount
				local percentpersecond = (percentagecomplete*1000)/(currenttime-starttime)
				local ETA = secondsToReadable((1000-(percentagecomplete*1000))/percentpersecond)
				if percentagecomplete < 0.001 or currenttime-starttime < 5 then
					ETA = "Calculating..."
				end
				stitle("Slicing: "..tostring(math.floor(percentagecomplete*1000)/10).."% ETA: "..ETA)
			end
			local file = endOfPath(filepath)
			if lfs.attributes(filepath) and lfs.attributes(filepath).mode == "file" and isSupportedImage(getEXT(file)) then
				local outputName = framesFolder
				if config.delimg ~= "y" then
					outputName = config.delimg
				end
				if config.cfilename ~= "" then
					outputName = outputName.."\\"..config.cfilename..".png"
				else
					outputName = outputName.."\\"..file..".png"
				end
				local width, height = unpack(imageinfo)
				
				local madetemp = false
				if (width ~= config.width or height ~= config.height) and (width and height) then
					if width < config.width or height < config.height then
						local xdiff = -1
						local ydiff = -1
						if height >= width then
							xdiff = config.width
						else
							ydiff = config.height
						end
						madetemp = filepath
						filepath = upscaleMediaByPx(filepath,xdiff,ydiff)
						width, height = imagedim.GetImageWidthHeight(filepath)
					end
					print(file)
					print(width,height)
					--pause()
					local function sliceImageAndProcessCaption(x,y,w,h)
						local tempoutputName = incrementPathName(outputName)
						if w < 1 then
							w = width+w
						end
						if h < 1 then
							h = height+h
						end
						cropImage(filepath,tempoutputName,x,y,w,h)
						local editcaption = false
						if config.captionfunction then
							editcaption = getcaptionfile(madetemp or filepath)
							--print(file)
							print(editcaption)
							--pause()
						end
						makecaptionfile(tempoutputName,editcaption,config.captionfunction)
					end
					
					
					if startswith(config.WaH,"crop") then
						sliceImageAndProcessCaption(config.xpos,config.ypos,config.width,config.height)
					else
						local cells = splitImage(config.width,config.height,width,height)
						if #cells>1 then
							for i,cell in ipairs(cells) do
								sliceImageAndProcessCaption(cell.x,cell.y,cell.w,cell.h)
							end
						end
					end
					--pause()
					if config.delimg == "y" then
						os.remove(filepath)
						if madetemp then os.remove(madetemp) end
					end
				elseif (width and height) then
					local tempoutputName = incrementPathName(outputName)
					if config.delimg == "y" and cfilename ~= "" then
						os.rename(filepath,tempoutputName)
					else
						os.execute([[copy "]]..filepath..[[" "]]..tempoutputName..[["]])
					end
					local editcaption = false
					if config.captionfunction then
						editcaption = getcaptionfile(filepath)
					end
					makecaptionfile(tempoutputName,editcaption,config.captionfunction)
				end
				
				if madetemp then os.remove(filepath) end
			end
			progress = progress+1
		
	end
end
local OK, er = pcall(splitframes)
if not OK then
	print(er)
	pause()
end
rtitle()
cls()
print(config.vfile)
print("Completed in "..secondsToReadable(os.time()-programstarttime))
pause()