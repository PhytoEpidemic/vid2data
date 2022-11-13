
@echo off
set arg1=%1
cd %~dp0
echo Removing duplicate frames...
mkdir %arg1%_frames
ffmpeg.exe -i %arg1% -vf mpdecimate=hi=200:lo=200:frac=1:max=0,setpts=N/FRAME_RATE/TB -r 2 %arg1%_frames/%%08d.png
