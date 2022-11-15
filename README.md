# vid2data
![alt text](https://github.com/PhytoEpidemic/vid2data/raw/main/logo.png)

This is a tool for extracting frames from videos and slicing them up into 512x512 images. Also for slicing up data-sets into 512x512 images without losing quality from scaling. Every pixel will be kept with a slight overlap if the image is not divisible by 512.

To use, simply run the vid2data.exe and a console will open and you can drag and drop video or folder of images into the console. Then press enter and continue to the settings.

Options are:

 Key frames only [y/n]<br />
 Remove blurred frames [y/n] (Does not work well if the whole video is partly blurry)<br />
 Custom name [words] (Applied to the final sliced up images)<br />
 Delete after slicing [y/n] (Deletes original frames after slicing. Be mindful when useing on a folder of images, always make copies of your data)<br />

The newest version of ffmpeg is required and is included in vid2data.exe so that is why the file is over 40MB instead of under 1MB

Download the latest offical release by clicking this link: https://github.com/PhytoEpidemic/vid2data/releases/download/Official/vid2data.exe

Don't download the vid2data.exe in the source repo as that is just a lua interpreter.
