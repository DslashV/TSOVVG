@echo off
mode 120, 30
SETLOCAL ENABLEDELAYEDEXPANSION
title Truly Simple Oscilloscope View Video Generator - by D/V
"!__APPDIR__!chcp.com" 65001 >nul
CALL :resetvariables
CALL :LOADINICONFIGFILE "%~1"

:: VERSION
SET "NSOVVGVERSION=1.0.4a12_dev"

set "chosenfiles="
set "ASSETSFOLDER=assets"
set "tempfileprefix=!ASSETSFOLDER!\"
set "userfileprefix=!ASSETSFOLDER!\NSOVVG-USER_"
IF NOT EXIST "!ASSETSFOLDER!\" mkdir "!ASSETSFOLDER!\"

set "progressbarpath=!tempfileprefix!displayrendering.bat"
set "progresslogpath=!tempfileprefix!ffmpegprogresslog.log"
set "fontpickerpath=!tempfileprefix!fontPicker.ps1"
set "numberboxpath=!tempfileprefix!numberBox.ps1"
set "reorderboxpath=!tempfileprefix!reorder.ps1"
set "ffmpeglogpath=!tempfileprefix!ffmpeglog.log"
set "ffmpegrenderingerrorboxpath=!tempfileprefix!ffmpegrenderingerrorBox.ps1"
set "chsortboxpath=!tempfileprefix!chsortBox.ps1"
set "loadingshowname=!userfileprefix!loadingscreen"
set "multidumperpath=!userfileprefix!multidumper"
set "multidumpersettingsboxpath=!tempfileprefix!vgmsettingsBox.ps1"
set "multidumperfullsoundtrackpath=!tempfileprefix!vgmfullsoundtrackBox"
set "helpchmpath=!userfileprefix!!NSOVVGVERSION!-helpchm"

REM echo. > "!loadingshowname!.b64"

set "msg_scgen=Generating the script... Please wait^!"
set "msg_scgendone=Done^!"

REM START conhost "!loadingshowname!.bat" "!loadingshowname!.b64" "NSOVVG is now loading"

CALL :FFMPEG_CHECK

echo Detecting your GPU... Please wait^!
call :gpudetect


:bfdrawlogo

 
:drawlogo
call :reallogo

