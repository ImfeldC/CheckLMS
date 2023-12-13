@Echo Off
rem
rem Check current LMS installation
rem 
rem ---------------------------------------------------------------------------------------
rem © Siemens 2018 - 2023
rem
rem Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
rem Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
rem ---------------------------------------------------------------------------------------
rem 
rem ===    THIS REPO HAS BEEN MOVED    ===
rem === THE CONTENT HERE IS DEPRECATED ===
rem
rem The new location is: https://code.siemens.com/licensemanagementsystem/checklms/-/raw/master/CheckLMS.bat (Siemens internal only!)
rem 
set LMS_SCRIPT_VERSION="CheckLMS Script 01-Dec-2023"
set LMS_SCRIPT_BUILD=20231201
set LMS_SCRIPT_PRODUCTID=6cf968fa-ffad-4593-9ecb-7a6f3ea07501

rem https://stackoverflow.com/questions/15815719/how-do-i-get-the-drive-letter-a-batch-script-is-running-from
set CHECKLMS_SCRIPT_DRIVE=%~d0
set CHECKLMS_SCRIPT_PATH=%~p0

rem most recent lms build: 2.7.872 (per 23-Jan-2023)
set MOST_RECENT_LMS_VERSION=2.7.872
set MOST_RECENT_LMS_BUILD=872
rem most recent lms field test version: n/a
rem - if not set - it is not downloaded.
rem set MOST_RECENT_FT_LMS_VERSION=2.6.869
rem set MOST_RECENT_FT_LMS_BUILD=869
rem most recent dongle driver version (per 19-sep-2023, LMS 2.8)
set MOST_RECENT_DONGLE_DRIVER_VERSION=9.14
set MOST_RECENT_DONGLE_DRIVER_MAJ_VERSION=9
set MOST_RECENT_DONGLE_DRIVER_MIN_VERSION=14
rem most recent BT ALM plugin (per 15-Nov-2021, LMS 2.6)
set MOST_RECENT_BT_ALM_PLUGIN=1.1.43.0

rem Internal Settings
set LOG_FILE_SNIPPET=20
set LOG_FILE_LINES=200
set LOG_EVENTLOG_EVENTS=5000
set LOG_EVENTLOG_FULL_EVENTS=20000
set LOG_FILESIZE_LIMIT=30000000

rem Check this issue: https://stackoverflow.com/questions/9797271/strange-character-in-textoutput-when-piping-from-tasklist-command-win7
chcp 1252
rem Check this: https://ss64.com/nt/delayedexpansion.html 
SETLOCAL EnableDelayedExpansion
setlocal ENABLEEXTENSIONS

rem External public download location
set CHECKLMS_EXTERNAL_SHARE=https://downloads.siemens.cloud/

rem CheckLMS configuration (Siemens internal only)
set CHECKLMS_CONFIG=

rem Connection Test to CheckLMS share
rem Internal share names are retrieved from CheckLMS.config
set CHECKLMS_PUBLIC_SHARE=
set CHECKLMS_CONNECTION_TEST_FILE=_CheckLMS_ReadMe_.txt

rem settings for scheduled task: CheckID
set LMS_SCHEDTASK_CHECKID_NAME=CheckLMS_CheckID
set LMS_SCHEDTASK_CHECKID_FULLNAME=\Siemens\Lms\!LMS_SCHEDTASK_CHECKID_NAME!

set ProgramFiles_x86=!ProgramFiles(x86)!

rem https://stackoverflow.com/questions/7727114/batch-command-date-and-time-in-file-name
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set lms_report_datetime=%%I
set lms_report_datetime=%lms_report_datetime:~0,8%-%lms_report_datetime:~8,6%
rem Store report start date & time
set LMS_REPORT_START=!DATE! !TIME!
echo Report Start at !LMS_REPORT_START! ....

rem check administrator privilege (see https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights)
set guid=%random%%random%-%random%-%random%-%random%-%random%%random%%random%
mkdir %WINDIR%\%guid%>nul 2>&1
rmdir %WINDIR%\%guid%>nul 2>&1
IF !ERRORLEVEL!==0 (
    rem ECHO PRIVILEGED! (%guid%)
    echo This script runs with administrator privilege. 
	set LMS_SCRIPT_RUN_AS_ADMINISTRATOR=1
) ELSE (
    rem ECHO NOT PRIVILEGED!  (%guid%)
    echo This script runs with NO administrator privilege. 
)

rem Retrieve desktop folder
FOR /F "usebackq" %%f IN (`PowerShell -NoProfile -Command "Write-Host([Environment]::GetFolderPath('Desktop'))"`) DO (
  SET "DESKTOP_FOLDER=%%f"
)
rem @ECHO DESKTOP_FOLDER=%DESKTOP_FOLDER%

rem Check LMS install & data path
if not defined LMS_DATA_PATH (
	set LMS_DATA_PATH=!ALLUSERSPROFILE!\Siemens\LMS
)
rem Check report log path
set LMS_PROGRAMDATA=!ALLUSERSPROFILE!\Siemens\LMS
set REPORT_LOG_PATH=!LMS_PROGRAMDATA!\Logs
IF NOT EXIST "!REPORT_LOG_PATH!\" (
	rem echo Create new folder: !REPORT_LOG_PATH!\
    mkdir !REPORT_LOG_PATH!\ >nul 2>&1

	IF NOT EXIST "!REPORT_LOG_PATH!\" (
		set REPORT_LOG_PATH=!temp!
		echo This is not a valid LMS Installation, use !temp! as path to store log files 
	)
)
set CHECKLMS_REPORT_LOG_PATH=!REPORT_LOG_PATH!\CheckLMSLogs
IF NOT EXIST "!CHECKLMS_REPORT_LOG_PATH!\" (
	rem echo Create new folder: !CHECKLMS_REPORT_LOG_PATH!\
    mkdir !CHECKLMS_REPORT_LOG_PATH!\ >nul 2>&1
)

rem Check & create download path
set LMS_DOWNLOAD_PATH=!LMS_PROGRAMDATA!\Download
IF NOT EXIST "!LMS_DOWNLOAD_PATH!\" (
	rem echo Create new folder: !LMS_DOWNLOAD_PATH!\
	mkdir !LMS_DOWNLOAD_PATH!\ >nul 2>&1
)
rem Check & create download path for CheckLMS
IF NOT EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS" (
	mkdir !LMS_DOWNLOAD_PATH!\CheckLMS\ >nul 2>&1
)
IF NOT EXIST "!LMS_DOWNLOAD_PATH!\LMSSetup" (
	rem echo Create new folder: !LMS_DOWNLOAD_PATH!\LMSSetup\
	mkdir !LMS_DOWNLOAD_PATH!\LMSSetup\ >nul 2>&1
)
IF NOT EXIST "!LMS_DOWNLOAD_PATH!\SDK" (
	mkdir !LMS_DOWNLOAD_PATH!\SDK\ >nul 2>&1
)

