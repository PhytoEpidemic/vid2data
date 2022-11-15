# vid2data
![alt text](https://github.com/PhytoEpidemic/vid2data/raw/main/logo.png)

This is a tool for extracting frames from videos and slicing them up into 512x512 images. Also for slicing up data-sets into 512x512 images without losing quality from scaling. Every pixel will be kept with a slight overlap if the image is not divisible by 512.

To use, simply run the vid2data.exe and a console will open and you can drag and drop video or folder of images into the console. Then press enter and continue to the settings.

Options are:

 Key frames only<br />
 Remove blurred frames (Does not work well if the whole video is partly blurry)<br />
 Custom name (Applied to the final sliced up images)<br />
 Delete after slicing (Deletes original frames after slicing. Be mindful when useing on a folder of images, always make copies of your data)<br />
