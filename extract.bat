@echo off
set "MAGICK=C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
set "SD=D:\DCIM"
set "NEW=C:\inbox\New"
set "RAW=%NEW%\raw"
set "SRC=%RAW%\100EOSR6"
set "TIFF=%NEW%\tiff"
set "DIST=%NEW%\out\video"

		set "LOGOP=C:\inbox\RRlogoP.tiff"
		set "LOGOL=C:\inbox\RRlogoL.tiff"
		set "INTROP=C:\inbox\intro.mp4"
		set "OUTROP=C:\inbox\outro.mp4"
		set "INTROL=C:\inbox\intro.mp4"
		set "OUTROL=C:\inbox\outro.mp4"
		set "AUDIOP=C:\inbox\music\list.txt"
		set "AUDIOL=C:\inbox\music\list.txt"
		set "WATERMARK=C:\inbox\watermark.png"


 ::  #of processing Cores in your CPU
set "MAXJOBS=%NUMBER_OF_PROCESSORS%"
set "RAYON_NUM_THREADS=%NUMBER_OF_PROCESSORS%"
set "BANG=#"
	
 set MAGICK_OCL_DEVICE=true
 set MAGICK_THREAD_LIMIT=0
 setlocal enabledelayedexpansion
 
 ::  Step 1 Extract RAWs frames from CR3s 
C:\PF\RollExtractor\dnglab.exe convert --image-index all -r --embed-raw false --crop activearea --override %SD% %RAW%

REM robocopy "%SD%" "%NEW%" /S /MOVE /XF *.cr3
REM robocopy "%SD%" "%NEW%" *.JPG *.jpg *.MP4 *.mp4 /S /MOV



 ::  Step 2 Extract TIFFs from RAWs frames 



for %%F in ("%SRC%\CR6_*_*.dng") do (
    call :waitslot
    start "" /b /high "%MAGICK%" mogrify -limit thread 1 -path "%TIFF%" -auto-orient -resize 1080x1080^^ -format tiff -depth 8 -compress lzw "%%F"
)

REM Wait until all remaining magick.exe jobs are finished
call :waitall

goto nextcommands


:waitslot
for /f %%N in ('tasklist /fi "imagename eq magick.exe" ^| find /i /c "magick.exe"') do set "COUNT=%%N"
if !COUNT! GEQ %MAXJOBS% (
    timeout /t 1 >nul
    goto waitslot
)
exit /b


:waitall
for /f %%N in ('tasklist /fi "imagename eq magick.exe" ^| find /i /c "magick.exe"') do set "COUNT=%%N"
if !COUNT! GTR 0 (
    timeout /t 1 >nul
    goto waitall
)
exit /b

:nextcommands

 for %%F in ("%TIFF%\CR6_*_*.tiff") do (
  for /f "tokens=1,2,3 delims=_" %%A in ("%%~nF") do (
    ren "%%F" "%%A_%%B_%%C00%%~xF"
  )
)

  ::  Step 3 Create MP4  NONSTOP videos from extracted  TIFFs 
 
 

for %%A in ("%TIFF%\CR6_*_000000.tiff") do (
    set "file=%%~nA"
    set "prefix=!file:~0,-7!"

    set "LIST=%TIFF%\!prefix!_list.txt"

    del "!LIST!" 2>nul

    for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (
        echo file '%TIFF%\%%F'>>"!LIST!"
    )

    ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -c:v libx264 -pix_fmt yuv420p "%DIST%\!prefix!_ns.mp4"
	del /Q "!LIST!" 2>nul
)


  ::  Open culling app
"C:\Program Files (x86)\FastStone Image Viewer\FSViewer.exe" %SRC%
  ::  call "selected.bat"