rem Check encoding of running script ...
rem https://stackoverflow.com/questions/32255747/on-windows-how-would-i-detect-the-line-ending-of-a-file#:~:text=use%20a%20text%20editor%20like,LF%2F%20CR%20LF%2FCR.
rem In Powershell, this command returns "True" for a Windows style file and "False" for a *nix style file.
FOR /F "tokens=* USEBACKQ" %%F IN (`Powershell -ExecutionPolicy Bypass -Command "& {(Get-Content '%0' -Raw) -match '\r\n$'}"`) DO (
	SET EOL_FILE_STYLE=%%F
)
if /I "!EOL_FILE_STYLE!" EQU "False" (
	echo The currently executed script, contains 'unix style' line endings. [EOL_FILE_STYLE="!EOL_FILE_STYLE!]
	echo Convert them into '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.CRLF.bat' and restart ...
	rem make sure that 'windows style' line endings are used
	Powershell -ExecutionPolicy Bypass -Command "& {Get-Content '%0' | Set-Content -path '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.CRLF.bat'}"

	start "Check LMS" !LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.CRLF.bat %*
	exit
	rem STOP EXECUTION HERE
)

set CHECKLMS_CRASH_DUMP_PATH=!CHECKLMS_REPORT_LOG_PATH!\CrashDumps
rmdir /S /Q !CHECKLMS_CRASH_DUMP_PATH!\ >nul 2>&1
IF NOT EXIST "%CHECKLMS_CRASH_DUMP_PATH%\" (
	rem echo Create new folder: %CHECKLMS_CRASH_DUMP_PATH%\
    mkdir %CHECKLMS_CRASH_DUMP_PATH%\ >nul 2>&1
)
set CHECKLMS_SETUP_LOG_PATH=!CHECKLMS_REPORT_LOG_PATH!\LMSSetupLogs
rmdir /S /Q !CHECKLMS_SETUP_LOG_PATH!\ >nul 2>&1
IF NOT EXIST "!CHECKLMS_SETUP_LOG_PATH!\" (
	rem echo Create new folder: !CHECKLMS_SETUP_LOG_PATH!\
    mkdir !CHECKLMS_SETUP_LOG_PATH!\ >nul 2>&1
)
set CHECKLMS_SSU_PATH=!CHECKLMS_REPORT_LOG_PATH!\SSU
rem rmdir /S /Q !CHECKLMS_SSU_PATH!\ >nul 2>&1
IF NOT EXIST "!CHECKLMS_SSU_PATH!\" (
	rem echo Create new folder: !CHECKLMS_SSU_PATH!\
    mkdir !CHECKLMS_SSU_PATH!\ >nul 2>&1
)
set CHECKLMS_ALM_PATH=!CHECKLMS_REPORT_LOG_PATH!\Automation
rmdir /S /Q !CHECKLMS_ALM_PATH!\ >nul 2>&1
IF NOT EXIST "!CHECKLMS_ALM_PATH!\" (
	rem echo Create new folder: !CHECKLMS_ALM_PATH!\
    mkdir !CHECKLMS_ALM_PATH!\ >nul 2>&1
)

rem Check flexera command line tools path 
set LMS_SERVERTOOL_PATH=!ProgramFiles_x86!\Siemens\LMS\server
IF NOT EXIST "!LMS_SERVERTOOL_PATH!" (
    set LMS_SERVERTOOL_PATH=!ProgramFiles!\Siemens\LMS\server
)
IF NOT EXIST "!LMS_SERVERTOOL_PATH!" (
	REM No Flexera tools locally installed
    echo This is not a valid LMS Installation, no Flexera tools locally installed at "!LMS_SERVERTOOL_PATH!" ....
	set LMS_SERVERTOOL_PATH=
)

rem Set documentation path
set DOCUMENTATION_PATH=!LMS_PROGRAMDATA!\Documentation

set DOWNLOAD_ARCHIVE=!LMS_PROGRAMDATA!\LMSDownloadArchive_!COMPUTERNAME!_!lms_report_datetime!.zip
set DOWNLOAD_PATH=!LMS_PROGRAMDATA!\Download


rem Create report log filename(s)
set REPORT_LOGARCHIVE=!LMS_PROGRAMDATA!\LMSLogArchive_!COMPUTERNAME!_!lms_report_datetime!.7z
set REPORT_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReport_!COMPUTERNAME!.log 
set REPORT_FULL_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReports_!COMPUTERNAME!.log 
set REPORT_WMIC_INSTALLED_SW_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\WMIC_Installed_SW_Report.log 
set REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV=!CHECKLMS_REPORT_LOG_PATH!\WMIC_Installed_SW_Report.csv 
set REPORT_WMIC_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\WMICReport.log 
set REPORT_PS_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\PSReport.log 
set REPORT_PowerShell_TEMPFILE=!CHECKLMS_REPORT_LOG_PATH!\PSOutputTemp.log

rem Local path for BT ALM plugin
set LMS_ALMBTPLUGIN_FOLDER_X86=C:\\Program Files (x86)\\Common Files\\Siemens\\SWS\\plugins\\bt
set LMS_ALMBTPLUGIN_FOLDER=C:\\Program Files\\Common Files\\Siemens\\SWS\\plugins\\bt

rem Local path for HASP dongle driver
set LMS_HASPDRIVER_FOLDER=!CommonProgramFiles(x86)!\Aladdin Shared\HASP
if "!PROCESSOR_ARCHITECTURE!" == "x86" (
	set LMS_HASPDRIVER_FOLDER=!CommonProgramFiles!\Aladdin Shared\HASP
)
rem Local path for V2C vendor file
set LMS_V2C_FOLDER=!CommonProgramFiles(x86)!\SafeNet Sentinel\Sentinel LDK\installed\111812
if "!PROCESSOR_ARCHITECTURE!" == "x86" (
	set LMS_V2C_FOLDER=!CommonProgramFiles!\SafeNet Sentinel\Sentinel LDK\installed\111812
)
set LMS_V2C_FILE=*_provisional.v2c

rem Application settings
if exist "!ProgramFiles!\Siemens\LMS\bin\LmuTool.exe" (
	set LMS_LMUTOOL=!ProgramFiles!\Siemens\LMS\bin\LmuTool.exe
) else (
	rem leave undefiend
	set LMS_LMUTOOL=
)


