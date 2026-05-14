With a Canon R6 mkII i faced the issue of inconvenience having all RAW Burst frames in one file. 
So I turned it from an inconvenience to an advantage and scriped a way to automatically create short videos (one per Burst) and combine only valuable session videos into the one big video with nice transitions like these.
To the result video you can add audio, logo, watermark, Intro, and Outro videos.

[https://www.youtube.com/watch?v=kLdmN_L_hxE](https://youtu.be/wjRXGIVnn04)

You will need only these 3 command-line tools

**dnglab** https://github.com/dnglab/dnglab/releases/latest

**ImageMagick** https://imagemagick.org/download/#gsc.tab=0

**ffmpeg** https://ffmpeg.org/download.html

How to use (**Windows only**): 

Initial setup: Download extract.bat and selected.bat to your local folder. Edit variables for your folders and files at the top of both BAT files.

Suggested flow is the following:

0) Before shooting, set proper custom white balance in your camera! And update it if the location or light changed. Yes you shooting RAW , yes you can change it later, but you won't change it for all the thousands of frames you use for the videos. 
1) Clean local drive folders from the previous session results. ( see path as RAW, SRC, TIFF variables in BAT files)
2) Insert the SD card into the reader
3) Start **extract.bat** it will convert CR3s rolls to DNGs and TIFFs, placing them on your drive. it will create a set of individual videos per roll and one that combines ALL rolls. 
4) cull DNG images in FastStone (Alt+1) in full-screen mode and zoom 175% (this is a free tool that is lightning fast for culling). you can use Photomechanic or others
5) Copy selected images DNGs to the output folder
6) Process them with DxO to create TIFFs with min side of 1080px into the same output folder and final JPGs if needed. This is an optional step
7) Run **selected.bat** to create a set of small videos and one covering all.
   IMPORTANT: big video will include ONLY burst rolls that have at least ONE picture selected at steps 3-4. These will be pause at these SELECTED images for a second (configurable).
