# vid2data
![alt text](https://github.com/PhytoEpidemic/vid2data/raw/main/logo.png)

This tool allows you to extract frames from a video and slice them into smaller images of a specified size. It can also slice up a folder of images without losing quality through scaling. Every pixel will be kept with a slight overlap if the image is not evenly divisible by the size specified.

## Usage

To use the tool, simply run the `vid2data.exe` file and a console will open. Drag and drop your video file or folder of images into the console and press enter. You will then be prompted to enter the following options:

- **Key frames only** [y/n]: Select "y" to only include key frames in the extracted frames. Select "n" to include all frames. This option is only applicable to video files.
- **Remove blurred frames** [y/n]: Select "y" to remove frames that are above a certain level of blurriness. Select "n" to include all frames. This option is only applicable to video files.
- **Custom name** [words]: Add a custom file name for the final sliced up images.
- **Custom caption** [words]: Add a custom caption to write to a file with the same names as the final sliced up images. If there are already caption files that you want to use for the sliced images just type "--keep". You can also type "--start " or "--end " before your caption to add your custom caption to the existing caption.
- **Size**: Enter custom width and height values in the format "WIDTHxHEIGHT" or "WIDTH,HEIGHT" (e.g. "512x512" or "512,512"). You can also enter a single number for a 1:1 aspect ratio. You can also type "crop X,Y,WIDTH,HEIGHT" to do a single crop of the image. Use negative numbers for WIDTH or HEIGHT to represent distance from the edge.
- **Delete after slicing** [y/n]: Select "y" to delete the original frames after slicing. Be mindful when using this option on a folder of images, as it will delete all of the original images. Always make copies of your data before using this option.

Note: If you select the "same size" option incorrectly, errors may occur.



The newest version of ffmpeg is required and is included in the release so that is why the file is over 40MB instead of under 1MB

Don't download the vid2data.exe in the source repo as that is just a lua interpreter.
