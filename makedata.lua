lfs = require("lfs")
imagedim = require("imagedim")
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

function incrementPathName(path,limit)
	local addednumber = ""
	local numbertotry = 2
	limit = tonumber(limit) or 1000000
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
			return filesavepath
		end
		limit = limit - 1
	end
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
	
	
	for i=0,wfull do
		for j=0,hfull do
			local cell = {}
			cell.w = tw
			cell.h = th
			cell.x = i*tw
			if i>0 then
				cell.x = cell.x-wpadding
			end
			
			cell.y = j*th
			if j>0 then
				cell.y = cell.y-hpadding
			end
				
			
			
			table.insert(cells,cell)
		end
	end
	
	
	return cells
end


local config = {}
function printset()
	if not config.folder then
		print("Selected Video: "..(config.vfile or "none"))
		print("Key frames only: "..(config.keyframesonly or "n"))
		print("Remove blurred frames: "..(config.removeblur or "n"))
	else
		print("Selected Folder: "..(config.vfile or "none"))
		print("Custom name: "..(config.cfilename or "none"))
		print("Delete after slicing: "..(config.delimg or "none"))
		
	end
end


rtitle()
print("Drag and drop your video file or folder of images")
config.vfile = (io.read():gsub('"',""))
local framesFolder = config.vfile..[[_frames]]
if lfs.attributes(config.vfile).mode == "directory" then
	framesFolder = config.vfile
	config.folder = true
end
if not config.folder then
	cls()
	printset()
	print("Key frames only?")
	config.keyframesonly = (io.read():gsub('"',""))
	cls()
	printset()
	print("Remove blurred frames?")
	config.removeblur = (io.read():gsub('"',""))	
end

cls()
printset()
print("Add custom file name?")
config.cfilename = (io.read():gsub('"',""))
cls()
printset()
print("Delete after slicing?")
config.delimg = (io.read():gsub('"',""))


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
				if blurnum > 9 then
					
					os.remove(framesFolder.."\\"..filename)
					print(filename)
					print(blur)
				end
				
			end
		end
	end
end
local OK, er = pcall(removeBl)
if not OK then
	print(er)
	pause()
end
if config.delimg ~= "y" then
	exe([[mkdir "]]..framesFolder..[[/output"]])
end


function splitframes()
	for file in lfs.dir(framesFolder) do
		if isAllowed(file) then
			local filepath = framesFolder.."\\"..file
			if lfs.attributes(filepath).mode == "file" then
				local outputName = framesFolder
				if config.delimg ~= "y" then
					outputName = outputName.."\\output"
				end
				if config.cfilename ~= "" then
					outputName = outputName.."\\"..config.cfilename..".png"
				else
					outputName = outputName.."\\"..file..".png"
				end
				
				local width, height = imagedim.GetImageWidthHeight(filepath)
				if width ~= 512 or height ~= 512 then
					print(width,height)
					local cells = splitImage(512,512,width,height)
					for i,cell in ipairs(cells) do
						
						os.execute([[ffmpeg -i "]]..filepath..[[" -vf "crop=]]..tostring(cell.w)..[[:]]..tostring(cell.h)..[[:]]..tostring(cell.x)..[[:]]..tostring(cell.y)..[[" "]]..incrementPathName(outputName)..[["]])
					end
					if config.delimg == "y" then
						os.remove(filepath)
					end
					
				end
			end
		end
	end
end
local OK, er = pcall(splitframes)
if not OK then
	print(er)
	pause()
end
cls()

pause()