rem analyze command line options
FOR %%A IN (%*) DO (
	set var=%%A
	if "!LMS_LOGFILENAME!" == "1" (
		set LMS_LOGFILENAME=!var!
		echo Start Logfile with Command Line Options: %* ....  > !LMS_LOGFILENAME!
	) else if "!LMS_GOTO!" == "1" (
		set LMS_GOTO=!var!
	) else if "!LMS_SET_INFO!" == "1" (
		set LMS_SET_INFO=!var!
	) else (
		set var=!var:~1!
		echo     var=!var!
		if "!var!"=="accepteula" (
			set LMS_ACCEPTEULA=1
		)
		if "!var!"=="showversion" (
			set LMS_SHOW_VERSION=1
			set LMS_NOUSERINPUT=1
			rem this prevents from creating logfile archive
			set LMS_CHECK_ID=1
		)
		if "!var!"=="nouserinput" (
			set LMS_NOUSERINPUT=1
		)
		if "!var!"=="nowait" (
			set LMS_NOUSERINPUT=1
		)
		if "!var!"=="cleanup" (
			set LMS_CLEANUP=1
		)
		if "!var!"=="logfilename" (
			set LMS_LOGFILENAME=1
		)
		if "!var!"=="skipdownload" (
			set LMS_SKIPDOWNLOAD=1
		)
		if "!var!"=="skipnetstat" (
			set LMS_SKIPNETSTAT=1
		)
		if "!var!"=="skipcontest" (
			set LMS_SKIPCONTEST=1
		)
		if "!var!"=="donotstartnewerscript" (
			set LMS_DONOTSTARTNEWERSCRIPT=1
		)
		if "!var!"=="checkdownload" (
			set LMS_CHECK_DOWNLOAD=1
			rem this prevents from creating logfile archive
			set LMS_CHECK_ID=1
		)
		if "!var!"=="checkid" (
			set LMS_ACCEPTEULA=1
			set LMS_CHECK_ID=1
			set LMS_SKIPDOWNLOAD=1
			set LMS_SKIPUNZIP=1
			set LMS_SKIPNETSTAT=1
			set LMS_SKIPNETSETTINGS=1
			set LMS_SKIPCONTEST=1
			set LMS_SKIPTSBACKUP=1
			set LMS_SKIPBTALMPLUGIN=1
			set LMS_SKIPSIGCHECK=1
			set LMS_SKIPWMIC=1
			set LMS_SKIPFIREWALL=1
			set LMS_SKIPSCHEDTASK=1
			set LMS_SKIPWER=1
			set LMS_SKIPSSU=1
			set LMS_SKIPFNP=1
			set LMS_SKIPLMS=1
			set LMS_SKIPSETUP=1
			set LMS_SKIPDDSETUP=1
			set LMS_SKIPLOGS=1
			set LMS_SKIPUCMS=1
			set LMS_SKIPWINEVENT=1
			set LMS_SKIPLICSERV=1
			set LMS_SKIPLOCLICSERV=1
			set LMS_SKIPREMLICSERV=1
			set LMS_SKIPONLICSERV=1
			set LMS_SKIPPRODUCTS=1
			set LMS_SKIPWINDOWS=1
		)
		if "!var!"=="setcheckidtask" (
			set LMS_SET_CHECK_ID_TASK=1
			set LMS_SKIPDOWNLOAD=1
			set LMS_SKIPUNZIP=1
		)
		if "!var!"=="delcheckidtask" (
			set LMS_DEL_CHECK_ID_TASK=1
			set LMS_SKIPDOWNLOAD=1
			set LMS_SKIPUNZIP=1
		)
		if "!var!"=="setfirewall" (
			set LMS_SET_FIREWALL=1
		)
		if "!var!"=="installlms" (
			set LMS_INSTALL_LMS_CLIENT=1
		)
		if "!var!"=="removelms" (
			set LMS_REMOVE_LMS_CLIENT=1
		)
		if "!var!"=="installdongledriver" (
			set LMS_INSTALL_DONGLE_DRIVER=1
		)
		if "!var!"=="removedongledriver" (
			set LMS_REMOVE_DONGLE_DRIVER=1
		)
		if "!var!"=="startdemovd" (
			set LMS_START_DEMO_VD=1
		)
		if "!var!"=="stopdemovd" (
			set LMS_STOP_DEMO_VD=1
		)
		if "!var!"=="info" (
			set LMS_SET_INFO=1
		)
		if "!var!"=="setinfo" (
			set LMS_SET_INFO=1
		)
		if "!var!"=="goto" (
			set LMS_GOTO=1
		)
		if "!var!"=="extend" (
			set LMS_EXTENDED_CONTENT=1
		)
	)
)

if defined LMS_SET_INFO (
    echo     Info: '!LMS_SET_INFO!' ....
)

if defined LMS_CHECK_ID (
	rem adjsut logfile name to avoid clash when two scripts a running at the same time
	set REPORT_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReport_!COMPUTERNAME!_checkid.log 
) else (
	IF EXIST "!ProgramFiles!\Siemens\LMS\scripts\lmu.psc1" (
		rem retrieve previous status of scheduled task
		for /f "delims=" %%a in ('powershell -PSConsoleFile "!ProgramFiles!\Siemens\LMS\scripts\lmu.psc1" -command "(Get-ScheduledTask | Where TaskName -eq !LMS_SCHEDTASK_CHECKID_NAME! ).State"') do set LMS_SCHEDTASK_PREV_STATUS=%%a
		rem disable scheduled task during execution of script, to avoid parallel running
		echo Disable scheduled task '!LMS_SCHEDTASK_CHECKID_FULLNAME!', previous state was '!LMS_SCHEDTASK_PREV_STATUS!'  
		schtasks /change /TN !LMS_SCHEDTASK_CHECKID_FULLNAME! /DISABLE  >nul 2>&1
	)
)

rem ----- avoid access to the main logfile BEFORE ths line -----
rem Frist access to logfile, create an empty file
echo.> !REPORT_LOGFILE! 2>&1

REM -- OS Version and Productname
set KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion
set VALUE_NAME=CurrentVersion
set OS_VERSION=
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set OS_VERSION=%%A
)
set VALUE_NAME=ProductName
set OS_PRODUCTNAME=
for /F "usebackq tokens=3,4,5,6,7" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set OS_PRODUCTNAME=%%A %%B %%C %%D %%E
)

REM -- OS Version (Win10)
set KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion
set VALUE_NAME=CurrentMajorVersionNumber
set OS_MAJ_VERSION=
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem convert hex in decimal (see https://stackoverflow.com/questions/9453246/reg-query-returning-hexadecimal-value)
	set /A OS_MAJ_VERSION=%%A
)
set KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion
set VALUE_NAME=CurrentMinorVersionNumber
set OS_MIN_VERSION=
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem convert hex in decimal (see https://stackoverflow.com/questions/9453246/reg-query-returning-hexadecimal-value)
	set /A OS_MIN_VERSION=%%A
)
REM -- Read MachineGuid
set KEY_NAME=HKLM\SOFTWARE\Microsoft\Cryptography
set VALUE_NAME=MachineGuid
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set OS_MACHINEGUID=%%A
)
if not defined OS_MACHINEGUID (
	echo ERROR: Cannot determine machine GUID! >> !REPORT_LOGFILE! 2>&1
	where where >> !REPORT_LOGFILE! 2>&1
	where find  >> !REPORT_LOGFILE! 2>&1
)

REM -- LMS Registry Keys
set LMS_MAIN_REGISTRY_KEY=HKLM\SOFTWARE\Siemens\LMS
set KEY_NAME=!LMS_MAIN_REGISTRY_KEY!
set VALUE_NAME=Version
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set LMS_VERSION=%%A
)
set VALUE_NAME=SystemId
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set LMS_SYSTEMID=%%A
)
set VALUE_NAME=LicenseMode
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set LMS_LICENSE_MODE=%%A
)
set VALUE_NAME=SkipALMBtPluginInstallation
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set LMS_SKIP_ALM_BT_PUGIN_INSTALLATION=%%A
)
REM -- LMS Registry Keys (ATOS)
rem "HKLM\SOFTWARE\LicenseManagementSystem\IsInstalled" is set to "1" if LMS has been installed by ATOS (2nd package of LMS 2.4.815)
rem ... BUT is never removed again!
set KEY_NAME=HKLM\SOFTWARE\LicenseManagementSystem
set VALUE_NAME=IsInstalled
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set LMS_INSTALLED_BY_ATOS=%%A
)
REM -- SSU Registry Keys
set SSU_MAIN_REGISTRY_KEY=HKLM\SOFTWARE\Siemens\SSU
set KEY_NAME=!SSU_MAIN_REGISTRY_KEY!
set VALUE_NAME=SystemId
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set SSU_SYSTEMID=%%A
)
REM -- Dongle Driver Registry Keys
set KEY_NAME=HKLM\SOFTWARE\Aladdin Knowledge Systems\HASP\Driver\Installer
set VALUE_NAME=DrvPkgVersion
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set DONGLE_DRIVER_PKG_VERSION=%%A
)
set VALUE_NAME=Version
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set DONGLE_DRIVER_VERSION=%%A
)
set VALUE_NAME=InstCount
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem convert hex in decimal (see https://stackoverflow.com/questions/9453246/reg-query-returning-hexadecimal-value)
	set /A DONGLE_DRIVER_INST_COUNT=%%A
)
rem 1204576: CheckLMS: Consider that ” DrvPkgVersion” is not longer available!
rem the content of «HKLM\SOFTWARE\Aladdin Knowledge Systems\HASP\Driver\Installer» has changed in 8.13; the entry ” DrvPkgVersion” is not longer available!
if not defined DONGLE_DRIVER_PKG_VERSION (
	set DONGLE_DRIVER_PKG_VERSION=!DONGLE_DRIVER_VERSION!
)
for /f "tokens=1 delims=." %%a in ("!DONGLE_DRIVER_PKG_VERSION!") do set DONGLE_DRIVER_MAJ_VERSION=%%a
for /f "tokens=2 delims=." %%a in ("!DONGLE_DRIVER_PKG_VERSION!") do set DONGLE_DRIVER_MIN_VERSION=%%a

