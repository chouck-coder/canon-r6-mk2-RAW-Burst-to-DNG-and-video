@echo off

set "MAGICK=C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
set "DNGEXE=C:\PF\dnglab.exe"
set "SD=D:\DCIM"
set "NEW=C:\inbox\New"
set "RAW=%NEW%\raw"
set "TIFF=%NEW%\tiff"
set "DIST=%NEW%\out\video"

REM Letters P or L at the end of variables correspond to the Portrait or Landscape orientation of the file 


 ::  #of processing Cores in your CPU
set "MAXJOBS=%NUMBER_OF_PROCESSORS%"
set "RAYON_NUM_THREADS=%NUMBER_OF_PROCESSORS%"
set "BANG=#"
	
 set MAGICK_OCL_DEVICE=true
 set MAGICK_THREAD_LIMIT=0
 setlocal enabledelayedexpansion
 


REM set progress messages coloe RED
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"

 goto skip
:skip
 
 ::  Step 1 Extract RAWs frames from CR3s 
REM "%DNGEXE%" convert --image-index all -r --embed-raw false --crop activearea --override %SD% %RAW%
rem Count source files
set "TOTAL=0"
for /r "%SD%" %%F in (*.CR3) do (
    set /a TOTAL+=1
)

set "DONE=1"
rem Get start epoch time
for /f %%A in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()"') do set "START_EPOCH=%%A"

for /r "%SD%" %%F in (*.CR3) do (
	"%DNGEXE%" convert --image-index all -r --embed-raw false --crop activearea --override "%%F" %RAW%
	rem Get current epoch time
	for /f %%A in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()"') do set "NOW_EPOCH=%%A"
	if !TOTAL! GTR 0 (
    set /a PERCENT=DONE*100/TOTAL
	) else (
		set "PERCENT=0"
	)
	set /a TOTAL_ESTIMATED=ELAPSED*TOTAL/DONE
    set /a ETA=TOTAL_ESTIMATED-ELAPSED
	call :FormatTime !ELAPSED! ELAPSED_TXT
	call :FormatTime !ETA! ETA_TXT
	REM echo Progress: !DONE! / !TOTAL! files  !PERCENT!%% complete  Elapsed: !ELAPSED_TXT!  ETA: !ETA_TXT!
	echo %ESC%[91mProgress: !DONE! / !TOTAL! files  !PERCENT!%% complete  Elapsed: !ELAPSED_TXT!  ETA: !ETA_TXT!%ESC%[0m
	set /a DONE+=1
)

echo Conversion finished.


REM If you want to move all non CR3 files from SD card to local drive
REM robocopy "%SD%" "%NEW%" /S /MOVE /XF *.cr3

REM If you want to move JPGs and videos files from SD card to local drive
robocopy "%SD%" "%NEW%" *.JPG *.jpg *.MP4 *.mp4 /S /MOV

 ::  Step 2 Extract TIFFs from RAWs frames 




rem Count total files first
set "TOTAL=0"
for %%F in ("%RAW%\*_*_*.dng") do (
    set /a TOTAL+=1
)


echo Total files to process: !TOTAL!

call :NowSeconds STARTSEC

set "DONE=0"

for %%F in ("%RAW%\*_*_*.dng") do (
    call :waitslot

    start "" /b /high "%MAGICK%" mogrify -limit thread 1 -path "%TIFF%" -auto-orient -resize 1080x1080^^ -format tiff -depth 8 -compress lzw "%%F"

    set /a DONE+=1
    set /a MOD=DONE %% 100

    if !MOD! EQU 0 (
        call :ShowProgress
    )
)

call :ShowProgress
echo.
echo All files have been submitted to ImageMagick.

goto :EOF

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

 for %%F in ("%TIFF%\*_*_*.tiff") do (
  for /f "tokens=1,2,3 delims=_" %%A in ("%%~nF") do (
    ren "%%F" "%%A_%%B_%%C00%%~xF"
  )
)

  ::  Step 3 Create MP4  NONSTOP videos from extracted  TIFFs 
 
 

for %%A in ("%TIFF%\*_*_000000.tiff") do (
    set "file=%%~nA"
    set "prefix=!file:~0,-7!"

    set "LIST=%TIFF%\!prefix!_list.txt"

    del "!LIST!" 2>nul

    for /f "delims=" %%F in ('dir /b /on "%TIFF%\!prefix!_*.tiff"') do (
        echo file '%TIFF%\%%F'>>"!LIST!"
    )

    REM ffmpeg -y -r 30 -f concat -safe 0 -i "!LIST!" -c:v libx264 -pix_fmt yuv420p "%DIST%\!prefix!_ns.mp4"
	del /Q "!LIST!" 2>nul
)


  ::  Open culling app
"C:\Program Files (x86)\FastStone Image Viewer\FSViewer.exe" %RAW%
  ::  call "selected.bat"
 


:ShowProgress
call :NowSeconds NOWSEC

set /a ELAPSED=NOWSEC-STARTSEC

rem Fix if crossed midnight
if !ELAPSED! LSS 0 set /a ELAPSED+=86400

if !DONE! GTR 0 (
    set /a PERCENT=DONE*100/TOTAL
    set /a REMAINING=TOTAL-DONE
    set /a ETA=ELAPSED*REMAINING/DONE
) else (
    set "PERCENT=0"
    set "ETA=0"
)

call :FormatSeconds !ELAPSED! ELAPSED_TXT
call :FormatSeconds !ETA! ETA_TXT

	echo %ESC%[91mProgress: !DONE! / !TOTAL! files started - !PERCENT!%% - elapsed !ELAPSED_TXT! - ETA !ETA_TXT!%ESC%[0m
exit /b


:NowSeconds
rem Returns seconds since midnight
set "T=%TIME: =0%"
set /a HH=1%T:~0,2%-100
set /a MM=1%T:~3,2%-100
set /a SS=1%T:~6,2%-100
set /a %~1=HH*3600+MM*60+SS
exit /b

:FormatSeconds
set /a FS=%~1
set /a FH=FS/3600
set /a FM=(FS%%3600)/60
set /a FSS=FS%%60

if !FM! LSS 10 set "FM=0!FM!"
if !FSS! LSS 10 set "FSS=0!FSS!"

set "%~2=!FH!:!FM!:!FSS!"
exit /b



:FormatTime
rem %1 = seconds
rem %2 = output variable name

setlocal EnableDelayedExpansion
set /a T=%1
set /a HH=T/3600
set /a MM=(T%%3600)/60
set /a SS=T%%60

if !HH! LSS 10 set "HH=0!HH!"
if !MM! LSS 10 set "MM=0!MM!"
if !SS! LSS 10 set "SS=0!SS!"

endlocal & set "%2=%HH%:%MM%:%SS%"
exit /b
