print("video file")
local vfile = '"'..(io.read():gsub('"',""))..'"'
print("")
os.execute("fixframes "..vfile)