REM -- Automation License Manager (ALM) Registry Keys
set KEY_NAME=HKLM\SOFTWARE\Siemens\AUTSW\LicenseManager
set VALUE_NAME=Release
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set ALM_RELEASE=%%A
	for /f "tokens=1 delims=." %%a in ("!ALM_RELEASE!") do set ALM_MAJ_VERSION=%%a
	for /f "tokens=2 delims=." %%a in ("!ALM_RELEASE!") do set ALM_MIN_VERSION=%%a
	for /f "tokens=3 delims=." %%a in ("!ALM_RELEASE!") do set ALM_PATCH_VERSION=%%a
	rem remove leading zeroes: https://stackoverflow.com/questions/14762813/remove-leading-zeros-in-batch-file
	for /f "tokens=* delims=0" %%a in ("!ALM_MAJ_VERSION!") do set ALM_MAJ_VERSION=%%a
	for /f "tokens=* delims=0" %%a in ("!ALM_MIN_VERSION!") do set ALM_MIN_VERSION=%%a
	for /f "tokens=* delims=0" %%a in ("!ALM_PATCH_VERSION!") do set ALM_PATCH_VERSION=%%a
)
set VALUE_NAME=TechnVersion
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set ALM_TECH_VERSION=%%A
)
set VALUE_NAME=Version
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set ALM_VERSION=%%A
)
set VALUE_NAME=VersionString
for /F "usebackq tokens=3*" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem fixed 12-Jan-2022: Include also 'spaces' in result
	set ALM_VERSION_STRING=%%A %%B
)
rem extract 'PendingFileRenameOperations' from \HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager
set KEY_NAME=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager
set VALUE_NAME=PendingFileRenameOperations
set ALM_REG_PendingFileRenameOperations=
for /F "usebackq tokens=3*" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem Include also 'spaces' in result
	set ALM_REG_PendingFileRenameOperations=%%A %%B
)


REM -- Check FIPS mode
REM HKLM\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy\Enabled
set KEY_NAME=HKLM\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy
set VALUE_NAME=Enabled
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	rem convert hex in decimal (see https://stackoverflow.com/questions/9453246/reg-query-returning-hexadecimal-value)
	set /A FIPS_MODE_ENABLED=%%A
)
REM -- Get Language Code
wmic os get locale, oslanguage, codeset /format:list > !temp!\wmic_output.txt
IF EXIST "!temp!\wmic_output.txt" for /f "tokens=2 delims== eol=@" %%i in ('type !temp!\wmic_output.txt ^|find /I "OSLanguage"') do set "OS_LANGUAGE=%%i"
IF EXIST "!temp!\wmic_output.txt" for /f "tokens=2 delims== eol=@" %%i in ('type !temp!\wmic_output.txt ^|find /I "Locale"') do set /A "LOCAL_LANGUAGE=0x%%i"
if /I !OS_LANGUAGE! NEQ 1033 if /I !OS_LANGUAGE! NEQ 1031 (
	rem Non standard OS language (1031, 1033) found
	set NON_STANDARD_OS_LANGUAGE=!OS_LANGUAGE!
)
if /I !LOCAL_LANGUAGE! NEQ 1033 if /I !LOCAL_LANGUAGE! NEQ 1031 (
	rem Non standard local language (1031, 1033) found
	set NON_STANDARD_LOCAL_LANGUAGE=!LOCAL_LANGUAGE!
)

REM --- Check, that LMS version is defined
if defined LMS_VERSION (
	REM --- Determine LMS Version ---
	set LMS_MAJ_VERSION=!LMS_VERSION:~0,1!
	set LMS_MIN_VERSION=!LMS_VERSION:~2,1!
	set LMS_BUILD_VERSION=!LMS_VERSION:~4,3!
) else (
    echo This is not a valid LMS Installation, cannot read LMS version. 
    set LMS_VERSION=N/A
	set LMS_MAJ_VERSION=N/A
	set LMS_MIN_VERSION=N/A
	set LMS_BUILD_VERSION=0
)

