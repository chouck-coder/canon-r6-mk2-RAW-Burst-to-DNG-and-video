@echo off
setlocal

REM example https://youtu.be/wjRXGIVnn04

	setlocal enabledelayedexpansion 

	set "MAGICK=C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
	set "NEW=C:\inbox\New"
	set "RAW=%NEW%\raw"
	set "SRC=%NEW%\out"
	set "TIFF=%NEW%\tiff"
	set "DIST=%NEW%\out\video"

	 ::  #of frames +1 to pause video, so 29+1 = 1sec at 30 FPS
	set "COPIES=29"

		set "LOGOP=C:\inbox\assets\RR\RRlogoP.tiff"
		set "LOGOL=C:\inbox\assets\RR\RRlogoL.tiff"
		REM if you need a logo between the clips, uncomment these lines. Each line will add one logo frame 1/30 of a sec . 0 is NO logo
		set "LOGOFRAMES=0"		 
		set "INTROP=C:\inbox\assets\RR\intro\RR_logoP3.mp4"
		set "OUTROP=C:\inbox\assets\RR\outro\RR_logoP3.mp4"
		set "INTROL=C:\inbox\assets\RR\intro\RR_logoL3.mp4"
		set "OUTROL=C:\inbox\assets\RR\outro\RR_logoL3.mp4"
		set "AUDIOP=C:\inbox\music\list.txt"
		set "AUDIOL=C:\inbox\music\list.txt"
		set "WATERMARK=C:\inbox\assets\RR\RedRush_logo_02_lowrez-01-1.png"

 set MAGICK_OCL_DEVICE=true
 set MAGICK_THREAD_LIMIT=0
	 ::  #of processing Cores in your CPU
set "MAXJOBS=%NUMBER_OF_PROCESSORS%"
	set "BANG=#"
	
goto skip
:skip	
 


ren "%SRC%\*.tif" *.tiff


