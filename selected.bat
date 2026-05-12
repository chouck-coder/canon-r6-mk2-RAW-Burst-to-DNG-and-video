@echo off

	setlocal enabledelayedexpansion

	set "MAGICK=C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
	set "NEW=C:\inbox\New"
	set "RAW=%NEW%\raw"
	set "SRC=%NEW%\out"
::  set "SRC=C:\inbox\New\out\test"
	set "TIFF=%NEW%\tiff"
::  set "TIFF=C:\inbox\New\out\test"
	set "DIST=%NEW%\out\video"
	 ::  #of processing Cores in your CPU
	set "MAXJOBS=24"
	 ::  #of frames +1 to pause video, so 29+1 = 1sec at 30 FPS
	set "COPIES=29"
	set "BANG=#"

 set MAGICK_OCL_DEVICE=true
 set MAGICK_THREAD_LIMIT=0



 


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
 


for %%A in ("%TIFF%\CR6_*_????01.tiff") do (    ::  to create videos only for rolls with the selected picture use CR6_*_?????1.tiff , to create for ALL use CR6_*_000000.tiff
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

for %%A in ("%TIFF%\CR6_*_????01.tiff") do (  
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




 
set "LIST=%TIFF%\all_list.txt"
del /Q "!LIST!" 2>nul

set "LASTPREFIX="

for %%A in ("%TIFF%\CR6_*_????01.tiff") do (  
    set "file=%%~nA"
    set "prefix=!file:~0,-7!"

    if not "!prefix!"=="!LASTPREFIX!" (
 
			set "LASTPREFIX=!prefix!"
						for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (
					REM	echo file '%TIFF%\%%F'
				echo file '%TIFF%\%%F'>>"!LIST!"	
			)
			
			
		)
)		
			
		 ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -c:v libx264 -pix_fmt yuv420p "%DIST%\all.mp4"	
			
			
del /Q "!LIST!" 2>nul
