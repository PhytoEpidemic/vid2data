lfs = require("lfs")
imagedim = require("imagedim")
lfsaddons = require("lfsaddons")
parallelism = require("parallelism")
require("functions")

clearExecutableList()


local config = {}

function printset()
	printsettingstosconsole(config)
end


local config_loader = {"InputType","vfile","WaH","keyframesonly","samesize","delimg","cfilename","caption","OutputFolder","removeblur"}

rtitle()
--os.remove("GUIoutput.txt")
--exe([[vid2dataGUI.exe -File GUI.ps1]])


-- Open the file
local config_file = io.open("GUIoutput.txt","r")

-- Iterate through each line in the file
local line_count = 0
for line in config_file:lines() do
    line_count = line_count+1
	if config_loader[line_count] then
		local value = line
		if value == "True" or value == "False" then
			value = value == "True"
		end
		config[config_loader[line_count]] = value
	end
end

-- Close the file
config_file:close()


for n,v in pairs(config) do
	print(n,v)
end

if config.InputType == "Video" then
	config.samesize = true
end


--pause()

print("Drag and drop your video file or folder of images")
--config.vfile = (io.read():gsub('"',""))
if lfs.attributes(config.OutputFolder) and lfs.attributes(config.OutputFolder).mode == "directory" then
else
	config.OutputFolder = folderUP(config.vfile)
end
local framesFolder = ""

if lfs.attributes(config.vfile).mode == "directory" then
	framesFolder = config.vfile
	config.folder = true
else
	framesFolder = incrementPathName(config.OutputFolder..[[\]]..endOfPath(config.vfile)..[[_frames]])
end
if not config.folder then
	cls()
	printset()
	print("Keep key frames only? [y/n]")
	--config.keyframesonly = (io.read():gsub('"',""))
	cls()
	printset()
	print("Remove blurred frames?[0-20] (threshold blur level for removal. Lower number will remove more frames)")
	--config.removeblur = (io.read():gsub('"',""))
end




cls()
printset()
print("Are all of the images the same size?")
--config.samesize = (io.read():gsub('"',""))
cls()
printset()
print("Add custom file name?")
--config.cfilename = (io.read():gsub('"',""))
cls()
printset()
print("Add custom caption file?")
--config.caption = (io.read():gsub('"',""))
if captioncommands[(splitstring(config.caption," ")[1])] then
	if captioncommands[(splitstring(config.caption," ")[1])] then
		config.captionfunction = (splitstring(config.caption," ")[1])
	end
	
	local newcaption = splitstring(config.caption," ")
	if #newcaption > 1 then
		table.remove(newcaption,1)
	end
	config.caption = table.concat(newcaption," ")
end

cls()
printset()
print("Delete after slicing?")
--config.delimg = (io.read():gsub('"',""))
cls()
printset()
print("Custom width and height (default 512x512, format WIDTHxHEIGHT or WIDTH,HEIGHT)(type a single number for 1:1 aspect ratio)?")
config.WaH = string.lower((config.WaH:gsub('"',"")):gsub(" ",""):gsub(",","x"))
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
--print("Are you ready?")
--local gonow = (io.read():gsub('"',""))
--if gonow ~= "y" then
--	os.exit()
--end
local programstarttime = os.time()
print("")

exe([[mkdir "]]..framesFolder..[["]])
--exe([[mkdir "]]..framesFolder..[[mp"]])
if config.keyframesonly then
	config.keyframesonly = [[ -skip_frame nokey]]
else
	config.keyframesonly = ""
end
if not config.folder then
	set_progress(100)
	cls()
	local ffmpeg_command = [[ffmpeg.exe]]..config.keyframesonly..[[ -i "]]..config.vfile..[[" -vf mpdecimate,setpts=N/FRAME_RATE/TB,blurdetect=block_width=128:block_height=128:block_pct=95,blackdetect=d=0,metadata=print:file=log.txt "]]..framesFolder..[[/%08d.png"]]
	printout("Extracting frames: "..config.vfile.."\n\n"..ffmpeg_command)
	exe(ffmpeg_command)
end
local cancelProcessing = lfs.attributes("cancel.txt")

removeBl(config)



config.ActualOutput = incrementPathName(config.OutputFolder..[[\]]..endOfPath(config.vfile)..[[_output]])
if not cancelProcessing then
	exe([[mkdir "]]..config.ActualOutput..[["]])
end