for %%F in ("%SRC%\CR6_*_*.dng") do (
    if not exist "%SRC%\%%~nF.tiff" (
        echo TIFF missing, converting: %%~nxF
        call :waitslot
        start "" /b /high "%MAGICK%" mogrify -limit thread 1 -path "%SRC%" -auto-orient -resize 1080x1080^^ -format tiff -depth 8 -compress lzw "%%F"
    ) else (
        echo TIFF already exists, skipping: %%~nF.tiff
    )
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
for %%F in ("%SRC%\CR6_*_????.tiff") do (
  for /f "tokens=1,2,3 delims=_" %%A in ("%%~nF") do (
    ren "%%F" "%%A_%%B_%%C00%%~xF"
  )
)




for %%F in ("%SRC%\CR6_*_??????.tiff") do (
    set "full=%%~fF"
    set "name=%%~nF"
    set "ext=%%~xF"

    REM Get prefix: CR6_1726
    set "prefix=!name:~0,-7!"

    REM Get number: 001400
    set "num=!name:~-6!"

    REM Convert 001400 to number
    set /a n=1!num! - 1000000

    echo Original: %%~nxF

    for /L %%I in (1,1,%COPIES%) do (
        set /a newn=n+%%I

        REM Pad back to 6 digits
        set "pad=000000!newn!"
        set "newnum=!pad:~-6!"

        set "newfile=%SRC%\!prefix!_!newnum!!ext!"

        echo Creating: !newfile!
        copy /Y "%%~fF" "!newfile!" >nul
    )
)


move /Y "%SRC%\*.tiff" "%TIFF%\"

  ::  Step 4 Create MP4 pause videos from extracted  TIFFs 
 


for %%A in ("%TIFF%\CR6_*_0???01.tiff") do (    ::  to create videos only for rolls with the selected picture use CR6_*_?????1.tiff , to create for ALL use CR6_*_000000.tiff
    set "file=%%~nA"
    set "prefix=!file:~0,-7!"

    set "LIST=%TIFF%\!prefix!_list.txt"

    del "!LIST!" 2>nul

    for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (
        echo file '%TIFF%\%%F'>>"!LIST!"
    )

    ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -c:v libx264 -pix_fmt yuv420p "%DIST%\!prefix!.mp4"
	del /Q "!LIST!" 2>nul
)


 

set "LASTPREFIX="

for %%A in ("%TIFF%\CR6_*_0???01.tiff") do (  
    set "file=%%~nA"
    set "prefix=!file:~0,-7!"

    if not "!prefix!"=="!LASTPREFIX!" (
 
			set "LASTPREFIX=!prefix!"
		
			for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (
				 set "LASTFILE=%%F"
			)
			
						for /L %%I in (1,1,5) do (
				set /a NEWN=N+%%I
				set "PAD=000000!NEWN!"
				set "NEWNUM=!PAD:~-6!"
				 set /a "XXX=300 - (%%I-1) * 200 / 4"
				  set /a "N=(%%I-1)"
				
				
				echo Creating: !prefix!_!BANG!0000!N!.tiff	!XXX!
				"%MAGICK%" "%TIFF%\!prefix!_000000.tiff" ^( +clone -colorspace gray -negate -blur 0x5 -channel A -evaluate multiply 1 ^) -compose ColorDodge -composite -modulate !XXX!,100,100 "%TIFF%\!prefix!_!BANG!0000!N!.tiff"
		 )
		 			set "NAME=!LASTFILE:.tiff=!"
			set "FILEPREFIX=!NAME:~0,-6!"
			set "NUM=!NAME:~-6!"
			set /a N=1!NUM! - 1000000

			for /L %%I in (1,1,5) do (
				set /a NEWN=N+%%I
				set "PAD=000000!NEWN!"
				set "NEWNUM=!PAD:~-6!"
				REM set /a "XXX=300 - (%%I-1) * 200 / 9"
				set /a "XXX=100 + (%%I-1) * 200 / 4"
				
				echo Creating: !FILEPREFIX!!NEWNUM!.tiff	!XXX!
				 "%MAGICK%" "%TIFF%\!LASTFILE!" ^( +clone -colorspace gray -negate -blur 0x5 -channel A -evaluate multiply 1 ^) -compose ColorDodge -composite -modulate !XXX!,100,100 "%TIFF%\!FILEPREFIX!!NEWNUM!.tiff"
		 )
		
	)

)



set "LISTP=%TIFF%\all_listP.txt"
del /Q "!LISTP!" 2>nul
set "LISTL=%TIFF%\all_listL.txt"
del /Q "!LISTL!" 2>nul

set "LASTPREFIX="

for %%X in ("%TIFF%\CR6_*_0???01.tiff") do (  
    set "file=%%~nX"
    set "prefix=!file:~0,-7!"


    if not "!prefix!"=="!LASTPREFIX!" (
 
			set "LASTPREFIX=!prefix!"
						for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (

							for /f "tokens=1,2" %%A in ('magick identify -format "%%w %%h" "%TIFF%\%%F"') do (
								set "W=%%A"
								set "H=%%B"
							)

							if !H! GTR !W! ( 
								echo file '%TIFF%\%%F'>>"!LISTP!"	
							) else if !W! GTR !H! (
								echo file '%TIFF%\%%F'>>"!LISTL!"	
							) else (
								echo Square IMAGE
							)
			)
			for /L %%I in (1,1,%LOGOFRAMES%) do (
							if !H! GTR !W! ( 
								echo file '%LOGOP%'>>"!LISTP!"
							) else if !W! GTR !H! (
								echo file '%LOGOL%'>>"!LISTL!"
							) else (
								echo Square IMAGE
							)
			)

	)
)		
		

	REM without AUDIO ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -c:v libx264 -pix_fmt yuv420p "%DIST%\all.mp4"	
	REM  with AUDIO 		ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -stream_loop -1 -f concat -safe 0 -i "%AUDIOP%" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "%DIST%\all.mp4"

:: iw*0.5:ih*0.5 Watarmark is 50% size of the original file

 set "SCALE=1080:1618"
 set "ORIENT=P"
set "INTRO=%INTROP%"
set "OUTRO=%OUTROP%"
set "AUDIO=%AUDIOP%"
set "LIST=%LISTP%"
call :generateVideo

 set "SCALE=1618:1080"
 set "ORIENT=L"
set "INTRO=%INTROL%"
set "OUTRO=%OUTROL%"
set "AUDIO=%AUDIOL%"
set "LIST=%LISTL%"
call :generateVideo


exit /b

:generateVideo

ffmpeg -y ^
-i "%INTRO%" ^
-r 30 -f concat -safe 0 -i "!LIST!" ^
-i "%OUTRO%" ^
-stream_loop -1 -f concat -safe 0 -i "%AUDIO%" ^
-loop 1 -i "%WATERMARK%" ^
-filter_complex "[0:v]fps=30,scale=!SCALE!:force_original_aspect_ratio=decrease,pad=!SCALE!:(ow-iw)/2:(oh-ih)/2,format=yuv420p,setsar=1[vintro];[1:v]fps=30,scale=!SCALE!:force_original_aspect_ratio=decrease,pad=!SCALE!:(ow-iw)/2:(oh-ih)/2,format=yuv420p,setsar=1[vmain];[2:v]fps=30,scale=!SCALE!:force_original_aspect_ratio=decrease,pad=!SCALE!:(ow-iw)/2:(oh-ih)/2,format=yuv420p,setsar=1[voutro];[vintro][vmain][voutro]concat=n=3:v=1:a=0[base];[4:v]scale=iw*0.5:ih*0.5,format=rgba,colorchannelmixer=aa=0.30[wm];[base][wm]overlay=W-w-20:H-h-20:shortest=1[v]" ^
-map "[v]" -map 3:a ^
-c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "%DIST%\all!ORIENT!.mp4"

del /Q "!LIST!" 2>nul

exit /b