REM --- Read FNP Version ---
REM see https://superuser.com/questions/363278/is-there-a-way-to-get-file-metadata-from-the-command-line for more information
REM see https://docs.microsoft.com/en-us/windows/desktop/WinProg64/wow64-implementation-details to check bitness of operating system
REM NOTE: %ProgramFiles(x86)% and !ProgramFiles! doesn't work together with "wmic datafile"
REM       you need to replace \ with \\, see https://alt.msdos.batch.narkive.com/LNB84uUc/replace-all-backslashes-in-a-string-with-double-backslash
set FNPVersion=
REM Keep "old" way to retrieve file version ...
if exist "C:\Program Files\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService64.exe" (
	wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService64.exe" get Manufacturer,Name,Version  /format:list  > NUL
	IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
)
if not defined FNPVersion (
	if exist "C:\Program Files (x86)\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe" (
		wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list  > NUL
		IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	if exist "C:\Program Files\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe" (
		REM Covers the case of Win7 32-bit
		wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list  > NUL
		IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
REM Add new way to retrieve file version ....
REM Replace \ with \\, see https://alt.msdos.batch.narkive.com/LNB84uUc/replace-all-backslashes-in-a-string-with-double-backslash
if not defined FNPVersion (
	set TARGETFILE=!ProgramFiles!\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService64.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list  > NUL
		IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	set TARGETFILE=!ProgramFiles_x86!\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list  > NUL
		IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	set TARGETFILE=!ProgramFiles!\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:!REPORT_WMIC_LOGFILE! datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list  > NUL
		IF EXIST "!REPORT_WMIC_LOGFILE!" for /f "tokens=2 delims== eol=@" %%i in ('type !REPORT_WMIC_LOGFILE! ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)

set LMS_SERVERTOOL_DW=
set LMS_SERVERTOOL_DW_PATH=
if defined FNPVersion (
	rem FNP 11.16.2.0 (or newer), set them on general rule.
	set LMS_SERVERTOOL_DW=SiemensFNP-!FNPVersion!-Binaries
	set LMS_SERVERTOOL_DW_PATH=!LMS_DOWNLOAD_PATH!\!LMS_SERVERTOOL_DW!\
) else (
    echo This is not a valid LMS Installation, cannot read FNP version. 
)

rem check if colored ouput is supported
set SHOW_COLORED_OUTPUT=
if /I "!OS_MAJ_VERSION!" EQU "10" (
	set SHOW_COLORED_OUTPUT="Yes"
	set SHOW_RED=[1;31m
	set SHOW_YELLOW=[1;33m
	set SHOW_GREEN=[1;32m
	set SHOW_BLUE=[1;34m
	set SHOW_NORMAL=[1;37m
)

echo !SHOW_NORMAL!LMS Status Report for LMS System !LMS_SYSTEMID! with LMS Version: !LMS_VERSION!
echo !SHOW_YELLOW!    be patient, the collection of the information requires some time, up to several minutes !SHOW_NORMAL!

echo Check current LMS installation .....
if exist "!LMS_SERVERTOOL_PATH!" cd "!LMS_SERVERTOOL_PATH!"

if not defined LMS_CHECK_ID (
	set LMS_BALLOON_TIP_TITLE=CheckLMS Script
	set LMS_BALLOON_TIP_TEXT=Start CheckLMS script [!LMS_SCRIPT_BUILD!] on !COMPUTERNAME! with LMS Version !LMS_VERSION! ...
	set LMS_BALLOON_TIP_ICON=Information
	powershell -Command "[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $objNotifyIcon=New-Object System.Windows.Forms.NotifyIcon; $objNotifyIcon.BalloonTipText='!LMS_BALLOON_TIP_TEXT!'; $objNotifyIcon.Icon=[system.drawing.systemicons]::!LMS_BALLOON_TIP_ICON!; $objNotifyIcon.BalloonTipTitle='!LMS_BALLOON_TIP_TITLE!'; $objNotifyIcon.BalloonTipIcon='None'; $objNotifyIcon.Visible=$True; $objNotifyIcon.ShowBalloonTip(5000);"
	if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
		EVENTCREATE.exe /T INFORMATION /L Siemens /so CheckLMS /ID 301 /D "!LMS_BALLOON_TIP_TEXT!"  >nul 2>&1
	)
)

rem Determine if script is running on a virtual machine (means within a hypervisor)
rem see https://devblogs.microsoft.com/scripting/use-powershell-to-detect-if-hypervisor-is-present/
rem see https://stackoverflow.com/questions/21706204/how-to-put-a-single-powershell-output-string-into-a-cmd-variable
for /f "delims=" %%a in ('powershell -c "(gcim Win32_ComputerSystem).HypervisorPresent"') do set "LMS_IS_VM=%%a"
rem echo LMS_IS_VM=!LMS_IS_VM!

echo Report Start '%0' at !LMS_REPORT_START! ....                                                                            >> !REPORT_LOGFILE! 2>&1
echo ============================================================================================================================================================ >> !REPORT_LOGFILE! 2>&1
echo =                                                                                                                       >> !REPORT_LOGFILE! 2>&1
echo =   L      M     M   SSSS                                                                                               >> !REPORT_LOGFILE! 2>&1
echo =   L      MM   MM  S                                                                                                   >> !REPORT_LOGFILE! 2>&1
echo =   L      M M M M   SSS                                                                                                >> !REPORT_LOGFILE! 2>&1
echo =   L      M  M  M      S                                                                                               >> !REPORT_LOGFILE! 2>&1
echo =   LLLLL  M     M  SSSS                                                                                                >> !REPORT_LOGFILE! 2>&1
echo =                                                                                                                       >> !REPORT_LOGFILE! 2>&1
echo ==============================================================================                                          >> !REPORT_LOGFILE! 2>&1
echo =                                                                                                                       >> !REPORT_LOGFILE! 2>&1
echo =  LMS Status Report for LMS Version: !LMS_VERSION! on !COMPUTERNAME!, with !PROCESSOR_ARCHITECTURE!                    >> !REPORT_LOGFILE! 2>&1
echo =  Date: !DATE! / Time: !TIME!                                                                                          >> !REPORT_LOGFILE! 2>&1
echo =  LMS System Id: !LMS_SYSTEMID!                                                                                        >> !REPORT_LOGFILE! 2>&1
echo =  SSU System Id: %SSU_SYSTEMID%                                                                                        >> !REPORT_LOGFILE! 2>&1
echo =  Machine GUID : %OS_MACHINEGUID%                                                                                      >> !REPORT_LOGFILE! 2>&1
echo =                                                                                                                       >> !REPORT_LOGFILE! 2>&1
echo =  Check Script Version: %LMS_SCRIPT_VERSION% [!LMS_SCRIPT_BUILD!]                                                      >> !REPORT_LOGFILE! 2>&1
echo =  Check Script File   : %0                                                                                             >> !REPORT_LOGFILE! 2>&1
IF "%~1"=="" (
	echo =  Command Line Options: no options passed.                                                                         >> !REPORT_LOGFILE! 2>&1
) else (
	echo =  Command Line Options: %*                                                                                         >> !REPORT_LOGFILE! 2>&1
)
if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
	echo =  Script started with : Administrator privilege                                                                    >> !REPORT_LOGFILE! 2>&1
) else (
	echo =  Script started with : normal privilege                                                                           >> !REPORT_LOGFILE! 2>&1
)


echo Start at !DATE! !TIME! ....    E N D   U S E R   L I C E N S E   A G R E E M E N T                                      >> !REPORT_LOGFILE! 2>&1
echo ==============================================================================
echo =   E N D   U S E R   L I C E N S E   A G R E E M E N T                      =
echo ==============================================================================
echo ==============================================================================                                          >> !REPORT_LOGFILE! 2>&1
echo =   E N D   U S E R   L I C E N S E   A G R E E M E N T                      =                                          >> !REPORT_LOGFILE! 2>&1
echo ==============================================================================                                          >> !REPORT_LOGFILE! 2>&1

echo Please read the EULA before proceeding ...  
IF EXIST "!DOCUMENTATION_PATH!\LMS EULA.pdf" (
	echo To read the EULA, open: !DOCUMENTATION_PATH!\LMS EULA.pdf  
	echo To read the EULA, open: !DOCUMENTATION_PATH!\LMS EULA.pdf                                                           >> !REPORT_LOGFILE! 2>&1
) else (
	IF EXIST "!DOCUMENTATION_PATH!\LMS EULA.rtf" (
		echo To read the EULA, open: !DOCUMENTATION_PATH!\LMS EULA.rtf  
		echo To read the EULA, open: !DOCUMENTATION_PATH!\LMS EULA.rtf                                                       >> !REPORT_LOGFILE! 2>&1
	)
)
echo.
if not defined LMS_ACCEPTEULA (
	set /p acceptEULA=Please enter YES to accept the EULA:   
) else (
	set acceptEULA=YES
)
if /I "!acceptEULA!"=="YES" (  
    echo EULA accepted. Continuing with the processing...  
    echo EULA accepted. Continuing with the processing... User input was: '!acceptEULA!'                                     >> !REPORT_LOGFILE! 2>&1  
) else (  
    echo EULA not accepted. Exiting...  
    echo EULA not accepted. Exiting... User input was: '!acceptEULA!'                                                        >> !REPORT_LOGFILE! 2>&1 

	echo ==============================================================================                                      >> !REPORT_LOGFILE! 2>&1
	echo ==                                                                                                                  >> !REPORT_LOGFILE! 2>&1
	echo ==   E U L A   N O T   A C C E P T E D  -  S T O P   E X E C U T I O N                                              >> !REPORT_LOGFILE! 2>&1
	echo ==                                                                                                                  >> !REPORT_LOGFILE! 2>&1
	echo ==============================================================================                                      >> !REPORT_LOGFILE! 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                              >> !REPORT_LOGFILE! 2>&1
	if "!LMS_SCHEDTASK_PREV_STATUS!" == "Ready" (
		rem enable scheduled task during execution of script; if it was enabled at script start ..
		echo Re-enable scheduled task '!LMS_SCHEDTASK_CHECKID_FULLNAME!', previous state was '!LMS_SCHEDTASK_PREV_STATUS!'   >> !REPORT_LOGFILE! 2>&1
		schtasks /change /TN !LMS_SCHEDTASK_CHECKID_FULLNAME! /ENABLE >nul 2>&1
	)
	rem save (single) report in full report file
	Type !REPORT_LOGFILE! >> %REPORT_FULL_LOGFILE%
	
	if not defined LMS_NOUSERINPUT (
		set /p DUMMY=Hit ENTER to continue...
	)
	exit
	rem STOP EXECUTION HERE

)
echo Start at !DATE! !TIME! ....    E U L A   A C C E P T E D  /  S H O W   I N F O                                          >> !REPORT_LOGFILE! 2>&1


echo ==============================================================================
echo =   C H E C K  L M S  I N F O                                                =
echo ==============================================================================
echo ==============================================================================                                          >> !REPORT_LOGFILE! 2>&1
echo =   C H E C K  L M S  I N F O                                                =                                          >> !REPORT_LOGFILE! 2>&1
echo ==============================================================================                                          >> !REPORT_LOGFILE! 2>&1
echo ... checklms info section ...
if defined LMS_SET_INFO (
	echo Info: [!LMS_REPORT_START!] !LMS_SET_INFO! ....                                                                      >> !REPORT_LOGFILE! 2>&1
	echo [!LMS_REPORT_START!] !LMS_SET_INFO! >> "!DOCUMENTATION_PATH!\info.txt" 2>&1
)
IF EXIST "!ProgramFiles!\7-Zip\7z.exe" (
	set UNZIP_TOOL=!ProgramFiles!\7-Zip\7z.exe
) else IF EXIST "!ProgramFiles!\Siemens\SSU\bin\7z.exe" (
	set UNZIP_TOOL=!ProgramFiles!\Siemens\SSU\bin\7z.exe
)
if NOT defined UNZIP_TOOL (
    echo No local unzip tool [7z.exe] found.                                                                                 >> !REPORT_LOGFILE! 2>&1
	echo Search for installed local '7z' tool ....                                                                           >> !REPORT_LOGFILE! 2>&1
	where 7z                                                                                                                 >> !REPORT_LOGFILE! 2>&1
) else (
    echo Local Unzip tool [!UNZIP_TOOL!] found.                                                                              >> !REPORT_LOGFILE! 2>&1
	"!UNZIP_TOOL!" -version    >> "!CHECKLMS_REPORT_LOG_PATH!\unziptool_version.log" 2>&1
)
powershell -Command "Get-Command  Expand-Archive"   >> "!CHECKLMS_REPORT_LOG_PATH!\expandarchive_version.log" 2>&1

echo -------------------------------------------------------                                                                 >> !REPORT_LOGFILE! 2>&1
if not defined LMS_SKIPDOWNLOAD (
	echo Start at !DATE! !TIME! .... Connection Test to BT download site                           >> !REPORT_LOGFILE! 2>&1
	echo ... Connection Test to BT download site ...
	rem Connection Test to BT download site
	set ConnectionTestStatus=Unknown
	del !LMS_DOWNLOAD_PATH!\ReadMe.txt >nul 2>&1
	powershell -Command "(New-Object Net.WebClient).DownloadFile('!CHECKLMS_EXTERNAL_SHARE!lms/ReadMe.txt', '!LMS_DOWNLOAD_PATH!\ReadMe.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_btdownloads.txt 2>&1
	if exist "!LMS_DOWNLOAD_PATH!\ReadMe.txt" (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access !CHECKLMS_EXTERNAL_SHARE!
		echo Connection Test PASSED, can access !CHECKLMS_EXTERNAL_SHARE!                          >> !REPORT_LOGFILE! 2>&1
		set ConnectionTestStatus=Passed
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access !CHECKLMS_EXTERNAL_SHARE!
		echo Connection Test FAILED, cannot access !CHECKLMS_EXTERNAL_SHARE!                       >> !REPORT_LOGFILE! 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_btdownloads.txt                            >> !REPORT_LOGFILE! 2>&1
		set ConnectionTestStatus=Failed
	)
	echo Start at !DATE! !TIME! .... download newer CheckLMS scripts                               >> !REPORT_LOGFILE! 2>&1
	echo ... download newer CheckLMS scripts ...
	if "!ConnectionTestStatus!" == "Passed" (

		if defined LMS_DOWNLOAD_PATH (

			rem Check if newer CheckLMS.bat is available in !LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat
			IF EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat" (
				echo     Check script on '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat' ... 
				echo Check script on '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat' ...                                                                                                       >> !REPORT_LOGFILE! 2>&1
				for /f "tokens=2 delims== eol=@" %%i in ('type !LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD set LMS_SCRIPT_BUILD_DOWNLOAD=%%i
			)	

			rem Download newest LMS check script from download share as 'CheckLMS.bat'
			if not defined LMS_DONOTSTARTNEWERSCRIPT (
				set LMS_DOWNLOAD_LINK=!CHECKLMS_EXTERNAL_SHARE!lms/CheckLMS/CheckLMS.bat
			 	echo     Download newest LMS check script: !LMS_DOWNLOAD_LINK!
			 	echo Download newest LMS check script: !LMS_DOWNLOAD_LINK!                                                                                                                 >> !REPORT_LOGFILE! 2>&1
				IF NOT EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS\bat" (
					mkdir !LMS_DOWNLOAD_PATH!\CheckLMS\bat\ >nul 2>&1
				)
			 	del !LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat >nul 2>&1
			 	powershell -Command "(New-Object Net.WebClient).DownloadFile('!LMS_DOWNLOAD_LINK!', '!LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat')"                                      >> !REPORT_LOGFILE! 2>&1
				if !ERRORLEVEL!==0 (
					echo     Download PASSED, file available at '!LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat'                                                                            >> !REPORT_LOGFILE! 2>&1
				) else if !ERRORLEVEL!==1 (
					echo     Download FAILED, cannot access '!LMS_DOWNLOAD_LINK!'                                                                                                          >> !REPORT_LOGFILE! 2>&1
				)
			 	IF EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat" (
					rem CheckLMS.bat has been downloaded from share
					for /f "tokens=2 delims== eol=@" %%i in ('type !LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_BAT set LMS_SCRIPT_BUILD_DOWNLOAD_BAT=%%i
					echo     Check script downloaded from download share. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_BAT!, Running script version: !LMS_SCRIPT_BUILD!.            >> !REPORT_LOGFILE! 2>&1
					IF defined LMS_SCRIPT_BUILD_DOWNLOAD (
						if /I !LMS_SCRIPT_BUILD_DOWNLOAD_BAT! GTR !LMS_SCRIPT_BUILD_DOWNLOAD! (
							echo Newer check script copied. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_BAT!, Previous script version: !LMS_SCRIPT_BUILD_DOWNLOAD!.                >> !REPORT_LOGFILE! 2>&1
							copy /Y "!LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat" "!LMS_DOWNLOAD_PATH!\CheckLMS\"                                                                        >> !REPORT_LOGFILE! 2>&1
							set LMS_SCRIPT_BUILD_DOWNLOAD=!LMS_SCRIPT_BUILD_DOWNLOAD_BAT!
						)
					) else (
						copy /Y "!LMS_DOWNLOAD_PATH!\CheckLMS\bat\CheckLMS.bat" "!LMS_DOWNLOAD_PATH!\CheckLMS\"                                                                            >> !REPORT_LOGFILE! 2>&1
						set LMS_SCRIPT_BUILD_DOWNLOAD=!LMS_SCRIPT_BUILD_DOWNLOAD_BAT!
					)
				)			
			) else (
				echo Skip download of 'CheckLMS.bat' from download share,  because option 'donotstartnewerscript' is set. '%0'                                                             >> !REPORT_LOGFILE! 2>&1
			) 

		)
	)
	
	rem Download newest LMS check script from OSD
	IF EXIST "!ProgramFiles!\Siemens\LMS\scripts\CheckForUpdate.ps1" (
		rem Start CheckForUpdate.ps1 script within LMS environment.
		set LMS_CHECKFORUPDATE_SCRIPT=!ProgramFiles!\Siemens\LMS\scripts\CheckForUpdate.ps1
		set LMS_CHECKFORUPDATE_OPTIONS=-PSConsoleFile "!ProgramFiles!\Siemens\LMS\scripts\lmu.psc1"
	) else (
		IF EXIST "!ProgramFiles!\Siemens\SSU\bin\CheckForUpdate.ps1" (
			rem Start CheckForUpdate.ps1 script within SSU environment.
			set LMS_CHECKFORUPDATE_SCRIPT=!ProgramFiles!\Siemens\SSU\bin\CheckForUpdate.ps1
			set LMS_CHECKFORUPDATE_OPTIONS=
		)
	)
	IF EXIST "!LMS_CHECKFORUPDATE_SCRIPT!" (
		del "!LMS_DOWNLOAD_PATH!\CheckLMS.bat" >nul 2>&1
		echo RUN: powershell !LMS_CHECKFORUPDATE_OPTIONS! -Command "& '!LMS_CHECKFORUPDATE_SCRIPT!' -SkipSiemensSoftware 1 -verbose 1 -DownloadSoftware 1 -productversion '!LMS_SCRIPT_BUILD!' -productcode '!LMS_SCRIPT_PRODUCTID!'; exit $LASTEXITCODE"         >> !REPORT_LOGFILE! 2>&1
		powershell !LMS_CHECKFORUPDATE_OPTIONS! -Command "& '!LMS_CHECKFORUPDATE_SCRIPT!' -SkipSiemensSoftware 1 -verbose 1 -DownloadSoftware 1 -productversion '!LMS_SCRIPT_BUILD!' -productcode '!LMS_SCRIPT_PRODUCTID!'; exit $LASTEXITCODE"                   >> !REPORT_LOGFILE! 2>&1
		IF EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS.bat" (
			rem CheckLMS.bat has been downloaded from OSD server
			for /f "tokens=2 delims== eol=@" %%i in ('type !LMS_DOWNLOAD_PATH!\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_OSD set LMS_SCRIPT_BUILD_DOWNLOAD_OSD=%%i
			echo     Check script downloaded from OSD. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_OSD!, Running script version: !LMS_SCRIPT_BUILD!.            >> !REPORT_LOGFILE! 2>&1
			IF defined LMS_SCRIPT_BUILD_DOWNLOAD (
				if /I !LMS_SCRIPT_BUILD_DOWNLOAD_OSD! GTR !LMS_SCRIPT_BUILD_DOWNLOAD! (
					echo Newer check script copied. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_OSD!, Previous script version: !LMS_SCRIPT_BUILD_DOWNLOAD!.     >> !REPORT_LOGFILE! 2>&1
					copy /Y "!LMS_DOWNLOAD_PATH!\CheckLMS.bat" "!LMS_DOWNLOAD_PATH!\CheckLMS\"                                                                          >> !REPORT_LOGFILE! 2>&1
					set LMS_SCRIPT_BUILD_DOWNLOAD=!LMS_SCRIPT_BUILD_DOWNLOAD_OSD!
				)
			) else (
				copy /Y "!LMS_DOWNLOAD_PATH!\CheckLMS.bat" "!LMS_DOWNLOAD_PATH!\CheckLMS\"                                                                              >> !REPORT_LOGFILE! 2>&1
				set LMS_SCRIPT_BUILD_DOWNLOAD=!LMS_SCRIPT_BUILD_DOWNLOAD_OSD!
			)
		)
	) else (
		echo ERROR: Cannot execute powershell script 'CheckForUpdate.ps1', it doesn't exist at '!LMS_CHECKFORUPDATE_SCRIPT!'.                    >> !REPORT_LOGFILE! 2>&1
	)
	
)

if not defined LMS_DONOTSTARTNEWERSCRIPT (
	set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=
	rem Check if newer CheckLMS.bat is available in !LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat (even if connection test doesn't run succesful)
	IF EXIST "!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat" (
		echo     Check script on '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat' ... 
		echo Check script on '!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat' ...                                                                                            >> !REPORT_LOGFILE! 2>&1
		set LMS_SCRIPT_BUILD_DOWNLOAD=
		for /f "tokens=2 delims== eol=@" %%i in ('type !LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD set LMS_SCRIPT_BUILD_DOWNLOAD=%%i
		echo     Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD!, Running script version: !LMS_SCRIPT_BUILD!.                                                      >> !REPORT_LOGFILE! 2>&1
		if /I !LMS_SCRIPT_BUILD_DOWNLOAD! GTR !LMS_SCRIPT_BUILD! (
			echo     Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD!, Running script version: !LMS_SCRIPT_BUILD!.
			echo Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD!, Running script version: !LMS_SCRIPT_BUILD!.                       >> !REPORT_LOGFILE! 2>&1
			set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=!LMS_DOWNLOAD_PATH!\CheckLMS\CheckLMS.bat
		)
	)	
) else (
	echo SKIPPED check for newer script. Command line option "Do not start new script" is set.                                                                          >> !REPORT_LOGFILE! 2>&1
)
echo Download Summary, newest downloaded script version '!LMS_SCRIPT_BUILD_DOWNLOAD!'.  From GIT: !LMS_SCRIPT_BUILD_DOWNLOAD_GIT! /  From Share: !LMS_SCRIPT_BUILD_DOWNLOAD_BAT! /  From OSD: !LMS_SCRIPT_BUILD_DOWNLOAD_OSD! /  Running script version: !LMS_SCRIPT_BUILD!.  >> !REPORT_LOGFILE! 2>&1
echo     Download Summary, newest downloaded script version '!LMS_SCRIPT_BUILD_DOWNLOAD!'.  From GIT: !LMS_SCRIPT_BUILD_DOWNLOAD_GIT! /  From Share: !LMS_SCRIPT_BUILD_DOWNLOAD_BAT! /  From OSD: !LMS_SCRIPT_BUILD_DOWNLOAD_OSD! /  Running script version: !LMS_SCRIPT_BUILD!.

if defined LMS_SCRIPT_BUILD_DOWNLOAD_TO_START (
	if not defined LMS_DONOTSTARTNEWERSCRIPT (

		rem Start newer script in an own command shell window
		echo ==============================================================================                                        >> !REPORT_LOGFILE! 2>&1
		echo ==                                                                                                                    >> !REPORT_LOGFILE! 2>&1
		echo == Start newer script in an own command shell window.                                                                 >> !REPORT_LOGFILE! 2>&1
		echo ==    command: start "Check LMS !LMS_SCRIPT_BUILD_DOWNLOAD!" !LMS_SCRIPT_BUILD_DOWNLOAD_TO_START! %*                  >> !REPORT_LOGFILE! 2>&1
		echo ==                                                                                                                    >> !REPORT_LOGFILE! 2>&1
		echo ==============================================================================                                        >> !REPORT_LOGFILE! 2>&1
		echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                >> !REPORT_LOGFILE! 2>&1
		if "!LMS_SCHEDTASK_PREV_STATUS!" == "Ready" (
			rem enable scheduled task during execution of script; if it was enabled at script start ..
			echo Re-enable scheduled task '!LMS_SCHEDTASK_CHECKID_FULLNAME!', previous state was '!LMS_SCHEDTASK_PREV_STATUS!'     >> !REPORT_LOGFILE! 2>&1
			schtasks /change /TN !LMS_SCHEDTASK_CHECKID_FULLNAME! /ENABLE >nul 2>&1
		)
		rem save (single) report in full report file
		Type !REPORT_LOGFILE! >> %REPORT_FULL_LOGFILE%
		
		start "Check LMS" !LMS_SCRIPT_BUILD_DOWNLOAD_TO_START! %* /donotstartnewerscript
		exit
		rem STOP EXECUTION HERE
	
	) else (
		echo !SHOW_YELLOW!    SKIPPED start of newer script. Command line option "Do not start new script" is set. !SHOW_NORMAL!
		echo SKIPPED start of newer script. Command line option "Do not start new script" is set.                                  >> !REPORT_LOGFILE! 2>&1
	)
)	

if defined LMS_SHOW_VERSION (
	echo ==============================================================================                                          
	echo =                                                                                                                       
	echo =  LMS Status Report for LMS Version: !LMS_VERSION! on !COMPUTERNAME!, with !PROCESSOR_ARCHITECTURE!
	echo =  LMS System Id: !LMS_SYSTEMID! 
	echo =  SSU System Id: %SSU_SYSTEMID% 
	echo =  Machine GUID : %OS_MACHINEGUID%
	echo =                                 
	echo =  Check Script Version: %LMS_SCRIPT_VERSION% [!LMS_SCRIPT_BUILD!]
	echo =  Check Script File   : %0       
	IF "%~1"=="" (
		echo =  Command Line Options: no options passed. 
	) else (
		echo =  Command Line Options: %*                 
	)
	if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
		echo =  Script started with : Administrator privilege   
	) else (
		echo =  Script started with : normal privilege          
	)
	echo ==============================================================================

	goto script_end
	rem STOP EXECUTION HERE
)

REM === All content removed, keep only download from downloads.siemens.com ===

:script_end
echo -------------------------------------------------------                                                             >> !REPORT_LOGFILE! 2>&1
echo     === THIS REPO IS DEPRECATED ===
echo     === THIS REPO IS DEPRECATED ===                                                                                 >> !REPORT_LOGFILE! 2>&1
echo ==============================================================================                                                             >> !REPORT_LOGFILE! 2>&1
echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                                     >> !REPORT_LOGFILE! 2>&1

rem save (single) report in full report file
Type !REPORT_LOGFILE! >> !REPORT_FULL_LOGFILE!

rem copy default logfile to specified <LMS_LOGFILENAME>
if defined LMS_LOGFILENAME (
	Type !REPORT_LOGFILE! >> !LMS_LOGFILENAME!
)

if not defined LMS_CHECK_ID (
	set LMS_BALLOON_TIP_TITLE=CheckLMS Script
	set LMS_BALLOON_TIP_TEXT=Script CheckLMS ended, on !COMPUTERNAME! with LMS Version !LMS_VERSION!, see !REPORT_LOGFILE!. Send this log file togther with zipped archive of !REPORT_LOG_PATH! to your local system supplier. 
	set LMS_BALLOON_TIP_ICON=Information
	powershell -Command "[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $objNotifyIcon=New-Object System.Windows.Forms.NotifyIcon; $objNotifyIcon.BalloonTipText='!LMS_BALLOON_TIP_TEXT!'; $objNotifyIcon.Icon=[system.drawing.systemicons]::!LMS_BALLOON_TIP_ICON!; $objNotifyIcon.BalloonTipTitle='!LMS_BALLOON_TIP_TITLE!'; $objNotifyIcon.BalloonTipIcon='None'; $objNotifyIcon.Visible=$True; $objNotifyIcon.ShowBalloonTip(5000);"
	if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
		EVENTCREATE /T INFORMATION /L Siemens /so CheckLMS /ID 302 /D "!LMS_BALLOON_TIP_TEXT!"  >nul 2>&1
	)
)

:create_archive
if "!LMS_SCHEDTASK_PREV_STATUS!" == "Ready" (
	rem enable scheduled task during execution of script; if it was enabled at script start ..
	echo Re-enable scheduled task '!LMS_SCHEDTASK_CHECKID_FULLNAME!', previous state was '!LMS_SCHEDTASK_PREV_STATUS!'   >> !REPORT_LOGFILE! 2>&1
	schtasks /change /TN !LMS_SCHEDTASK_CHECKID_FULLNAME! /ENABLE >nul 2>&1
)

echo Script finished!                  >> !REPORT_LOGFILE! 2>&1
echo End at !DATE! !TIME! ....         >> !REPORT_LOGFILE! 2>&1
rem ----- avoid access to the main logfile AFTER ths line -----

if not defined LMS_CHECK_ID (
	if defined UNZIP_TOOL (
		echo .
		echo .
		echo Create logfile archive '!REPORT_LOGARCHIVE!' ....
		echo ===========================================================                       >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
		echo Start at !DATE! !TIME! to create !REPORT_LOGARCHIVE! ....                         >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
		"!UNZIP_TOOL!" a -ssw -t7z "!REPORT_LOGARCHIVE!" "!REPORT_LOG_PATH!"                   >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
		if "!SiemensConnectionTestStatus!" == "Passed" (
			rem access to internal public share, copy zipped archive to this share
			echo -------------------------------------------------------                       >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo Start at !DATE! !TIME! to copy '!REPORT_LOGARCHIVE!' ....                     >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo !SHOW_YELLOW!    be patient, the upload of the archive requires some time, up to several hours !SHOW_NORMAL!
			echo     start upload '!REPORT_LOGARCHIVE!' to '!CHECKLMS_PUBLIC_SHARE!' at !DATE! !TIME! ...
			xcopy "!REPORT_LOGARCHIVE!" "!CHECKLMS_PUBLIC_SHARE!" /Y /H /I                     >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo     ... '!REPORT_LOGARCHIVE!' copied to '!CHECKLMS_PUBLIC_SHARE!'!            >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo     ... copied to '!CHECKLMS_PUBLIC_SHARE!' at !DATE! !TIME!!
		)
		echo .
		echo .
		if exist "!REPORT_LOGARCHIVE!" (
			rem ZIP archive has been created ...
			echo ... finished, see '!REPORT_LOGARCHIVE!'!
		) else (
			rem ZIP archive is not available ...
			echo Creation of logfile archive failed.
			echo .
			echo .
			echo ... finished, see '!REPORT_LOGFILE!'!
			echo .
			echo Send this log file together with zipped archive of !REPORT_LOG_PATH! folder to ....
			echo NOTE: Make sure to zip whole "Logs" folder, including any sub-folder.
		)
	) else (
		echo .
		echo .
		echo ... finished, see '!REPORT_LOGFILE!'!
		echo .
		echo Send this log file together with zipped archive of !REPORT_LOG_PATH! folder to ....
		echo NOTE: Make sure to zip whole "Logs" folder, including any sub-folder.
	)
	echo .
	echo Send all files to ....
	echo      - your local system supplier
	echo      - on the Siemens internet at https://support.industry.siemens.com/cs/ww/en/ps/18367
	echo For Technical Support please use the Support Request wizard at 
	echo      - https://support.industry.siemens.com/cs/ww/en/my
	echo        [ https://support.industry.siemens.com/cs/my/src ]
	echo .
	echo .

	if not defined LMS_NOUSERINPUT (
		set /p DUMMY=Hit ENTER to continue...
	)
	
	rem exit
)