:menu
echo 	[100m[97m[7m[O][27m - Open config file[0m	[100m[97m[7m[S][27m - Save config file[0m	[44m[97m[7m[Z][27m - Choose the audio channels using drag and drop[0m
echo.
echo 	[43m[97m[7m[M][27m - Choose the master audio[0m	[44m[97m[7m[C][27m - Choose the audio channels[0m
echo 	[44m[97m[7m[D][27m - Change display mode[0m	[104m[97m[7m[F][27m - Configure the audio channels[0m
echo 	[44m[97m[7m[G][27m - Global configuration[0m	[41m[34m[7m[N][27m - New project[0m
echo 	[42m[97m[7m[I][27m - Import VGM file[0m		[45m[97m[7m[V][27m - Video settings[0m
echo 	[100m[97m[7m[H][27m - Help			[0m[101m[93m[7m[R][27m - Render^^![0m
echo.
CALL :channelbrr
CHOICE /C OSMCDFHRGNIVZ /N
IF /I "!ERRORLEVEL!"=="1" (
	for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Config File|*.ini'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "selectedFile=%%a"
	IF NOT "!selectedFile!"=="None" (
		SET i=0
		REM CALL :CHLOOP_CLEAR
		REM for /f "tokens=1,* delims==" %%a in ('type "!selectedFile!"') do (
			REM set dummyvariable1=%%a
			REM IF NOT "!dummyvariable1:~0,1!"=="[" set "%%a=%%b"
		REM )
		CALL :LOADINICONFIGFILE "!selectedFile!"
	)
	goto drawlogo
)

IF /I "!ERRORLEVEL!"=="2" (
	for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.SaveFileDialog; $f.Filter = 'Config File|*.ini'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "saveFile=%%a"
	IF NOT "!saveFile!"=="None" (
		set i=1
		(ECHO [globalConfig])> "!saveFile!"
		(echo x_res=!x_res!)>> "!saveFile!"
		(echo y_res=!y_res!)>> "!saveFile!"
		(echo fps=!fps!)>> "!saveFile!"
		(echo masteraudio=!masteraudio!)>> "!saveFile!"
		(echo linemode=!linemode!)>> "!saveFile!"
		(echo dffont=!dffont!)>> "!saveFile!"
		(echo sizefont=!sizefont!)>> "!saveFile!"
		(echo colorfont=!colorfont!)>> "!saveFile!"
		(echo bgimage=!bgimage!)>> "!saveFile!"
		(echo darkerbg=!darkerbg!)>> "!saveFile!"
		(echo chsort=!chsort!)>> "!saveFile!"
		(ECHO [channelConfig])>> "!saveFile!"
		:CHLOOP_SAVE
		if not "!channel%i%!"=="" (
			(echo channel!i!=!channel%i%!)>> "!saveFile!"
			(echo label!i!=!label%i%!)>> "!saveFile!"
			(echo amp!i!=!amp%i%!)>> "!saveFile!"
			(echo color!i!=!color%i%!)>> "!saveFile!"
			Set /A i+=1
			goto CHLOOP_SAVE
		)
	)
	goto drawlogo
)

if /i "!ERRORLEVEL!"=="3" (
	for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Audio Files|*.wav;*.mp3'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "selectedFile=%%a"
	IF NOT "!selectedFile!"=="None" set "masteraudio=!selectedFile!"
	goto drawlogo
)

if /i "!ERRORLEVEL!"=="4" (
	set pwshcmd=powershell -NoP -C "[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')|Out-Null;$OFD = New-Object System.Windows.Forms.OpenFileDialog;$OFD.Multiselect = $True;$OFD.Filter = 'Audio Files|*.mp3;*.wav';$OFD.InitialDirectory = [Environment]::GetFolderPath('Desktop');$OFD.ShowDialog()|out-null;$OFD.FileNames"
	Set i=0
	for /f "delims=" %%I in ('!pwshcmd!') do (
		Set /A i+=1
		set "channel!i!=%%I"
		set "label!i!=Channel !i!"
		set "amp!i!=2"
		set "color!i!=#FFFFFF"
	)
	if !i! NEQ 0 (
		CALL :CHLOOP_CLEAR
		set /a i-=1
		echo !i!
		set /a h1number=!i! / 2
		set /a hremainder=!i! %% 2

		if !hremainder! equ 0 (
			set /a h1number=!i! / 2
			set /a h2number=!i! / 2
		) else (
			set /a h1number=!i! / 2
			set /a h2number=!hremainder! + !h1number!
		)		
	)
	goto drawlogo
)

if /i "!ERRORLEVEL!"=="5" (
	if "!linemode!"=="point" (
		set "linemode=p2p"
	) else if "!linemode!"=="p2p" (
		set "linemode=line"
	) else if "!linemode!"=="line" (
		set "linemode=cline"
	) else if "!linemode!"=="cline" (
		set "linemode=point
	) else (
		set "lmwv1=p2p"
	)
	goto drawlogo
)

if /i "!ERRORLEVEL!"=="6" (
	if not defined channel1 call :errmsg "You need to add the audio channels first" && goto drawlogo	
	:REASK_CONFIGINDIVIDUAL
	call :reallogo
	set i=1
	IF "!ERRORLEVEL!" EQU "6" (
		CALL :channelbrr
		if defined channel2 (
			echo.
			SET /P configch=Which channel would you like to configure? 
		) else set configch=1
		echo.
		if not defined channel!configch! ( call :errmsg "Invalid vaule. Cancelling" && goto drawlogo ) ELSE ( 
			call :reallogo 
			set i=1
			CALL :channelbrr !configch! 
		)
	) ELSE CALL :channelbrr !configch!
	
	echo [0m
	ECHO Which configuration would you like to configure?
	echo 	[44m[97m[7m[L][27m - Label text[0m		[44m[97m[7m[A][27m - Amplification[0m		[44m[97m[7m[C][27m - Wave color[0m
	ECHO 	[41m[34m[7m[N][27m - Remove this channel[0m	[100m[97m[7m[X][27m - Cancel[0m
	CHOICE /C LACXN /N
	if "!ERRORLEVEL!"=="1" (
		call :inputbox "Please Type Label Text for Channel No. !configch!" "NSOVVG"
		if not "!input!"=="" set "label!configch!=!input!"
	)
	if "!ERRORLEVEL!"=="2" (
		call :SCRIPTGEN_NUMBERBOX 50 !amp%configch%! "Please Set Amplification for Channel No. !configch!" 1
		if not "!selectedNumber!"=="None" set "amp!configch!=!selectedNumber!"
	)
	if "!ERRORLEVEL!"=="3" call :CREATE_COLORPICKER "!color%configch%!" color!configch!
	IF "!ERRORLEVEL!"=="5" (
		SET i=1
		set dummyvariable1=1
		call :MsgBox "Are you sure to remove this channel?" "VBYesNo+VBQuestion" "NSOVVG"
		if "!exitCode!"=="6" CALL :REMOVE_CHANNEL !configch! && goto drawlogo
	)
	IF "!ERRORLEVEL!" NEQ "4" GOTO REASK_CONFIGINDIVIDUAL
	goto drawlogo
	
)

if /i "!ERRORLEVEL!"=="7" (
	start https://github.com/HeeminTV/NSOVVG/wiki/Options
	goto drawlogo
)

if /i "!ERRORLEVEL!"=="8" (
	if not defined channel1 call :errmsg "You need to add the audio channels first" && goto drawlogo 
	if "!masteraudio!"=="None" call :errmsg "You need to choose the master audio" && goto drawlogo
	CALL :FFMPEG_CHECK
	echo 	[101m[93m[R] - Render^^![0m		[46m[97m[P] - Preview[0m		[100m[97m[X] - Cancel[0m
	CHOICE /C RPX /N
	if /i "!ERRORLEVEL!"=="1" (
		for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.SaveFileDialog; $f.Filter = 'Video File|*.mp4'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "saveFile=%%a"
		IF NOT "!saveFile!"=="None" (
			set "ffmpegoutput=!saveFile!"
			set "renderorpreview=2"
			goto render
		)
	)
	if /i "!ERRORLEVEL!"=="2" (
			set "renderorpreview=1"
			goto render
	)
	goto drawlogo
)
if /i "!ERRORLEVEL!"=="9" (
	if not defined channel1 call :errmsg "You have no channels to configure" && goto drawlogo
	:REASK_GLOBALCONFIG
	if not defined channel1 goto drawlogo
	call :reallogo
	call :channelbrr
	set i=1
	echo.
	ECHO [0mWhich configuration would you like to configure globally?
	echo 	[44m[97m[7m[L][27m - Label text[0m		[44m[97m[7m[A][27m - Amplification[0m		[44m[97m[7m[C][27m - Wave color[0m
	echo 	[44m[97m[7m[R][27m - Reorder the channels[0m	[44m[97m[7m[M][27m - Remove quiet channels[0m	[100m[97m[7m[X][27m - Cancel[0m
	CHOICE /C LACXRM /N
	echo.
	if /i "!ERRORLEVEL!"=="1" (
		echo Which channel name template do you want?
		echo 	[44m[97m[7m[1][27m - "Channel No. $"[0m		[44m[97m[7m[2][27m - "Channel #$"[0m		[44m[97m[7m[3][27m - Use the name of the file[0m
		echo		[44m[97m[7m[4][27m - Custom[0m			[44m[97m[7m[5][27m - Clear[0m			[100m[97m[7m[X][27m - Cancel[0m
		for /f %%A in ('powershell -command "$key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character; Write-Host $key"') do set "userInput=%%A"
		if /i "!userInput!"=="5" (
			:CHLOOP_LABELSET1			
			if not "!channel%i%!"=="" (
				ECHO !I!
				set "label!i!="
				Set /A i+=1
				goto CHLOOP_LABELSET1
			)
		)
		IF /I "!userInput!"=="1" (
			:CHLOOP_LABELSET2
			if not "!channel%i%!"=="" (
				set "label!i!=Channel No. !i!"
				Set /A i+=1
				goto CHLOOP_LABELSET2
			)
		)
		IF /I "!userInput!"=="2" (
			:CHLOOP_LABELSET3
			if not "!channel%i%!"=="" (
				set "label!i!=Channel #!i!"
				Set /A i+=1
				goto CHLOOP_LABELSET3
			)
		)
		IF /I "!userInput!"=="3" (
			:CHLOOP_LABELSET4
			if not "!channel%i%!"=="" (
				for %%F in ("!channel%i%!") do set "label!i!=%%~nF"
				Set /A i+=1
				goto CHLOOP_LABELSET4
			)
		)
		IF /I "!userInput!"=="4" (
			call :inputbox "The following text applies to all channels, the letter $ is assigned to the channel number (Example: CH$ = CH1, CH2, CH3...)" "NSOVVG"
			if not "!input!"=="" (
				:CHLOOP_LABELSET5
				set labelstr=!input:$=%i%!
				if not "!channel%i%!"=="" (
					set "label!i!=!labelstr!"
					Set /A i+=1
					goto CHLOOP_LABELSET5
				)
			)
		)
	)
	if "!ERRORLEVEL!"=="2" (
		call :SCRIPTGEN_NUMBERBOX 50 !amp1! "Please Set Amplification" 1
		if not "!selectedNumber!"=="None" (
			:CHLOOP_LABELSET6
			if not "!channel%i%!"=="" (
				set "amp!i!=!selectedNumber!"
				Set /A i+=1
				goto CHLOOP_LABELSET6
			)
		)
	)
	if "!ERRORLEVEL!"=="3" ( 
		call :CREATE_COLORPICKER "!color1!" dummyvariable1
		:CHLOOP_LABELSET7
		if not "!channel%i%!"=="" (
			set "color!i!=!color!"
			Set /A i+=1
			goto CHLOOP_LABELSET7
		)
		
	)
	IF "!ERRORLEVEL!"=="4" goto drawlogo
	IF "!ERRORLEVEL!"=="5" (
		set i=1
		if not defined channel2 call :errmsg "There are no more than 2 channels to reorder" && goto drawlogo
		for /f "tokens=*" %%A in ('powershell -ExecutionPolicy Bypass -File "!reorderboxpath!"') do (
			if "%%A" neq "None" (
				set "buffer_channel!i!=!channel%%A!"
				set "buffer_label!i!=!label%%A!"
				set "buffer_amp!i!=!amp%%A!"
				set "buffer_color!i!=!color%%A!"
				set /a i+=1
			)
		)
		if "!i!" neq "1" (
			 for /L %%i in (1,1,!i!) do (
				set "channel%%i=!buffer_channel%%i!"
				set "label%%i=!buffer_label%%i!"
				set "amp%%i=!buffer_amp%%i!"
				set "color%%i=!buffer_color%%i!"
				set "buffer_channel%%i="
				set "buffer_label%%i="
				set "buffer_amp%%i="
				set "buffer_color%%i="
			)
		)
	)
	IF "!ERRORLEVEL!"=="6" (
		set i=1
		set "dummyvariable1="
		START conhost "!loadingshowname!.bat" "!tempfileprefix!REMOVEQUIETCH_analysis.txt" "Analyzing"
		:CHLOOP_REMOVEQUIETCHANNELS
		if defined channel!i! (
			FFMPEG -i "!channel%i%!" -filter:a volumedetect -f null nul 2> "!tempfileprefix!REMOVEQUIETCH_analysis.txt"
			For /F "tokens=2 delims=:" %%a In ('FINDSTR /C:"mean_volume:" "!tempfileprefix!REMOVEQUIETCH_analysis.txt"') DO FOR /F "tokens=1" %%b IN ("%%a") DO for /f "tokens=*" %%C in ('powershell -Command "if ([double]-80 -lt [double]%%b) { echo true } else { echo false }"') do (
				REM echo Analysis for channel number !i! has been done. The result is "%%C".
				IF /I "%%C"=="FALSE" ( 
					set "dummyvariable1=!dummyvariable1!!i!="
					echo Analysis for channel no. !i! has been done. This audio does not have any sounds.
				) else echo Analysis for channel no. !i! has been done. This audio have sounds.
			)
			
			set /a i+=1
			goto :CHLOOP_REMOVEQUIETCHANNELS
		)
		SET dummyvariable2=0
		IF "!dummyvariable1!" NEQ "" for /f "tokens=*" %%a in ("!dummyvariable1:~0,-1!") DO for %%b in (%%a) do (
			set /a dummyvariable3=%%b - dummyvariable2
			set i=1
			SET dummyvariable1=1
			REM ECHO %%b=!dummyvariable3!=!CHANNEL1!			
			call :REMOVE_CHANNEL !dummyvariable3!
			set /a dummyvariable2+=1
		)
		set "dummyvariable2="
		set "dummyvariable3="
		del /q "!tempfileprefix!REMOVEQUIETCH_analysis.txt" 2>nul
		REM PAUSE
	)
	goto REASK_GLOBALCONFIG
)

if /i "!ERRORLEVEL!"=="10" (
	SET i=0
	if defined channel1 call :MsgBox "You imported a lot of channels, are you sure to clear everything?" "VBYesNo+VBQuestion" "NSOVVG"
	if "!exitCode!"=="6" ( 
		if defined channel1 CALL :CHLOOP_CLEAR
		CALL :resetvariables
	)

	goto drawlogo
	
)

if /i "!ERRORLEVEL!"=="11" (
	if defined channel1 (
		SET i=0
		call :MsgBox "You imported a lot of channels, are you sure to clear everything?" "VBYesNo+VBQuestion" "NSOVVG"
		if "!exitCode!"=="6" CALL :CHLOOP_CLEAR
	)
	:: MY NAME IS P S Y HANGOOK MAL RON BAK JAE SEONG
	SET i=0
	set multidumperErrorCount=0
	IF NOT EXIST "!multidumperpath!\multidumper.exe" (
		call :MsgBox "Could not find multidumper in NSOVVG temp directory. Would you like to download it now?" "VBYesNo+VBQuestion" "NSOVVG"
		if "!exitCode!"=="6" (
			echo. > "!multidumperpath!.zip"
			START conhost "!loadingshowname!.bat" "!multidumperpath!.zip" "Downloading multidumper"
			powershell "(New-Object System.Net.WebClient).DownloadFile('https://github.com/maxim-zhao/multidumper/releases/download/v20220512/multidumper.zip','!multidumperpath!.zip')"
			if "!ERRORLEVEL!" NEQ "0" call :errmsg "An error occurred while downloading the file. Returning to menu" && goto drawlogo
			powershell "Expand-Archive -LiteralPath !multidumperpath!.zip -DestinationPath !multidumperpath!"
			del /q !multidumperpath!.zip
		)
	)
	IF NOT EXIST "!multidumperpath!\multidumper.exe" goto drawlogo
	for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Multidumper Compatible Files|*.ay;*.gbs;*.gym;*.hes;*.kss;*.nsf;*.nsfe;*.sap;*.sfm;*.sgc;*.spc;*.vgm;*.vgz;*.spu'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "selectedFile=%%a" && set "multidumperFileDir=%%~dpa" && set "multidumperExtansion=%%~xa"
	IF NOT "!selectedFile!"=="None" (
		echo WScript.Echo^(new Date^(^).getTime^(^)^); > "!tempfileprefix!unixTime.js"
		for /f "tokens=*" %%a in ('cscript //nologo "!tempfileprefix!unixTime.js"') do set "multidumperTimeStamp=%%a"
		rem for /f "tokens=*" %%a in ("!selectedFile!") do set "multidumperExtansion=%%~xa"
		del /q "!tempfileprefix!unixTime.js" 2>nul
		mkdir "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\"
		copy /y /v "!selectedFile!" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\vgm!multidumperExtansion!"
		!multidumperpath!\multidumper.exe "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\vgm!multidumperExtansion!" --json > "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json"
		findstr /i "error" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json"
		if "!errorlevel!" EQU "0" (
			call :guierrorbox "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json" "A problem occurred while converting file information to json in multidumper."
			goto drawlogo
		)
		ECHO !msg_scgen!
		call :SCRIPTGEN_MULTIDUMPERSETTINGS
		echo !msg_scgendone!
		:f
		for /f "tokens=1,2 delims==" %%a in ('powershell -ExecutionPolicy Bypass -Command "!multidumpersettingsboxpath!" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json"') do (
			if "%%a"=="None" goto drawlogo
			IF /I "%%a"=="FullSoundtrack" (
				echo !msg_scgen!
				set i=0
				CALL :SCRIPTGEN_FULLSOUNDTRACK
				echo !msg_scgendone!
				for /f "tokens=1,2,3 delims==" %%f in ('powershell -ExecutionPolicy Bypass -Command "!multidumperfullsoundtrackpath!.ps1" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json"') do (
					if "%%f"=="None" ( 
						goto f 
					) else if "%%f"=="Header" (
						if %%g LEQ 2 (
							if %%g NEQ 0 CALL :errmsg "You need to choose at least two tracks"
							goto f
						)
						set /a multidumperTotalWavSize="(((441 * 16 * 2 * %%h / 8) / 10000) * (%%g + 1)) + ((441 * 16 * 2 * (%%h * %%g) / 8) / 10000)" 
						call :MsgBox "This render will use about !multidumperTotalWavSize!MB of disk. Do you want to continue?" "VBYesNo+VBQuestion" "NSOVVG"
						if "!exitCode!" NEQ "6" goto f
						START conhost "!loadingshowname!.bat" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json" "Processing"
					) else (
						set "multidumperSubdirNumber=%%f" 
						MKDIR "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\TRACK_!multidumperSubdirNumber!\"
						copy /y /v "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\vgm!multidumperExtansion!" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\TRACK_!multidumperSubdirNumber!\vgm!multidumperExtansion!"						
						!multidumperpath!\multidumper.exe "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\TRACK_!multidumperSubdirNumber!\vgm!multidumperExtansion!" %%f --play_length=%%g000 --fade_length=2000
						if "!ERRORLEVEL!" NEQ "0"  ( 
							IF !multidumperErrorCount! GTR 2 (
								call :errmsg "Too many errors occurred. The process is aborting"
								goto drawlogo
							) else (
								call :errmsg "An error occurred while rendering track !multidumperSubdirNumber!. ERRORLEVEL is !ERRORLEVEL!" 
							)
							set /a multidumperErrorCount+=1
						) else for %%z in ("!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\TRACK_!multidumperSubdirNumber!\*.wav") do echo file '%%z' >> "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\%%~nz_concatlist.txt"
					)
				)
				for %%h in ("!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\*_concatlist.txt") do (
					set "multidumperTempFilename=%%~dpnh"
					ffmpeg -f concat -safe 0 -i "%%~h" -c copy "!multidumperTempFilename:_concatlist=.wav!"
				)
				
			) else (
				START conhost "!loadingshowname!.bat" "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json" "Seperating audio channels"
				!multidumperpath!\multidumper.exe "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\vgm!multidumperExtansion!" %%a --play_length=%%b000 --fade_length=2000
			)
			
			set "multidumperFFmpegMixingCommand="
			echo $jsonData = Get-Content -Path '!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json' ^| ConvertFrom-Json;foreach ^($channel in $jsonData.channels^) { Write-Host "vgm - $channel.wav" } > "!tempfileprefix!multidumperchsort.ps1"
			for /f "tokens=*" %%l in ('powershell -ExecutionPolicy Bypass -File "!tempfileprefix!multidumperchsort.ps1"') do (
				set /a i+=1
				set "channel!i!=!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\%%l"
				set "multidumperFilename=%%~nl"
				set "label!i!=!multidumperFilename:~6!"
				set "amp!i!=2"
				set "color!i!=#FFFFFF"
				set "multidumperFFmpegMixingCommand=!multidumperFFmpegMixingCommand!-i "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\%%l" "
			)
			
			ffmpeg.exe !multidumperFFmpegMixingCommand! -filter_complex amix=inputs=!i!:duration=longest:normalize=0 "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\masteraud.wav"
			set "masteraudio=!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\masteraud.wav"
			del /q "!multidumperFileDir!NSOVVG-USER_VGMimportTEMP_!multidumperTimeStamp!\info.json"
			
		)
		
	)
	goto drawlogo
)
if /i "!ERRORLEVEL!"=="12" (
	echo.
	ECHO [0mWhich configuration would you like to configure?
	echo 	[44m[97m[7m[I][27m - Background image / video[0m						[44m[97m[7m[C][27m - Background color[0m
	if "!gpu!"=="libx264" (
		echo 	[46m[97m[7m[S][27m - Use hardware rendering for this time[0m				[44m[97m[7m[W][27m - Configure channel array[0m
	) else (
		echo 	[41m[97m[7m[S][27m - Use software rendering for this time ^(libx264^)[0m			[44m[97m[7m[W][27m - Configure channel array[0m
	)
	echo 	[44m[97m[7m[T][27m - Font configuration[0m						[44m[97m[7m[R][27m - Change video resolution, FPS[0m
	echo 	[100m[97m[7m[X][27m - Cancel[0m
	CHOICE /C BIXCSWTR /N
	echo.
	if /i "!ERRORLEVEL!"=="2" (
		for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Picture Files|*.png;*.jpg;*.mp4;*.jpeg;*.avi'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "selectedFile=%%a"
		IF NOT "!selectedFile!"=="None" (
			rem set "bgimage=!selectedFile!"
			ECHO [0mWould you like to get darker background?
			echo 	[102m[97m[Y] - Yes![0m				[41m[97m[N] - No[0m			[100m[97m[X] - Cancel[0m
			for /f %%A in ('powershell -command "$key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character; Write-Host $key"') do set "userInput=%%A"
			if /i "!userInput!"=="y" set "darkerbg=on"
			if /i "!userInput!"=="n" set "darkerbg=off"
			if /i not "!userInput!"=="x" set "bgimage=!selectedFile!"
		)
		rem rem TEST
	goto drawlogo
	)
	IF /I "!ERRORLEVEL!"=="4" (
		call :CREATE_COLORPICKER "#000000" dummyvariable1
		if "!dummyvariable1!"=="#000000" ( set "bgimage=None" ) else set "bgimage=!dummyvariable1!"
	)
	IF /I "!ERRORLEVEL!"=="1" (
		call :SCRIPTGEN_NUMBERBOX 100000 !bitrate:~0,-1! "Please set the bitrate of the video. (kbps)" 100
		if not "!selectedNumber!"=="None" set "bitrate=!selectedNumber!k"
	)
	rem 
	IF /I "!ERRORLEVEL!"=="5" (
		if NOT "!gpu!"=="libx264" (
			set "gpu=libx264"
		) else (
			call :gpudetect
			if "!ERRORLEVEL!"=="2" ( call :errmsg "It appears that your computer does not support hardware rendering. Use software rendering instead" )
		)
	)
	
	if /i "!ERRORLEVEL!" EQU "6" (
		if not defined channel1 ( call :errmsg "You need to add the audio channels first" && goto drawlogo )
		set /a SORT2_h1number=!chcount_fortitle! / 2
		set /a SORT2_hremainder=!chcount_fortitle! %% 2	
		if !SORT2_hremainder! equ 0 (
			set /a SORT2_h2number=!chcount_fortitle! / 2
		) else (
			set /a SORT2_h2number=!SORT2_hremainder! + !SORT2_h1number!
		)
		
		if "!chsort!"=="AUTO" (
			set "SORT_h1number=!SORT2_h1number!"
			set "SORT_h2number=!SORT2_h2number!"
			
		) else if /i "!chsort!"=="AllVertical" (
			set "SORT_h1number=!SORT2_h1number!"
			set "SORT_h2number=!SORT2_h2number!"
			
		) else (
			for /f "tokens=1,2 delims==" %%a in ("!chsort!") do (
				set "SORT_h2number=%%a"
				set "SORT_h1number=%%b"
			)
		)
		ECHO !msg_scgen!
		call :SCRIPTGEN_CHSORT
		ECHO !msg_scgendone!
		for /f "tokens=1,2 delims==" %%a in ('powershell -ExecutionPolicy Bypass -Command "!chsortboxpath!" !SORT_h2number! !SORT_h1number!') do (
			if "%%a" NEQ "None" IF "%%a" EQU "AllVertical" (
				set "chsort=ALLVERTICAL"
			) else (
				if "!SORT2_h2number!"=="%%a" ( set "chsort=AUTO" ) ELSE ( set "chsort=%%a=%%b" )
			)
			ECHO %%a%%b
			echo !SORT2_h2number!x!SORT2_h1number!
		)
		set "SORT_h1number="
		set "SORT_h2number="
		set "SORT_hremainder="
		set "SORT2_h1number="
		set "SORT2_h2number="
		set "SORT2_hremainder="
	)
	
	if /i "!ERRORLEVEL!"=="7" (
		ECHO [101m[97m[1m[WARNING] Nothing is supported other than "Font selection", "Font color", and "Font size".[0m

		call :SCRIPTGEN_FONTPICKER
		for /f "tokens=1,2 delims==" %%a in ('powershell -ExecutionPolicy Bypass -File "!fontpickerpath!"') do (
			if "%%a"=="Canceled" goto drawlogo
			if "%%a"=="FontName" set "dffont=%%b"
			if "%%a"=="FontSize" set "sizefont=%%b"
			if "%%a"=="FontColor" set "colorfont=%%b"
		)
	)
	if /i "!ERRORLEVEL!"=="8" (
		call :SCRIPTGEN_VIDEOCONFIG 
		for /f "tokens=1,2,3 delims==" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!numberboxpath!"') do (
			if not "%%a"=="None" (
				SET "x_res=%%a"
				SET "y_res=%%b"
				SET "fps=%%c"
			)
		)
	)
	goto drawlogo
)

IF "!ERRORLEVEL!"=="13" (
	REM set i=1
	call :reallogo
	set i=1
	ECHO.
	ECHO Drag and drop your channel files here and press [7m[ENTER][27m at the end.
	set /p dummyvariable1=
	REM if !errorlevel! equ 1 goto drawlogo
	REM echo !ERRORLEVEL!
	REM echo !dummyvariable1!
	REM pause
	REM if not defined dummyvariable1 goto drawlogo
	set dummyvariable2=0
	call :CHLOOP_ADDCHFROMDRAGNDROP !dummyvariable1!
	
	
	goto drawlogo
)
goto drawlogo

:InputBox
REM Input routine for batch using VBScript to provide input box
REM Stephen Knight, October 2009, http://www.dragon-it.co.uk/
set "input="
echo wscript.echo inputbox(WScript.Arguments(0),WScript.Arguments(1)) >"!tempfileprefix!input.vbs"
for /f "tokens=* delims=" %%a in ('cscript //nologo "!tempfileprefix!input.vbs" "%~1" "%~2"') do set input=%%a
del /q "!tempfileprefix!input.vbs"
goto :EOF

:errmsg
echo msgbox "%~1^!",vbOKOnly+vbCritical,"NSOVVG" > "!tempfileprefix!error.vbs"
cscript //nologo "!tempfileprefix!error.vbs"
DEL /Q "!tempfileprefix!error.vbs"
goto :EOF


:MsgBox prompt type title
set "tempFile=!tempfileprefix!msgbox.tmp"
>"!tempFile!" echo(WScript.Quit msgBox("%~1",%~2,"%~3") & cscript //nologo //e:vbscript "!tempFile!"
set "exitCode=!errorlevel!" & del "!tempFile!" >nul 2>nul
goto :eof
 
:reallogo
SET i=0
if "!linemode!"=="point" (
	set "lmwv1=.·'·.·'·.·'·.·"
) else if "!linemode!"=="p2p" (
	set "lmwv1=  /\/\/\/\/\/\/\"
) else if "!linemode!"=="line" (
	set "lmwv1= ▲▲▲▲▲▲▲▲▲▲▲▲▲▲"
) else if "!linemode!"=="cline" (
	set "lmwv1=◆◆◆◆◆◆◆◆◆◆◆◆◆◆"
) else (
	set "lmwv1=undefined"
)
if "!masteraudio!"=="None" (
	set "mastername=[91mNone"
) else for %%F in ("!masteraudio!") do set "mastername=[93m"%%~nxF""

if "!bgimage!"=="None" (
	set "imagename=[32mBackground Image:	[93m[91mNone[97m"
) else if "!bgimage:~0,1!"=="#" (
	set "hexColor=!bgimage:~1!"
	set /a r=0x!hexColor:~0,2!
	set /a g=0x!hexColor:~2,2!
	set /a b=0x!hexColor:~4,2!
	set "displaybgimage=[38;2;!r!;!g!;!b!m!bgimage!"
	set "imagename=[32mBackground Color:	[93m!displaybgimage![97m"
) else for %%F in ("!bgimage!") do set "imagename=[32mBackground Image:	[93m"%%~nxF"[97m"

set strLen=0
for /l %%a in (0,1,64) do if not "!dffont:~%%a,1!" == "" set /a strLen+=1
if !strLen! geq 23 (
	set "displayfont=!dffont!"
) else (
	set /a remainLen=23-!strLen!
	set "fillString="
	for /l %%i in (1,1,!remainLen!) do set "fillString=!fillString! "
	set "displayfont=!dffont!!fillString!"
)

set "hexColor=!colorfont:~1!"
set /a r=0x!hexColor:~0,2!
set /a g=0x!hexColor:~2,2!
set /a b=0x!hexColor:~4,2!
set "displaycolorfont=[38;2;!r!;!g!;!b!m!colorfont!"
set "r="
set "g="
set "b="
set "hexColor="
:CHLOOP_FORTITLE
Set /A i+=1
if defined channel1 ( 
	if not "!channel%i%!"=="" (
		set "chcount_fortitle=!i!" 
		goto CHLOOP_FORTITLE 
	)
) else set "chcount_fortitle=0"

if "!chsort!"=="AUTO" (
	set "displaychannelsorting=	[91mAuto"
) else if "!chsort!"=="ALLVERTICAL" (
	set "displaychannelsorting=	[93mVertical Sort"
) ELSE (
	for /f "tokens=1,2 delims==" %%a in ("!chsort!") do (
		set /a CCresult=%%a + %%b
		IF "!CCresult!" NEQ "!chcount_fortitle!" ( set "chsort=AUTO" && set "displaychannelsorting=	[91mAuto" ) ELSE set "displaychannelsorting=	[93mL=%%a, R=%%b"
	)
)

IF "!NSOVVGVERSION:a=!" NEQ "!NSOVVGVERSION!" (
	SET "displaytoptab=THIS IS UNSTABLE VERSION OF NSOVVG."
) else set "displaytoptab="

cls
IF DEFINED DISPLAYTOPTAB ( echo [90mNSOVVG Version !NSOVVGVERSION! by [D/V[24m	[7m[5m_==[!displaytoptab!]==_[0m ) ELSE ( echo [90mNSOVVG Version !NSOVVGVERSION! by [4mheeminwelcome1@gmail.com[0m )
echo    _______   ______   _____     _     _    _     _    ______
echo   /\_______)\/ ____/\ ) ___ (   /_/\ /\_\  /_/\ /\_\  /_/\___\
echo   \(___  __\/) ) __\// /\_/\ \  ) ) ) ( (  ) ) ) ( (  ) ) ___/
echo     / / /     \ \ \ / /_/ (_\ \/_/ / \ \_\/_/ / \ \_\/_/ /  ___
echo    ( ( (      _\ \ \\ \ )_/ / /\ \ \_/ / /\ \ \_/ / /\ \ \_/\__\
echo     \ \ \    )____) )\ \/_\/ /  \ \   / /  \ \   / /  )_)  \/ _/
echo      /_/_/    \____\/  )_____(    \_\_/_/    \_\_/_/   \_\____/
echo.
echo.             Truly Simple Oscilloscope View Video Generator
echo.
goto :EOF

:CHLOOP_CLEAR
Set /A i+=1
REM if not "!channel%i%!"=="" (
	REM set "channel!i!="
	REM goto CHLOOP_CLEAR
REM )
IF DEFINED channel!i! (
	set "channel!i!="
	goto CHLOOP_CLEAR
)
goto :EOF
		
:SCRIPTGEN_FONTPICKER
echo Add-Type -AssemblyName System.Windows.Forms > !fontpickerpath!
echo $fontDialog = New-Object System.Windows.Forms.FontDialog >> !fontpickerpath!

echo $fontDialog.ShowColor = $true >> !fontpickerpath!

echo $defaultFont = New-Object System.Drawing.Font("!dffont!", !sizefont!, [System.Drawing.FontStyle]::Regular) >> !fontpickerpath!
echo $fontDialog.Font = $defaultFont >> !fontpickerpath!

echo $defaultColor = [System.Drawing.ColorTranslator]::FromHtml^("!colorfont!"^) >> !fontpickerpath!
echo $fontDialog.Color = $defaultColor >> !fontpickerpath!
rem THANK YOU STACKOVERFLOW NERDS

echo if ($fontDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK^) { >> !fontpickerpath!
echo Write-Host "FontName=$($fontDialog.Font.Name)" >> !fontpickerpath!
echo Write-Host "FontSize=$([int]$fontDialog.Font.Size)" >> !fontpickerpath!
echo $red = $fontDialog.Color.R >> !fontpickerpath!
echo $green = $fontDialog.Color.G >> !fontpickerpath!
echo $blue = $fontDialog.Color.B >> !fontpickerpath!
echo $hexshit = "#{0:X2}{1:X2}{2:X2}" -f $red, $green, $blue >> !fontpickerpath!
echo Write-Host "FontColor=$hexshit" >> !fontpickerpath!
echo } else { Write-Host "Canceled" } >> !fontpickerpath!

goto :EOF

:SCRIPTGEN_NUMBERBOX
rem set "numberboxpath=asd.ps1"
	echo Add-Type -AssemblyName System.Windows.Forms > !numberboxpath!
	echo Add-Type -AssemblyName System.Drawing >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $form ^= New-Object System.Windows.Forms.Form >> !numberboxpath!
	echo $form.Text ^= 'NSOVVG' >> !numberboxpath!
	echo $form.Size ^= New-Object System.Drawing.Size^(250, 150^) >> !numberboxpath!
	echo $form.StartPosition ^= 'CenterScreen' >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $label ^= New-Object System.Windows.Forms.Label >> !numberboxpath!
	echo $label.Text ^= "%~3" >> !numberboxpath!
	echo $label.AutoSize ^= $true >> !numberboxpath!
	echo $label.Location ^= New-Object System.Drawing.Point(0, 10) >> !numberboxpath!
	echo $form.Controls.Add($label) >> !numberboxpath!

	echo $numericUpDown ^= New-Object System.Windows.Forms.NumericUpDown >> !numberboxpath!
	echo $numericUpDown.Location ^= New-Object System.Drawing.Point^(50, 30^) >> !numberboxpath!
	echo $numericUpDown.Width ^= 100  >> !numberboxpath!
	echo $numericUpDown.Minimum ^= 0  >> !numberboxpath!
	echo $numericUpDown.Maximum ^= %~1  >> !numberboxpath!
	echo $numericUpDown.DecimalPlaces ^= 0  >> !numberboxpath!
	echo $numericUpDown.Value ^= %~2  >> !numberboxpath!
	ECHO $numericUpDown.Increment = %~4  >> !numberboxpath!
	echo $form.Controls.Add^($numericUpDown^) >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $okButton ^= New-Object System.Windows.Forms.Button >> !numberboxpath!
	echo $okButton.Text ^= 'OK' >> !numberboxpath!
	echo $okButton.Location ^= New-Object System.Drawing.Point^(30, 70^) >> !numberboxpath!
	echo $okButton.Add_Click^({ >> !numberboxpath!
	echo     $form.Tag ^= $numericUpDown.Value >> !numberboxpath!
	echo     $form.Close^(^) >> !numberboxpath!
	echo }^) >> !numberboxpath!
	echo $form.Controls.Add^($okButton^) >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $cancelButton ^= New-Object System.Windows.Forms.Button >> !numberboxpath!
	echo $cancelButton.Text ^= 'Cancel' >> !numberboxpath!
	echo $cancelButton.Location ^= New-Object System.Drawing.Point^(120, 70^) >> !numberboxpath!
	echo $cancelButton.Add_Click^({ >> !numberboxpath!
	echo     $form.Tag ^= 'None' >> !numberboxpath!
	echo     $form.Close^(^) >> !numberboxpath!
	echo }^) >> !numberboxpath!
	echo $form.Controls.Add^($cancelButton^) >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $form.Add_FormClosing^({ >> !numberboxpath!
	echo     if ^($form.Tag -eq $null^) { >> !numberboxpath!
	echo         $form.Tag ^= 'None' >> !numberboxpath!
	echo     } >> !numberboxpath!
	echo }^) >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo $form.ShowDialog^(^) ^| Out-Null >> !numberboxpath!
	rem echo.  >> !numberboxpath!

	echo Write-Host $form.Tag >> !numberboxpath!
	rem echo.  >> !numberboxpath!
	rem echo.  >> !numberboxpath!

for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!numberboxpath!"') do set selectedNumber=%%i

del /q !numberboxpath!
goto :eof

:gpudetect
for /f "tokens=2 delims==" %%G in ('wmic path win32_videocontroller get name /value') do set "gpu_name=%%G"

echo !gpu_name! | find /i "NVIDIA" >nul
if %errorlevel%==0 (
    set "gpu=h264_nvenc"
    rem goto bfdrawlogo
)

echo !gpu_name! | find /i "Intel" >nul
if %errorlevel%==0 (
    set "gpu=h264_qsv"
    rem goto bfdrawlogo
)

echo !gpu_name! | find /i "AMD" >nul
if %errorlevel%==0 (
    set "gpu=h264_amf"
    rem goto bfdrawlogo
)

if not defined gpu ( set "gpu=libx264" && exit /b 2 ) else ( exit /b 1 )

:channelbrr
	SET i=1
	rem echo %~1
	:CHLOOP_CHSHOW
	rem echo s%~1s
	if not "!channel%i%!"=="" (
		if !i! equ 1 echo	[100m[97mChannels[0m
		if "!label%i%!"=="" ( set "temp_displayedlabel=[91mNone" ) else ( set "temp_displayedlabel="!label%i%!"" )
		set strLen=0
		for /l %%a in (0,1,64) do if not "!temp_displayedlabel:~%%a,1!" == "" set /a strLen+=1
			if !strLen! geq 23 (
				set "displayedlabel=!temp_displayedlabel!"
			) else (
				set /a remainLen=23-!strLen!
				set "fillString="
				for /l %%i in (1,1,!remainLen!) do set "fillString=!fillString! "
				set "displayedlabel=!temp_displayedlabel!!fillString!"
			)
		rem if not exist "!channel%i%!" ( call :errmsg "Couldn't find " && goto drawlogo )
		for %%F in ("!channel%i%!") do set "displaych=%%~nxF"
		set "hexColor=!color%i%:~1!"
		set /a r=0x!hexColor:~0,2!
		set /a g=0x!hexColor:~2,2!
		set /a b=0x!hexColor:~4,2!
		set "displaycolor=[38;2;!r!;!g!;!b!m!color%i%!"
		IF "%~1"=="" ( echo 	[96m[7mChannel No. !i![27m [93m[7m"!displaych!"[27m && echo [36m	 └─── [96mLabel Text: [93m!displayedlabel![100m[97m^|^|[0m	[96mAmplification: [93m!amp%i%!	[100m[97m^|^|[0m	[96mWave Color: !displaycolor![0m ) ELSE (
			if "!i!" equ "%~1" ( echo 	[92m[107m[SELECTED][40m[7m Channel No. !i![27m [93m[7m"!displaych!"[27m ) else ( echo 	[96m[7mChannel No. !i![27m [93m[7m"!displaych!"[27m )
			echo [36m	 └─── [96mLabel Text: [93m!displayedlabel![100m[97m^|^|[0m	[96mAmplification: [93m!amp%i%!	[100m[97m^|^|[0m	[96mWave Color: !displaycolor![0m
		)
		set chcount=!i!
		rem echo !chcount!
		Set /A i+=1
		goto CHLOOP_CHSHOW
	)
	set i=1
	goto :EOF
	
:render

set channelCount=0
set H1Count=0
set H2Count=0
set "channelInputs="
set "filterComplex="
set "layout="
IF "!chsort!" equ "AUTO" ( 
	set autosortvaule=4
) else if "!chsort!" equ "ALLVERTICAL" ( 
	set autosortvaule=64
) else set autosortvaule=1
REM @echo on
set "outer="
set "H1F="
set "H2F="
set "bgcf1="
set "bgcf2="
set "linemode2="
set "bitrate=5000k"
set "scalemode=lin"
set "linemode2=!linemode!:split_channels=0"
set stack_num=!chcount!
set /a stack_y_res=y_res / stack_num
set /a remainder=y_res %% stack_num
echo !stack_num!
set /a last_stack_y_res=stack_y_res + remainder

	if !chcount! GTR !autosortvaule! (
		if "!chsort!"=="AUTO" (
			echo AUTO CHANNEL SORTING

			set /a h1number=!chcount! / 2
			set /a hremainder=!chcount! %% 2

			if !hremainder! equ 0 (
				set /a h2number=!chcount! / 2
			) else set /a h2number=!hremainder! + !h1number!
			
		) else for /f "tokens=1,2 delims==" %%a in ("!chsort!") do (
			set "h2number=%%a"
			set "h1number=%%b"
		)
		echo !h2number! !h1number!
		set /a H1_y_res=y_res / h2number
		set /a H1remainder=y_res %% h2number
		set /a last_H1_y_res=H1_y_res + H1remainder

		set /a H2_y_res=y_res / h1number
		set /a H2remainder=y_res %% h1number
		set /a last_H2_y_res=H2_y_res + H2remainder

		set /a x_reshalf=x_res/2
		rem echo !x_res!
		ECHO H1 : !H1_y_res!, !last_H1_y_res!
		echo H2 : !H2_y_res!, !last_H2_y_res!

	)

:loop
rem shift
set /a channelCount+=1
set "beforeshowwaves=volume=!amp%channelCount%![g"
if !channelCount! gtr !chcount! goto endloop

rem set /a channelCount+=1
set "channelInputs=!channelInputs! -i "!channel%channelCount%!""

if defined label!channelCount! (
	set "drawtext=[wave%channelCount%]drawtext=text='!label%channelCount%!':font='!dffont!':x=10:y=10:fontsize=!sizefont!:fontcolor=!colorfont![wave%channelCount%];"
) else set "drawtext="

if !chcount! GTR !autosortvaule! (
	REM echo !h2number! !h1number! HAAA
	if !channelCount! LEQ !h2number! (
		rem OSCI LEFT SIDE
		set /a H1Count+=1
		if "!H1Count!"=="!h2number!" (
			rem LAST CHANNEL

				set "H1F=!H1F! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_reshalf!x!last_H1_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
				if "!h2number!" EQU "1" ( set "LAYOUT_VSTACKL=wave%channelCount%" ) ELSE (
					set "layout=!layout![wave%channelCount%]vstack=inputs=!H1Count![left];"
					set "LAYOUT_VSTACKL=left"
				)
		) else (
			rem OTHERS

				set "H1F=!H1F! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_reshalf!x!H1_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
				set "layout=!layout![wave%channelCount%]"
		)

			REM :: set "layout=!layout![wave%channelCount%]"

	) else (
		rem OSCI RIGHT SIDE
		set /a H2Count+=1
		if "!H2Count!"=="!h1number!" (
				rem LAST CHANNEL

				set "H2F=!H2F! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_reshalf!x!last_H2_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
				rem if "!h1number!" EQU "1" ( set "layout=!layout![wave%channelCount%];" ) ELSE set "layout=!layout![wave%channelCount%]vstack=inputs=!H2Count![right];"
				if "!h1number!" EQU "1" ( set "LAYOUT_VSTACKR=wave%channelCount%" ) ELSE (
					set "layout=!layout![wave%channelCount%]vstack=inputs=!H2Count![right];"
					set "LAYOUT_VSTACKR=right"
				)
				rem set "layout=!layout![wave%channelCount%]vstack=inputs=!H2Count![right];"
		) else (
				rem OTHERS
				set "H2F=!H2F! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_reshalf!x!H2_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
				set "layout=!layout![wave%channelCount%]"
		)

			REM :: set "layout=!layout![wave%channelCount%]"

	)
	if "!H1F:~3072,1!" NEQ "" (
		rem ECHO %H1F:~4096,1%
		call :errmsg "The length of the command being generated has reached the console's maximum length. Try removing some channels"
		GOTO DRAWLOGO
	)
) else (
	if "!channelCount!"=="!chcount!" (
		if !chcount!==1 (
			set "filterComplex=!filterComplex! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_res!x!last_stack_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
		) else (
			set "filterComplex=!filterComplex! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_res!x!last_stack_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
		)
	) else (
		if !chcount!==1 (
			set "filterComplex=!filterComplex! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_res!x!stack_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
		) else (
			set "filterComplex=!filterComplex! [%channelCount%:a]!beforeshowwaves!%channelCount%];[g%channelCount%]showwaves=s=!x_res!x!stack_y_res!:mode=!linemode2!:colors=!color%channelCount%!:rate=!fps!:scale=!scalemode![wave%channelCount%];!drawtext!"
		)
	)
	if !chcount!==1 (
		set "layout="
	) else (
		set "layout=!layout![wave%channelCount%]"
	)
	if "!filterComplex:~7168,1!" NEQ "" (
		rem ECHO %H1F:~4096,1%
		call :errmsg "The length of the command being generated has reached the console's maximum length. Try removing some channels"
		GOTO DRAWLOGO
	)
)
rem shift
rem set /a i-=1

goto loop

:endloop
set channelCount+=1
rem echo %channelCount% %i%
:: 譆謙 轎溘 溯檜嬴醒擊 薑曖
if "!bgimage!"=="None" (
	set "bgcf1="
	set "bgcf2="
) else if "!bgimage:~0,1!"=="#" (
	rem (This is only a temporary solution. We will optimize it further soon)
	if "!chcount!"=="1" (
		set "bgcf1=color=c=!bgimage!:size=!x_res!x!y_res!:d=1 [bgimg];[bgimg][wave1]overlay=x=0:y=0[wave1]"
	) else (
		set "bgcf1=color=c=!bgimage!:size=!x_res!x!y_res!:d=1 [bgimg];[bgimg][v2]overlay=x=0:y=0[v2]"
	)
) else (
	rem (This is only a temporary solution. We will optimize it further soon)
	if "!chcount!"=="1" (
			if /i "!darkerbg!"=="on" (
			set "bgcf1=[!channelCount!:v]scale='if(gt(iw/ih,!x_res!/!y_res!),!x_res!,-2)':'if(gt(iw/ih,!x_res!/!y_res!),-2,!y_res!)', pad=width=!x_res!:height=!y_res!:x=(ow-iw)/2:y=(oh-ih)/2[bgimg];[bgimg]eq=brightness=-0.5[bgimg];[bgimg][wave1]overlay=x=0:y=0[wave1];"
		) else (
			set "bgcf1=[!channelCount!:v]scale='if(gt(iw/ih,!x_res!/!y_res!),!x_res!,-2)':'if(gt(iw/ih,!x_res!/!y_res!),-2,!y_res!)', pad=width=!x_res!:height=!y_res!:x=(ow-iw)/2:y=(oh-ih)/2[bgimg];[bgimg][wave1]overlay=x=0:y=0[wave1];"
		)
		
	) else (
		if /i "!darkerbg!"=="on" (
			set "bgcf1=[!channelCount!:v]scale='if(gt(iw/ih,!x_res!/!y_res!),!x_res!,-2)':'if(gt(iw/ih,!x_res!/!y_res!),-2,!y_res!)', pad=width=!x_res!:height=!y_res!:x=(ow-iw)/2:y=(oh-ih)/2[bgimg];[bgimg]eq=brightness=-0.5[bgimg];[bgimg][v2]overlay=x=0:y=0[v2];"
		) else (
			set "bgcf1=[!channelCount!:v]scale='if(gt(iw/ih,!x_res!/!y_res!),!x_res!,-2)':'if(gt(iw/ih,!x_res!/!y_res!),-2,!y_res!)', pad=width=!x_res!:height=!y_res!:x=(ow-iw)/2:y=(oh-ih)/2[bgimg];[bgimg][v2]overlay=x=0:y=0[v2];"
		)
		rem set "bgcf1=[!channelCount!:v]scale^=!x_res!:!y_res!:force_original_aspect_ratio^=decrease,pad^=!x_res!:!y_res!:-1:-1:color^=black[v2]"
	)
	set "bgcf2=-i "!bgimage!" "
)
REM set "outer=-c:v !gpu! -format yuv420p -map [v2]"
if "!chcount!"=="1" (
	set "layout=!bgcf1!"
	 set "outer=-c:v !gpu! -format yuv420p -b:v !bitrate! -map [wave1]"
) else if !chcount! GTR !autosortvaule! (
	set "filterComplex=!H1F!!H2F!"
	set "layout=!layout![!LAYOUT_VSTACKL!][!LAYOUT_VSTACKR!]hstack=inputs=2[v2];!bgcf1!"
	 set "outer=-c:v !gpu! -format yuv420p -b:v !bitrate! -map [v2]"
) else (
	set "layout=!layout!vstack=inputs=!chcount![v2];!bgcf1!"
	 set "outer=-c:v !gpu! -format yuv420p -b:v !bitrate! -map [v2]"
)
REM echo ffmpeg -i "%masterAudio%" %channelInputs% -filter_complex "%filterComplex% %layout%" -map 0:a -c:a aac %outer% -f nut
:playorrender
del /q "!ffmpeglogpath!"
set "ffmpegcommand=-loglevel error -stats -i "!masterAudio!" !channelInputs! !bgcf2!-filter_complex "!filterComplex! !layout!" -map 0:a -c:a aac -b:a 192k !outer!"
rem CHOICE /C PR /N /M "Press "P" to preview, or "R" to render. "
if /i "!renderorpreview!"=="2" (
	del /q !progresslogpath!
	start conhost !progressbarpath! "!masterAudio!" "!progresslogpath!"

	ffmpeg -y -progress !progresslogpath! !ffmpegcommand! "!ffmpegoutput!" 2> "!ffmpeglogpath!"
	
	echo None> !progresslogpath!
	IF "!ERRORLEVEL!" NEQ "255" ( CALL :ffmpegerrorhandling NEQ ) ELSE ( ECHO If you see the message ※Terminate batch job ^(Y/N^)§, please type [7m[N][27m. )
				
) else if /i "!renderorpreview!"=="1" (

	ffmpeg -y !ffmpegcommand! -f nut - | ffplay - 2> "!ffmpeglogpath!"
	findstr /i "Invalid" "!ffmpeglogpath!"
	REM echo !errorlevel!r
	REM pause
	if "!ERRORLEVEL!"=="0" ( 
		rem ffmpeg !ffmpegcommand!  2> "!ffmpeglogpath!"
		ffmpeg !ffmpegcommand! -f null - 2> "!ffmpeglogpath!"
		CALL :ffmpegerrorhandling NEQ
	)
	
) else (
	echo Aborted.
	exit
)
goto drawlogo

:ffmpegerrorhandling
IF "!ERRORLEVEL!" %1 "0" (
	echo. >> "!ffmpeglogpath!"
	echo !ffmpegcommand! >> "!ffmpeglogpath!"
	call :guierrorbox "!ffmpeglogpath!" "An error occurred during video rendering."
)
goto :EOF

:guierrorbox logfilepath message
	for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command !ffmpegrenderingerrorboxpath! '%~1' '%~2'') do (
		if "%%a"=="YES" (
			for /f "delims=" %%a in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $f = New-Object System.Windows.Forms.SaveFileDialog; $f.Filter = 'Error Log|*.log'; $f.Multiselect = $false; if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host $f.FileName } else { Write-Host 'None' }"') do set "saveFile=%%a"
			IF NOT "!saveFile!"=="None" move /y "%~1" "!saveFile!"
		)
	)
	set "saveFile="
	rem del /q "%~1" 2>nul
goto :EOF

:resetvariables
set "masteraudio=None"
set "bgimage=None"
set x_res=1280
set y_res=720
set "fps=60"
set "bitrate=5000k"
set "linemode=p2p"
set "dffont=Arial"
set "h1count="
set "h2count="
set "sizefont=14"
set "colorfont=#FFFFFF"
set "chsort=AUTO"
goto :eof

:SCRIPTGEN_FULLSOUNDTRACK
echo Add-Type -AssemblyName System.Windows.Forms > "!multidumperfullsoundtrackpath!.ps1"
echo Add-Type -AssemblyName System.Drawing >> "!multidumperfullsoundtrackpath!.ps1"
echo $buttonClicked = $false >> "!multidumperfullsoundtrackpath!.ps1"
echo $jsonData = Get-Content -Raw -Path $args[0] ^| ConvertFrom-Json >> "!multidumperfullsoundtrackpath!.ps1"


echo $subsongCount = $args[1] >> "!multidumperfullsoundtrackpath!.ps1"
echo if ^(-not $subsongCount^) { $subsongCount = $jsonData.subsongCount } >> "!multidumperfullsoundtrackpath!.ps1"
echo $copyright = $jsonData.containerinfo.copyright >> "!multidumperfullsoundtrackpath!.ps1"
echo if ^(-not $copyright^) { $copyright = $jsonData.containerinfo.system } >> "!multidumperfullsoundtrackpath!.ps1"
echo $game = $jsonData.containerinfo.game >> "!multidumperfullsoundtrackpath!.ps1"
echo if ^(-not $game^) { $game = $jsonData.containerinfo.dumper } >> "!multidumperfullsoundtrackpath!.ps1"
echo if ^(-not $copyright^) { $copyright = "Unknown Artist" } >> "!multidumperfullsoundtrackpath!.ps1"
echo if ^(-not $game^) { $game = "Unknown Game" } >> "!multidumperfullsoundtrackpath!.ps1"


echo $form = New-Object System.Windows.Forms.Form >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Text = "NSOVVG [$copyright - $game]" >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Size = New-Object System.Drawing.Size^(800, 500^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.StartPosition = "CenterScreen" >> "!multidumperfullsoundtrackpath!.ps1"


echo $labelText = New-Object System.Windows.Forms.Label >> "!multidumperfullsoundtrackpath!.ps1"
echo $labelText.Text = "The shown window provides assistance with rendering the entire song of a game into a single video, known as a ""Full Soundtrack Oscilloscope View"".`nCheck or uncheck the checkboxes in the window, on the left of ""Track No. _"" to remove sound effects or songs that are basically useless when rendering, and set the length of each song if you need to." >> "!multidumperfullsoundtrackpath!.ps1"
echo $labelText.Location = New-Object System.Drawing.Point^(10, 10^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $labelText.Size = New-Object System.Drawing.Size^(780, 60^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($labelText^) >> "!multidumperfullsoundtrackpath!.ps1"


echo $listView = New-Object System.Windows.Forms.ListView >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.View = [System.Windows.Forms.View]::Details >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.Location = New-Object System.Drawing.Point^(10, 80^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.Size = New-Object System.Drawing.Size^(760, 200^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.FullRowSelect = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.GridLines = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.CheckBoxes = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo $listView.Scrollable = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo [void]$listView.Columns.Add^("Select", 50^)        >> "!multidumperfullsoundtrackpath!.ps1"
echo [void]$listView.Columns.Add^("Track No.", 600^)   >> "!multidumperfullsoundtrackpath!.ps1"
echo [void]$listView.Columns.Add^("Length", 50^)      >> "!multidumperfullsoundtrackpath!.ps1"


echo for ^($i = 1; $i -le $subsongCount; $i++^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo     $item = New-Object System.Windows.Forms.ListViewItem >> "!multidumperfullsoundtrackpath!.ps1"
echo     $item.Checked = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo     [void]$item.SubItems.Add^("Track No. $i"^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     [void]$item.SubItems.Add^("120"^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     [void]$listView.Items.Add^($item^) >> "!multidumperfullsoundtrackpath!.ps1"
echo } >> "!multidumperfullsoundtrackpath!.ps1"



echo function ShowEditForm { >> "!multidumperfullsoundtrackpath!.ps1"
echo     param ^( >> "!multidumperfullsoundtrackpath!.ps1"
echo         [string]$currentValue >> "!multidumperfullsoundtrackpath!.ps1"
echo     ^) >> "!multidumperfullsoundtrackpath!.ps1"


echo     $editForm = New-Object System.Windows.Forms.Form >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.Text = "Edit Length" >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.Size = New-Object System.Drawing.Size^(300, 150^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.StartPosition = "CenterParent" >> "!multidumperfullsoundtrackpath!.ps1"


echo     $textBox = New-Object System.Windows.Forms.TextBox >> "!multidumperfullsoundtrackpath!.ps1"
echo     $textBox.Location = New-Object System.Drawing.Point^(50, 20^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $textBox.Size = New-Object System.Drawing.Size^(200, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $textBox.Text = $currentValue >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.Controls.Add^($textBox^) >> "!multidumperfullsoundtrackpath!.ps1"


echo     $okButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo     $okButton.Text = "OK" >> "!multidumperfullsoundtrackpath!.ps1"
echo     $okButton.Location = New-Object System.Drawing.Point^(50, 60^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $okButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo         $editForm.Tag = $textBox.Text   >> "!multidumperfullsoundtrackpath!.ps1"
echo         $editForm.Close^(^)              >> "!multidumperfullsoundtrackpath!.ps1"
echo     }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.Controls.Add^($okButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo     $cancelButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo     $cancelButton.Text = "Cancel" >> "!multidumperfullsoundtrackpath!.ps1"
echo     $cancelButton.Location = New-Object System.Drawing.Point^(150, 60^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $cancelButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo         $editForm.Tag = $null          >> "!multidumperfullsoundtrackpath!.ps1"
echo         $editForm.Close^(^)              >> "!multidumperfullsoundtrackpath!.ps1"
echo     }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $editForm.Controls.Add^($cancelButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo     $editForm.ShowDialog^(^) ^| Out-Null >> "!multidumperfullsoundtrackpath!.ps1"

echo     return $editForm.Tag   >> "!multidumperfullsoundtrackpath!.ps1"
echo } >> "!multidumperfullsoundtrackpath!.ps1"



echo $listView.Add_MouseDoubleClick^({ >> "!multidumperfullsoundtrackpath!.ps1"

echo     $mousePosition = $listView.PointToClient^([System.Windows.Forms.Cursor]::Position^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $hitTest = $listView.HitTest^($mousePosition^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     $item = $hitTest.Item >> "!multidumperfullsoundtrackpath!.ps1"
REM echo     if ($item.Checked -eq $true) { $item.Checked = $false } else { $item.Checked = $true } >> "!multidumperfullsoundtrackpath!.ps1"

echo     if ^($item -ne $null -and $hitTest.SubItem -ne $null^) { >> "!multidumperfullsoundtrackpath!.ps1"

echo         $clickedColumnIndex = 0 >> "!multidumperfullsoundtrackpath!.ps1"
echo         foreach ^($subItem in $item.SubItems^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo             if ^($subItem -eq $hitTest.SubItem^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo                 break >> "!multidumperfullsoundtrackpath!.ps1"
echo             } >> "!multidumperfullsoundtrackpath!.ps1"
echo             $clickedColumnIndex++ >> "!multidumperfullsoundtrackpath!.ps1"
echo         } >> "!multidumperfullsoundtrackpath!.ps1"
echo     if ($item.Checked -eq $true) { $item.Checked = $false } else { $item.Checked = $true } >> "!multidumperfullsoundtrackpath!.ps1"

echo         if ^($clickedColumnIndex -eq 2^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo             $currentLength = $item.SubItems[$clickedColumnIndex].Text >> "!multidumperfullsoundtrackpath!.ps1"
echo             $newLength = ShowEditForm -currentValue $currentLength >> "!multidumperfullsoundtrackpath!.ps1"

echo             if ^($newLength -ne $null^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo                 $item.SubItems[$clickedColumnIndex].Text = $newLength >> "!multidumperfullsoundtrackpath!.ps1"
echo             } >> "!multidumperfullsoundtrackpath!.ps1"
echo         } >> "!multidumperfullsoundtrackpath!.ps1"
echo     } >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"



echo $form.Controls.Add^($listView^) >> "!multidumperfullsoundtrackpath!.ps1"



echo $toggleButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo $toggleButton.Text = "Uncheck All" >> "!multidumperfullsoundtrackpath!.ps1"
echo $toggleButton.Location = New-Object System.Drawing.Point^(10, 290^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $toggleButton.Size = New-Object System.Drawing.Size^(100, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $toggleButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo     if ^($toggleButton.Text -eq "Check All"^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo         $listView.Items ^| ForEach-Object { $_.Checked = $true } >> "!multidumperfullsoundtrackpath!.ps1"
echo         $toggleButton.Text = "Uncheck All" >> "!multidumperfullsoundtrackpath!.ps1"
echo     } else { >> "!multidumperfullsoundtrackpath!.ps1"
echo         $listView.Items ^| ForEach-Object { $_.Checked = $false } >> "!multidumperfullsoundtrackpath!.ps1"
echo         $toggleButton.Text = "Check All" >> "!multidumperfullsoundtrackpath!.ps1"
echo     } >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($toggleButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo $rangeStartBox = New-Object System.Windows.Forms.NumericUpDown >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeStartBox.Location = New-Object System.Drawing.Point^(10, 330^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeStartBox.Size = New-Object System.Drawing.Size^(60, 20^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeStartBox.Minimum = 1 >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeStartBox.Maximum = $subsongCount >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeStartBox.Value = 1 >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($rangeStartBox^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $rangeEndBox = New-Object System.Windows.Forms.NumericUpDown >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeEndBox.Location = New-Object System.Drawing.Point^(80, 330^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeEndBox.Size = New-Object System.Drawing.Size^(60, 20^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeEndBox.Minimum = 1 >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeEndBox.Maximum = $subsongCount >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeEndBox.Value = $subsongCount >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($rangeEndBox^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $rangeButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeButton.Text = "Select Range" >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeButton.Location = New-Object System.Drawing.Point^(150, 330^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeButton.Size = New-Object System.Drawing.Size^(100, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $rangeButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo     $start = $rangeStartBox.Value >> "!multidumperfullsoundtrackpath!.ps1"
echo     $end = $rangeEndBox.Value >> "!multidumperfullsoundtrackpath!.ps1"
echo     if ^($start -lt $end^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo         $listView.Items ^| ForEach-Object { >> "!multidumperfullsoundtrackpath!.ps1"
echo             $trackNo = $_.SubItems[1].Text -replace 'Track No. ', '' >> "!multidumperfullsoundtrackpath!.ps1"
echo             if ^([int]::TryParse^($trackNo, [ref]$null^)^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo                 $_.Checked = ^([int]$trackNo -ge $start -and [int]$trackNo -le $end^) >> "!multidumperfullsoundtrackpath!.ps1"
echo             } >> "!multidumperfullsoundtrackpath!.ps1"
echo         } >> "!multidumperfullsoundtrackpath!.ps1"
echo     } >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $form.Controls.Add^($rangeButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo $lengthBox = New-Object System.Windows.Forms.NumericUpDown >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthBox.Location = New-Object System.Drawing.Point^(10, 370^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthBox.Size = New-Object System.Drawing.Size^(60, 20^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthBox.Minimum = 1 >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthBox.Maximum = 600 >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthBox.Value = 120 >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($lengthBox^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $lengthButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthButton.Text = "Set All Lengths" >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthButton.Location = New-Object System.Drawing.Point^(80, 370^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthButton.Size = New-Object System.Drawing.Size^(150, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $lengthButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo     $newLength = $lengthBox.Value >> "!multidumperfullsoundtrackpath!.ps1"
echo     $listView.Items ^| ForEach-Object { >> "!multidumperfullsoundtrackpath!.ps1"
echo         $_.SubItems[2].Text = $newLength.ToString^(^) >> "!multidumperfullsoundtrackpath!.ps1"
echo     } >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($lengthButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo $confirmButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo $confirmButton.Text = "Confirm" >> "!multidumperfullsoundtrackpath!.ps1"
echo $confirmButton.Location = New-Object System.Drawing.Point^(550, 420^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $confirmButton.Size = New-Object System.Drawing.Size^(100, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $confirmButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
ECHO	 $listView.Items ^| Where-Object { $_.Checked } ^| ForEach-Object { $totalLength += [int]$_.SubItems[2].Text } >> "!multidumperfullsoundtrackpath!.ps1"
ECHO	 Write-Host "Header=$($jsonData.channels.Count)=$($totalLength)" >> "!multidumperfullsoundtrackpath!.ps1"
echo     $listView.Items ^| Where-Object { $_.Checked } ^| ForEach-Object { >> "!multidumperfullsoundtrackpath!.ps1"
echo         $trackNo = $_.SubItems[1].Text -replace 'Track No. ', '' >> "!multidumperfullsoundtrackpath!.ps1"
echo         $length = $_.SubItems[2].Text >> "!multidumperfullsoundtrackpath!.ps1"
echo         Write-Host "$($trackNo - 1)=$length" >> "!multidumperfullsoundtrackpath!.ps1"
echo     } >> "!multidumperfullsoundtrackpath!.ps1"
echo 	 $buttonClicked = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo     $form.Close^(^) >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($confirmButton^) >> "!multidumperfullsoundtrackpath!.ps1"


echo $cancelButton = New-Object System.Windows.Forms.Button >> "!multidumperfullsoundtrackpath!.ps1"
echo $cancelButton.Text = "Cancel" >> "!multidumperfullsoundtrackpath!.ps1"
echo $cancelButton.Location = New-Object System.Drawing.Point^(660, 420^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $cancelButton.Size = New-Object System.Drawing.Size^(100, 30^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $cancelButton.Add_Click^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo     Write-Host "None" >> "!multidumperfullsoundtrackpath!.ps1"
echo 	 $buttonClicked = $true >> "!multidumperfullsoundtrackpath!.ps1"
echo     $form.Close^(^) >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo $form.Controls.Add^($cancelButton^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $form.Add_FormClosing^({ >> "!multidumperfullsoundtrackpath!.ps1"
echo 	if ^(-not $buttonClicked^) { >> "!multidumperfullsoundtrackpath!.ps1"
echo 		Write-Host "None" >> "!multidumperfullsoundtrackpath!.ps1"
echo 	} >> "!multidumperfullsoundtrackpath!.ps1"
echo }^) >> "!multidumperfullsoundtrackpath!.ps1"

echo $form.Add_Shown^({ $form.Activate() }^) >> "!multidumperfullsoundtrackpath!.ps1"
echo [void]$form.ShowDialog^(^) >> "!multidumperfullsoundtrackpath!.ps1"


goto :EOF

:SCRIPTGEN_VIDEOCONFIG
	echo Add-Type -AssemblyName System.Windows.Forms > !numberboxpath!
	echo Add-Type -AssemblyName System.Drawing >> !numberboxpath!

	echo $buttonClicked = $false >> !numberboxpath!

	echo $form = New-Object System.Windows.Forms.Form >> !numberboxpath!
	echo $form.Text = "NSOVVG" >> !numberboxpath!
	echo $form.Size = New-Object System.Drawing.Size^(435, 200^) >> !numberboxpath!


	echo $xLabel = New-Object System.Windows.Forms.Label >> !numberboxpath!
	echo $xLabel.Text = "Width (X):" >> !numberboxpath!
	echo $xLabel.Location = New-Object System.Drawing.Point^(20, 20^) >> !numberboxpath!
	echo $form.Controls.Add^($xLabel^) >> !numberboxpath!

	echo $yLabel = New-Object System.Windows.Forms.Label >> !numberboxpath!
	echo $yLabel.Text = "Height (Y):" >> !numberboxpath!
	echo $yLabel.Location = New-Object System.Drawing.Point^(160, 20^) >> !numberboxpath!
	echo $form.Controls.Add^($yLabel^) >> !numberboxpath!

	echo $fpsLabel = New-Object System.Windows.Forms.Label >> !numberboxpath!
	echo $fpsLabel.Text = "FPS:" >> !numberboxpath!
	echo $fpsLabel.Location = New-Object System.Drawing.Point^(300, 20^) >> !numberboxpath!
	echo $form.Controls.Add^($fpsLabel^) >> !numberboxpath!


	echo $xBox = New-Object System.Windows.Forms.NumericUpDown >> !numberboxpath!
	echo $xBox.Location = New-Object System.Drawing.Point^(20, 50^) >> !numberboxpath!
	echo $xBox.Size = New-Object System.Drawing.Size^(100, 20^) >> !numberboxpath!
	echo $xBox.Minimum = 160 >> !numberboxpath!
	echo $xBox.Maximum = 1366 >> !numberboxpath!
	echo $xBox.Value = !x_res! >> !numberboxpath!
	echo $form.Controls.Add^($xBox^) >> !numberboxpath!

	echo $yBox = New-Object System.Windows.Forms.NumericUpDown >> !numberboxpath!
	echo $yBox.Location = New-Object System.Drawing.Point^(160, 50^) >> !numberboxpath!
	echo $yBox.Size = New-Object System.Drawing.Size^(100, 20^) >> !numberboxpath!
	echo $yBox.Minimum = 90 >> !numberboxpath!
	echo $yBox.Maximum = 768 >> !numberboxpath!
	echo $yBox.Value = !y_res! >> !numberboxpath!
	echo $form.Controls.Add^($yBox^) >> !numberboxpath!

	echo $fpsBox = New-Object System.Windows.Forms.NumericUpDown >> !numberboxpath!
	echo $fpsBox.Location = New-Object System.Drawing.Point^(300, 50^) >> !numberboxpath!
	echo $fpsBox.Size = New-Object System.Drawing.Size^(100, 20^) >> !numberboxpath!
	echo $fpsBox.Minimum = 24 >> !numberboxpath!
	echo $fpsBox.Maximum = 240 >> !numberboxpath!
	echo $fpsBox.Value = !fps! >> !numberboxpath!
	echo $form.Controls.Add^($fpsBox^) >> !numberboxpath!


	echo $okButton = New-Object System.Windows.Forms.Button >> !numberboxpath!
	echo $okButton.Text = "OK" >> !numberboxpath!
	echo $okButton.Location = New-Object System.Drawing.Point^(300, 100^) >> !numberboxpath!
	echo $okButton.Size = New-Object System.Drawing.Size^(80, 30^) >> !numberboxpath!
	echo $okButton.Add_Click^({ >> !numberboxpath!
	echo     Write-Host "$($xBox.Value)=$($yBox.Value)=$($fpsBox.Value)" >> !numberboxpath!
	echo 	 $buttonClicked = $true >> !numberboxpath!
	echo     $form.Close^(^) >> !numberboxpath!
	echo }^) >> !numberboxpath!
	echo $form.Controls.Add^($okButton^) >> !numberboxpath!

	echo $cancelButton = New-Object System.Windows.Forms.Button >> !numberboxpath!
	echo $cancelButton.Text = "Cancel" >> !numberboxpath!
	echo $cancelButton.Location = New-Object System.Drawing.Point^(200, 100^) >> !numberboxpath!
	echo $cancelButton.Size = New-Object System.Drawing.Size^(80, 30^) >> !numberboxpath!
	echo $cancelButton.Add_Click^({ >> !numberboxpath!
	echo     $form.Close^(^) >> !numberboxpath!
	echo }^) >> !numberboxpath!
	echo $form.Controls.Add^($cancelButton^) >> !numberboxpath!

	echo $form.Add_FormClosing^({ >> !numberboxpath!
	echo 	if ^(-not $buttonClicked^) { >> !numberboxpath!
	echo 		Write-Host "None" >> !numberboxpath!
	echo 	} >> !numberboxpath!
	echo }^) >> !numberboxpath!

	echo [void]$form.ShowDialog^(^) >> !numberboxpath!
	
:SCRIPTGEN_HELPCHM
Goto :EOF

:SCRIPTGEN_MULTIDUMPERSETTINGS
echo $jsonFilePath = $args[0]   > "!multidumpersettingsboxpath!"
echo $jsonData = Get-Content -Raw -Path $jsonFilePath ^| ConvertFrom-Json >> "!multidumpersettingsboxpath!"


echo $subsongCount = $jsonData.subsongCount >> "!multidumpersettingsboxpath!"

echo $copyright = $jsonData.containerinfo.copyright >> "!multidumpersettingsboxpath!"
echo if ^(-not $copyright^) { $copyright = $jsonData.containerinfo.system } >> "!multidumpersettingsboxpath!"
echo $game = $jsonData.containerinfo.game >> "!multidumpersettingsboxpath!"
echo if ^(-not $game^) { $game = $jsonData.containerinfo.dumper } >> "!multidumpersettingsboxpath!"
echo if ^(-not $copyright^) { $copyright = "Unknown Artist" } >> "!multidumpersettingsboxpath!"
echo if ^(-not $game^) { $game = "Unknown Game" } >> "!multidumpersettingsboxpath!"


echo Add-Type -AssemblyName System.Windows.Forms >> "!multidumpersettingsboxpath!"
echo Add-Type -AssemblyName System.Drawing >> "!multidumpersettingsboxpath!"

echo $form = New-Object System.Windows.Forms.Form >> "!multidumpersettingsboxpath!"
echo $form.Text = "NSOVVG [$copyright - $game]" >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $form.Size = New-Object System.Drawing.Size^(300, 220^) } else { $form.Size = New-Object System.Drawing.Size^(300, 180^) } >> "!multidumpersettingsboxpath!"
echo $form.StartPosition = 'CenterScreen' >> "!multidumpersettingsboxpath!"


echo $labelSubsong = New-Object System.Windows.Forms.Label >> "!multidumpersettingsboxpath!"
echo $labelSubsong.Text = "Subsong No." >> "!multidumpersettingsboxpath!"
echo $labelSubsong.Location = New-Object System.Drawing.Point^(10, 20^) >> "!multidumpersettingsboxpath!"
echo $labelSubsong.Size = New-Object System.Drawing.Size^(100, 20^) >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $form.Controls.Add^($labelSubsong^) } >> "!multidumpersettingsboxpath!"


echo $numSubsong = New-Object System.Windows.Forms.NumericUpDown >> "!multidumpersettingsboxpath!"
echo $numSubsong.Minimum = 1 >> "!multidumpersettingsboxpath!"
echo $numSubsong.Maximum = $subsongCount >> "!multidumpersettingsboxpath!"
echo $numSubsong.Value = 1 >> "!multidumpersettingsboxpath!"
echo $numSubsong.Location = New-Object System.Drawing.Point^(120, 20^) >> "!multidumpersettingsboxpath!"
echo $numSubsong.Size = New-Object System.Drawing.Size^(150, 20^) >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $form.Controls.Add^($numSubsong^) } >> "!multidumpersettingsboxpath!"


echo $labelLength = New-Object System.Windows.Forms.Label >> "!multidumpersettingsboxpath!"
echo $labelLength.Text = "Length" >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $labelLength.Location = New-Object System.Drawing.Point^(10, 60^) } else { $labelLength.Location = New-Object System.Drawing.Point^(10, 40^) } >> "!multidumpersettingsboxpath!"
echo $labelLength.Size = New-Object System.Drawing.Size^(100, 20^) >> "!multidumpersettingsboxpath!"
echo $form.Controls.Add^($labelLength^) >> "!multidumpersettingsboxpath!"


echo $numLength = New-Object System.Windows.Forms.NumericUpDown >> "!multidumpersettingsboxpath!"
echo $numLength.Minimum = 1 >> "!multidumpersettingsboxpath!"
echo $numLength.Maximum = [decimal]::MaxValue >> "!multidumpersettingsboxpath!"
echo $numLength.Value = 180 >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $numLength.Location = New-Object System.Drawing.Point^(120, 60^) } else { $numLength.Location = New-Object System.Drawing.Point^(120, 40^) } >> "!multidumpersettingsboxpath!"
echo $numLength.Size = New-Object System.Drawing.Size^(150, 20^) >> "!multidumpersettingsboxpath!"
echo $form.Controls.Add^($numLength^) >> "!multidumpersettingsboxpath!"


echo $btnConfirm = New-Object System.Windows.Forms.Button >> "!multidumpersettingsboxpath!"
echo $btnConfirm.Text = "Confirm" >> "!multidumpersettingsboxpath!"
echo $btnConfirm.Location = New-Object System.Drawing.Point^(50, 100^) >> "!multidumpersettingsboxpath!"
echo $btnConfirm.Size = New-Object System.Drawing.Size^(80, 30^) >> "!multidumpersettingsboxpath!"
echo $btnConfirm.Add_Click^({ >> "!multidumpersettingsboxpath!"
echo     Write-Host "$($numSubsong.Value - 1)=$($numLength.Value - 1)" >> "!multidumpersettingsboxpath!"
echo 	 $buttonClicked = $true >> "!multidumpersettingsboxpath!"
echo     $form.Close^(^) >> "!multidumpersettingsboxpath!"
echo }^) >> "!multidumpersettingsboxpath!"
echo $form.Controls.Add^($btnConfirm^) >> "!multidumpersettingsboxpath!"


echo $btnCancel = New-Object System.Windows.Forms.Button >> "!multidumpersettingsboxpath!"
echo $btnCancel.Text = "Cancel" >> "!multidumpersettingsboxpath!"
echo $btnCancel.Location = New-Object System.Drawing.Point^(150, 100^) >> "!multidumpersettingsboxpath!"
echo $btnCancel.Size = New-Object System.Drawing.Size^(80, 30^) >> "!multidumpersettingsboxpath!"
echo $btnCancel.Add_Click^({ >> "!multidumpersettingsboxpath!"
echo 	 $buttonClicked = $true >> "!multidumpersettingsboxpath!"
echo     Write-Host "None" >> "!multidumpersettingsboxpath!"
echo     $form.Close^(^) >> "!multidumpersettingsboxpath!"
echo }^) >> "!multidumpersettingsboxpath!"
echo $form.Controls.Add^($btnCancel^) >> "!multidumpersettingsboxpath!"

echo $btnFullSoundtrack = New-Object System.Windows.Forms.Button >> "!multidumpersettingsboxpath!"
echo $btnFullSoundtrack.Text = "Make ""Full Soundtrack"" Video" >> "!multidumpersettingsboxpath!"
echo $btnFullSoundtrack.Location = New-Object System.Drawing.Point^(50, 140^) >> "!multidumpersettingsboxpath!"
echo $btnFullSoundtrack.Size = New-Object System.Drawing.Size^(180, 30^) >> "!multidumpersettingsboxpath!"
echo $btnFullSoundtrack.Add_Click^({ >> "!multidumpersettingsboxpath!"
echo 	 $buttonClicked = $true >> "!multidumpersettingsboxpath!"
echo     Write-Host "FullSoundtrack" >> "!multidumpersettingsboxpath!"
echo     $form.Close^(^) >> "!multidumpersettingsboxpath!"
echo }^) >> "!multidumpersettingsboxpath!"
echo if ^($subsongCount -ne 1 ^) { $form.Controls.Add^($btnFullSoundtrack^) } >> "!multidumpersettingsboxpath!"


echo $form.Add_FormClosing^({ >> "!multidumpersettingsboxpath!"
echo     if ^(-not $buttonClicked^) { >> "!multidumpersettingsboxpath!"
echo         Write-Host "None" >> "!multidumpersettingsboxpath!"
echo     } >> "!multidumpersettingsboxpath!"
echo }^) >> "!multidumpersettingsboxpath!"



echo [void]$form.ShowDialog^(^) >> "!multidumpersettingsboxpath!"
GOTO :EOF

:SCRIPTGEN_CHSORT

echo Add-Type -AssemblyName System.Windows.Forms > !chsortboxpath!
echo Add-Type -AssemblyName System.Drawing >> !chsortboxpath!

echo $L = $args[0] >> !chsortboxpath!
echo $R = $args[1] >> !chsortboxpath!
echo $total = $L + $R >> !chsortboxpath!


echo $form = New-Object System.Windows.Forms.Form >> !chsortboxpath!

echo $form.Text = "NSOVVG" >> !chsortboxpath!
echo $form.Size = New-Object System.Drawing.Size^(300, 230^) >> !chsortboxpath!
echo $form.StartPosition = "CenterScreen" >> !chsortboxpath!


echo $labelL = New-Object System.Windows.Forms.Label >> !chsortboxpath!
echo $labelL.Text = "Left Channels:" >> !chsortboxpath!
echo $labelL.Location = New-Object System.Drawing.Point^(10, 20^) >> !chsortboxpath!
echo $labelL.Size = New-Object System.Drawing.Size^(100, 20^) >> !chsortboxpath!
echo $form.Controls.Add^($labelL^) >> !chsortboxpath!

echo $numericL = New-Object System.Windows.Forms.NumericUpDown >> !chsortboxpath!
echo $numericL.Location = New-Object System.Drawing.Point^(120, 20^) >> !chsortboxpath!
echo $numericL.Size = New-Object System.Drawing.Size^(100, 20^) >> !chsortboxpath!
echo $numericL.Minimum = 1 >> !chsortboxpath!
echo $numericL.Maximum = $total - 1 >> !chsortboxpath!
echo $numericL.Value = $L >> !chsortboxpath!
echo $form.Controls.Add^($numericL^) >> !chsortboxpath!


echo $labelR = New-Object System.Windows.Forms.Label >> !chsortboxpath!
echo $labelR.Text = "Right Channels:" >> !chsortboxpath!
echo $labelR.Location = New-Object System.Drawing.Point^(10, 60^) >> !chsortboxpath!
echo $labelR.Size = New-Object System.Drawing.Size^(100, 20^) >> !chsortboxpath!
echo $form.Controls.Add^($labelR^) >> !chsortboxpath!

echo $numericR = New-Object System.Windows.Forms.NumericUpDown >> !chsortboxpath!
echo $numericR.Location = New-Object System.Drawing.Point^(120, 60^) >> !chsortboxpath!
echo $numericR.Size = New-Object System.Drawing.Size^(100, 20^) >> !chsortboxpath!
echo $numericR.Minimum = 1 >> !chsortboxpath!
echo $numericR.Maximum = $total - 1 >> !chsortboxpath!
echo $numericR.Value = $R >> !chsortboxpath!
echo $form.Controls.Add^($numericR^) >> !chsortboxpath!


echo $numericL.add_ValueChanged^({ >> !chsortboxpath!
echo     $numericR.Value = $total - $numericL.Value >> !chsortboxpath!
echo }^) >> !chsortboxpath!


echo $numericR.add_ValueChanged^({ >> !chsortboxpath!
echo     $numericL.Value = $total - $numericR.Value >> !chsortboxpath!
echo }^) >> !chsortboxpath!


echo $btnOK = New-Object System.Windows.Forms.Button >> !chsortboxpath!
echo $btnOK.Text = "OK" >> !chsortboxpath!
echo $btnOK.Location = New-Object System.Drawing.Point^(50, 120^) >> !chsortboxpath!
echo $btnOK.Size = New-Object System.Drawing.Size^(75, 30^) >> !chsortboxpath!
echo $btnOK.Add_Click^({ >> !chsortboxpath!
echo 	$buttonClicked = $true >> !chsortboxpath!
echo     Write-Host "$($numericL.Value)=$($numericR.Value)" >> !chsortboxpath!
echo     $form.Close^(^) >> !chsortboxpath!
echo }^) >> !chsortboxpath!
echo $form.Controls.Add^($btnOK^) >> !chsortboxpath!


echo $btnCancel = New-Object System.Windows.Forms.Button >> !chsortboxpath!
echo $btnCancel.Text = "Cancel" >> !chsortboxpath!
echo $btnCancel.Location = New-Object System.Drawing.Point^(150, 120^) >> !chsortboxpath!
echo $btnCancel.Size = New-Object System.Drawing.Size^(75, 30^) >> !chsortboxpath!
echo $btnCancel.Add_Click^({ >> !chsortboxpath!
echo 	$buttonClicked = $true >> !chsortboxpath!
echo     Write-Host "None" >> !chsortboxpath!
echo     $form.Close^(^) >> !chsortboxpath!
echo }^) >> !chsortboxpath!
echo $form.Controls.Add^($btnCancel^) >> !chsortboxpath!


echo $btnAuto = New-Object System.Windows.Forms.Button >> !chsortboxpath!
echo $btnAuto.Text = "Auto" >> !chsortboxpath!
echo $btnAuto.Location = New-Object System.Drawing.Point^(50, 160^) >> !chsortboxpath!
echo $btnAuto.Size = New-Object System.Drawing.Size^(75, 30^) >> !chsortboxpath!
echo $btnAuto.Add_Click^({ >> !chsortboxpath!     
echo     if ^($total %% 2 -eq 0^) { >> !chsortboxpath!
echo         $numericL.Value = $total / 2 >> !chsortboxpath!
echo         $numericR.Value = $total / 2 >> !chsortboxpath!
echo     } else { >> !chsortboxpath!
echo         $numericL.Value = [math]::Ceiling^($total / 2.0^) >> !chsortboxpath!
echo         $numericR.Value = [math]::Floor^($total / 2.0^) >> !chsortboxpath!
echo     } >> !chsortboxpath!
echo }^) >> !chsortboxpath!
echo $form.Controls.Add^($btnAuto^) >> !chsortboxpath!

echo $btnAllVertical = New-Object System.Windows.Forms.Button >> !chsortboxpath!
echo $btnAllVertical.Text = "Vertical" >> !chsortboxpath!
echo $btnAllVertical.Location = New-Object System.Drawing.Point^(150, 160^) >> !chsortboxpath!
echo $btnAllVertical.Size = New-Object System.Drawing.Size^(75, 30^) >> !chsortboxpath!
echo $btnAllVertical.Add_Click^({ >> !chsortboxpath!
echo 	$buttonClicked = $true >> !chsortboxpath!
echo     Write-Host "AllVertical" >> !chsortboxpath!
echo     $form.Close^(^) >> !chsortboxpath!
echo }^) >> !chsortboxpath!
echo $form.Controls.Add^($btnAllVertical^) >> !chsortboxpath!



echo $buttonClicked = $false >> !chsortboxpath!
echo $form.Add_Shown^({ $form.Activate^(^) }^) >> !chsortboxpath!
echo [void]$form.ShowDialog^(^) >> !chsortboxpath!

echo $form.Add_FormClosing^({ >> !chsortboxpath!
echo     if ^(-not $buttonClicked^) { >> !chsortboxpath!
echo         Write-Host "None" >> !chsortboxpath!
echo     } >> !chsortboxpath!
echo }^) >> !chsortboxpath!

GOTO :EOF

:REMOVE_CHANNEL CHNUM
if defined channel!i! (
	set "buffer_channel!i!=!channel%dummyvariable1%!"
	set "buffer_label!i!=!label%dummyvariable1%!"
	set "buffer_amp!i!=!amp%dummyvariable1%!"
	set "buffer_color!i!=!color%dummyvariable1%!"
	set /a i+=1
	IF "!i!"=="%~1" ( set /a dummyvariable1+=2 ) else set /a dummyvariable1+=1
	goto REMOVE_CHANNEL
)
set /a i-=2
for /L %%i in (1,1,!i!) do (
	set "channel%%i=!buffer_channel%%i!"
	set "label%%i=!buffer_label%%i!"
	set "amp%%i=!buffer_amp%%i!"
	set "color%%i=!buffer_color%%i!"
	set "buffer_channel%%i="
	set "buffer_label%%i="
	set "buffer_amp%%i="
	set "buffer_color%%i="
)
set /a i+=1
set "channel!i!="
set "label!i!="
set "amp!i!="
set "color!i!="
set "dummyvariable1="
GOTO :EOF

:FFMPEG_CHECK
echo Checking for the existence of the ffmpeg set... Please wait^!
set fmpeg=0
set fplay=0
set fprobe=0

IF EXIST "ffmpeg.exe" ( set "fmpeg=1" ) else for %%P in (!PATH!) do IF EXIST "%%~P\ffmpeg.exe" set "fmpeg=1"
IF EXIST "ffplay.exe" ( set "fplay=1" ) else for %%P in (!PATH!) do IF EXIST "%%~P\ffplay.exe" set "fplay=1"
IF EXIST "ffprobe.exe" ( set "fprobe=1" ) else for %%P in (!PATH!) do IF EXIST "%%~P\ffprobe.exe" set "fprobe=1"

if "!fmpeg!!fplay!!fprobe!" NEQ "111" call :errmsg "Some or all of the ffmpeg set is missing. Please put the set in the same directory as this script or system path"
REM YES I WANT SOME NEWFACE
REM EEEEEEEEY WE WANT SOME NEW FACE

set fmpeg=0
set fplay=0
set fprobe=0

GOTO :EOF

:CHLOOP_ADDCHFROMDRAGNDROP
if NOT "%~1"=="" IF EXIST "%~1" (
	REM echo !i!
	IF /i "%~x1" NEQ ".wav" IF /i "%~x1" NEQ ".mp3" (
		IF /i "%~x1" EQU ".ini" (
			CALL :LOADINICONFIGFILE "%~1"
			GOTO DRAWLOGO
		) else (
			call :errmsg "%~x1 is not a supported file format"
			shift
			GOTO CHLOOP_ADDCHFROMDRAGNDROP
		)
	)
	set /a dummyvariable2+=1
	set "channel!i!=%~1"
	set "label!i!=Channel !i!"
	set "amp!i!=2"
	set "color!i!=#FFFFFF"		
	shift
	SET /a i+=1
	GOTO CHLOOP_ADDCHFROMDRAGNDROP
) 
if not "!dummyvariable2!"=="0" (
	set "channel!i!="
	set "label!i!="
	set "amp!i!="
	set "color!i!="
)
GOTO :EOF

:LOADINICONFIGFILE FILE
set i=0
CALL :CHLOOP_CLEAR
if not "%~1"=="" if exist "%~1" if /i "%~x1"==".ini" for /f "tokens=1,* delims==" %%a in ('type "%~1"') do (
	set dummyvariable1=%%a
	IF NOT "!dummyvariable1:~0,1!"=="[" set "%%a=%%b"
)
GOTO :EOF

:CREATE_COLORPICKER DF_COLOR VARINAME
set "hexColor=%~1"
set "hexColor=!hexColor:~1!"
set /a r=0x!hexColor:~0,2!
set /a g=0x!hexColor:~2,2!
set /a b=0x!hexColor:~4,2!
powershell -command "Add-Type -AssemblyName System.Windows.Forms ;$colorDialog = New-Object System.Windows.Forms.ColorDialog ;$colorDialog.FullOpen = $true ;$colorDialog.Color = [System.Drawing.Color]::FromArgb(!r!, !g!, !b!) ;if ($colorDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Write-Host \"$($colorDialog.Color.R)=$($colorDialog.Color.G)=$($colorDialog.Color.B)\" } else { Write-Host \"!r!=!g!=!b!\" }" >"!TEMP!\.tmp"
SET /P dummyvariable1=<"!TEMP!\.tmp"
DEL /Q "!TEMP!\.tmp"
REM echo !dummyvariable1!
for /f "tokens=*" %%a in ('powershell -command "$rgbString = \"%dummyvariable1%\";$rgbValues = $rgbString -split \"=\" | ForEach-Object { [convert]::ToString($_, 16).PadLeft(2, \"0\") };$hexColor = \"#\" + ($rgbValues -join \"\");Write-Host $hexColor"') do set "%~2=%%a"

goto :eof