function splitframes()
	cls()
	set_progress(1)
	local imagecount = 0
	local loading_speed = 0
	local last_loading_speed = 0
	local last_image_count = 0
	local imageDimensions = {}
	local tempImages = {}
	local tempImages_processing = {}
	local vidw, vidh = false, false
	local showtimer = os.time()
	printout("Loading image info...")
	local processing_node = parallelism.new()
	local max_threads = 1
	local function getResults()
		local results = processing_node:getResults(true)
		for t,result in ipairs(results) do
			if result[1] then
					
				
				if result[4] then
					table.insert(tempImages,result[4])
				end
				imageDimensions[result[4] or result[3]] = {result[1], result[2]}
				imagecount = imagecount+1
				
			end
			processing_node.threads[t]:cleanUP()
		end
		processing_node:clear()
	end
	
	local directory_item_count = 0
	for file in lfs.dir(framesFolder) do
		if isAllowed(file) then
			directory_item_count = directory_item_count+1
			
		end
	end
	
	local directory_item_count_max = directory_item_count
	directory_item_count = 0
	for file in lfs.dir(framesFolder) do
		if isAllowed(file) then
			directory_item_count = directory_item_count+1
			
			if showtimer ~= os.time() then
				set_progress(math.floor(directory_item_count/directory_item_count_max*100))
				local time_diff = os.time()-showtimer
				showtimer = os.time()
				
				cls()
				printout("Loading image info...")
				printout("Folder: "..framesFolder)
				printout("Workers: "..max_threads)
				printout("Checking "..directory_item_count_max.." files")
				printout("images loaded: "..tostring(imagecount))
				--pause()
				if last_image_count == 0 then
					last_image_count = imagecount
					
				end
				if imagecount ~= last_image_count then
					loading_speed = imagecount - last_image_count
					
					last_image_count = imagecount
					
					if loading_speed >= last_loading_speed then
						max_threads = math.min(128,math.ceil(max_threads*1.5))
						
					else
						max_threads = math.min(128,math.ceil(max_threads*0.8))
					end
					last_loading_speed = loading_speed
				end
			end
			
			if isSupportedImage(getEXT(file)) then
				local filepath = framesFolder.."\\"..file
				local width, height = vidw, vidh
				local repaired_image = false
				local function add_image_to_list()
					imageDimensions[repaired_image or filepath] = {width, height}
					imagecount = imagecount+1
				end
				local function getwidthandheightofimage(thefilepath)
					if thefilepath then
						require("functions")
					end
					
					width, height = imagedim.GetImageWidthHeight(thefilepath or filepath)
					if not width or (width and width > 1024*16) or (height and height > 1024*16) then
						repaired_image = repairImage(thefilepath or filepath)
						width, height = imagedim.GetImageWidthHeight(repaired_image)
						if not thefilepath then
							table.insert(tempImages,repaired_image)
						end
					end
					return {width, height,(thefilepath or filepath), repaired_image}
				end
				
				if config.folder and not vidw and (not config.samesize) then
					if getEXT(file) == "png" then
						getwidthandheightofimage()
						add_image_to_list()
					else
						local function open_new_thread()
							addToExecutableList(processing_node:run(getwidthandheightofimage,filepath):getExecutableName())
						end
						cancelProcessing = lfs.attributes("cancel.txt")
						if (not cancelProcessing) and (processing_node and #processing_node.threads < max_threads) or not processing_node then
							open_new_thread()
						else
							if cancelProcessing then
								break
							end
							getResults()
							clearExecutableList()
							open_new_thread()
						end
					end
				elseif not vidw and config.samesize then
					getwidthandheightofimage()
					vidw, vidh = width, height
					add_image_to_list()
				elseif vidw then
					width, height = vidw, vidh
					add_image_to_list()
				end
				
			end
			
			
			
		end
	end
	if #processing_node.threads > 0 then
		getResults()
	end
	processing_node:cleanUP(true)
	processing_node:clear()
	if cancelProcessing then
		for _,temp in pairs(tempImages) do
			os.remove(temp)
		end
		return false
	end
	max_threads = 1
	processing_node = parallelism.new()
	local last_percentpersecond = 0
	--pause()
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
	local function delete_tempImages_processing()
		for i=#tempImages_processing,1,-1 do
			os.remove(tempImages_processing[i])
			table.remove(tempImages_processing)
		end
	end
	for filepath,imageinfo in pairs(imageDimensions) do
		
		if showtimer ~= os.time() then
			showtimer = os.time()
			
			
			
			
			local currenttime = os.time()
			local percentagecomplete = progress/imagecount
			local percentpersecond = (percentagecomplete*1000)/(currenttime-starttime)
			if last_percentpersecond == 0 then
				last_percentpersecond = percentpersecond
			end
			if config.cfilename == "" then
				if percentpersecond >= last_percentpersecond then
					max_threads = math.min(4,math.ceil(max_threads*1.5))
					
				else
					max_threads = math.min(4,math.ceil(max_threads*0.8))
				end
			end
			last_percentpersecond = percentpersecond
			local ETA = secondsToReadable((1000-(percentagecomplete*1000))/percentpersecond)
			if percentagecomplete < 0.001 or currenttime-starttime < 5 then
				ETA = "Calculating..."
			end
			
			cls()
			printout("Slicing: "..tostring(math.floor(percentagecomplete*1000)/10).."% ETA: "..ETA)
			printout("Folder: "..framesFolder)
			printout("Workers: "..max_threads)
			printout("Images processed: "..tostring(math.max(progress-max_threads,0)).." / "..imagecount)
			set_progress(math.floor(percentagecomplete*100))
			--pause()
			
		end
		local file = endOfPath(filepath)
		if lfs.attributes(filepath) and lfs.attributes(filepath).mode == "file" and isSupportedImage(getEXT(file)) then
			local outputName = config.ActualOutput

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
					if (config.height/height) >= config.width/width then
						ydiff = config.height
					else
						xdiff = config.width
					end
					madetemp = filepath
					filepath = upscaleMediaByPx(filepath,xdiff,ydiff)
					--local tempnode = parallelism.run(upscaleMediaByPx,{{filepath,xdiff,ydiff}})
					--local results = tempnode:getResults(true)
					--for _,r in pairs(results) do
					--	print(r)
					--	for _,v in pairs(r) do
					--		print(v)
					--	end
					--end
					--filepath = results[1][1]
					--tempnode:cleanUP(true)
					--tempnode:clear()
					width, height = imagedim.GetImageWidthHeight(filepath)
				end
				--print(file)
				--print(width,height)
				--pause()
				
				if startswith(config.WaH,"crop") then
					sliceImageAndProcessCaption(config.xpos,config.ypos,config.width,config.height,config,outputName,width,height,filepath)
				else
					local function imagesplitloop(config,width,height,outputName,filepath)
						require("functions")
						local cells = get_cells(config.width,config.height,width,height)
						
						for i,cell in ipairs(cells) do
							sliceImageAndProcessCaption(cell.x,cell.y,cell.w,cell.h,config,outputName,width,height,filepath)
						end
						return false
					end
					cancelProcessing = lfs.attributes("cancel.txt")
					local function open_new_thread()
						addToExecutableList(processing_node:run(imagesplitloop,config,width,height,outputName,filepath):getExecutableName())
					end
					
					if (not cancelProcessing) and (processing_node and #processing_node.threads < max_threads) then
						open_new_thread()
						--pause()
					else
						local results = processing_node:getResults(true)
						clearExecutableList()
						--for _,result in ipairs(results) do
						--	print(result)
						--	pause()
						--end
						delete_tempImages_processing()
						
						
						for _,thread in pairs(processing_node.threads) do
							thread:cleanUP()
						end
						processing_node:clear()
						if cancelProcessing then
							break
						end
						open_new_thread()
					end
					
					
				end
				--pause()
				if config.delimg then
					table.insert(tempImages_processing,filepath)
					if madetemp then
						table.insert(tempImages_processing,madetemp)
					end
				end
			elseif (width and height) then
				local tempoutputName = incrementPathName(outputName)
				if config.delimg and config.cfilename ~= "" then
					os.rename(filepath,tempoutputName)
				else
					exe([[copy "]]..filepath..[[" "]]..tempoutputName..[["]])
				end
				local editcaption = false
				if config.captionfunction then
					editcaption = getcaptionfile(filepath)
				end
				makecaptionfile(tempoutputName,editcaption,config)
			end
			
			if madetemp then
				table.insert(tempImages_processing,filepath)
			end
		end
		progress = progress+1
		
	end
	processing_node:getResults(true)
	processing_node:cleanUP(true)
	clearExecutableList()
	for _,temp in pairs(tempImages) do
		os.remove(temp)
	end
	delete_tempImages_processing()
	if cancelProcessing then
		return false
	end
	return true
end
local OK, er
if not cancelProcessing then
	OK, er = pcall(splitframes)
end


rtitle()
cls()
printout(config.vfile)
printout("Completed in "..secondsToReadable(os.time()-programstarttime))
set_progress(100)
--pause()
if not OK then
	printout(er)
	--pause()
end
local finaloutput = io.open("finished.txt","w")
finaloutput:write("f")
finaloutput:close()