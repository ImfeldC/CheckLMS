@Echo Off
rem
rem Check current LMS installation
rem
rem Changelog:
rem     24-Jul-2018: 
rem        - Initial version
rem     
rem     Full details ses changelog.md
rem
rem     07-Jan-2021:
rem        - Adjust LMS version check, consider LMS 2.5 (2.5.824)
rem        - corrected small typo "Measure exection"
rem        - Upload CheckLMS.exe on \\dekher90mttsto.ad001.siemens.net\webservices-p$\STATIC\12657\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.5.824 build (Sprint 21)
rem        - Move CheckLMS script (Version: 07-Jan-2021) under source control: https://github.com/ImfeldC/CheckLMS
rem     11-Jan-2021:
rem        - Check if newer CheckLMS.bat is available in C:\ProgramData\Siemens\LMS\Download (see task 1046557)
rem        - Create new download folder for download from github: %DOWNLOAD_LMS_PATH%\git\
rem     12-Jan-2021:
rem        - Support USBDeview tool (see task 1198261)
rem     13-Jan-2021: (see also 09-Nov-2020)
rem        - Consider “ecmcommonutil.exe” (V1.19) (see task 1200154)
rem        - Download "ecmcommonutil_1.19.exe" (similar to "GetVMGenerationIdentifier.exe") from 'https://static.siemens.com/btdownloads/lms/FNP/ecmcommonutil_1.19.exe'
rem        - Execute in script the commands: ecmcommonutil_1.19.exe -l -f -d device; ecmcommonutil_1.19.exe -l -f -d net; ecmcommonutil_1.19.exe -l -f -d smbios; ecmcommonutil_1.19.exe -l -f -d vm
rem     14-Jan-2021:
rem        - show message at file upload
rem        - add 'ping %COMPUTERNAME%' to connection test section
rem        - Retrieve content of %WinDir%\System32\Drivers\Etc folder (see task 1202358)
rem     15-Jan-2021:
rem        - investigate some suspect crash of CheckLMS.bat in case newer script is downloaded (seen on Christian's laptop)
rem        - Upload CheckLMS.exe on \\dekher90mttsto.ad001.siemens.net\webservices-p$\STATIC\12657\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     16-Jan-2021:
rem        - rename "servercomptranutil_listRequests.xml" to "servercomptranutil_listRequests_XML.xml"
rem        - store information retrieved with -listrequests in separate files: servercomptranutil_listRequests_simple.xml and servercomptranutil_listRequests_long.xml
rem        - retrieve pending requests and store them in separate files; e.g. pending_req_41272.xml
rem     18-Jan-2021:
rem        - add script name and path to header output
rem        - consider script name (%0) when newer script is downloaded; do not replace script itself
rem        - Upload CheckLMS.exe on \\dekher90mttsto.ad001.siemens.net\webservices-p$\STATIC\12657\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     19-Jan-2021:
rem        - add option "checkdownload"
rem        - Create download archive
rem        - retrieve adapter bidnings for TCP/IP: Get-NetAdapterBinding -ComponentID ms_tcpip / Get-NetAdapterBinding -ComponentID ms_tcpip6 
rem          (see also https://www.majorgeeks.com/content/page/how_to_enable_or_disable_ipv6_in_windows.html#:~:text=Windows%20offers%20a%20few%20ways,Get%2DNetAdapterBinding%20%2DComponentID%20ms_tcpip6. )
rem        - call "netstat -a -f" only when extended mode is enabled
rem     25-Jan-2021:
rem        - Retrieve installed security protocols [using 'powershell -command "[Net.ServicePointManager]::SecurityProtocol"']
rem        - Retreive registry key: powershell -Command "Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto'" 
rem          (see https://trailheadtechnology.com/solving-could-not-create-ssl-tls-secure-channel-error-in-net-4-6-x/)
rem     27-Jan-2021:
rem        - store results of connection tests in separate files: !CHECKLMS_REPORT_LOG_PATH!\connection_test_XXXX.txt
rem     28-Jan-2021:
rem        - add also result of conection test to akamai download share
rem     02-Feb-2021:
rem        - support VMGENID.EXE from Stratus to read-out geneartion id
rem        - remove hint, that GetVMGenerationIdentifier.exe is from Flexera; it seems this tool is NOT from Flexera.
rem     04-Feb-2021:
rem        - introduce !LMS_PROGRAMDATA! as root path for LMS program data.
rem        - In case internet connection is not possible, search for download zip archive - created on another machine - and prcoess them on this machine.
rem     05-Feb-2021:
rem        - Improve unzip; as 7zr.exe seems not working on windows 2019 server. Use "Expand-Archive" of PowerShell V5.
rem          See also https://ridicurious.com/2019/07/29/3-ways-to-unzip-compressed-files-using-powershell/
rem        - to access desktop, use also %userprofile%\desktop, as %desktop% is not available on all windows systems 
rem          See also https://stackoverflow.com/questions/18629768/path-of-user-desktop-in-batch-files
rem     09-Feb-2021:
rem        - Extract 'Host Info' from SIEMBT.log
rem        - adjust parsing of 'servercomptranutil_listRequests_XML.xml' and 'fake_id_request_file.xml' to avoid duplicate lines (using 'LMS_START_LOG' pattern).
rem        - adjust logic for 'LMS_START_LOG' pattern, to find end of section/block.
rem     10-Feb-2021:
rem        - Extract important identifiers from SIEMBT.log: LMS_SIEMBT_HOSTNAME, LMS_SIEMBT_HYPERVISOR and LMS_SIEMBT_HOSTIDS
rem        - Add values retrived from SIMEBT to summary at end of logfile. Display error message in case of "suspect" values.
rem     11-Feb-2021:
rem        - adjust format of LMS_REPORT_START to be more "humable" readable
rem     16-Feb-2021:
rem        - add option: /setfirewall; see also https://wiki.siemens.com/display/en/LMS+VMware+configuration
rem        - change firewall settings analyze part, to use extract of 'Powershell -command "Show-NetFirewallRule"' instead of 'netsh advfirewall firewall show rule name=all verbose';
rem          because the ouptut of netsh is language specific and the further pasring doesn't work correct on "non-English" systems.
rem     17-Feb-2021:
rem        - correct typo (Anaylze)
rem        - change type of download archive from 7zip to zip, to make it independent of target system.
rem          Because: Expand-Archive : .7z is not a supported archive file format. .zip is the only supported archive file format.
rem     18-Feb-2021:
rem        - add option /info, to allow user to pass addtional information to be tracked in logfile (e.g. )
rem        - replace 'find' with 'find /I' to make comparisions independent of uppercase/lowercase
rem        - correct typo: desigcc_reistry.txt -> desigocc_registry.txt
rem        - use own subfolder for GMS (CHECKLMS_GMS_PATH=!CHECKLMS_REPORT_LOG_PATH!\GMS)
rem        - make sure that project-specific subfolders are only created when the product is installed (otherwise empty folders have been created).
rem        - Search for desigo cc logfiles [PVSS_II.*, WCCOActrl253.*] and copy them into CheckLMS logfolder.
rem     19-Feb-2021:
rem        - Adjust search algorithm for Desigo CC logfiles, somehow "for /r" doesn't work as expected :-(
rem        - Adjust search for TS files, serach only for '*tsf.data' instead '*tsf*'
rem     22-Feb-2021:
rem        - in case command 'powershell -command "Get-WindowsUpdateLog"' fails, print output of command execution in this logfile.
rem        - retrieve DESKTOP_FOLDER (mainly used in case desktop folder has been moved to another location)
rem        - check ERRORLEVEL when executing 'dotnet --info'
rem     23-Feb-2021:
rem        - Download "AccessCHK" from https://download.sysinternals.com/files/AccessChk.zip
rem     24-Feb-2021:
rem        - download latest released LMS client; e.g. from https://static.siemens.com/btdownloads/lms/LMSSetup2.6.826/x64/setup64.exe
rem        - disable one of two TS backups; execute second backup only with /extend option
rem        - skip GetVMGenerationIdentifier.exe execution, in case MSVCR120.dll doesn't exists.
rem        - improved output on clean/new machines, check existence of '%ALLUSERSPROFILE%\FLEXnet\'
rem     26-Feb-2021:
rem        - disable connection test against quality system, run them only when /extend option is set.
rem     02-Mar-2021:
rem        - support FNP 11.18.0.0 (or newer) used in LMS 2.6 (or newer), create donwload path with general rule (doesn't require update of script for future FNP versions)
rem     10-Mar-2021:
rem        - set field test version to LMS 2.6.828
rem     15-Mar-2021:
rem        - add: wmic path win32_computersystemproduct get uuid [similar to 'wmic csproduct get *']                (see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/identify_ec2_instances.html)
rem        - add: powershell -c "Get-WmiObject -query 'select uuid from Win32_ComputerSystemProduct' | Select UUID" (see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/identify_ec2_instances.html)
rem        - add: powershell -c (gcim Win32_ComputerSystem).HypervisorPresent                                       (see https://devblogs.microsoft.com/scripting/use-powershell-to-detect-if-hypervisor-is-present/)
rem        - added new section "V I R T U A L   E N V I R O N M E N T", to collect information about hypervisior, when running in a virtual machine.
rem        - retrieve "Instance identity documents" for AWS (see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/instance-identity-documents.html)
rem     16-Mar-2021:
rem        - add VMID.txt to track changes in virtual ids, like VMGENID, etc.
rem        - reduce output in general logfile for unzip operations (keep them in own files, do not add them to general logfile)
rem        - remove log entry "Run CheckLMS.bat 64-Bit" and "Run CheckLMS.bat 32-Bit"
rem     17-Mar-2021:
rem        - add option /checkid (incl. LMS_SKIPDOWNLOAD, LMS_SKIPTSBACKUP, LMS_SKIPBTALMPLUGIN, LMS_SKIPSIGCHECK, LMS_SKIPWMIC, LMS_SKIPFIREWALL, LMS_SKIPSCHEDTASK, LMS_SKIPWER, LMS_SKIPFNP)
rem        - content of "%WinDir%\System32\Drivers\Etc" is only copied, no longer addded to general logfile.
rem        - add further: LMS_SKIPSSU, LMS_SKIPLMS, LMS_SKIPSETUP, LMS_SKIPWINEVENT
rem        - move VMGENID.exe and GetVMGenerationIdentifier.exe into new section for virtual environments
rem        - add further: LMS_SKIPLICSERV, LMS_SKIPLOCLICSERV, LMS_SKIPREMLICSERV, LMS_SKIPPRODUCTS, LMS_SKIPWINDOWS
rem        - replace at several places %-characters with !-charaters; as they would not work within IF expression
rem        - rename fnpversion to fnpversionFromLogFile, to avoid name colision with FNPVersion
rem        - add further: LMS_SKIPUNZIP, LMS_SKIPNETSETTINGS, LMS_SKIPLOGS, LMS_SKIPDDSETUP, LMS_SKIPUCMS
rem        - create UMN_Latest.txt which contains always the latest (most recent) values; previous values are not kept like in UMN.txt
rem        - create VMID_Latest.txt which contains always the latest (most recent) values; previous values are not kept like in VMID.txt
rem        - This script implementes /checkid correct; the processing and ouptut is minimized to a minimum; this allows repetative exection of the script!
rem     18-Mar-2021:
rem        - split output of ecmcommonutil into debug (with separate logfile) and regular ouput kept in general logfile
rem        - add VMECMID.txt (and VMECMID_Latest.txt) which contains results of ecmcommonutil (received from Flexera)
rem        - add AWS.txt (and AWS_Latest.txt) which contains specific AWS information
rem        - add /setcheckidtask option, to setup periodic task to run checklms.bat with /checkid option.
rem        - add /delcheckidtask to delete periodic checkid task, see option /setcheckidtask
rem     19-Mar-2021:
rem        - added new section "C H E C K - I D"
rem        - moved several existing checks into this new section
rem        - added further checks, to compare values from previous run with values of current run.
rem     20-Mar-2021:
rem        - add output of ecmcommonutil V1.19 to the common output, as it seems more reliable on some virtual machines.
rem     22-Mar-2021:
rem        - retrieve version of downloaded dongle driver and print them out.
rem        - use "!ProgramFiles_x86!" instead of "%ProgramFiles(x86)%"
rem        - add option /installdongledriver and /removedongledriver
rem     23-Mar-2021:
rem        - copy "config" folder and add them to the logfile archive
rem        - add '!LMS_PROGRAMDATA!\Config\SurHistory', try to decrypt them and show content
rem        - set field test version to LMS 2.6.829
rem     24-Mar-2021:
rem        - download "counted.lic" from https://static.siemens.com/btdownloads/lms/FNP/counted.lic (as part of demo vendor daemon)
rem        - add option /startdemovd to start the demo vendor daemon provided by Flexera.
rem        - add option /stopdemovd to stop the demo vendor daemon provided by Flexera.
rem     25-Mar-2021:
rem        - delete demo vendor daemon when calling /stopdemovd
rem        - Analyze 'demo_debuglog.txt' similar like 'SIEMBT.log'
rem     26-Mar-2021:
rem        - read-out LmsConfigVersion and CsidConfigVersion
rem        - fix output of lmvminfo
rem     29-Mar-2021:
rem        - fix issue with TS backup, introduced with LMS_SKIPTSBACKUP (at 17-Mar-2021)
rem        - use separate logfile for checkid: LMSStatusReport_%COMPUTERNAME%_checkid
rem     30-Mar-2021:
rem        - execute 'LmuTool.exe /MULTICSID' if LMS 2.5.816 or newer
rem     06-Apr-2021:
rem        - Skip download from akamai share, download of 'CheckLMS.exe' is no longer supported.
rem        - add output of registry key: 'HKLM:\SOFTWARE\Siemens\LMS'
rem        - add content of the three services (fnls, fnls64 and vd) of 'HKLM:\SYSTEM\CurrentControlSet\Services\'
rem        - collect vendor daemon specific values from SIEMBT in 'SIEMBTID.txt'
rem        - re-enable download from akamai share, download of 'CheckLMS.exe' is again supported.
rem 
rem
rem     SCRIPT USAGE:
rem        - Call script w/o any parameter is the default and collects relevant system information.
rem        - The generated log-file is listed at execution end with further instructions how to collect and return system information
rem        - To run the script w/o window, execute:
rem              "%ProgramFiles%\Siemens\LMS\bin\Launcher.exe" "%ProgramFiles%\Siemens\LMS\scripts\CheckLMS.bat" /nouserinput /B
rem              NOTE: the /B option needs to be the last option, as it is used by launcher app.
rem        - The following command line options are supported:
rem              - /nouserinput                 supresses any user input (mainly the stop command at the end of the script)
rem              - /nowait                      supresses any user input and any further "wait" commands 
rem              - /logfilename <logfilename>   specifies the name and location of the logfile
rem              - /skipnetstat                 skip section wich performs netstat commands. 
rem              - /skipcontest                 skip section wich performs connection tests.
rem              - /extend                      run extended content, increases script running time!
rem              - /donotstartnewerscript       don't start newer script even if available (mainly to ensure proper handling of command line options) 
rem              - /checkdownload               perform downloads and print file versions.
rem              - /checkid                     check machine identifiers, like UMN, VMGENID, ...
rem              - /setcheckidtask              sets periodic task to run checklms.bat with /checkid option.
rem              - /delcheckidtask              delete periodic checkid task, see option /setcheckidtask
rem              - /setfirewall                 sets firewall for external access to LMS. 
rem              - /installdongledriver         installs downloaded dongle driver.
rem              - /removedongledriver          remove installed dongle driver.
rem              - /info "Any text"             Adds this text to the output, e.g. reference to field issue /info "SR1-XXXX"
rem              - /goto <gotolabel>            jump to a dedicated part within script.
rem  
rem
set LMS_SCRIPT_VERSION="CheckLMS Script 06-Apr-2021"
set LMS_SCRIPT_BUILD=20210406

rem most recent lms build: 2.5.824 (per 07-Jan-2021)
set MOST_RECENT_LMS_VERSION=2.5.824
set MOST_RECENT_LMS_BUILD=824
rem most recent lms field test version: 2.6.829 (per 23-Mar-2021)
set MOST_RECENT_FT_LMS_VERSION=2.6.829
set MOST_RECENT_FT_LMS_BUILD=829
rem most recent dongle driver version (per 13-Nov-2020, LMS 2.5)
set MOST_RECENT_DONGLE_DRIVER_VERSION=8.13
set MOST_RECENT_DONGLE_DRIVER_MAJ_VERSION=8
set MOST_RECENT_DONGLE_DRIVER_MIN_VERSION=13
rem most recent BT ALM plugin (per 15-Nov-2019)
set MOST_RECENT_BT_ALM_PLUGIN=1.1.42.0

rem Internal Settings
set LOG_FILE_LINES=200
set LOG_EVENTLOG_EVENTS=5000
set LOG_EVENTLOG_FULL_EVENTS=20000
set LOG_FILESIZE_LIMIT=30000000

rem Connection Test to CheckLMS share
set CHECKLMS_PUBLIC_SHARE=\\ch1w43110.ad001.siemens.net\ASSIST_SR_Attachements\CheckLMS
set CHECKLMS_CONNECTION_TEST_FILE=_CheckLMS_ReadMe_.txt

rem Check this issue: https://stackoverflow.com/questions/9797271/strange-character-in-textoutput-when-piping-from-tasklist-command-win7
chcp 1252
rem Check this: https://ss64.com/nt/delayedexpansion.html 
SETLOCAL EnableDelayedExpansion
setlocal ENABLEEXTENSIONS

set ProgramFiles_x86=%ProgramFiles(x86)%

rem https://stackoverflow.com/questions/7727114/batch-command-date-and-time-in-file-name
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set lms_report_datetime=%%I
set lms_report_datetime=%lms_report_datetime:~0,8%-%lms_report_datetime:~8,6%
rem Store report start date & time
set LMS_REPORT_START=!DATE! !TIME!
echo Report Start at !LMS_REPORT_START! ....

rem check administrator priviledge (see https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights)
set guid=%random%%random%-%random%-%random%-%random%-%random%%random%%random%
mkdir %WINDIR%\%guid%>nul 2>&1
rmdir %WINDIR%\%guid%>nul 2>&1
IF %ERRORLEVEL%==0 (
    rem ECHO PRIVILEGED! (%guid%)
    echo This script runs with administrator priviledge! 
	set LMS_SCRIPT_RUN_AS_ADMINISTRATOR=1
) ELSE (
    rem ECHO NOT PRIVILEGED!  (%guid%)
    echo This script runs with NO administrator priviledge! 
)

rem Retrieve desktop folder
FOR /F "usebackq" %%f IN (`PowerShell -NoProfile -Command "Write-Host([Environment]::GetFolderPath('Desktop'))"`) DO (
  SET "DESKTOP_FOLDER=%%f"
)
rem @ECHO DESKTOP_FOLDER=%DESKTOP_FOLDER%

rem Check report log path
set LMS_PROGRAMDATA=%ALLUSERSPROFILE%\Siemens\LMS
set REPORT_LOG_PATH=!LMS_PROGRAMDATA!\Logs
IF NOT EXIST "!REPORT_LOG_PATH!\" (
    set REPORT_LOG_PATH=%TEMP%
    echo This is not a valid LMS Installation, use %TEMP% as path to store log files 
)
set CHECKLMS_REPORT_LOG_PATH=!REPORT_LOG_PATH!\CheckLMSLogs
IF NOT EXIST "!CHECKLMS_REPORT_LOG_PATH!\" (
	rem echo Create new folder: !CHECKLMS_REPORT_LOG_PATH!\
    mkdir !CHECKLMS_REPORT_LOG_PATH!\ >nul 2>&1
)

rem clean-up logfiles created with older CheckLMS script
del !REPORT_LOG_PATH!\eventlog_*.txt >nul 2>&1
del !REPORT_LOG_PATH!\aksdrvsetup*.log >nul 2>&1
del !REPORT_LOG_PATH!\LMSSetupLogFilesFound.txt >nul 2>&1
del !REPORT_LOG_PATH!\servercomptranutil*.txt >nul 2>&1
del !REPORT_LOG_PATH!\appactutil*.txt >nul 2>&1
del !REPORT_LOG_PATH!\FlexeraLogFilesFound.txt >nul 2>&1
del !REPORT_LOG_PATH!\lmvminfo*.txt >nul 2>&1
del !REPORT_LOG_PATH!\tfsFilesFound.txt >nul 2>&1
del !REPORT_LOG_PATH!\license_all*.txt >nul 2>&1
del !REPORT_LOG_PATH!\schtasks*.log >nul 2>&1
del !REPORT_LOG_PATH!\firewall*.txt >nul 2>&1
del !REPORT_LOG_PATH!\tasklist*.txt >nul 2>&1
del !REPORT_LOG_PATH!\wmic*.txt >nul 2>&1
del !REPORT_LOG_PATH!\WMICReport.log >nul 2>&1
del !REPORT_LOG_PATH!\LmsCfg.txt >nul 2>&1
del !REPORT_LOG_PATH!\getservice.txt >nul 2>&1
del !REPORT_LOG_PATH!\InstalledProgramsReport.log >nul 2>&1
del !REPORT_LOG_PATH!\InstalledPowershellCommandlets.txt >nul 2>&1
del !REPORT_LOG_PATH!\dongledriver_diagnostics.html >nul 2>&1
del !REPORT_LOG_PATH!\SIEMBT_*_event.log >nul 2>&1
del !REPORT_LOG_PATH!\yes.txt >nul 2>&1
del !CHECKLMS_REPORT_LOG_PATH!\desigcc_reistry.txt >nul 2>&1
del !CHECKLMS_REPORT_LOG_PATH!\desigocc_installed_EM.txt >nul 2>&1

rem remove former used local path (clean-up no longer used data)
rmdir /S /Q !REPORT_LOG_PATH!\CrashDumps >nul 2>&1
del !REPORT_LOG_PATH!\CrashDumpFilesFound.txt >nul 2>&1

set CHECKLMS_CRASH_DUMP_PATH=!CHECKLMS_REPORT_LOG_PATH!\CrashDumps
rmdir /S /Q !CHECKLMS_CRASH_DUMP_PATH!\ >nul 2>&1
IF NOT EXIST "%CHECKLMS_CRASH_DUMP_PATH%\" (
	rem echo Create new folder: %CHECKLMS_CRASH_DUMP_PATH%\
    mkdir %CHECKLMS_CRASH_DUMP_PATH%\ >nul 2>&1
)
set CHECKLMS_SETUP_LOG_PATH=!CHECKLMS_REPORT_LOG_PATH!\LMSSetupLogs
rmdir /S /Q !CHECKLMS_SETUP_LOG_PATH!\ >nul 2>&1
IF NOT EXIST "%CHECKLMS_SETUP_LOG_PATH%\" (
	rem echo Create new folder: %CHECKLMS_SETUP_LOG_PATH%\
    mkdir %CHECKLMS_SETUP_LOG_PATH%\ >nul 2>&1
)
set CHECKLMS_SSU_PATH=!CHECKLMS_REPORT_LOG_PATH!\SSU
rem rmdir /S /Q !CHECKLMS_SSU_PATH!\ >nul 2>&1
IF NOT EXIST "!CHECKLMS_SSU_PATH!\" (
	rem echo Create new folder: !CHECKLMS_SSU_PATH!\
    mkdir !CHECKLMS_SSU_PATH!\ >nul 2>&1
)
set CHECKLMS_ALM_PATH=!CHECKLMS_REPORT_LOG_PATH!\Automation
rmdir /S /Q !CHECKLMS_ALM_PATH!\ >nul 2>&1
IF NOT EXIST "%CHECKLMS_ALM_PATH%\" (
	rem echo Create new folder: %CHECKLMS_ALM_PATH%\
    mkdir %CHECKLMS_ALM_PATH%\ >nul 2>&1
)

rem Check & create download path
set DOWNLOAD_LMS_PATH=!LMS_PROGRAMDATA!\Download
IF NOT EXIST "%DOWNLOAD_LMS_PATH%\" (
	rem echo Create new folder: %DOWNLOAD_LMS_PATH%\
	mkdir %DOWNLOAD_LMS_PATH%\ >nul 2>&1
)
IF NOT EXIST "%DOWNLOAD_LMS_PATH%\git" (
	rem echo Create new folder: %DOWNLOAD_LMS_PATH%\git\
	mkdir %DOWNLOAD_LMS_PATH%\git\ >nul 2>&1
)
IF NOT EXIST "%DOWNLOAD_LMS_PATH%\LMSSetup" (
	rem echo Create new folder: %DOWNLOAD_LMS_PATH%\LMSSetup\
	mkdir %DOWNLOAD_LMS_PATH%\LMSSetup\ >nul 2>&1
)
rem Check flexera command line tools path 
set LMS_SERVERTOOL_PATH=!ProgramFiles_x86!\Siemens\LMS\server
IF NOT EXIST "!LMS_SERVERTOOL_PATH!" (
    set LMS_SERVERTOOL_PATH=%ProgramFiles%\Siemens\LMS\server
)
IF NOT EXIST "!LMS_SERVERTOOL_PATH!" (
	REM No Flexera tools locally installed
    echo This is not a valid LMS Installation, no Flexera tools locally installed at "%LMS_SERVERTOOL_PATH%" ....
	set LMS_SERVERTOOL_PATH=
)

rem Set documentation path
set DOCUMENTATION_PATH=!LMS_PROGRAMDATA!\Documentation

set DOWNLOAD_ARCHIVE=!LMS_PROGRAMDATA!\LMSDownloadArchive_%COMPUTERNAME%_!lms_report_datetime!.zip
set DOWNLOAD_PATH=!LMS_PROGRAMDATA!\Download


rem Create report log filename(s)
set REPORT_LOGARCHIVE=!LMS_PROGRAMDATA!\LMSLogArchive_%COMPUTERNAME%_!lms_report_datetime!.7z
set REPORT_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReport_%COMPUTERNAME%.log 
set REPORT_FULL_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReports_%COMPUTERNAME%.log 
set REPORT_WMIC_INSTALLED_SW_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\WMIC_Installed_SW_Report.log 
set REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV=!CHECKLMS_REPORT_LOG_PATH!\WMIC_Installed_SW_Report.csv 
set REPORT_WMIC_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\WMICReport.log 
set REPORT_PS_LOGFILE=!CHECKLMS_REPORT_LOG_PATH!\PSReport.log 

rem Local path for BT ALM plugin
set LMS_ALMBTPLUGIN_FOLDER_X86=C:\\Program Files (x86)\\Common Files\\Siemens\\SWS\\plugins\\bt
set LMS_ALMBTPLUGIN_FOLDER=C:\\Program Files\\Common Files\\Siemens\\SWS\\plugins\\bt

rem Local path for HASP dongle driver
rem see https://www.rocscience.com/support/sentinel
set LMS_HASPDRIVER_FOLDER=%CommonProgramFiles(x86)%\Aladdin Shared\HASP
if "%PROCESSOR_ARCHITECTURE%" == "x86" (
	set LMS_HASPDRIVER_FOLDER=%CommonProgramFiles%\Aladdin Shared\HASP
)

rem Application settings
if exist "%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe" (
	set LMS_LMUTOOL=%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe
) else (
	rem leave undefiend
	set LMS_LMUTOOL=
)


rem External Settings
set LMS_LIC_SERVER=27000@localhost


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
		if "!var!"=="nouserinput" (
			set LMS_NOUSERINPUT=1
		)
		if "!var!"=="nowait" (
			set LMS_NOUSERINPUT=1
		)
		if "!var!"=="logfilename" (
			set LMS_LOGFILENAME=1
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
		)
		if "!var!"=="checkid" (
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
	set REPORT_LOGFILE=!REPORT_LOG_PATH!\LMSStatusReport_%COMPUTERNAME%_checkid.log 
)
rem Frist access to logfile, create an empty file
echo.> !REPORT_LOGFILE! 2>&1

REM -- .NET Framework Version
REM see https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
REM Decimal values in hex:
rem -- .NET Framework 4.8  : 528049, 528040, 528372
rem -- .NET Framework 4.7.2: 461814->70BF6, 461808->70BF0, 
rem -- .NET Framework 4.7.1: 461310->709FE, 461308->709FC
rem -- .NET Framework 4.7  : 460805->70805, 460798->707FE
rem -- .NET Framework 4.6.2: 394806->60636, 394802->60632
rem -- .NET Framework 4.6.1: 394271->6041F, 394254->6040E
rem -- .NET Framework 4.6  : 393297->60051, 393295->6004F
rem -- .NET Framework 4.5.2: 379893->5CBF5
rem -- .NET Framework 4.5.1: 378758->5C786, 378675->5C733
rem -- .NET Framework 4.5  : 378389->5C615
rem -- -NET Framework Versions before 4.5 are not considered
set NETVersion=
set NETVersionHex=
set NETVersionDec=
set KEY_NAME=HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full
set VALUE_NAME=Release
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set NETVersionHex=%%A
	rem convert hex in decimal (see https://stackoverflow.com/questions/9453246/reg-query-returning-hexadecimal-value)
	set /A NETVersionDec=%%A
)
if "%NETVersionDec%" == "528049" (
	rem On all others Windows operating systems (including other Windows 10 operating systems): 528049
	set NETVersion=4.8
)
if "%NETVersionDec%" == "528040" (
	rem On Windows 10 May 2019 Update: 528040
	set NETVersion=4.8
)
if "%NETVersionDec%" == "528372" (
	rem On Windows 10 May 2020 Update: 528372
	set NETVersion=4.8
)
if "%NETVersionDec%" == "461814" (
	rem On all Windows operating systems other than Windows 10 April 2018 Update and Windows Server, version 1803: 461814
	set NETVersion=4.7.2
)
if "%NETVersionDec%" == "461808" (
	rem On Windows 10 April 2018 Update and Windows Server, version 1803: 461808
	set NETVersion=4.7.2
)
if "%NETVersionDec%" == "461310" (
	rem On all other Windows operating systems (including other Windows 10 operating systems): 461310
	set NETVersion=4.7.1
)
if "%NETVersionDec%" == "461308" (
	rem On Windows 10 Fall Creators Update and Windows Server, version 1709: 461308
	set NETVersion=4.7.1
)
if "%NETVersionDec%" == "460805" (
	rem On all other Windows operating systems (including other Windows 10 operating systems): 460805
	set NETVersion=4.7
)
if "%NETVersionDec%" == "460798" (
	rem On Windows 10 Creators Update: 460798
	set NETVersion=4.7
)
if "%NETVersionDec%" == "394806" (
	rem On all other Windows operating systems (including other Windows 10 operating systems): 394806
	set NETVersion=4.6.2
)
if "%NETVersionDec%" == "394802" (
	rem On Windows 10 Anniversary Update and Windows Server 2016: 394802
	set NETVersion=4.6.2
)
if "%NETVersionDec%" == "394271" (
	rem On all other Windows operating systems (including Windows 10): 394271
	set NETVersion=4.6.1
)
if "%NETVersionDec%" == "394254" (
	rem On Windows 10 November Update systems: 394254
	set NETVersion=4.6.1
)
if "%NETVersionDec%" == "393297" (
	rem On all other Windows operating systems: 393297
	set NETVersion=4.6
)
if "%NETVersionDec%" == "393295" (
	rem On Windows 10: 393295
	set NETVersion=4.6
)
if "%NETVersionDec%" == "379893" (
	rem All Windows operating systems: 379893
	set NETVersion=4.5.2
)
if "%NETVersionDec%" == "378758" (
	rem On all other Windows operating systems: 378758
	set NETVersion=4.5.1
)
if "%NETVersionDec%" == "378675" (
	rem On Windows 8.1 and Windows Server 2012 R2: 378675
	set NETVersion=4.5.1
)
if "%NETVersionDec%" == "378389" (
	rem All Windows operating systems: 378389
	set NETVersion=4.5
)
if not defined NETVersion (
  set NETVersion=Smaller than 4.5
)

REM -- VC++ redistributable package
rem see https://stackoverflow.com/questions/46178559/how-to-detect-if-visual-c-2017-redistributable-is-installed
if "%PROCESSOR_ARCHITECTURE%" == "x86" (
	set KEY_NAME=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86
) else (
	set KEY_NAME=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64
)
set VALUE_NAME=Version
set VC_REDIST_VERSION=
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set VC_REDIST_VERSION=%%A
)


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
	echo ERROR: Cannot determine machine GUID! >> %REPORT_LOGFILE% 2>&1
	where where >> %REPORT_LOGFILE% 2>&1
	where find  >> %REPORT_LOGFILE% 2>&1
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
for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
	set ALM_VERSION_STRING=%%A
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
wmic os get locale, oslanguage, codeset /format:list > %temp%\wmic_output.txt
IF EXIST "%temp%\wmic_output.txt" for /f "tokens=2 delims== eol=@" %%i in ('type %temp%\wmic_output.txt ^|find /I "OSLanguage"') do set "OS_LANGUAGE=%%i"
IF EXIST "%temp%\wmic_output.txt" for /f "tokens=2 delims== eol=@" %%i in ('type %temp%\wmic_output.txt ^|find /I "Locale"') do set /A "LOCAL_LANGUAGE=0x%%i"
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
	set LMS_MAJ_VERSION=%LMS_VERSION:~0,1%
	set LMS_MIN_VERSION=%LMS_VERSION:~2,1%
	set LMS_BUILD_VERSION=%LMS_VERSION:~4,3%
) else (
    echo This is not a valid LMS Installation, cannot read LMS version. 
    set LMS_VERSION=N/A
	set LMS_MAJ_VERSION=N/A
	set LMS_MIN_VERSION=N/A
	set LMS_BUILD_VERSION=N/A
)

REM --- Read FNP Version ---
REM see https://superuser.com/questions/363278/is-there-a-way-to-get-file-metadata-from-the-command-line for more information
REM see https://docs.microsoft.com/en-us/windows/desktop/WinProg64/wow64-implementation-details to check bitness of operating system
REM NOTE: %ProgramFiles(x86)% and %ProgramFiles% doesn't work together with "wmic datafile"
REM       you need to replace \ with \\, see https://alt.msdos.batch.narkive.com/LNB84uUc/replace-all-backslashes-in-a-string-with-double-backslash
set FNPVersion=
REM Keep "old" way to retrieve file version ...
if exist "C:\Program Files\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService64.exe" (
	wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService64.exe" get Manufacturer,Name,Version  /format:list
	IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
)
if not defined FNPVersion (
	if exist "C:\Program Files (x86)\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe" (
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	if exist "C:\Program Files\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe" (
		REM Covers the case of Win7 32-bit
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
REM Add new way to retrieve file version ....
REM Replace \ with \\, see https://alt.msdos.batch.narkive.com/LNB84uUc/replace-all-backslashes-in-a-string-with-double-backslash
if not defined FNPVersion (
	set TARGETFILE=%ProgramFiles%\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService64.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	set TARGETFILE=!ProgramFiles_x86!\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)
if not defined FNPVersion (
	set TARGETFILE=%ProgramFiles%\Common Files\Macrovision Shared\FlexNet Publisher\FNPLicensingService.exe
	if exist "!TARGETFILE!" (
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "FNPVersion=%%i"
	)
)

set LMS_SERVERTOOL_DW=
set LMS_SERVERTOOL_DW_PATH=
if defined FNPVersion (
	if "!FNPVersion!" == "11.17.2.0" (
		rem FNP 11.17.2.0 used in LMS 2.5
		set LMS_SERVERTOOL_DW=SiemensFNP-11.17.2.0-Binaries
		rem the process architecture is no longer considered; we distribute only 32-bit tools
		set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\
	)
	if "!FNPVersion!" == "11.17.0.0" (
		set LMS_SERVERTOOL_DW=SiemensFNP-11.17.0.0-Binaries
		rem the process architecture is no longer considered; we distribute only 32-bit tools
		set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\
	)
	if "!FNPVersion!" == "11.16.6.0" (
		set LMS_SERVERTOOL_DW=SiemensFNP-11.16.6.0-Binaries
		rem the process architecture is no longer considered; we distribute only 32-bit tools
		set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\
	)
	if "!FNPVersion!" == "11.16.2.0" (
		set LMS_SERVERTOOL_DW=SiemensFNP-11.16.2.0-Binaries
		rem the process architecture is no longer considered; we distribute only 32-bit tools
		set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\
	)
	if "!FNPVersion!" == "11.16.0.0" (
		set LMS_SERVERTOOL_DW=SiemensFNP-11.16.0.0-Distr03
		if "%PROCESSOR_ARCHITECTURE%" == "x86" (
			set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\11.16.0.0\x86
		) else (
			set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\11.16.0.0\x64
		)
	)
	if "!FNPVersion!" == "11.14.0.0" (
		set LMS_SERVERTOOL_DW=SiemensFNP-11.14.0.0-Distr01
		if "%PROCESSOR_ARCHITECTURE%" == "x86" (
			set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\11.14.0.0\x86
		) else (
			set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\11.14.0.0\x64
		)
	)

	rem if dowload path not already set, set them on general rule.
	if not defined LMS_SERVERTOOL_DW (
		rem FNP 11.18.0.0 (or newer) used in LMS 2.6 (or newer)
		set LMS_SERVERTOOL_DW=SiemensFNP-!FNPVersion!-Binaries
		set LMS_SERVERTOOL_DW_PATH=%DOWNLOAD_LMS_PATH%\!LMS_SERVERTOOL_DW!\
	)
) else (
    echo This is not a valid LMS Installation, cannot read FNP version. 
)

rem check if colored ouput is supported
set SHOW_COLORED_OUTPUT=
if /I "%OS_MAJ_VERSION%" EQU "10" (
	set SHOW_COLORED_OUTPUT="Yes"
)

if defined SHOW_COLORED_OUTPUT (
	echo [1;37mLMS Status Report for LMS System !LMS_SYSTEMID! with LMS Version: !LMS_VERSION!
	echo [1;33m    be patient, the collection of the information requires some time, up to several minutes [1;37m
) else (
	echo LMS Status Report for LMS System !LMS_SYSTEMID! with LMS Version: !LMS_VERSION!
	echo    be patient, the collection of the information requires some time, up to several minutes
)
echo Check current LMS installation .....
if exist "%LMS_SERVERTOOL_PATH%" cd "%LMS_SERVERTOOL_PATH%"

if not defined LMS_CHECK_ID (
	set LMS_BALLOON_TIP_TITLE=CheckLMS Script
	set LMS_BALLOON_TIP_TEXT=Start CheckLMS script [!LMS_SCRIPT_BUILD!] on %COMPUTERNAME% with LMS Version !LMS_VERSION! ...
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

echo Report Start at !LMS_REPORT_START! ....                                                                                 >> %REPORT_LOGFILE% 2>&1
echo ============================================================================================================================================================ >> %REPORT_LOGFILE% 2>&1
echo =                                                                                                                       >> %REPORT_LOGFILE% 2>&1
echo =   L      M     M   SSSS                                                                                               >> %REPORT_LOGFILE% 2>&1
echo =   L      MM   MM  S                                                                                                   >> %REPORT_LOGFILE% 2>&1
echo =   L      M M M M   SSS                                                                                                >> %REPORT_LOGFILE% 2>&1
echo =   L      M  M  M      S                                                                                               >> %REPORT_LOGFILE% 2>&1
echo =   LLLLL  M     M  SSSS                                                                                                >> %REPORT_LOGFILE% 2>&1
echo =                                                                                                                       >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =                                                                                                                       >> %REPORT_LOGFILE% 2>&1
echo =  LMS Status Report for LMS Version: !LMS_VERSION! (on %COMPUTERNAME%, with %PROCESSOR_ARCHITECTURE%)                  >> %REPORT_LOGFILE% 2>&1
echo =  Date: !DATE! / Time: !TIME!                                                                                          >> %REPORT_LOGFILE% 2>&1
echo =  LMS System Id: !LMS_SYSTEMID!                                                                                        >> %REPORT_LOGFILE% 2>&1
echo =  SSU System Id: %SSU_SYSTEMID%                                                                                        >> %REPORT_LOGFILE% 2>&1
echo =  Machine GUID : %OS_MACHINEGUID%                                                                                      >> %REPORT_LOGFILE% 2>&1
echo =                                                                                                                       >> %REPORT_LOGFILE% 2>&1
echo =  Check Script Version: %LMS_SCRIPT_VERSION% (!LMS_SCRIPT_BUILD!)                                                      >> %REPORT_LOGFILE% 2>&1
echo =  Check Script File   : %0                                                                                             >> %REPORT_LOGFILE% 2>&1
IF "%~1"=="" (
	echo =  Command Line Options: no options passed.                                                                         >> %REPORT_LOGFILE% 2>&1
) else (
	echo =  Command Line Options: %*                                                                                         >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
	echo =  Script started with : Administrator priviledge                                                                    >> %REPORT_LOGFILE% 2>&1
) else (
	echo =  Script started with : normal priviledge                                                                           >> %REPORT_LOGFILE% 2>&1
)
echo =  Hypervisor Present  : !LMS_IS_VM!                                                                                    >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
if defined LMS_SET_INFO (
	echo Info: [!LMS_REPORT_START!] !LMS_SET_INFO! ....                                                                      >> %REPORT_LOGFILE% 2>&1
	echo [!LMS_REPORT_START!] !LMS_SET_INFO! >> "%DOCUMENTATION_PATH%\info.txt" 2>&1
)
IF EXIST "%DOCUMENTATION_PATH%\info.txt" (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	Type "%DOCUMENTATION_PATH%\info.txt"                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
)

IF EXIST "%ProgramFiles%\7-Zip\7z.exe" (
	set UNZIP_TOOL=%ProgramFiles%\7-Zip\7z.exe
) else IF EXIST "%ProgramFiles%\Siemens\SSU\bin\7z.exe" (
	set UNZIP_TOOL=%ProgramFiles%\Siemens\SSU\bin\7z.exe
)
if NOT defined UNZIP_TOOL (
    echo No local unzip tool [7z.exe] found.                                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Search for installed local '7z' tool ....                                                                           >> %REPORT_LOGFILE% 2>&1
	where 7z                                                                                                                 >> %REPORT_LOGFILE% 2>&1
) else (
    echo Local Unzip tool [!UNZIP_TOOL!] found.                                                                              >> %REPORT_LOGFILE% 2>&1
	"!UNZIP_TOOL!" -version    >> "!CHECKLMS_REPORT_LOG_PATH!\unziptool_version.log" 2>&1
)

if !LMS_BUILD_VERSION! NEQ "N/A" (
	REM Check: not 2.4.815 AND not 2.3.745 AND less or equal than 2.3.744  --> DEPRECATED (per Oct-2020)
	REM See https://support.industry.siemens.com/cs/document/109738214/
	if /I !LMS_BUILD_VERSION! NEQ 815 (
		if /I !LMS_BUILD_VERSION! NEQ 745 (
			if /I !LMS_BUILD_VERSION! LEQ 744 (
				REM LMS Version 2.3.744 or older (lower build number)
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    NOTE: The LMS version !LMS_VERSION! which you are using is DEPRECATED, pls update your system. [1;37m
				) else (
					echo     NOTE: The LMS version !LMS_VERSION! which you are using is DEPRECATED, pls update your system.
				)
				echo NOTE: The LMS version !LMS_VERSION! which you are using is DEPRECATED, pls update your system.              >> %REPORT_LOGFILE% 2>&1
			) else (
				REM Check: ... less than MOST_RECENT_LMS_BUILD --> IN TEST
				if /I !LMS_BUILD_VERSION! LSS %MOST_RECENT_LMS_BUILD% (
					if defined SHOW_COLORED_OUTPUT (
						echo [1;33m    WARNING: The LMS version !LMS_VERSION! which you are using is a field test version, pls update your system as soon final version is available. [1;37m
					) else (
						echo     WARNING: The LMS version !LMS_VERSION! which you are using is a field test version, pls update your system as soon final version is available.
					)
					echo WARNING: The LMS version !LMS_VERSION! which you are using is a field test version, pls update your system as soon final version is available. >> %REPORT_LOGFILE% 2>&1
				)
			)
		) else (
			REM LMS Version 2.3.745
			echo NOTE: The LMS version !LMS_VERSION! which you are using is officially supported. 								 >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		REM LMS Version 2.4.815
		echo NOTE: The LMS version !LMS_VERSION! which you are using is officially supported. 								 >> %REPORT_LOGFILE% 2>&1
	)
) else (
	REM LMS Version not defined
	echo NOTE: This is not a valid LMS Installation! LMS Version: !LMS_VERSION!              								 >> %REPORT_LOGFILE% 2>&1
)
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
echo     Check Script Version: %LMS_SCRIPT_VERSION% (!LMS_SCRIPT_BUILD!)
if defined OS_PRODUCTNAME (
	echo     OS Product Name: %OS_PRODUCTNAME%
	echo OS Product Name: %OS_PRODUCTNAME%                                                                                   >> %REPORT_LOGFILE% 2>&1
) else (
	echo     OS Product Name: was not able to determine OS version. OS_PRODUCTNAME is missing.
	echo OS Product Name: was not able to determine OS version. OS_PRODUCTNAME is missing.                                   >> %REPORT_LOGFILE% 2>&1
)
if defined OS_VERSION (
	echo     OS Version: %OS_VERSION%
	echo OS Version: %OS_VERSION%                                                                                            >> %REPORT_LOGFILE% 2>&1
) else (
	echo     OS Version: was not able to determine OS version. OS_VERSION is missing.
	echo OS Version: was not able to determine OS version. OS_VERSION is missing.                                            >> %REPORT_LOGFILE% 2>&1
)
if defined OS_MAJ_VERSION (
	echo     OS Version: %OS_MAJ_VERSION%.%OS_MIN_VERSION%
	echo OS Version: %OS_MAJ_VERSION%.%OS_MIN_VERSION%                                                                       >> %REPORT_LOGFILE% 2>&1
) else (
	echo     OS Version: was not able to determine OS version. OS_MAJ_VERSION is missing.
	echo OS Version: was not able to determine OS version. OS_MAJ_VERSION is missing.                                        >> %REPORT_LOGFILE% 2>&1
)
if defined FNPVersion (
	echo     Installed FNP Version: !FNPVersion!
	echo Installed FNP Version: !FNPVersion!                                                                                 >> %REPORT_LOGFILE% 2>&1
) else (
	echo     Installed FNP Version: was not able to determine installed FNP version.
	echo Installed FNP Version: was not able to determine installed FNP version.                                             >> %REPORT_LOGFILE% 2>&1
)
if defined NETVersion (
	echo     Installed .NET Version: %NETVersion%
	echo Installed .NET Version: %NETVersion%                                                                                >> %REPORT_LOGFILE% 2>&1
) else (
	echo     Installed .NET Version: was not able to determine installed version.
	echo Installed .NET Version: was not able to determine installed version.                                                >> %REPORT_LOGFILE% 2>&1
)
if defined VC_REDIST_VERSION (
	echo     Installed VC++ redistributable package: %VC_REDIST_VERSION%
	echo Installed VC++ redistributable package: %VC_REDIST_VERSION%                                                         >> %REPORT_LOGFILE% 2>&1
) else (
	echo     Installed VC++ redistributable package: was not able to determine installed version.
	echo Installed VC++ redistributable package: was not able to determine installed version.                                >> %REPORT_LOGFILE% 2>&1
)
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPDOWNLOAD (
	echo ... download additional tools and libraries ...
	rem Connection Test to CheckLMS share
	set SiemensConnectionTestStatus=Unknown
	IF EXIST "!CHECKLMS_PUBLIC_SHARE!\!CHECKLMS_CONNECTION_TEST_FILE!" (
		rem Connection Test: PASSED
		echo     Connection Test to public share PASSED, can access '!CHECKLMS_CONNECTION_TEST_FILE!'
		echo Connection Test to public share PASSED, can access !CHECKLMS_PUBLIC_SHARE!\!CHECKLMS_CONNECTION_TEST_FILE!          >> %REPORT_LOGFILE% 2>&1
		set SiemensConnectionTestStatus=Passed
	) else (
		rem Connection Test: FAILED
		echo     Connection Test to public share FAILED, cannot access '!CHECKLMS_CONNECTION_TEST_FILE!'
		echo Connection Test to public share FAILED, cannot access !CHECKLMS_PUBLIC_SHARE!\!CHECKLMS_CONNECTION_TEST_FILE!       >> %REPORT_LOGFILE% 2>&1
		set SiemensConnectionTestStatus=Failed
	)
	rem Connection Test to BT download site
	set ConnectionTestStatus=Unknown
	powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/ReadMe.txt', '%DOWNLOAD_LMS_PATH%\ReadMe.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_btdownloads.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access https://static.siemens.com/btdownloads/
		echo Connection Test PASSED, can access https://static.siemens.com/btdownloads/                                          >> %REPORT_LOGFILE% 2>&1
		set ConnectionTestStatus=Passed
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access https://static.siemens.com/btdownloads/
		echo Connection Test FAILED, cannot access https://static.siemens.com/btdownloads/                                       >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_btdownloads.txt                                                          >> %REPORT_LOGFILE% 2>&1
		set ConnectionTestStatus=Failed
	)
	REM Download FNP Siemens Library
	REM see https://stackoverflow.com/questions/4619088/windows-batch-file-file-download-from-a-url for more information
	if "!ConnectionTestStatus!" == "Passed" (

		if defined DOWNLOAD_LMS_PATH (
			rem Download 7zip tool [64-bit]
			rem see also https://sourceforge.net/p/sevenzip/discussion/45798/thread/b599cf02/?limit=25
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\7zr.exe" (
				echo     Download 7zip app: https://www.7-zip.org/a/7zr.exe
				echo Download 7zip app: https://www.7-zip.org/a/7zr.exe                                                                         >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.7-zip.org/a/7zr.exe', '%DOWNLOAD_LMS_PATH%\7zr.exe')" >> %REPORT_LOGFILE% 2>&1

			) else (
				echo     Don't download 7zip app [ https://www.7-zip.org/a/7zr.exe ], because they exist already.
				echo Don't download 7zip app [ https://www.7-zip.org/a/7zr.exe ], because they exist already.                           >> %REPORT_LOGFILE% 2>&1
			)
			rem Set unzip tool: %DOWNLOAD_LMS_PATH%\7zr.exe
			IF EXIST "%DOWNLOAD_LMS_PATH%\7zr.exe" (
				if not defined UNZIP_TOOL (
					set UNZIP_TOOL=%DOWNLOAD_LMS_PATH%\7zr.exe
					echo     Set Unzip tool [%DOWNLOAD_LMS_PATH%\7zr.exe].                                                              >> %REPORT_LOGFILE% 2>&1
				)
			) else (
				echo     No unzip tool [%DOWNLOAD_LMS_PATH%\7zr.exe] downloaded.                                                        >> %REPORT_LOGFILE% 2>&1
			)
		)
		if defined LMS_SERVERTOOL_DW (
			if defined UNZIP_TOOL (
				rem Download and unzip FNP toolkit [as ZIP]
				IF NOT EXIST "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip" (
					echo     Download FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip
					echo Download FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip                                                                                                           >> %REPORT_LOGFILE% 2>&1
					powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/%LMS_SERVERTOOL_DW%.zip', '%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip')"   >> %REPORT_LOGFILE% 2>&1

					REM Unzip FNP Siemens Library
					REM See https://sourceforge.net/p/sevenzip/discussion/45798/thread/8cb61347/?limit=25
					IF EXIST "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip" (
						echo     Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip
						echo Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip                                       >> %REPORT_LOGFILE% 2>&1
						"!UNZIP_TOOL!" x -y -spe -o"%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%\" "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip" > !CHECKLMS_REPORT_LOG_PATH!\unzip_fnp_library_zip.txt 2>&1
					)
				) else (
					echo     Don't download FNP Siemens Library [ZIP], because they exist already.
					echo Don't download FNP Siemens Library [ZIP], because they exist already.                                              >> %REPORT_LOGFILE% 2>&1
				)
			) else (
				rem 
				rem NO LONGER USED EXE DOWNLOAD, as UNZIP tool is also provided 
				rem 
				rem Download and unzip FNP toolkit [as EXE]
				IF NOT EXIST "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe" (
					echo     Download FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe
					echo Download FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe                                                                                                           >> %REPORT_LOGFILE% 2>&1
					powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/%LMS_SERVERTOOL_DW%.exe', '%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe')"   >> %REPORT_LOGFILE% 2>&1

					REM Unzip FNP Siemens Library
					REM see https://stackoverflow.com/questions/17687390/how-do-i-silently-install-a-7-zip-self-extracting-archive-to-a-specific-director for more information
					IF EXIST "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe" (
						echo     Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe
						echo Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe                                       >> %REPORT_LOGFILE% 2>&1
						%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.exe -y -o"%DOWNLOAD_LMS_PATH%\"                                             > !CHECKLMS_REPORT_LOG_PATH!\unzip_fnp_library_exe.txt 2>&1
					)
				) else (
					echo     Don't download FNP Siemens Library [EXE], because they exist already.
					echo Don't download FNP Siemens Library [EXE], because they exist already.                                              >> %REPORT_LOGFILE% 2>&1
				)
			)
		)	
		if defined DOWNLOAD_LMS_PATH (
		
			rem Download newest LMS check script from akamai share
			rem echo Skip download from akamai share, download of 'CheckLMS.ex' is no longer supported.                                                                                             >> %REPORT_LOGFILE% 2>&1
			if not defined LMS_DONOTSTARTNEWERSCRIPT (
			 	echo     Download newest LMS check script: %DOWNLOAD_LMS_PATH%\CheckLMS.exe
			 	echo Download newest LMS check script: %DOWNLOAD_LMS_PATH%\CheckLMS.exe                                                                                                        >> %REPORT_LOGFILE% 2>&1
			 	del %DOWNLOAD_LMS_PATH%\CheckLMS.exe >nul 2>&1
			 	powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe', '%DOWNLOAD_LMS_PATH%\CheckLMS.exe')"          >> %REPORT_LOGFILE% 2>&1
			 	IF EXIST "%DOWNLOAD_LMS_PATH%\CheckLMS.exe" (
			 		rem CheckLMS.exe has been downloaded from akamai share
			 		del %DOWNLOAD_LMS_PATH%\CheckLMS.bat >nul 2>&1
			 		echo     Extract LMS check script: %DOWNLOAD_LMS_PATH%\CheckLMS.exe
			 		echo Extract LMS check script: %DOWNLOAD_LMS_PATH%\CheckLMS.exe                                                                                                            >> %REPORT_LOGFILE% 2>&1
			 		%DOWNLOAD_LMS_PATH%\CheckLMS.exe -y -o"%DOWNLOAD_LMS_PATH%\"                                                                                                               >> %REPORT_LOGFILE% 2>&1
			 		IF EXIST "%DOWNLOAD_LMS_PATH%\CheckLMS.bat" (
			 			for /f "tokens=2 delims== eol=@" %%i in ('type %DOWNLOAD_LMS_PATH%\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_EXE set LMS_SCRIPT_BUILD_DOWNLOAD_EXE=%%i
			 			echo     Check script downloaded from akamai share. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_EXE!, Running script version: !LMS_SCRIPT_BUILD!.
			 			echo Check script downloaded from akamai share. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_EXE!, Running script version: !LMS_SCRIPT_BUILD!.                  >> %REPORT_LOGFILE% 2>&1
			 		)
			 	)
			) else (
			 	echo Skip download from akamai share, because option 'donotstartnewerscript' is set. '%0'                                                                                      >> %REPORT_LOGFILE% 2>&1
			) 
			
			rem Download newest LMS check script from github
			if not defined LMS_DONOTSTARTNEWERSCRIPT (
				echo     Download newest LMS check script from github: %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat
				echo Download newest LMS check script: %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat                                                                                                     >> %REPORT_LOGFILE% 2>&1
				del %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat >nul 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/ImfeldC/CheckLMS/master/CheckLMS.bat', '%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat')" >> %REPORT_LOGFILE% 2>&1
				IF EXIST "%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat" (
					rem CheckLMS.bat has been downloaded from github
					for /f "tokens=2 delims== eol=@" %%i in ('type %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_GIT set LMS_SCRIPT_BUILD_DOWNLOAD_GIT=%%i
					echo     Check script downloaded from github. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_GIT!, Running script version: !LMS_SCRIPT_BUILD!.
					echo Check script downloaded from github. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_GIT!, Running script version: !LMS_SCRIPT_BUILD!.                             >> %REPORT_LOGFILE% 2>&1
				)			
			) else (
				echo Skip download from github,  because option 'donotstartnewerscript' is set. '%0'                                                                                            >> %REPORT_LOGFILE% 2>&1
			) 

			if /I !LMS_BUILD_VERSION! NEQ %MOST_RECENT_LMS_BUILD% (
				rem Not "most recent" [="released"] build installed, download latest released LMS client; e.g. from https://static.siemens.com/btdownloads/lms/LMSSetup2.6.826/x64/setup64.exe
				set LMS_SETUP_EXECUTABLE=%DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_LMS_VERSION%\setup64.exe
				IF NOT EXIST "!LMS_SETUP_EXECUTABLE!" (
					IF NOT EXIST "%DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_LMS_VERSION%" (
						rem echo Create new folder: %DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_LMS_VERSION%
						mkdir %DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_LMS_VERSION% >nul 2>&1
					)
					set LMS_SETUP_DOWNLOAD_LINK=https://static.siemens.com/btdownloads/lms/LMSSetup%MOST_RECENT_LMS_VERSION%/x64/setup64.exe
					echo     Download latest released LMS setup [%MOST_RECENT_LMS_VERSION%]: !LMS_SETUP_EXECUTABLE!
					echo Download latest released LMS setup [%MOST_RECENT_LMS_VERSION%]: !LMS_SETUP_EXECUTABLE!                                      >> %REPORT_LOGFILE% 2>&1
					powershell -Command "(New-Object Net.WebClient).DownloadFile('!LMS_SETUP_DOWNLOAD_LINK!', '!LMS_SETUP_EXECUTABLE!')"             >> %REPORT_LOGFILE% 2>&1
				) else (
					echo     Don't download latest released LMS setup [%MOST_RECENT_LMS_VERSION%], because it exist already: !LMS_SETUP_EXECUTABLE!
					echo Don't download latest released LMS setup [%MOST_RECENT_LMS_VERSION%], because it exist already: !LMS_SETUP_EXECUTABLE!      >> %REPORT_LOGFILE% 2>&1
				)
			)
			
			if /I !LMS_BUILD_VERSION! NEQ %MOST_RECENT_FT_LMS_BUILD% (
				rem Not "most recent" field test build installed, download latest field test LMS client; e.g. from https://static.siemens.com/btdownloads/lms/LMSSetup2.6.826/x64/setup64.exe
				set LMS_FT_SETUP_EXECUTABLE=%DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_FT_LMS_VERSION%\setup64.exe
				IF NOT EXIST "!LMS_FT_SETUP_EXECUTABLE!" (
					IF NOT EXIST "%DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_FT_LMS_VERSION%" (
						rem echo Create new folder: %DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_FT_LMS_VERSION%
						mkdir %DOWNLOAD_LMS_PATH%\LMSSetup\%MOST_RECENT_FT_LMS_VERSION% >nul 2>&1
					)
					set LMS_FT_SETUP_DOWNLOAD_LINK=https://static.siemens.com/btdownloads/lms/LMSSetup%MOST_RECENT_FT_LMS_VERSION%/x64/setup64.exe
					echo     Download latest field test LMS setup [%MOST_RECENT_FT_LMS_VERSION%]: !LMS_FT_SETUP_EXECUTABLE!
					echo Download latest field test LMS setup [%MOST_RECENT_FT_LMS_VERSION%]: !LMS_FT_SETUP_EXECUTABLE!                                      >> %REPORT_LOGFILE% 2>&1
					powershell -Command "(New-Object Net.WebClient).DownloadFile('!LMS_FT_SETUP_DOWNLOAD_LINK!', '!LMS_FT_SETUP_EXECUTABLE!')"               >> %REPORT_LOGFILE% 2>&1
				) else (
					echo     Don't download latest field test LMS setup [%MOST_RECENT_FT_LMS_VERSION%], because it exist already: !LMS_FT_SETUP_EXECUTABLE!
					echo Don't download latest field test LMS setup [%MOST_RECENT_FT_LMS_VERSION%], because it exist already: !LMS_FT_SETUP_EXECUTABLE!      >> %REPORT_LOGFILE% 2>&1
				)
			)
			
			rem Download tool "VMGENID.EXE" (from Stratus) to read-out generation id
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\VMGENID.EXE" (
				echo     Download VM GENID app [from Stratus]: %DOWNLOAD_LMS_PATH%\VMGENID.EXE
				echo Download VM GENID app [from Stratus]: %DOWNLOAD_LMS_PATH%\VMGENID.EXE                                                                                         >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/tools/VMGENID.EXE', '%DOWNLOAD_LMS_PATH%\VMGENID.EXE')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download VM GENID app [from Stratus] [VMGENID.EXE], because it exist already.
				echo Don't download VM GENID app [from Stratus] [VMGENID.EXE], because it exist already.                                                                           >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download tool "GetVMGenerationIdentifier.exe" to read-out generation id
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe" (
				echo     Download VM GENID app: %DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe
				echo Download VM GENID app: %DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe                                           >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/GetVMGenerationIdentifier.exe', '%DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download VM GENID app [GetVMGenerationIdentifier.exe], because they exist already.
				echo Don't download VM GENID app [GetVMGenerationIdentifier.exe], because they exist already.                           >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download tool "ecmcommonutil.exe" (from Flexera) to read-out host id's
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" (
				echo     Download ecmcommonutil app: %DOWNLOAD_LMS_PATH%\ecmcommonutil.exe
				echo Download ecmcommonutil app: %DOWNLOAD_LMS_PATH%\ecmcommonutil.exe                                                  >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/ecmcommonutil.exe', '%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download ecmcommonutil app [ecmcommonutil.exe], because they exist already.
				echo Don't download ecmcommonutil app [ecmcommonutil.exe], because they exist already.                                  >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download tool "ecmcommonutil.exe" V1.19 (=ecmcommonutil_1.19.exe) (from Flexera) to read-out host id's
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" (
				echo     Download ecmcommonutil app: %DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe
				echo Download ecmcommonutil app: %DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe                                             >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/ecmcommonutil_1.19.exe', '%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download ecmcommonutil app V1.19 [ecmcommonutil_1.19.exe], because they exist already.
				echo Don't download ecmcommonutil app V1.19 [ecmcommonutil_1.19.exe], because they exist already.                       >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download newest dongle driver always, to ensure that older driver get overwritten
			echo     Download newest dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [%MOST_RECENT_DONGLE_DRIVER_VERSION%] ...
			echo Download newest dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [%MOST_RECENT_DONGLE_DRIVER_VERSION%] ...             >> %REPORT_LOGFILE% 2>&1
			powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/hasp/%MOST_RECENT_DONGLE_DRIVER_VERSION%/haspdinst.exe', '%DOWNLOAD_LMS_PATH%\haspdinst.exe')"   >> %REPORT_LOGFILE% 2>&1
			if exist "%DOWNLOAD_LMS_PATH%\haspdinst.exe" (
				set TARGETFILE=%DOWNLOAD_LMS_PATH%\haspdinst.exe
				set TARGETFILE=!TARGETFILE:\=\\!
				wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
				IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "haspdinstVersion=%%i"
				echo     Newest dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] downloaded!
				echo Newest dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] downloaded!                           >> %REPORT_LOGFILE% 2>&1
			)
						
			rem Download AccessChk tool
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\AccessChk.zip" (
				echo     Download AccessChk tool: %DOWNLOAD_LMS_PATH%\AccessChk.zip
				echo Download AccessChk tool: %DOWNLOAD_LMS_PATH%\AccessChk.zip                                                         >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.sysinternals.com/files/AccessChk.zip', '%DOWNLOAD_LMS_PATH%\AccessChk.zip')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download AccessChk tool [AccessChk.zip], because it exist already.
				echo Don't download AccessChk tool [AccessChk.zip], because it exist already.                                           >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download SigCheck tool
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\Sigcheck.zip" (
				echo     Download SigCheck tool: %DOWNLOAD_LMS_PATH%\Sigcheck.zip
				echo Download SigCheck tool: %DOWNLOAD_LMS_PATH%\Sigcheck.zip                                                           >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.sysinternals.com/files/Sigcheck.zip', '%DOWNLOAD_LMS_PATH%\Sigcheck.zip')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download SigCheck tool [Sigcheck.zip], because it exist already.
				echo Don't download SigCheck tool [Sigcheck.zip], because it exist already.                                             >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download USBDeview tool
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\usbdeview-x64.zip" (
				echo     Download USBDeview tool: %DOWNLOAD_LMS_PATH%\usbdeview-x64.zip
				echo Download USBDeview tool: %DOWNLOAD_LMS_PATH%\usbdeview-x64.zip                                                     >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.nirsoft.net/utils/usbdeview-x64.zip', '%DOWNLOAD_LMS_PATH%\usbdeview-x64.zip')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download USBDeview tool [usbdeview-x64.zip], because it exist already.
				echo Don't download USBDeview tool [usbdeview-x64.zip], because it exist already.                                       >> %REPORT_LOGFILE% 2>&1
			)
			
			rem Download “counted.lic”
			IF NOT EXIST "%DOWNLOAD_LMS_PATH%\counted.lic" (
				echo     Download 'counted.lic': %DOWNLOAD_LMS_PATH%\counted.lic
				echo Download 'counted.lic': %DOWNLOAD_LMS_PATH%\counted.lic                                                            >> %REPORT_LOGFILE% 2>&1
				powershell -Command "(New-Object Net.WebClient).DownloadFile('https://static.siemens.com/btdownloads/lms/FNP/counted.lic', '%DOWNLOAD_LMS_PATH%\counted.lic')"   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     Don't download 'counted.lic', because it exist already.
				echo Don't download 'counted.lic', because it exist already.                                                            >> %REPORT_LOGFILE% 2>&1
			)
			
		)
	) else (
		echo     Don't download additional libraries and files, because no internet connection available.
		echo Don't download additional libraries and files, because no internet connection available.                                         >> %REPORT_LOGFILE% 2>&1
		
		rem in case no connection is available, check local folder for a "download" zip archive
		dir /S /A /B "!LMS_PROGRAMDATA!\LMSDownloadArchive_*.zip" > "!CHECKLMS_REPORT_LOG_PATH!\LMSDownloadArchivesFound.txt"  
		rem type !CHECKLMS_REPORT_LOG_PATH!\LMSDownloadArchivesFound.txt
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_REPORT_LOG_PATH!\LMSDownloadArchivesFound.txt) DO (                       
			rem see https://stackoverflow.com/questions/15567809/batch-extract-path-and-filename-from-a-variable/15568164
			set file=%%i
			set filedrive=%%~di
			set filepath=%%~pi
			set filename=%%~ni
			set fileextension=%%~xi
			rem ECHO filedrive=!filedrive! / filepath=!filepath! /  filename=!filename! / fileextension=!fileextension!
			for /f "tokens=1,2,3 eol=@ delims=_" %%a in ("!filename!") do set filemachine=%%b
			for /f "tokens=1,2,3 eol=@ delims=_" %%a in ("!filename!") do set filetimestamp=%%c
			rem echo filemachine=!filemachine! / filetimestamp=!filetimestamp!
			if "%COMPUTERNAME%" == "!filemachine!" (
				echo Skip download archive '!file!', as it was created on this machine!                                                   >> %REPORT_LOGFILE% 2>&1
			) else (
				echo Found download archive '!file!' from machine '!filemachine!'.                                                        >> %REPORT_LOGFILE% 2>&1
				if exist "!file!.processed.%COMPUTERNAME%.txt" (
					rem this download archive has been processed already
					echo Skip download archive '!file!', as it was processed already on this machine!                                     >> %REPORT_LOGFILE% 2>&1
					type "!file!.processed.%COMPUTERNAME%.txt"                                                                            >> %REPORT_LOGFILE% 2>&1
				) else (
					rem unzip this download archive on this machine
					echo Unzip download archive '!file!' into '!LMS_PROGRAMDATA!' ...                                                     >> %REPORT_LOGFILE% 2>&1
					if defined UNZIP_TOOL (
						echo Unzip download archive [LMSDownloadArchive_*.zip] with unzip tool '!UNZIP_TOOL!'.                            >> %REPORT_LOGFILE% 2>&1
						"!UNZIP_TOOL!" x -y -spe -o"!LMS_PROGRAMDATA!" "!file!"                                                           > !CHECKLMS_REPORT_LOG_PATH!\unzip_download_archive.txt
					) else (
						echo Can't unzip download archive [LMSDownloadArchive_*.zip], because no unzip tool is available.                 >> %REPORT_LOGFILE% 2>&1
					)
					echo Unzip download archive [LMSDownloadArchive_*.zip] with powershell tool 'Expand-Archive'.                         >> %REPORT_LOGFILE% 2>&1
					powershell -Command "Expand-Archive -Path !file! -DestinationPath !LMS_PROGRAMDATA! -Verbose -Force"                  >> %REPORT_LOGFILE% 2>&1
					echo Download archive !file! processed on %COMPUTERNAME% and unzipped into '!LMS_PROGRAMDATA!' at !DATE! !TIME! > "!file!.processed.%COMPUTERNAME%.txt"
				)
			)
		)
	)
) else (
	rem LMS_SKIPDOWNLOAD
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED download section. The script didn't execute the download commands. [1;37m
	) else (
		echo     SKIPPED download section. The script didn't execute the download commands.
	)
	echo SKIPPED download section. The script didn't execute the download commands.                                               >> %REPORT_LOGFILE% 2>&1
)

if not defined LMS_SKIPUNZIP (
	if defined LMS_SERVERTOOL_DW (
		REM Unzip FNP Siemens Library
		REM See https://sourceforge.net/p/sevenzip/discussion/45798/thread/8cb61347/?limit=25
		IF EXIST "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip" (
			echo     Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip
			echo Extract FNP Siemens Library: %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip                                             >> %REPORT_LOGFILE% 2>&1
			if defined UNZIP_TOOL (
				"!UNZIP_TOOL!" x -y -spe -o"%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%\" "%DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip"   > !CHECKLMS_REPORT_LOG_PATH!\unzip_fnp_library_using_zip_tool.txt
			) else (
				echo Can't unzip FNP Siemens Library [%LMS_SERVERTOOL_DW%.zip], because no unzip tool is available.                   >> %REPORT_LOGFILE% 2>&1
			)
			powershell -Command "Expand-Archive -Path %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%.zip -DestinationPath %DOWNLOAD_LMS_PATH%\%LMS_SERVERTOOL_DW%\ -Verbose -Force"   > !CHECKLMS_REPORT_LOG_PATH!\unzip_fnp_library_using_powershell.txt
		)
	)
	rem Unzip AccessChk tool
	IF EXIST "%DOWNLOAD_LMS_PATH%\AccessChk.zip" (
		if defined UNZIP_TOOL (
			"!UNZIP_TOOL!" x -o!DOWNLOAD_LMS_PATH!\AccessChk -y %DOWNLOAD_LMS_PATH%\AccessChk.zip                                     > !CHECKLMS_REPORT_LOG_PATH!\unzip_accessChk.txt
		) else (
			echo Can't unzip AccessChk tool [AccessChk.zip], because no unzip tool is available.                                      >> %REPORT_LOGFILE% 2>&1
		)
		powershell -Command "Expand-Archive -Path %DOWNLOAD_LMS_PATH%\AccessChk.zip -DestinationPath !DOWNLOAD_LMS_PATH!\AccessChk -Verbose -Force"   > !CHECKLMS_REPORT_LOG_PATH!\unzip_accesschk_using_powershell.txt
	) else (
		echo     Don't unzip AccessChk tool [AccessChk.zip], because zip archive doesn't exists.
		echo Don't unzip AccessChk tool [AccessChk.zip], because zip archive doesn't exists.                                          >> %REPORT_LOGFILE% 2>&1
	)
	rem Unzip SigCheck tool
	IF EXIST "%DOWNLOAD_LMS_PATH%\Sigcheck.zip" (
		if defined UNZIP_TOOL (
			"!UNZIP_TOOL!" x -o!DOWNLOAD_LMS_PATH!\SigCheck -y %DOWNLOAD_LMS_PATH%\Sigcheck.zip                                       > !CHECKLMS_REPORT_LOG_PATH!\unzip_sigcheck.txt
		) else (
			echo Can't unzip SigCheck tool [Sigcheck.zip], because no unzip tool is available.                                        >> %REPORT_LOGFILE% 2>&1
		)
		powershell -Command "Expand-Archive -Path %DOWNLOAD_LMS_PATH%\Sigcheck.zip -DestinationPath !DOWNLOAD_LMS_PATH!\SigCheck -Verbose -Force"   > !CHECKLMS_REPORT_LOG_PATH!\unzip_sigcheck_using_powershell.txt
	) else (
		echo     Don't unzip SigCheck tool [Sigcheck.zip], because zip archive doesn't exists.
		echo Don't unzip SigCheck tool [Sigcheck.zip], because zip archive doesn't exists.                                            >> %REPORT_LOGFILE% 2>&1
	)
	rem Unzip USBDeview tool
	IF EXIST "%DOWNLOAD_LMS_PATH%\usbdeview-x64.zip" (
		if defined UNZIP_TOOL (
			"!UNZIP_TOOL!" x -o!DOWNLOAD_LMS_PATH!\usbdeview -y %DOWNLOAD_LMS_PATH%\usbdeview-x64.zip                                 > !CHECKLMS_REPORT_LOG_PATH!\unzip_usbdeview.txt
		) else (
			echo Can't unzip USBDeview tool [usbdeview-x64.zip], because no unzip tool is available.                                  >> %REPORT_LOGFILE% 2>&1
		)
		powershell -Command "Expand-Archive -Path %DOWNLOAD_LMS_PATH%\usbdeview-x64.zip -DestinationPath !DOWNLOAD_LMS_PATH!\usbdeview -Verbose -Force"   > !CHECKLMS_REPORT_LOG_PATH!\unzip_usbdeview_using_powershell.txt
	) else (
		echo     Don't unzip USBDeview tool [usbdeview-x64.zip], because zip archive doesn't exists.
		echo Don't unzip USBDeview tool [usbdeview-x64.zip], because zip archive doesn't exists.                                      >> %REPORT_LOGFILE% 2>&1
	)

	set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=
	rem Check if newer CheckLMS.bat is available in %DOWNLOAD_LMS_PATH%\CheckLMS.bat (even if connection test doesn't run succesful)
	IF EXIST "%DOWNLOAD_LMS_PATH%\CheckLMS.bat" (
		echo     Check script on '%DOWNLOAD_LMS_PATH%\CheckLMS.bat' ... 
		echo Check script on '%DOWNLOAD_LMS_PATH%\CheckLMS.bat' ...                                                                                                                      >> %REPORT_LOGFILE% 2>&1
		for /f "tokens=2 delims== eol=@" %%i in ('type %DOWNLOAD_LMS_PATH%\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_1 set LMS_SCRIPT_BUILD_DOWNLOAD_1=%%i
		if /I !LMS_SCRIPT_BUILD_DOWNLOAD_1! GTR !LMS_SCRIPT_BUILD! (
			echo     Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_1!, Running script version: !LMS_SCRIPT_BUILD!.
			echo Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_1!, Running script version: !LMS_SCRIPT_BUILD!.                                      >> %REPORT_LOGFILE% 2>&1
			set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=%DOWNLOAD_LMS_PATH%\CheckLMS.bat
		)
	)	
	rem Check if newer CheckLMS.bat is available in %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat (even if connection test doesn't run succesful)
	IF EXIST "%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat" (
		echo     Check script on '%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat' ... 
		echo Check script on '%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat' ...                                                                                                                  >> %REPORT_LOGFILE% 2>&1
		for /f "tokens=2 delims== eol=@" %%i in ('type %DOWNLOAD_LMS_PATH%\git\CheckLMS.bat ^|find /I "LMS_SCRIPT_BUILD="') do if not defined LMS_SCRIPT_BUILD_DOWNLOAD_2 set LMS_SCRIPT_BUILD_DOWNLOAD_2=%%i
		if /I !LMS_SCRIPT_BUILD_DOWNLOAD_2! GTR !LMS_SCRIPT_BUILD! (
			echo     Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_2!, Running script version: !LMS_SCRIPT_BUILD!.
			echo Newer check script downloaded. Download script version: !LMS_SCRIPT_BUILD_DOWNLOAD_2!, Running script version: !LMS_SCRIPT_BUILD!.                                      >> %REPORT_LOGFILE% 2>&1
			set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat
		)
	)	
	if defined LMS_SCRIPT_BUILD_DOWNLOAD_1 (
		if defined LMS_SCRIPT_BUILD_DOWNLOAD_2 (
			rem From both servers have new CheckLMS.bat scripts been downloaded.
			if /I !LMS_SCRIPT_BUILD_DOWNLOAD_1! GTR !LMS_SCRIPT_BUILD! (
				if /I !LMS_SCRIPT_BUILD_DOWNLOAD_1! GTR !LMS_SCRIPT_BUILD_DOWNLOAD_2! (
					rem The CheckLMS.bat script on github is older than the script downloaded from akamai share
					echo Start script downloaded from akamai '%DOWNLOAD_LMS_PATH%\CheckLMS.bat'. Script version from github: !LMS_SCRIPT_BUILD_DOWNLOAD_2!, Script version from akamai: !LMS_SCRIPT_BUILD_DOWNLOAD_1!.  >> %REPORT_LOGFILE% 2>&1
					set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=%DOWNLOAD_LMS_PATH%\CheckLMS.bat
				)
			)
			if /I !LMS_SCRIPT_BUILD_DOWNLOAD_2! GTR !LMS_SCRIPT_BUILD! (
				if /I !LMS_SCRIPT_BUILD_DOWNLOAD_2! GTR !LMS_SCRIPT_BUILD_DOWNLOAD_1! (
					rem The CheckLMS.bat script on github is newer than the script downloaded from akamai share
					echo Start script downloaded from github '%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat'. Script version from github: !LMS_SCRIPT_BUILD_DOWNLOAD_2!, Script version from akamai: !LMS_SCRIPT_BUILD_DOWNLOAD_1!.  >> %REPORT_LOGFILE% 2>&1
					set LMS_SCRIPT_BUILD_DOWNLOAD_TO_START=%DOWNLOAD_LMS_PATH%\git\CheckLMS.bat
				)
			)
		)
	)
) else (
	rem LMS_SKIPUNZIP
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED unzip section. The script didn't execute the unzip commands. [1;37m
	) else (
		echo     SKIPPED unzip section. The script didn't execute the unzip commands.
	)
	echo SKIPPED unzip section. The script didn't execute the unzip commands.                                               >> %REPORT_LOGFILE% 2>&1
)

if defined LMS_CHECK_DOWNLOAD (
	if defined UNZIP_TOOL (
		echo -------------------------------------------------------                           >> %REPORT_LOGFILE% 2>&1
		echo Create download archive '!DOWNLOAD_ARCHIVE!' ....
		echo Start at !DATE! !TIME! to create !DOWNLOAD_ARCHIVE! ....                          >> %REPORT_LOGFILE% 2>&1
		"!UNZIP_TOOL!" a -ssw -tzip "!DOWNLOAD_ARCHIVE!" "!DOWNLOAD_PATH!"                     >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                               >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
)

if defined LMS_SCRIPT_BUILD_DOWNLOAD_TO_START (
	if not defined LMS_DONOTSTARTNEWERSCRIPT (

		rem Start newer script in an own command shell window
		echo ==============================================================================                                                                                >> %REPORT_LOGFILE% 2>&1
		echo ==                                                                                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo == Start newer script in an own command shell window.                                                                                                         >> %REPORT_LOGFILE% 2>&1
		echo ==    command: start "Check LMS !LMS_SCRIPT_BUILD!" !LMS_SCRIPT_BUILD_DOWNLOAD_TO_START! %*                                                                   >> %REPORT_LOGFILE% 2>&1
		echo ==                                                                                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo ==============================================================================                                                                                >> %REPORT_LOGFILE% 2>&1
		echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                                                        >> %REPORT_LOGFILE% 2>&1
		rem save (single) report in full report file
		Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
		
		start "Check LMS" !LMS_SCRIPT_BUILD_DOWNLOAD_TO_START! %* /donotstartnewerscript
		exit
		rem STOP EXECUTION HERE
	
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    SKIPPED start of newer script. Command line option "Do not start new script" is set. [1;37m
		) else (
			echo     SKIPPED start of newer script. Command line option "Do not start new script" is set.
		)
		echo SKIPPED start of newer script. Command line option "Do not start new script" is set.                                                                          >> %REPORT_LOGFILE% 2>&1
	)
)	

rem -- AccessChk.exe
set ACCESSCHECK_TOOL=
IF EXIST "!DOWNLOAD_LMS_PATH!\AccessChk\AccessChk.exe" (
	set ACCESSCHECK_TOOL=!DOWNLOAD_LMS_PATH!\AccessChk\AccessChk.exe
	set ACCESSCHECK_TOOL=-nobanner -accepteula
)
rem -- Sigcheck.exe
set SIGCHECK_TOOL=
IF EXIST "!DOWNLOAD_LMS_PATH!\SigCheck\SigCheck.exe" (
	set SIGCHECK_TOOL=!DOWNLOAD_LMS_PATH!\SigCheck\SigCheck.exe
	set SIGCHECK_OPTIONS=-nobanner -accepteula -a -h -i
)
rem -- USBDeview.exe
set USBDEVIEW_TOOL=
IF EXIST "!DOWNLOAD_LMS_PATH!\usbdeview\USBDeview.exe" (
	set USBDEVIEW_TOOL=!DOWNLOAD_LMS_PATH!\usbdeview\USBDeview.exe
)
rem -- appactutil.exe
set LMS_APPACTUTIL=
set LMS_APPACTUTIL=!ProgramFiles_x86!\Siemens\LMS\server\appactutil.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\appactutil.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\appactutil.exe" (
		set LMS_APPACTUTIL=%ProgramFiles%\Siemens\LMS\server\appactutil.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\appactutil.exe" (
			set LMS_APPACTUTIL=%LMS_SERVERTOOL_DW_PATH%\appactutil.exe
		) else (
			set LMS_APPACTUTIL=
		)
	)
)
rem -- lmdiag.exe
set LMS_LMDIAG=
set LMS_LMDIAG=!ProgramFiles_x86!\Siemens\LMS\server\lmdiag.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmdiag.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmdiag.exe" (
		set LMS_LMDIAG=%ProgramFiles%\Siemens\LMS\server\lmdiag.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmdiag.exe" (
			set LMS_LMDIAG=%LMS_SERVERTOOL_DW_PATH%\lmdiag.exe
		) else (
			set LMS_LMDIAG=
		)
	)
)
rem -- lmhostid.exe
set LMS_LMHOSTID=
set LMS_LMHOSTID=!ProgramFiles_x86!\Siemens\LMS\server\lmhostid.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmhostid.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmhostid.exe" (
		set LMS_LMHOSTID=%ProgramFiles%\Siemens\LMS\server\lmhostid.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmhostid.exe" (
			set LMS_LMHOSTID=%LMS_SERVERTOOL_DW_PATH%\lmhostid.exe
		) else (
			set LMS_LMHOSTID=
		)
	)
)
rem -- lmstat.exe
set LMS_LMSTAT=
set LMS_LMSTAT=!ProgramFiles_x86!\Siemens\LMS\server\lmstat.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmstat.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmstat.exe" (
		set LMS_LMSTAT=%ProgramFiles%\Siemens\LMS\server\lmstat.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmstat.exe" (
			set LMS_LMSTAT=%LMS_SERVERTOOL_DW_PATH%\lmstat.exe
		) else (
			set LMS_LMSTAT=
		)
	)
)
rem -- lmtpminfo.exe
set LMS_LMTPMINFO=
set LMS_LMTPMINFO=!ProgramFiles_x86!\Siemens\LMS\server\lmtpminfo.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmtpminfo.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmtpminfo.exe" (
		set LMS_LMTPMINFO=%ProgramFiles%\Siemens\LMS\server\lmtpminfo.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmtpminfo.exe" (
			set LMS_LMTPMINFO=%LMS_SERVERTOOL_DW_PATH%\lmtpminfo.exe
		) else (
			set LMS_LMTPMINFO=
		)
	)
)
rem -- lmvminfo.exe
set LMS_LMVMINFO=
set LMS_LMVMINFO=!ProgramFiles_x86!\Siemens\LMS\server\lmvminfo.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmvminfo.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmvminfo.exe" (
		set LMS_LMVMINFO=%ProgramFiles%\Siemens\LMS\server\lmvminfo.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmvminfo.exe" (
			set LMS_LMVMINFO=%LMS_SERVERTOOL_DW_PATH%\lmvminfo.exe
		) else (
			set LMS_LMVMINFO=
		)
	)
)
rem -- servercomptranutil.exe
set LMS_SERVERCOMTRANUTIL=
set LMS_SERVERCOMTRANUTIL=!ProgramFiles_x86!\Siemens\LMS\server\servercomptranutil.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\servercomptranutil.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\servercomptranutil.exe" (
		set LMS_SERVERCOMTRANUTIL=%ProgramFiles%\Siemens\LMS\server\servercomptranutil.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\servercomptranutil.exe" (
			set LMS_SERVERCOMTRANUTIL=%LMS_SERVERTOOL_DW_PATH%\servercomptranutil.exe
		) else (
			set LMS_SERVERCOMTRANUTIL=
		)
	)
)
rem -- tsactdiags_SIEMBT_svr.exe
set LMS_TSACTDIAGSSVR=
set LMS_TSACTDIAGSSVR=!ProgramFiles_x86!\Siemens\LMS\server\tsactdiags_SIEMBT_svr.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\tsactdiags_SIEMBT_svr.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\tsactdiags_SIEMBT_svr.exe" (
		set LMS_TSACTDIAGSSVR=%ProgramFiles%\Siemens\LMS\server\tsactdiags_SIEMBT_svr.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\tsactdiags_SIEMBT_svr.exe" (
			set LMS_TSACTDIAGSSVR=%LMS_SERVERTOOL_DW_PATH%\tsactdiags_SIEMBT_svr.exe
		) else (
			set LMS_TSACTDIAGSSVR=
		)
	)
)
rem -- tsreset_svr.exe
set LMS_TSRESETSVR=
set LMS_TSRESETSVR=!ProgramFiles_x86!\Siemens\LMS\server\tsreset_svr.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\tsreset_svr.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\tsreset_svr.exe" (
		set LMS_TSRESETSVR=%ProgramFiles%\Siemens\LMS\server\tsreset_svr.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\tsreset_svr.exe" (
			set LMS_TSRESETSVR=%LMS_SERVERTOOL_DW_PATH%\tsreset_svr.exe
		) else (
			set LMS_TSRESETSVR=
		)
	)
)
rem -- tsreset_app.exe
set LMS_TSRESETAPP=
set LMS_TSRESETAPP=!ProgramFiles_x86!\Siemens\LMS\server\tsreset_app.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\tsreset_app.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\tsreset_app.exe" (
		set LMS_TSRESETAPP=%ProgramFiles%\Siemens\LMS\server\tsreset_app.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\tsreset_app.exe" (
			set LMS_TSRESETAPP=%LMS_SERVERTOOL_DW_PATH%\tsreset_app.exe
		) else (
			set LMS_TSRESETAPP=
		)
	)
)
rem -- serveractutil.exe (since 06-Dec-2018)
set LMS_SERVERACTUTIL=
set LMS_SERVERACTUTIL=!ProgramFiles_x86!\Siemens\LMS\server\serveractutil.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\serveractutil.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\serveractutil.exe" (
		set LMS_SERVERACTUTIL=%ProgramFiles%\Siemens\LMS\server\serveractutil.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\serveractutil.exe" (
			set LMS_SERVERACTUTIL=%LMS_SERVERTOOL_DW_PATH%\serveractutil.exe
		) else (
			set LMS_SERVERACTUTIL=
		)
	)
)
rem -- appcomptranutil.exe (since 24-Apr-2019)
set LMS_APPCOMPTRANUTIL=
set LMS_APPCOMPTRANUTIL=!ProgramFiles_x86!\Siemens\LMS\server\appcomptranutil.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\appcomptranutil.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\appcomptranutil.exe" (
		set LMS_APPCOMPTRANUTIL=%ProgramFiles%\Siemens\LMS\server\appcomptranutil.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\appcomptranutil.exe" (
			set LMS_APPCOMPTRANUTIL=%LMS_SERVERTOOL_DW_PATH%\appcomptranutil.exe
		) else (
			set LMS_APPCOMPTRANUTIL=
		)
	)
)
rem -- lmutil.exe (since 26-Nov-2019)
set LMS_LMUTIL=
set LMS_LMUTIL=!ProgramFiles_x86!\Siemens\LMS\server\lmutil.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmutil.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmutil.exe" (
		set LMS_LMUTIL=%ProgramFiles%\Siemens\LMS\server\lmutil.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmutil.exe" (
			set LMS_LMUTIL=%LMS_SERVERTOOL_DW_PATH%\lmutil.exe
		) else (
			set LMS_LMUTIL=
		)
	)
)
rem -- lmver.exe (since 09-Nov-2020)
set LMS_LMVER=
set LMS_LMVER=!ProgramFiles_x86!\Siemens\LMS\server\lmver.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmver.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmver.exe" (
		set LMS_LMVER=%ProgramFiles%\Siemens\LMS\server\lmver.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmver.exe" (
			set LMS_LMVER=%LMS_SERVERTOOL_DW_PATH%\lmver.exe
		) else (
			set LMS_LMVER=
		)
	)
)
rem -- lmdown.exe (since 24-Mar-2021)
set LMS_LMDOWN=
set LMS_LMDOWN=!ProgramFiles_x86!\Siemens\LMS\server\lmdown.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\lmdown.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\lmdown.exe" (
		set LMS_LMDOWN=%ProgramFiles%\Siemens\LMS\server\lmdown.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\lmdown.exe" (
			set LMS_LMDOWN=%LMS_SERVERTOOL_DW_PATH%\lmdown.exe
		) else (
			set LMS_LMDOWN=
		)
	)
)
rem -- demoLF.exe (since 24-Mar-2021)
set LMS_DEMOLF_VD=
set LMS_DEMOLF_VD=!ProgramFiles_x86!\Siemens\LMS\server\demoLF.exe
IF NOT EXIST "!ProgramFiles_x86!\Siemens\LMS\server\demoLF.exe" (
	IF EXIST "%ProgramFiles%\Siemens\LMS\server\demoLF.exe" (
		set LMS_DEMOLF_VD=%ProgramFiles%\Siemens\LMS\server\demoLF.exe
	) else (
		IF EXIST "%LMS_SERVERTOOL_DW_PATH%\demoLF.exe" (
			set LMS_DEMOLF_VD=%LMS_SERVERTOOL_DW_PATH%\demoLF.exe
		) else (
			set LMS_DEMOLF_VD=
		)
	)
)

rem - for test purpose
rem goto flexera_fnp_information
rem goto ssu_update_information
rem goto lms_log_files
rem goto windows_error_reporting
rem goto lms_section
rem goto alm_section
rem goto connection_test
rem goto collect_product_info
rem goto create_archive
rem - Usage: /goto <gotolabel>:           jump to a dedicated part within script.
if defined LMS_GOTO (
	echo Goto within check script to: !LMS_GOTO! ....                                                                        >> %REPORT_LOGFILE% 2>&1
	goto !LMS_GOTO!
)

echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   S Y S T E M   C O N F I G U R A T I O N   S E C T I O N                  =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo ... system configuration section ...

if defined LMS_SET_FIREWALL (
	echo     set firewall settings ...
	echo Set firewall settings ...                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
		rem set firewall settings ...
		echo Delete rule: netsh advfirewall firewall delete rule name="LMS lmgrd"                                                                              >> %REPORT_LOGFILE% 2>&1
		netsh advfirewall firewall delete rule name="LMS lmgrd"                                                                                                >> %REPORT_LOGFILE% 2>&1
		echo Delete rule: netsh advfirewall firewall delete rule name="LMS SIEMBT"                                                                             >> %REPORT_LOGFILE% 2>&1
		netsh advfirewall firewall delete rule name="LMS SIEMBT"                                                                                               >> %REPORT_LOGFILE% 2>&1
		rem see also https://wiki.siemens.com/display/en/LMS+VMware+configuration
		echo Set rule: netsh advfirewall firewall add rule name="LMS lmgrd" dir=in action=allow program="!ProgramFiles_x86!\Siemens\LMS\server\lmgrd.exe"     >> %REPORT_LOGFILE% 2>&1
		netsh advfirewall firewall add rule name="LMS lmgrd" dir=in action=allow program="!ProgramFiles_x86!\Siemens\LMS\server\lmgrd.exe"                    >> %REPORT_LOGFILE% 2>&1
		echo Setrule : netsh advfirewall firewall add rule name="LMS siembt" dir=in action=allow program="!ProgramFiles_x86!\Siemens\LMS\server\siembt.exe"   >> %REPORT_LOGFILE% 2>&1
		netsh advfirewall firewall add rule name="LMS siembt" dir=in action=allow program="!ProgramFiles_x86!\Siemens\LMS\server\siembt.exe"                  >> %REPORT_LOGFILE% 2>&1
		echo     DONE
		echo Set firewall settings ... DONE                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: Cannot set firewall settings, start script with administrator priviledge. [1;37m
		) else (
			echo     WARNING: Cannot set firewall settings, start script with administrator priviledge.
		)
		echo WARNING: Cannot set firewall settings, start script with administrator priviledge.                                                           >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                               >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Show-NetFirewallRule"  > !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt 2>&1
	rem Analyze firewall rules (retrieved with PS); check for LMS entries
	del !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt >nul 2>&1
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt" for /f "tokens=1* eol=@ delims=<>: " %%A in (!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt) do (
		rem echo [%%A] [%%B]
		set PARAMETER_NAME=%%A
		set PARAMETER_VALUE=%%B
		rem echo [!PARAMETER_NAME!] [!PARAMETER_VALUE!]
		for /f "tokens=* delims= " %%a in ("!PARAMETER_NAME!") do set PARAMETER_NAME=%%a
		for /f "tokens=* delims= " %%a in ("!PARAMETER_VALUE!") do set PARAMETER_VALUE=%%a
		rem echo [!PARAMETER_NAME!] [!PARAMETER_VALUE!]
		if "!PARAMETER_NAME!" EQU "DisplayName" (
			set FIREWALL_RULE_NAME=!PARAMETER_VALUE!
			rem echo Rule Name: !FIREWALL_RULE_NAME!
		)
		if "!PARAMETER_NAME!" EQU "Program" (
			set FIREWALL_PROG_NAME=!PARAMETER_VALUE!
			rem echo [Rule Name=!FIREWALL_RULE_NAME!][Program Name=!FIREWALL_PROG_NAME!]
			echo [Rule Name=!FIREWALL_RULE_NAME!][Program Name=!FIREWALL_PROG_NAME!] >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt  2>&1
		)
	)
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt" (
		for /f "tokens=1,2 eol=@ delims==<>[]" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt ^|find /I "lmgrd.exe"') do set "LMGRD_FOUND=%%B"
		for /f "tokens=1,2 eol=@ delims==<>[]" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt ^|find /I "SIEMBT.exe"') do set "SIEMBT_FOUND=%%B"
	)
	del !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt >nul 2>&1
	if defined LMGRD_FOUND (
		echo     Rule for lmgrd.exe found, with name "!LMGRD_FOUND!".                                                            >> %REPORT_LOGFILE% 2>&1
		echo     Rule for lmgrd.exe found, with name "!LMGRD_FOUND!".
		netsh advfirewall firewall show rule name="!LMGRD_FOUND!" verbose >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt 2>&1
	) else (
		echo     NO Rule for lmgrd.exe found.                                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     NO Rule for lmgrd.exe found.
	)
	if defined SIEMBT_FOUND (
		echo     Rule for SIEMBT.exe found, with name "!SIEMBT_FOUND!".                                                          >> %REPORT_LOGFILE% 2>&1
		echo     Rule for SIEMBT.exe found, with name "!SIEMBT_FOUND!".
		netsh advfirewall firewall show rule name="!SIEMBT_FOUND!" verbose >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt 2>&1
	) else (
		echo     NO Rule for SIEMBT.exe found.                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo     NO Rule for SIEMBT.exe found.
	)
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt" type "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt"        >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                  >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Set firewall settings ... NO                                                                                            >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_INSTALL_DONGLE_DRIVER (
	rem The same code block is again at script end (was introduced in an earlier script version and kept for "backward" compatibility)
	if exist "%DOWNLOAD_LMS_PATH%\haspdinst.exe" (
		set TARGETFILE=%DOWNLOAD_LMS_PATH%\haspdinst.exe
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "haspdinstVersion=%%i"
		echo     Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!
		echo Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!                                    >> %REPORT_LOGFILE% 2>&1
		if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
			rem install dongle driver downloaded by this script
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    --- Install newest dongle driver !haspdinstVersion! just downloaded by this script. [1;37m
			) else (
				echo     --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.
			)
			echo --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.                             >> %REPORT_LOGFILE% 2>&1
			start "Install dongle driver" "%DOWNLOAD_LMS_PATH%\haspdinst.exe" -install -killprocess 
			echo --- Installation started in an own process/shell.                                                               >> %REPORT_LOGFILE% 2>&1
		) else (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: Cannot install dongle driver, start script with administrator priviledge. [1;37m
			) else (
				echo     WARNING: Cannot install dongle driver, start script with administrator priviledge.
			)
			echo WARNING: Cannot install dongle driver, start script with administrator priviledge.                              >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: Cannot install dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist. [1;37m
		) else (
			echo     WARNING: Cannot install dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist.
		)
		echo WARNING: Cannot install dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist.                      >> %REPORT_LOGFILE% 2>&1
	)
	
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                  >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Install Dongle Driver ... NO                                                                                            >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_REMOVE_DONGLE_DRIVER (
	if exist "%DOWNLOAD_LMS_PATH%\haspdinst.exe" (
		set TARGETFILE=%DOWNLOAD_LMS_PATH%\haspdinst.exe
		set TARGETFILE=!TARGETFILE:\=\\!
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "haspdinstVersion=%%i"
		echo     Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!
		echo Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!                                    >> %REPORT_LOGFILE% 2>&1
		if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    --- Remove installed dongle driver !haspdinstVersion!. [1;37m
			) else (
				echo     --- Remove installed dongle driver !haspdinstVersion!.
			)
			echo --- Remove installed dongle driver !haspdinstVersion!.                                                          >> %REPORT_LOGFILE% 2>&1
			start "Remove dongle driver" "%DOWNLOAD_LMS_PATH%\haspdinst.exe" -remove -killprocess 
			echo --- Remove started in an own process/shell.                                                                     >> %REPORT_LOGFILE% 2>&1
		) else (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: Cannot remove dongle driver, start script with administrator priviledge. [1;37m
			) else (
				echo     WARNING: Cannot remove dongle driver, start script with administrator priviledge.
			)
			echo WARNING: Cannot remove dongle driver, start script with administrator priviledge.                               >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: Cannot remove dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist. [1;37m
		) else (
			echo     WARNING: Cannot remove dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist.
		)
		echo WARNING: Cannot remove dongle driver, file '%DOWNLOAD_LMS_PATH%\haspdinst.exe' doesn't exist.                       >> %REPORT_LOGFILE% 2>&1
	)

	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                  >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Remove Dongle Driver ... NO                                                                                             >> %REPORT_LOGFILE% 2>&1
)

if defined LMS_SET_CHECK_ID_TASK (
	set taskname=\Siemens\Lms\CheckLMS_CheckID
	set taskrun="%~dpnx0 /checkid"
	echo     set CheckId scheduled task '!taskname!' ...
	echo Set CheckId scheduled task '!taskname!' with command !taskrun! ...                                                  >> %REPORT_LOGFILE% 2>&1
	SCHTASKS /Create /TN !taskname! /TR !taskrun! /SC MINUTE /MO 60 /F                                                       >> %REPORT_LOGFILE% 2>&1
	SCHTASKS /Run /TN !taskname!                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                              >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Set CheckId scheduled task ... NO                                                                                   >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_DEL_CHECK_ID_TASK (
	set taskname=\Siemens\Lms\CheckLMS_CheckID
	echo     delete CheckId scheduled task '!taskname!' ...
	echo Delete CheckId scheduled task '!taskname!' ...                                                                      >> %REPORT_LOGFILE% 2>&1
	SCHTASKS /Delete /TN !taskname! /F                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                              >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Delete CheckId scheduled task ... NO                                                                                >> %REPORT_LOGFILE% 2>&1
)

rem Start Demo Vendor Daemon provided by Flexera; see also "1253827: CheckLMS: add support to run demo vendor daemon"
if defined LMS_START_DEMO_VD (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo     start demo vendor daemon ...
	echo Start Demo Vendor Daemon ...                                                                                        >> %REPORT_LOGFILE% 2>&1
	if exist "!LMS_DEMOLF_VD!" (
		if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
			echo Copy demo vendor daemon ...                                                                                 >> %REPORT_LOGFILE% 2>&1
			echo copy "!LMS_DEMOLF_VD!" to "!LMS_SERVERTOOL_PATH!\demo.exe" ...                                              >> %REPORT_LOGFILE% 2>&1
			copy /Y "!LMS_DEMOLF_VD!" "!LMS_SERVERTOOL_PATH!\demo.exe"                                                       >> %REPORT_LOGFILE% 2>&1
			if exist "!LMS_SERVERTOOL_PATH!\demo.exe" (
				echo Started: "!LMS_SERVERTOOL_PATH!\lmgrd.exe" -c !DOWNLOAD_LMS_PATH!\counted.lic -l !REPORT_LOG_PATH!\demo_debuglog.txt >> %REPORT_LOGFILE% 2>&1
				"!LMS_SERVERTOOL_PATH!\lmgrd.exe" -c "!DOWNLOAD_LMS_PATH!\counted.lic" -l "!REPORT_LOG_PATH!\demo_debuglog.txt"  >> %REPORT_LOGFILE% 2>&1
			)
		) else (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: Cannot start Demo Vendor Daemon, start script with administrator priviledge. [1;37m
			) else (
				echo     WARNING: Cannot start Demo Vendor Daemon, start script with administrator priviledge.
			)
			echo WARNING: Cannot start Demo Vendor Daemon, start script with administrator priviledge.                       >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: Cannot start Demo Vendor Daemon, file '!LMS_DEMOLF_VD!' doesn't exist. [1;37m
		) else (
			echo     WARNING: Cannot start Demo Vendor Daemon, file '!LMS_DEMOLF_VD!' doesn't exist.
		)
		echo WARNING: Cannot start Demo Vendor Daemon, file '!LMS_DEMOLF_VD!' doesn't exist.                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	if exist "!REPORT_LOG_PATH!\demo_debuglog.txt" (
		echo LOG FILE: demo_debuglog.txt [last %LOG_FILE_LINES% lines]                                                       >> %REPORT_LOGFILE% 2>&1
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\demo_debuglog.txt' | Select-Object -last %LOG_FILE_LINES%}"   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo LOG FILE: !REPORT_LOG_PATH!\demo_debuglog.txt not found!                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                              >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Start Demo Vendor Daemon ... NO                                                                                     >> %REPORT_LOGFILE% 2>&1
)
rem Stop Demo Vendor Daemon provided by Flexera; see also "1253827: CheckLMS: add support to run demo vendor daemon"
if defined LMS_STOP_DEMO_VD (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo     stop demo vendor daemon ...
	echo Stop Demo Vendor Daemon ...                                                                                         >> %REPORT_LOGFILE% 2>&1
	if exist "!LMS_SERVERTOOL_PATH!\demo.exe" (
		if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
			if exist "!LMS_LMDOWN!" (
				echo Stopped: "!LMS_LMDOWN!" -c !DOWNLOAD_LMS_PATH!\counted.lic -vendor demo -q                              >> %REPORT_LOGFILE% 2>&1
				"!LMS_LMDOWN!" -c "!DOWNLOAD_LMS_PATH!\counted.lic" -vendor demo -q                                          >> %REPORT_LOGFILE% 2>&1
				echo Kill all running lmgrd.exe ...                                                                          >> %REPORT_LOGFILE% 2>&1
				taskkill /f /im lmgrd.exe                                                                                    >> %REPORT_LOGFILE% 2>&1
				echo Delete demo vendor daemon ...                                                                           >> %REPORT_LOGFILE% 2>&1
				del "!LMS_SERVERTOOL_PATH!\demo.exe"                                                                         >> %REPORT_LOGFILE% 2>&1
				echo Restart: 'FlexNet Licensing Service' and 'Siemens BT Licensing Server'                                  >> %REPORT_LOGFILE% 2>&1
				powershell -Command "& {Restart-Service -displayname 'FlexNet Licensing Service' -force}"                    >> %REPORT_LOGFILE% 2>&1
				powershell -Command "& {Restart-Service -displayname 'Siemens BT Licensing Server'}"                         >> %REPORT_LOGFILE% 2>&1
			) else (
				if defined SHOW_COLORED_OUTPUT (
					echo [1;33m    WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_LMDOWN! doesn't exist. [1;37m
				) else (
					echo     WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_LMDOWN!' doesn't exist.
				)
				echo WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_LMDOWN!' doesn't exist.                             >> %REPORT_LOGFILE% 2>&1
			)
		) else (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: Cannot stop Demo Vendor Daemon, start script with administrator priviledge. [1;37m
			) else (
				echo     WARNING: Cannot stop Demo Vendor Daemon, start script with administrator priviledge.
			)
			echo WARNING: Cannot stop Demo Vendor Daemon, start script with administrator priviledge.                        >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_SERVERTOOL_PATH!\demo.exe' doesn't exist. [1;37m
		) else (
			echo     WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_SERVERTOOL_PATH!\demo.exe' doesn't exist.
		)
		echo WARNING: Cannot stop Demo Vendor Daemon, file '!LMS_SERVERTOOL_PATH!\demo.exe' doesn't exist.                   >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	if exist "!REPORT_LOG_PATH!\demo_debuglog.txt" (
		echo LOG FILE: demo_debuglog.txt [last %LOG_FILE_LINES% lines]                                                       >> %REPORT_LOGFILE% 2>&1
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\demo_debuglog.txt' | Select-Object -last %LOG_FILE_LINES%}"   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo LOG FILE: !REPORT_LOG_PATH!\demo_debuglog.txt not found!                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                              >> %REPORT_LOGFILE% 2>&1
	rem save (single) report in full report file
	Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%
	exit /b
	rem STOP EXECUTION HERE
) else (
	echo Stop Demo Vendor Daemon ... NO                                                                                      >> %REPORT_LOGFILE% 2>&1
)

if not defined LMS_CHECK_ID (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
	echo Convert CSID configuration file, with LmuTool.exe /MULTICSID                                                        >> %REPORT_LOGFILE% 2>&1
	echo     Convert CSID configuration file, with LmuTool.exe /MULTICSID
	if defined LMS_LMUTOOL (
		rem if 2.5.816 or newer ...
		if /I !LMS_BUILD_VERSION! GEQ 816 (
			"!LMS_LMUTOOL!" /MULTICSID                                                                                       >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     This operation is not required with LMS !LMS_VERSION!, don't perform operation.                         >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                  >> %REPORT_LOGFILE% 2>&1 
	)
)

echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1

echo ... start collecting information ...

rem This 'goto' is quite ugly, but some %LMS_xx% contains brackets, which fail within an IF :-(
if defined LMS_CHECK_ID goto skip_use_block
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
echo Use '%UNZIP_TOOL%' to unzip files.                                                                                      >> %REPORT_LOGFILE% 2>&1
echo Use '%SIGCHECK_TOOL%' with option '!SIGCHECK_OPTIONS!' to check signatutes of files.                                    >> %REPORT_LOGFILE% 2>&1
echo Use '%USBDEVIEW_TOOL%' to check USB devices connected to this system.                                                   >> %REPORT_LOGFILE% 2>&1
echo Use '!REPORT_LOG_PATH!' to search for logfiles.                                                                         >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_SERVERTOOL_PATH%' as path to call FNP library tools.                                                          >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_SERVERTOOL_DW_PATH%' as path to call FNP library tools just downloaded.                                       >> %REPORT_LOGFILE% 2>&1
echo Use '!LMS_LMUTOOL!' to call for LmuTool.                                                                                >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_APPACTUTIL%' to call for appactutil.exe.                                                                      >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMDIAG%' to call for lmdiag.exe.                                                                              >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMHOSTID%' to call for lmhostid.exe.                                                                          >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMSTAT%' to call for lmstat.exe.                                                                              >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMTPMINFO%' to call for lmtpminfo.exe.                                                                        >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMVMINFO%' to call for lmvminfo.exe.                                                                          >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_SERVERCOMTRANUTIL%' to call for servercomptranutil.exe.                                                       >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_TSACTDIAGSSVR%' to call for tsactdiags_SIEMBT_svr.exe.                                                        >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_TSRESETSVR%' to call for tsreset_svr.exe.                                                                     >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_TSRESETAPP%' to call for tsreset_app.exe.                                                                     >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_SERVERACTUTIL%' to call for serveractutil.exe.                                                                >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_APPCOMPTRANUTIL%' to call for appcomptranutil.exe.                                                            >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMUTIL%' to call for lmutil.exe.                                                                              >> %REPORT_LOGFILE% 2>&1
echo Use '%LMS_LMVER%' to call for lmver.exe.                                                                                >> %REPORT_LOGFILE% 2>&1
echo Use '!LMS_LMDOWN!' to call for lmdown.exe.                                                                              >> %REPORT_LOGFILE% 2>&1
echo Use '%DOCUMENTATION_PATH%' to search for documentation.                                                                 >> %REPORT_LOGFILE% 2>&1
:skip_use_block

echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPTSBACKUP (
	SET STAMP=%DATE:/=-% %TIME::=.%
	echo Backup trusted store files, into 'TSbackup !STAMP!'                                                                 >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		xcopy %ALLUSERSPROFILE%\FLEXnet\SIEMBT* "%ALLUSERSPROFILE%\FLEXnet\TSbackup !STAMP!" /Y /H /I                        >> %REPORT_LOGFILE% 2>&1
		echo     ... copied to '%ALLUSERSPROFILE%\FLEXnet\TSbackup !STAMP!'                                                  >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
	)
	xcopy %ALLUSERSPROFILE%\FLEXnet\SIEMBT* "!REPORT_LOG_PATH!\TSbackup !STAMP!" /Y /H /I                                    >> %REPORT_LOGFILE% 2>&1
	echo     ... copied to '!REPORT_LOG_PATH!\TSbackup !STAMP!'                                                              >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED TS backup section. The script didn't execute the TS backup commands. [1;37m
	) else (
		echo     SKIPPED TS backup section. The script didn't execute the TS backup commands.
	)
	echo SKIPPED TS backup section. The script didn't execute the TS backup commands.                                        >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Get LmuTool Configuration: [read with LmuTool]                                                                          >> %REPORT_LOGFILE% 2>&1
echo     Get LmuTool Configuration: [read with LmuTool]
if defined LMS_LMUTOOL "!LMS_LMUTOOL!" /??  > !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt 2>&1
set LMS_CFG_LICENSE_SRV_NAME=
IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "LicenseSrvName"') do set "LMS_CFG_LICENSE_SRV_NAME=%%i"
set LMS_CFG_LICENSE_SRV_PORT=
IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "LicenseSrvPort"') do set "LMS_CFG_LICENSE_SRV_PORT=%%i"
if defined LMS_CFG_LICENSE_SRV_NAME (
    echo Configured license server: !LMS_CFG_LICENSE_SRV_NAME! with port !LMS_CFG_LICENSE_SRV_PORT!                          >> %REPORT_LOGFILE% 2>&1
    echo     Configured license server: !LMS_CFG_LICENSE_SRV_NAME! with port !LMS_CFG_LICENSE_SRV_PORT!
) else (
    echo Configured license server: no server configured.                                                                    >> %REPORT_LOGFILE% 2>&1
    echo     Configured license server: no server configured.
)
set LMS_FNO_SERVER=
rem IF EXIST "%ProgramFiles%\Siemens\LMS\bin\LmuTool.profile" for /f "tokens=1,3 delims=<> eol=@" %%A in ('type "%ProgramFiles%\Siemens\LMS\bin\LmuTool.profile" ^|find /I "Fno"') do set "LMS_FNO_SERVER=%%B"
IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "FlexServiceAddress"') do set "LMS_FNO_SERVER=%%i"
if defined LMS_FNO_SERVER (
    echo Configured FNO server: %LMS_FNO_SERVER%                                                                             >> %REPORT_LOGFILE% 2>&1 
    echo     Configured FNO server: %LMS_FNO_SERVER% 
) else (
	set LMS_FNO_SERVER=https://lms.bt.siemens.com/flexnet/services/ActivationService
    echo Configured FNO server: no server configured, use %LMS_FNO_SERVER% instead.                                          >> %REPORT_LOGFILE% 2>&1 
    echo     Configured FNO server: no server configured, use %LMS_FNO_SERVER% instead.
)
set LMS_CFG_CULTUREID=
IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "CultureId"') do set "LMS_CFG_CULTUREID=%%i"
if defined LMS_CFG_CULTUREID (
    echo Configured culture Id: %LMS_CFG_CULTUREID%                                                                          >> %REPORT_LOGFILE% 2>&1 
    echo     Configured culture Id: %LMS_CFG_CULTUREID% 
) else (
    echo Configured culture Id: no id configured.                                                                            >> %REPORT_LOGFILE% 2>&1
    echo     Configured culture Id: no id configured.
)
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   W I N D O W S   S Y S T E M   I N F O R M A T I O N                      =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo Operating System Language: !OS_LANGUAGE!                                                                                >> %REPORT_LOGFILE% 2>&1
echo Local Language: !LOCAL_LANGUAGE!                                                                                        >> %REPORT_LOGFILE% 2>&1
echo Configured culture Id: %LMS_CFG_CULTUREID%                                                                              >> %REPORT_LOGFILE% 2>&1 
echo Temporary folder is: !temp!                                                                                             >> %REPORT_LOGFILE% 2>&1
rem echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
rem See output of 'systeminfo' further down
rem echo System start time:                                                                                                      >> %REPORT_LOGFILE% 2>&1
rem if /I !OS_LANGUAGE! EQU 1033 (
rem 	rem English (United States)
rem 	systeminfo | findstr "Time:"                                                                                             >> %REPORT_LOGFILE% 2>&1
rem ) else (
rem 	if /I !OS_LANGUAGE! EQU 1031 (
rem 		rem German (Standard)
rem 		systeminfo | findstr "Systemstartzeit:"                                                                              >> %REPORT_LOGFILE% 2>&1
rem 	) else (
rem 		echo     works only on "known" languages, for languages !OS_LANGUAGE! check output of systeminfo further down.       >> %REPORT_LOGFILE% 2>&1
rem 	)
rem )
echo Collect information from windows [wmic] ...                                                                                 >> %REPORT_LOGFILE% 2>&1
echo ... collect information from windows [wmic] ...
if not defined LMS_SKIPWMIC (
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo     Read installed products and version [with wmic /format:csv product get name, version, InstallDate, vendor]
	echo Read installed products and version [with wmic product get name, version, InstallDate, vendor /format:csv]              >> %REPORT_LOGFILE% 2>&1
	wmic /output:%REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV% product get name, version, InstallDate, vendor /format:csv               >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo WMIC Report [using PowerShell: Get-WmiObject -class Win32_BIOS]:                                                        >> %REPORT_LOGFILE% 2>&1
	powershell -c Get-WmiObject -class Win32_BIOS                                                                                >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/identify_ec2_instances.html
	echo WMIC Report [using PowerShell: Get-WmiObject -query 'select uuid from Win32_ComputerSystemProduct']:                    >> %REPORT_LOGFILE% 2>&1
	powershell -c "Get-WmiObject -query 'select uuid from Win32_ComputerSystemProduct' | Select UUID"                            >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	rem see https://www.lisenet.com/2014/get-windows-system-information-via-wmi-command-line-wmic/
	echo WMIC Report                                                                                                             >> %REPORT_LOGFILE% 2>&1
	del %REPORT_WMIC_LOGFILE% >nul 2>&1
	echo ---------------- wmic csproduct get *                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo     wmic csproduct get *
	wmic /output:%REPORT_WMIC_LOGFILE% csproduct get * /format:list                    
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic OS get Caption,CSDVersion,OSArchitecture,Version                                                  >> %REPORT_LOGFILE% 2>&1
	echo     More information to Windows Version, see https://en.wikipedia.org/wiki/Windows_10_version_history                   >> %REPORT_LOGFILE% 2>&1
	echo     wmic OS get Caption,CSDVersion,OSArchitecture,Version
	wmic /output:%REPORT_WMIC_LOGFILE% OS get Caption,CSDVersion,OSArchitecture,Version /format:list                    
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicOS_fullList.txt OS get /format:list                                              >> %REPORT_LOGFILE% 2>&1                    
	echo ---------------- wmic BIOS get Manufacturer,Name,SMBIOSBIOSVersion,Version,BuildNumber,InstallDate,SerialNumber,Description                         >> %REPORT_LOGFILE% 2>&1
	echo     wmic BIOS get Manufacturer,Name,SMBIOSBIOSVersion,Version,BuildNumber,InstallDate,SerialNumber,Description
	wmic /output:%REPORT_WMIC_LOGFILE% BIOS get Manufacturer,Name,SMBIOSBIOSVersion,Version,BuildNumber,InstallDate,SerialNumber,Description  /format:list   >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicBIOS_fullList.txt BIOS get /format:list                                          >> %REPORT_LOGFILE% 2>&1             
	echo ---------------- wmic CPU get Name,NumberOfCores,NumberOfLogicalProcessors                                              >> %REPORT_LOGFILE% 2>&1
	echo     wmic CPU get Name,NumberOfCores,NumberOfLogicalProcessors
	wmic /output:%REPORT_WMIC_LOGFILE% CPU get Name,NumberOfCores,NumberOfLogicalProcessors /format:list                         >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicCPU_fullList.txt CPU get /format:list                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic MEMPHYSICAL get MaxCapacity                                                                       >> %REPORT_LOGFILE% 2>&1
	echo     wmic MEMPHYSICAL get MaxCapacity
	wmic /output:%REPORT_WMIC_LOGFILE% MEMPHYSICAL get MaxCapacity /format:list                                                  >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicMEMPHYSICAL_fullList.txt MEMPHYSICAL get /format:list                            >> %REPORT_LOGFILE% 2>&1              
	echo ---------------- wmic MEMORYCHIP get Capacity,DeviceLocator,PartNumber,Tag                                              >> %REPORT_LOGFILE% 2>&1
	echo     wmic MEMORYCHIP get Capacity,DeviceLocator,PartNumber,Tag
	wmic /output:%REPORT_WMIC_LOGFILE% MEMORYCHIP get Capacity,DeviceLocator,PartNumber,Tag                                      >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicMEMORYCHIP_fullList.txt MEMORYCHIP get /format:list                              >> %REPORT_LOGFILE% 2>&1    
	echo ---------------- wmic NIC get Description,MACAddress,NetEnabled,Speed,PhysicalAdapter,PNPDeviceID                       >> %REPORT_LOGFILE% 2>&1
	echo     wmic NIC get Description,MACAddress,NetEnabled,Speed,PhysicalAdapter,PNPDeviceID
	wmic /output:%REPORT_WMIC_LOGFILE% NIC get Description,MACAddress,NetEnabled,Speed,PhysicalAdapter,PNPDeviceID               >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicNIC_fullList.txt NIC get /format:list                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic DISKDRIVE get InterfaceType,Name,Manufacturer,Model,MediaType,SerialNumber,Size,Status            >> %REPORT_LOGFILE% 2>&1
	echo     wmic DISKDRIVE get InterfaceType,Name,Manufacturer,Model,MediaType,SerialNumber,Size,Status
	wmic /output:%REPORT_WMIC_LOGFILE% DISKDRIVE get InterfaceType,Name,Manufacturer,Model,MediaType,SerialNumber,Size,Status    >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicDISKDRIVE_fullList.txt DISKDRIVE get /format:list                                >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic path win32_physicalmedia get SerialNumber                                                         >> %REPORT_LOGFILE% 2>&1
	echo     wmic path win32_physicalmedia get SerialNumber
	wmic /output:%REPORT_WMIC_LOGFILE% path win32_physicalmedia get SerialNumber                                                 >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicpathwin32_fullList.txt path win32_physicalmedia get /format:list                 >> %REPORT_LOGFILE% 2>&1     
	echo ---------------- wmic path win32_computersystemproduct get uuid                                                         >> %REPORT_LOGFILE% 2>&1
	rem see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/identify_ec2_instances.html
	echo     wmic path win32_computersystemproduct get uuid
	wmic /output:%REPORT_WMIC_LOGFILE% path win32_computersystemproduct get uuid                                                 >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicpathwin32_computersystemproduct_fullList.txt path win32_computersystemproduct get /format:list               >> %REPORT_LOGFILE% 2>&1     
	echo ---------------- wmic path msft_disk get Model,BusType,SerialNumber,AdapterSerialNumber                                 >> %REPORT_LOGFILE% 2>&1
	echo     wmic path msft_disk get Model,BusType,SerialNumber,AdapterSerialNumber
	wmic /output:%REPORT_WMIC_LOGFILE% /namespace:\\root\microsoft\windows\storage path msft_disk get Model,BusType,SerialNumber,AdapterSerialNumber         >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicpathmsftdisk_fullList.txt /namespace:\\root\microsoft\windows\storage path msft_disk get /format:list        >> %REPORT_LOGFILE% 2>&1     
	echo ---------------- wmic baseboard get manufacturer, product, Serialnumber, version                                        >> %REPORT_LOGFILE% 2>&1
	echo     wmic baseboard get manufacturer, product, Serialnumber, version
	wmic /output:%REPORT_WMIC_LOGFILE% baseboard get manufacturer, product, Serialnumber, version                                >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicbaseboard_fullList.txt baseboard get /format:list                                >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic os get locale, oslanguage, codeset                                                                >> %REPORT_LOGFILE% 2>&1
	echo     wmic os get locale, oslanguage, codeset
	echo see http://www.robvanderwoude.com/languagecodes.php                                                                     >> %REPORT_LOGFILE% 2>&1
	wmic /output:%REPORT_WMIC_LOGFILE% os get locale, oslanguage, codeset /format:list                                           >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicos_fullList.txt os get /format:list                                              >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic product get name, version, InstallDate, vendor [with vendor=Siemens]                              >> %REPORT_LOGFILE% 2>&1
	echo ... read installed products and version [with wmic] ...
	echo     wmic product get name, version, InstallDate, vendor [for vendor=Siemens]
	echo Read installed products and version [with wmic, for vendor=Siemens]                                                     >> %REPORT_LOGFILE% 2>&1
	wmic /output:%REPORT_WMIC_LOGFILE% product where "Vendor like '%%Siemens%%'" get name, version, InstallDate, vendor          >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo ---------------- analyze installed software [%REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV%]                                    >> %REPORT_LOGFILE% 2>&1
	set DONGLE_DRIVER_INSTALL_DATE=N/A
	set SSU_INSTALL_DATE=N/A
	set LMS_INSTALL_DATE=N/A
	IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=1 eol=@ delims=<> " %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Siemens License Management"') do set LMS_INSTALL_DATE=%%i
	IF EXIST "%REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV%" for /f "tokens=1,2,3,4,5 eol=@ delims=," %%A in ('type %REPORT_WMIC_INSTALLED_SW_LOGFILE_CSV%') do (
		if "%%C" == "Sentinel Runtime" (
			set DONGLE_DRIVER_INSTALL_DATE=%%B
			echo 'Dongle Driver' [Version=%%E] installation date: !DONGLE_DRIVER_INSTALL_DATE!                                   >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Sentinel Runtime R01" (
			set DONGLE_DRIVER_INSTALL_DATE=%%B
			echo 'Dongle Driver' [Version=%%E] installation date: !DONGLE_DRIVER_INSTALL_DATE!                                   >> %REPORT_LOGFILE% 2>&1
			echo NOTE: There was a dongle driver update to version V7.81 at !DONGLE_DRIVER_INSTALL_DATE! provided by ATOS.       >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Sentinel License Manager R01" (
			set DONGLE_DRIVER_INSTALL_DATE=%%B
			echo 'Dongle Driver' [Version=%%E] installation date: !DONGLE_DRIVER_INSTALL_DATE!                                   >> %REPORT_LOGFILE% 2>&1
			echo NOTE: There was a dongle driver update to version V7.92 at !DONGLE_DRIVER_INSTALL_DATE! provided by ATOS.       >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Siemens Software Updater" (
			set SSU_INSTALL_DATE=%%B
			echo 'Siemens Software Updater' [Version=%%E] installation date: !SSU_INSTALL_DATE!                                  >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Siemens License Management" (
			set LMS_INSTALL_DATE=%%B
			echo 'License Management System' [Version=%%E] installation date: !LMS_INSTALL_DATE!                                 >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Siemens License Management R01" (
			set LMS_INSTALL_DATE=%%B
			echo 'License Management System' [Version=%%E] installation date: !LMS_INSTALL_DATE!                                 >> %REPORT_LOGFILE% 2>&1
			echo NOTE: LMS 'R01' has been installed at !LMS_INSTALL_DATE! via Software Center [provided by ATOS]                 >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
		if "%%C" == "Siemens License Management R02" (
			set LMS_INSTALL_DATE=%%B
			echo 'License Management System' [Version=%%E] installation date: !LMS_INSTALL_DATE!                                 >> %REPORT_LOGFILE% 2>&1
			echo NOTE: LMS 'R02' has been installed at !LMS_INSTALL_DATE! via Software Center [provided by ATOS]                 >> %REPORT_LOGFILE% 2>&1
			echo     [Installldate=%%B] / [App=%%C] / [Vendor=%%D] /[Version=%%E]                                                >> %REPORT_LOGFILE% 2>&1
		)
	)
	if defined LMS_INSTALLED_BY_ATOS (
		rem based on registry key: "HKLM\SOFTWARE\LicenseManagementSystem\IsInstalled"
		echo NOTE: LMS has been installed at !LMS_INSTALL_DATE! via Software Center [provided by ATOS]                           >> %REPORT_LOGFILE% 2>&1
	)
	echo ---------------- analyze installed software [check number of installed Siemens Software]                                >> %REPORT_LOGFILE% 2>&1
	set NUM_OF_INSTALLED_SW_FROM_SIEMENS=
	set NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1=130
	set NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2=80
	IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "usebackq" %%A in (`TYPE %REPORT_WMIC_LOGFILE% ^| find /v /c "" `) do set NUM_OF_INSTALLED_SW_FROM_SIEMENS=%%A
	if defined NUM_OF_INSTALLED_SW_FROM_SIEMENS (
		set /A NUM_OF_INSTALLED_SW_FROM_SIEMENS -= 1 
		echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS!.                               >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		rem check bumber of installed siemens software, see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/822161
		if /I !NUM_OF_INSTALLED_SW_FROM_SIEMENS! GEQ !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1! (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation. [1;37m
			) else (
				echo     NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation.
			)
			echo NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation.              >> %REPORT_LOGFILE% 2>&1
		) else (
			if /I !NUM_OF_INSTALLED_SW_FROM_SIEMENS! GEQ !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2! (
					if defined SHOW_COLORED_OUTPUT (
						echo [1;33m    WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation. [1;37m
					) else (
						echo     WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation.
					)
					echo WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation. >> %REPORT_LOGFILE% 2>&1
			)
		)
	)
	echo ---------------- wmic product get name, version, InstallDate, vendor                                                    >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo     Read installed products and version [with wmic product get name, version, InstallDate, vendor]
	echo Read installed products and version [with wmic]                                                                         >> %REPORT_LOGFILE% 2>&1
	wmic /output:%REPORT_WMIC_INSTALLED_SW_LOGFILE% product get name, version, InstallDate, vendor                               >> %REPORT_LOGFILE% 2>&1
	type %REPORT_WMIC_INSTALLED_SW_LOGFILE%                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     Read installed products and version [with wmic *] 
	echo Read installed products and version [with wmic *]                                                                       >> %REPORT_LOGFILE% 2>&1
	wmic /output:!CHECKLMS_REPORT_LOG_PATH!\wmicproduct_fullList.txt product get /format:list                                    >> %REPORT_LOGFILE% 2>&1
	echo     see more details in !CHECKLMS_REPORT_LOG_PATH!\wmicproduct_fullList.txt                                             >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED wmic section. The script didn't execute the wmic commands. [1;37m
	) else (
		echo     SKIPPED wmic section. The script didn't execute the wmic commands.
	)
	echo SKIPPED wmic section. The script didn't execute the wmic commands.                                                      >> %REPORT_LOGFILE% 2>&1
)
echo Collect further information from windows ...                                                                                >> %REPORT_LOGFILE% 2>&1
echo ... collect further information from windows ...
if not defined LMS_SKIPWINDOWS (
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... read installed .NET framework[s] [reg query] ...
	echo Read installed .NET framework[s] [reg query]                                                                            >> %REPORT_LOGFILE% 2>&1
	reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v "Version" /z                                          >> %REPORT_LOGFILE% 2>&1
	reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v "Release" /z                                          >> %REPORT_LOGFILE% 2>&1
	reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP" /f "v*"                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... read .NET information [dotnet --info] ...
	echo Read .NET information [dotnet --info]                                                                                   >> %REPORT_LOGFILE% 2>&1
	dotnet --info                                                                                                                >> %REPORT_LOGFILE% 2>&1
	if not !ERRORLEVEL!==0 (
		echo     ERROR: An error occured during execution of 'dotnet --info' [ERRORLEVEL=!ERRORLEVEL!]                           >> %REPORT_LOGFILE% 2>&1
		if exist "%programfiles%\dotnet\dotnet.exe" (
			echo     'dotnet.exe' found at '%programfiles%\dotnet\dotnet.exe'!                                                   >> %REPORT_LOGFILE% 2>&1
		)
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... read installed products and version [from registry] ...
	echo Read installed products and version [from registry]                                                                     >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\InstalledProgramsReport1.log 2>&1
	Powershell -command "Powershell -command "Get-Item HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"                                                                      > !CHECKLMS_REPORT_LOG_PATH!\InstalledProgramsReport2.log 2>&1
	rem type !CHECKLMS_REPORT_LOG_PATH!\InstalledProgramsReport.log >> %REPORT_LOGFILE% 2>&1
	echo     See full details in '!CHECKLMS_REPORT_LOG_PATH!\InstalledProgramsReport1.log' and '!CHECKLMS_REPORT_LOG_PATH!\InstalledProgramsReport2.log'!  >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo ... list installed VC++ redistributable binaries [DLLs] ...
	echo List installed VC++ redistributable binaries [DLLs]                                                                     >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "%windir%\System32\msvcp*"                                                                           >> %REPORT_LOGFILE% 2>&1
	dir /A /X /4 /W %windir%\System32\msvcp*                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	ver                                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo see https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions                                                    >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... display environment variables [using set command] ...
	echo Display environment variables [using set command]:                                                                      >> %REPORT_LOGFILE% 2>&1
	set                                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve list of drivers [using driverquery] ...
	echo Retrieve list of drivers [using driverquery]:                                                                           >> %REPORT_LOGFILE% 2>&1
	driverquery /v                                                                                                               >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo For more details, see !CHECKLMS_REPORT_LOG_PATH!\driverquery_fullList.txt                                               >> %REPORT_LOGFILE% 2>&1
	driverquery /FO list /v  >> !CHECKLMS_REPORT_LOG_PATH!\driverquery_fullList.txt 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve system time information ...
	echo     w32tm /stripchart /computer:us.pool.ntp.org /dataonly /samples:2 ...
	echo Retrieve system time information [using w32tm /stripchart /computer:us.pool.ntp.org /dataonly /samples:2]:              >> %REPORT_LOGFILE% 2>&1
	w32tm /stripchart /computer:us.pool.ntp.org /dataonly /samples:2                                                             >> %REPORT_LOGFILE% 2>&1
	echo     w32tm /query /status  ...
	echo Retrieve system time information [using w32tm /query /status]:                                                          >> %REPORT_LOGFILE% 2>&1
	w32tm /query /status                                                                                                         >> %REPORT_LOGFILE% 2>&1
	echo     w32tm /query /peers ...
	echo Retrieve system time information [using w32tm /query /peers]:                                                           >> %REPORT_LOGFILE% 2>&1
	w32tm /query /peers                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-Host"                                                                         >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve powershell version ...
	echo Retrieve powershell version [using 'powershell -command "Get-Host"']:                                                   >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-Host"                                                                                               >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "[Net.ServicePointManager]::SecurityProtocol"                                      >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve installed security protocols ...
	echo Retrieve installed security protocols [using 'powershell -command "[Net.ServicePointManager]::SecurityProtocol"']:      >> %REPORT_LOGFILE% 2>&1
	powershell -command "[Net.ServicePointManager]::SecurityProtocol"                                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' ..."   >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve regitry key 'SchUseStrongCrypto' ...
	echo Retrieve regitry key 'SchUseStrongCrypto' [using 'powershell -command "Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' ..."']: >> %REPORT_LOGFILE% 2>&1
	powershell -Command "Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto'"  >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-ExecutionPolicy"                                                              >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve powershell execution policy ...
	echo Retrieve powershell execution policy [using 'powershell -command "Get-ExecutionPolicy"']:                               >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-ExecutionPolicy"                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-TimeZone"                                                                     >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve time zone information ...
	echo Retrieve time zone information [using 'powershell -command "Get-TimeZone"']:                                            >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-TimeZone"                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "$PSVersionTable"                                                                  >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve powershell information ...
	echo Retrieve powershell information [using 'powershell -command "$PSVersionTable"']:                                        >> %REPORT_LOGFILE% 2>&1
	powershell -command "$PSVersionTable"                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "& {Get-Service -Name *}"                                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... list installed services [using Get-Service powershell command] ...
	echo List relevant installed services [using Get-Service powershell command]:                                                >> %REPORT_LOGFILE% 2>&1
	powershell -command "& {Get-Service -Name 'Siemens BT Licensing Server'}" > !CHECKLMS_REPORT_LOG_PATH!\getservice.txt 2>&1
	powershell -command "& {Get-Service -Name 'FlexNet Licensing Service*'}" >> !CHECKLMS_REPORT_LOG_PATH!\getservice.txt 2>&1
	powershell -command "& {Get-Service -Name 'Sentinel LDK License Manager'}" >> !CHECKLMS_REPORT_LOG_PATH!\getservice.txt 2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\getservice.txt                                                                               >> %REPORT_LOGFILE% 2>&1
	set /A PROC_RUNNING = 0
	set /A PROC_STOPPED = 0
	set /A PROC_FOUND = 0
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\getservice.txt" for /f "tokens=1 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\getservice.txt ^|find /I "Running"') do set /A PROC_RUNNING += 1
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\getservice.txt" for /f "tokens=1 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\getservice.txt ^|find /I "Stopped"') do set /A PROC_STOPPED += 1
	set /a "PROC_FOUND=!PROC_RUNNING!+!PROC_STOPPED!"
	echo Relevant services: Total !PROC_FOUND! services. !PROC_RUNNING! services running and !PROC_STOPPED! services stopped!    >> %REPORT_LOGFILE% 2>&1
	if /I !PROC_STOPPED! NEQ 0 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: !PROC_STOPPED! relevant services are stopped. [1;37m
		) else (
			echo     ATTENTION: !PROC_STOPPED! relevant services are stopped.
		)
		echo ATTENTION: !PROC_STOPPED! relevant services are stopped.                                                            >> %REPORT_LOGFILE% 2>&1
	)
	if /I !PROC_FOUND! NEQ 4 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Only !PROC_FOUND! relevant services found. [1;37m
		) else (
			echo     ATTENTION: Only !PROC_FOUND! relevant services found.
		)
		echo ATTENTION: Only !PROC_FOUND! relevant services found.                                                               >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\FlexNet Licensing Service' | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_fnls.txt 2>&1
	echo Content of registry key: "HKLM:\SYSTEM\CurrentControlSet\Services\FlexNet Licensing Service" ...                        >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_fnls.txt                                                                            >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\FlexNet Licensing Service 64' | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_fnls64.txt 2>&1
	echo Content of registry key: "HKLM:\SYSTEM\CurrentControlSet\Services\FlexNet Licensing Service 64" ...                     >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_fnls64.txt                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Siemens BT Licensing Server' | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_siembtvd.txt 2>&1
	echo Content of registry key: "HKLM:\SYSTEM\CurrentControlSet\Services\Siemens BT Licensing Server" ...                      >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_siembtvd.txt                                                                        >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo List installed services [using Get-Service powershell command]:                                                         >> %REPORT_LOGFILE% 2>&1
	powershell -command "& {Get-Service -Name *}"                                                                                >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "& {Get-Module -ListAvailable -All}"                                               >> %REPORT_LOGFILE% 2>&1
	echo ... list installed powershell commandlets [using Get-Module powershell command] ...
	echo List installed powershell commandlets [using Get-Module powershell command]:                                            >> %REPORT_LOGFILE% 2>&1
	echo For more details, see !CHECKLMS_REPORT_LOG_PATH!\InstalledPowershellCommandlets.txt                                     >> %REPORT_LOGFILE% 2>&1
	powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Get-Module -ListAvailable -All}" >> !CHECKLMS_REPORT_LOG_PATH!\InstalledPowershellCommandlets.txt 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "%WinDir%\System32\Drivers\Etc"                                                                      >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "%WinDir%\System32\Drivers\Etc"                                                                           >> %REPORT_LOGFILE% 2>&1
	mkdir !CHECKLMS_REPORT_LOG_PATH!\etc\  >nul 2>&1
	xcopy "%WinDir%\System32\Drivers\Etc\*" !CHECKLMS_REPORT_LOG_PATH!\etc\ /E /Y /H /I                                          >> %REPORT_LOGFILE% 2>&1 
	echo --- Files automatically copied from '%WinDir%\System32\Drivers\Etc\*' to '!CHECKLMS_REPORT_LOG_PATH!\etc\' at !DATE! !TIME! --- > !CHECKLMS_REPORT_LOG_PATH!\etc\__README.txt 2>&1
	rem if exist "%WinDir%\System32\Drivers\Etc\hosts" (
	rem 	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	rem 	echo Content of '%WinDir%\System32\Drivers\Etc\hosts':                                                                   >> %REPORT_LOGFILE% 2>&1
	rem 	type "%WinDir%\System32\Drivers\Etc\hosts"                                                                               >> %REPORT_LOGFILE% 2>&1
	rem 	echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	rem )
	rem if exist "%WinDir%\System32\Drivers\Etc\networks" (
	rem 	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	rem 	echo Content of '%WinDir%\System32\Drivers\Etc\networks':                                                                >> %REPORT_LOGFILE% 2>&1
	rem 	type "%WinDir%\System32\Drivers\Etc\networks"                                                                            >> %REPORT_LOGFILE% 2>&1
	rem 	echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	rem )
	rem if exist "%WinDir%\System32\Drivers\Etc\protocol" (
	rem 	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	rem 	echo Content of '%WinDir%\System32\Drivers\Etc\protocol':                                                                >> %REPORT_LOGFILE% 2>&1
	rem 	type "%WinDir%\System32\Drivers\Etc\protocol"                                                                            >> %REPORT_LOGFILE% 2>&1
	rem 	echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	rem )
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... collect system information ...
	echo Collect system information ...                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo ---------------- systeminfo                                                                                             >> %REPORT_LOGFILE% 2>&1
	systeminfo                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo ---------------- wmic qfe list                                                                                          >> %REPORT_LOGFILE% 2>&1
	rem There is an issue, that not all installed patches are listed, see https://support.microsoft.com/en-us/help/2644427/systeminfo-exe-does-not-display-all-updates-in-windows-server-2003
	rem Workaround, use "wmic qfe list"
	wmic /output:%REPORT_WMIC_LOGFILE% qfe list
	type %REPORT_WMIC_LOGFILE%                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-WindowsUpdateLog"                                                             >> %REPORT_LOGFILE% 2>&1
	rem copied from UCMS-LogcollectorDWP.ini
	rem See also https://support.microsoft.com/en-us/kb/3036646
	echo ... retrieve Windows Update Log ...
	echo Retrieve Windows Update Log [using 'powershell -command "Get-WindowsUpdateLog"']:                                       >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-WindowsUpdateLog"     > !CHECKLMS_REPORT_LOG_PATH!\Get-WindowsUpdateLog.log 2>&1
	if exist "%desktop%\WindowsUpdate.log" (
		rem echo ---------------- %desktop%\WindowsUpdate.log:                                                                                                       >> %REPORT_LOGFILE% 2>&1
		rem type "%desktop%\WindowsUpdate.log"                                                                                                                       >> %REPORT_LOGFILE% 2>&1
		robocopy.exe %desktop%  "!CHECKLMS_REPORT_LOG_PATH!" WindowsUpdate.log /MOV /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log                      >> %REPORT_LOGFILE% 2>&1
		echo See !CHECKLMS_REPORT_LOG_PATH!\WindowsUpdate.log                                                                                                        >> %REPORT_LOGFILE% 2>&1
	) else (
		if exist "%DESKTOP_FOLDER%\WindowsUpdate.log" (
			rem echo ---------------- %DESKTOP_FOLDER%\WindowsUpdate.log:                                                                                            >> %REPORT_LOGFILE% 2>&1
			robocopy.exe %DESKTOP_FOLDER% "!CHECKLMS_REPORT_LOG_PATH!" WindowsUpdate.log /MOV /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log            >> %REPORT_LOGFILE% 2>&1
			echo See !CHECKLMS_REPORT_LOG_PATH!\WindowsUpdate.log                                                                                                    >> %REPORT_LOGFILE% 2>&1
		) else (
			if exist "%userprofile%\desktop\WindowsUpdate.log" (
				rem echo ---------------- %userprofile%\desktop\WindowsUpdate.log:                                                                                   >> %REPORT_LOGFILE% 2>&1
				robocopy.exe %userprofile%\desktop "!CHECKLMS_REPORT_LOG_PATH!" WindowsUpdate.log /MOV /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log   >> %REPORT_LOGFILE% 2>&1
				echo See !CHECKLMS_REPORT_LOG_PATH!\WindowsUpdate.log                                                                                                >> %REPORT_LOGFILE% 2>&1
			) else (
				echo WARNING: The logfile 'WindowsUpdate.log' wasn't found; cannot copy it!                                                                          >> %REPORT_LOGFILE% 2>&1
				echo          It wasn't found at: [desktop]='%desktop%' / [DESKTOP_FOLDER]='%DESKTOP_FOLDER%' / [userprofile\desktop\]='%userprofile%\desktop\'.     >> %REPORT_LOGFILE% 2>&1
				if exist "!CHECKLMS_REPORT_LOG_PATH!\Get-WindowsUpdateLog.log" (
					echo Output of 'powershell -command "Get-WindowsUpdateLog"' ...                                                                                  >> %REPORT_LOGFILE% 2>&1
					type "!CHECKLMS_REPORT_LOG_PATH!\Get-WindowsUpdateLog.log"                                                                                       >> %REPORT_LOGFILE% 2>&1
				) else (
					echo WARNING: The output file '!CHECKLMS_REPORT_LOG_PATH!\Get-WindowsUpdateLog.log' doesn't exists; cannot display it!                           >> %REPORT_LOGFILE% 2>&1
				)
			)
		)
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... collect user information ...
	echo Collect user information ...                                                                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- whoami                                                                                                 >> %REPORT_LOGFILE% 2>&1
	whoami                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo ---------------- whoami /user                                                                                           >> %REPORT_LOGFILE% 2>&1
	whoami /user                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ---------------- whoami /groups /fo list                                                                                >> %REPORT_LOGFILE% 2>&1
	whoami /groups /fo list  > !CHECKLMS_REPORT_LOG_PATH!\whoami_groups.log 2>&1
	echo    See full details in '!CHECKLMS_REPORT_LOG_PATH!\whoami_groups.log'                                                   >> %REPORT_LOGFILE% 2>&1
	echo ---------------- whoami /all                                                                                            >> %REPORT_LOGFILE% 2>&1
	whoami /all              > !CHECKLMS_REPORT_LOG_PATH!\whoami_all.log 2>&1
	echo    See full details in '!CHECKLMS_REPORT_LOG_PATH!\whoami_all.log'                                                      >> %REPORT_LOGFILE% 2>&1
	echo ---------------- net user                                                                                               >> %REPORT_LOGFILE% 2>&1
	net user                                                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Gpresult /R                                                                                            >> %REPORT_LOGFILE% 2>&1
	rem copied from UCMS-LogcollectorDWP.ini
	Gpresult /R              > !CHECKLMS_REPORT_LOG_PATH!\gpresult_r.log 2>&1
	echo    See full details in '!CHECKLMS_REPORT_LOG_PATH!\gpresult_r.log'                                                      >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Gpresult /H '!CHECKLMS_REPORT_LOG_PATH!\GpResultUser.html'                                             >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		rem copied from UCMS-LogcollectorDWP.ini
		rem NOTE: Creation of GpResultUser.html takes up to 10 minutes
		del "!CHECKLMS_REPORT_LOG_PATH!\GpResultUser.html" >nul 2>&1
		echo Start creation of 'GpResultUser.html' at !DATE! !TIME! ....                                                         >> %REPORT_LOGFILE% 2>&1
		Gpresult /H "!CHECKLMS_REPORT_LOG_PATH!\GpResultUser.html"                                                               >> %REPORT_LOGFILE% 2>&1
		echo Creation of 'GpResultUser.html' ended at !DATE! !TIME!                                                              >> %REPORT_LOGFILE% 2>&1
		echo See '!CHECKLMS_REPORT_LOG_PATH!\GpResultUser.html' for more details.                                                >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Creation of 'GpResultUser.html' skipped, start script with option '/extend' to enable extended content.             >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... collect task list [process information] ...
	echo Task List [Process Infromation]                                                                                         >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays task list: for specific LMS processes                                                         >> %REPORT_LOGFILE% 2>&1
	echo ----- lmgrd*                                                                                                            >> %REPORT_LOGFILE% 2>&1
	tasklist /FI "IMAGENAME eq lmgrd*"                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo ----- SIEMBT*                                                                                                           >> %REPORT_LOGFILE% 2>&1
	tasklist /FI "IMAGENAME eq SIEMBT*"                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo ----- SIEMENS*                                                                                                          >> %REPORT_LOGFILE% 2>&1
	tasklist /FI "IMAGENAME eq SIEMENS*"                                                                                         >> %REPORT_LOGFILE% 2>&1
	echo ----- hasp*                                                                                                             >> %REPORT_LOGFILE% 2>&1
	tasklist /FI "IMAGENAME eq hasp*"                                                                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays task list: tasklist                                                                           >> %REPORT_LOGFILE% 2>&1
	tasklist                                                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays services hosted in each process: tasklist /SVC                                                >> %REPORT_LOGFILE% 2>&1
	tasklist /SVC                                                                                                                >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Lists all tasks currently using the given exe/dll name: tasklist /M                                    >> %REPORT_LOGFILE% 2>&1
	tasklist /M > !CHECKLMS_REPORT_LOG_PATH!\tasklist_currentlyUsed.txt 2>&1 
	echo     See !CHECKLMS_REPORT_LOG_PATH!\tasklist_currentlyUsed.txt                                                           >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... read network statistics ...
	echo Displays Windows IP Configuration [ipconfig]                                                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays Windows IP Configuration: ipconfig /all                                                       >> %REPORT_LOGFILE% 2>&1
	echo     Displays Windows IP Configuration: ipconfig /all
	ipconfig /all                                                                                                                >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Retrieve public IP address: from http://ip4only.me/api/                                                >> %REPORT_LOGFILE% 2>&1
	rem Connection Test to http://ip4only.me/api/
	powershell -Command "(New-Object Net.WebClient).DownloadFile('http://ip4only.me/api/', '!CHECKLMS_REPORT_LOG_PATH!\ip_address.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_ip4only.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access http://ip4only.me/api/
		echo Connection Test PASSED, can access http://ip4only.me/api/                                                           >> %REPORT_LOGFILE% 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\ip_address.txt"                                                                         >> %REPORT_LOGFILE% 2>&1
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access http://ip4only.me/api/
		echo Connection Test FAILED, cannot access http://ip4only.me/api/                                                        >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_ip4only.txt                                                              >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPWINDOWS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED windows section. The script didn't execute the windows specific commands. [1;37m
	) else (
		echo     SKIPPED windows section. The script didn't execute the windows specific commands.
	)
	echo SKIPPED windows section. The script didn't execute the windows specific commands.                                       >> %REPORT_LOGFILE% 2>&1
)
echo Read network statistics [netstat reports]                                                                                   >> %REPORT_LOGFILE% 2>&1
echo ... read network statistics [netstat reports] ...
if not defined LMS_SKIPNETSTAT (
	echo ---------------- Displays Ethernet statistics: netstat -e                                                               >> %REPORT_LOGFILE% 2>&1
	echo     Displays Ethernet statistics: netstat -e
	netstat -e                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the routing table: netstat -r                                                                 >> %REPORT_LOGFILE% 2>&1
	echo     Displays the routing table: netstat -r
	netstat -r      > !CHECKLMS_REPORT_LOG_PATH!\netstat_r.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_r.log'														 >> %REPORT_LOGFILE% 2>&1                    
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays per-protocol statistics: netstat -s                                                           >> %REPORT_LOGFILE% 2>&1
	echo     Displays per-protocol statistics: netstat -s
	netstat -s      > !CHECKLMS_REPORT_LOG_PATH!\netstat_s.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_s.log'														 >> %REPORT_LOGFILE% 2>&1                    
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays NetworkDirect connections, listeners, and shared endpoints: netstat -x                        >> %REPORT_LOGFILE% 2>&1
	echo     Displays NetworkDirect connections, listeners, and shared endpoints: netstat -x
	netstat -x      > !CHECKLMS_REPORT_LOG_PATH!\netstat_x.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_x.log'														 >> %REPORT_LOGFILE% 2>&1                    
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the owning process ID associated with each connection: netstat -o -f                          >> %REPORT_LOGFILE% 2>&1
	echo     Displays the owning process ID associated with each connection: netstat -o -f
	netstat -o -f   > !CHECKLMS_REPORT_LOG_PATH!\netstat_o_f.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_o_f.log'														 >> %REPORT_LOGFILE% 2>&1                  
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays all connections and listening ports: netstat -a -f                                            >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		echo     Displays all connections and listening ports: netstat -a -f
		netstat -a -f   > !CHECKLMS_REPORT_LOG_PATH!\netstat_a_f.log 2>&1
		echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_a_f.log'												     >> %REPORT_LOGFILE% 2>&1                  
	) else (
		echo Displays all connections and listening ports: 'netstat -a -f' skipped, start script with option '/extend' to enable extended content.             >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the current connection offload state: netstat -t -f                                           >> %REPORT_LOGFILE% 2>&1
	echo     Displays the current connection offload state: netstat -t -f
	netstat -t -f   > !CHECKLMS_REPORT_LOG_PATH!\netstat_t_f.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_t_f.log'														 >> %REPORT_LOGFILE% 2>&1                  
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the executable involved in creating each connection or listening port: netstat -b -f          >> %REPORT_LOGFILE% 2>&1
	echo     Displays the executable involved in creating each connection or listening port: netstat -b -f
	netstat -b -f   > !CHECKLMS_REPORT_LOG_PATH!\netstat_b_f.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_b_f.log'														 >> %REPORT_LOGFILE% 2>&1                  
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the TCP connection template for all connections: netstat -y -f                                >> %REPORT_LOGFILE% 2>&1
	echo     Displays the TCP connection template for all connections: netstat -y -f
	netstat -y -f   > !CHECKLMS_REPORT_LOG_PATH!\netstat_y_f.log 2>&1
    echo     More details see '!CHECKLMS_REPORT_LOG_PATH!\netstat_y_f.log'														 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPNETSTAT
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED netstat section. The script didn't execute the netstat commands. [1;37m
	) else (
		echo     SKIPPED netstat section. The script didn't execute the netstat commands.
	)
	echo SKIPPED netstat section. The script didn't execute the netstat commands.                                                >> %REPORT_LOGFILE% 2>&1
)
echo Read network settings ...                                                                                                   >> %REPORT_LOGFILE% 2>&1
echo ... read network settings ...
if not defined LMS_SKIPNETSETTINGS (
	echo ---------------- powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip"                                      >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve adapter bindings for IPv4 ...
	echo Retrieve powershell version [using 'powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip"']:                >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip"                                                            >> %REPORT_LOGFILE% 2>&1
	echo ---------------- powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip6"                                     >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve adapter bindings for IPv6 ...
	echo Retrieve powershell version [using 'powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip6"']:               >> %REPORT_LOGFILE% 2>&1
	powershell -command "Get-NetAdapterBinding -ComponentID ms_tcpip6"                                                           >> %REPORT_LOGFILE% 2>&1
	echo ---------------- Displays the current ephemeral port range: netsh int ipv4 show dynamicport tcp                         >> %REPORT_LOGFILE% 2>&1
	echo     Displays the current ephemeral port range: netsh int ipv4 show dynamicport tcp
	netsh int ipv4 show dynamicport tcp                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Retrieve WLAN settings [with 'netsh wlan show all']                                                                     >> %REPORT_LOGFILE% 2>&1
	netsh wlan show all   > !CHECKLMS_REPORT_LOG_PATH!\netsh_wlan.log 2>&1
	echo     Full details see '!CHECKLMS_REPORT_LOG_PATH!\netsh_wlan.log'                                                        >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPNETSETTINGS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED network section. The script didn't execute the network commands. [1;37m
	) else (
		echo     SKIPPED network section. The script didn't execute the network commands.
	)
	echo SKIPPED network section. The script didn't execute the network commands.                                            >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... retrieve firewall settings ...
if not defined LMS_SKIPFIREWALL (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Retrieve firewall settings [with 'netsh firewall show state']                                                       >> %REPORT_LOGFILE% 2>&1
	netsh firewall show state                                                                                                >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Retrieve firewall settings [with 'netsh advfirewall firewall show rule name=all verbose']                           >> %REPORT_LOGFILE% 2>&1
	echo     full list see !CHECKLMS_REPORT_LOG_PATH!\firewall_rules.txt                                                     >> %REPORT_LOGFILE% 2>&1
	netsh advfirewall firewall show rule name=all verbose > !CHECKLMS_REPORT_LOG_PATH!\firewall_rules.txt 2>&1
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Retrieve firewall settings [with 'Powershell -command "Show-NetFirewallRule"']                                      >> %REPORT_LOGFILE% 2>&1
	echo     full list see !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt                                                  >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Analyze firewall rules [retrieved with Powershell], check for LMS entries ...                                       >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Show-NetFirewallRule"  > !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt >nul 2>&1
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt" for /f "tokens=1* eol=@ delims=<>: " %%A in (!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_PS.txt) do (
		rem echo [%%A] [%%B]
		set PARAMETER_NAME=%%A
		set PARAMETER_VALUE=%%B
		rem echo [!PARAMETER_NAME!] [!PARAMETER_VALUE!]
		for /f "tokens=* delims= " %%a in ("!PARAMETER_NAME!") do set PARAMETER_NAME=%%a
		for /f "tokens=* delims= " %%a in ("!PARAMETER_VALUE!") do set PARAMETER_VALUE=%%a
		rem echo [!PARAMETER_NAME!] [!PARAMETER_VALUE!]
		if "!PARAMETER_NAME!" EQU "DisplayName" (
			set FIREWALL_RULE_NAME=!PARAMETER_VALUE!
			rem echo Rule Name: !FIREWALL_RULE_NAME!
		)
		if "!PARAMETER_NAME!" EQU "Program" (
			set FIREWALL_PROG_NAME=!PARAMETER_VALUE!
			rem echo [Rule Name=!FIREWALL_RULE_NAME!][Program Name=!FIREWALL_PROG_NAME!]
			echo [Rule Name=!FIREWALL_RULE_NAME!][Program Name=!FIREWALL_PROG_NAME!] >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt  2>&1
		)
	)
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt" (
		for /f "tokens=1,2 eol=@ delims==<>[]" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt ^|find /I "lmgrd.exe"') do set "LMGRD_FOUND=%%B"
		for /f "tokens=1,2 eol=@ delims==<>[]" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_extract.txt ^|find /I "SIEMBT.exe"') do set "SIEMBT_FOUND=%%B"
	)
	del !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt >nul 2>&1
	if defined LMGRD_FOUND (
		echo     Rule for lmgrd.exe found, with name "!LMGRD_FOUND!".                                                        >> %REPORT_LOGFILE% 2>&1
		echo     Rule for lmgrd.exe found, with name "!LMGRD_FOUND!".
		netsh advfirewall firewall show rule name="!LMGRD_FOUND!" verbose >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt 2>&1
	) else (
		echo     NO Rule for lmgrd.exe found.                                                                                >> %REPORT_LOGFILE% 2>&1
		echo     NO Rule for lmgrd.exe found.
	)
	if defined SIEMBT_FOUND (
		echo     Rule for SIEMBT.exe found, with name "!SIEMBT_FOUND!".                                                      >> %REPORT_LOGFILE% 2>&1
		echo     Rule for SIEMBT.exe found, with name "!SIEMBT_FOUND!".
		netsh advfirewall firewall show rule name="!SIEMBT_FOUND!" verbose >> !CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt 2>&1
	) else (
		echo     NO Rule for SIEMBT.exe found.                                                                               >> %REPORT_LOGFILE% 2>&1
		echo     NO Rule for SIEMBT.exe found.
	)
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt" type "!CHECKLMS_REPORT_LOG_PATH!\firewall_rules_LMS.txt"    >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED firewall section. The script didn't execute the firewall commands. [1;37m
	) else (
		echo     SKIPPED firewall section. The script didn't execute the firewall commands.
	)
	echo SKIPPED firewall section. The script didn't execute the firewall commands.                                          >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo ... check LMS registry permission ...
if not defined LMS_CHECK_ID (
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Retrieve registry permissison for !LMS_MAIN_REGISTRY_KEY! [with "Get-Acl HKLM:\SOFTWARE\Siemens\LMS | Format-List"]     >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-Acl HKLM:\SOFTWARE\Siemens\LMS | Format-List"                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   V I R T U A L   E N V I R O N M E N T                                    =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... get information of virtual environment ...
echo Get information of virtual environment ...                                                                             >> %REPORT_LOGFILE% 2>&1
if /I "!LMS_IS_VM!"=="true" (
	echo     Running on a virtual machine.
	echo Running on a virtual machine. LMS_IS_VM=!LMS_IS_VM!                                                                 >> %REPORT_LOGFILE% 2>&1
) else if /I "!LMS_IS_VM!"=="false" (
	echo     NOT running on a virtual machine.
	echo NOT running on a virtual machine. LMS_IS_VM=!LMS_IS_VM!                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	echo     Not clear if running on a virtual machine or not. LMS_IS_VM=!LMS_IS_VM!
	echo Not clear if running on a virtual machine or not. LMS_IS_VM=!LMS_IS_VM!                                             >> %REPORT_LOGFILE% 2>&1
)
rem Read VM Generation Id
IF EXIST "%DOWNLOAD_LMS_PATH%\VMGENID.EXE" (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... read VM Generation Id [using VMGENID.EXE] ...
	echo Read VM Generation Id [using VMGENID.EXE]:                                                                          >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\VMGENID.EXE"                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
)
IF EXIST "%DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe" (
	echo -------------------------------------------------------                                                                                 >> %REPORT_LOGFILE% 2>&1
	if exist "C:\WINDOWS\system32\MSVCR120.dll" (
		echo ... read VM Generation Id [using GetVMGenerationIdentifier.exe] ...
		echo Read VM Generation Id [using GetVMGenerationIdentifier.exe]:                                                                        >> %REPORT_LOGFILE% 2>&1
		"%DOWNLOAD_LMS_PATH%\GetVMGenerationIdentifier.exe"                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo ... read VM Generation Id [using GetVMGenerationIdentifier.exe], skipped because 'C:\WINDOWS\system32\MSVCR120.dll' doesn't exist.
		echo Read VM Generation Id [using GetVMGenerationIdentifier.exe], skipped because 'C:\WINDOWS\system32\MSVCR120.dll' doesn't exist.      >> %REPORT_LOGFILE% 2>&1
	)
)
if /I "!LMS_IS_VM!"=="true" (
	rem call further commands only, when running on a virtual machine, wthin a hypervisor.

	if exist "!REPORT_LOG_PATH!\AWS_Latest.txt" (
		for /f "tokens=1,2,3,4,* eol=@ delims=,/ " %%A in ('type !REPORT_LOG_PATH!\AWS_Latest.txt ^|find /I "AWS_ACCID"') do (
			rem echo %%A / %%B / %%C // %%F
			for /f "tokens=1,2 delims==" %%a in ("%%A") do set AWS_ACCID_PREV=%%b
			for /f "tokens=1,2 delims==" %%a in ("%%B") do set AWS_IMGID_PREV=%%b
			for /f "tokens=1,2 delims==" %%a in ("%%C") do set AWS_INSTID_PREV=%%b
			for /f "tokens=1,2 delims==" %%a in ("%%D") do set AWS_PENTIME_PREV=%%b
			set AWSINFO_PREV=%%E
		)
		echo Previous AWS instance identity document values, collected !AWSINFO_PREV!                                                                                >> %REPORT_LOGFILE% 2>&1
		echo     AWS_ACCID_PREV=!AWS_ACCID_PREV! / AWS_IMGID_PREV=!AWS_IMGID_PREV! / AWS_INSTID_PREV=!AWS_INSTID_PREV! / AWS_PENTIME_PREV=!AWS_PENTIME_PREV!         >> %REPORT_LOGFILE% 2>&1   
	)

	rem get AWS instance identify document (see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/instance-identity-documents.html )
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	powershell -Command "(New-Object Net.WebClient).DownloadFile('http://169.254.169.254/latest/dynamic/instance-identity/document', '!CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document_result.txt 2>&1
	if exist "!CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt" (
		echo AWS instance identity document retrieved:                                                                       >> %REPORT_LOGFILE% 2>&1
		type "!CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt"                                                 >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                               >> %REPORT_LOGFILE% 2>&1
		for /f "tokens=1,2,3 eol=@ delims=, " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt ^|find /I "pendingTime"') do set "AWS_PENTIME=%%C"
		for /f "tokens=1,2,3 eol=@ delims=, " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt ^|find /I "instanceId"') do set "AWS_INSTID=%%C"
		for /f "tokens=1,2,3 eol=@ delims=, " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt ^|find /I "imageId"') do set "AWS_IMGID=%%C"
		for /f "tokens=1,2,3 eol=@ delims=, " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\AWS_instance-identity-document.txt ^|find /I "accountId"') do set "AWS_ACCID=%%C"
		echo     AWS_ACCID=!AWS_ACCID! / AWS_IMGID=!AWS_IMGID! / AWS_INSTID=!AWS_INSTID! / AWS_PENTIME=!AWS_PENTIME!   
		echo     AWS_ACCID=!AWS_ACCID! / AWS_IMGID=!AWS_IMGID! / AWS_INSTID=!AWS_INSTID! / AWS_PENTIME=!AWS_PENTIME!         >> %REPORT_LOGFILE% 2>&1   
		echo     AWS_ACCID=!AWS_ACCID! / AWS_IMGID=!AWS_IMGID! / AWS_INSTID=!AWS_INSTID! / AWS_PENTIME=!AWS_PENTIME!  at !DATE! / !TIME!  >> !REPORT_LOG_PATH!\AWS.txt 2>&1
		echo     AWS_ACCID=!AWS_ACCID! / AWS_IMGID=!AWS_IMGID! / AWS_INSTID=!AWS_INSTID! / AWS_PENTIME=!AWS_PENTIME!  at !DATE! / !TIME!  >  !REPORT_LOG_PATH!\AWS_Latest.txt 2>&1
	) else (
		echo AWS instance identity document not found!                                                                       >> %REPORT_LOGFILE% 2>&1
	)
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   L M S   S C H E D U L E D   T A S K S                                    =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... collect scheduled tasks defintions ...
if not defined LMS_SKIPSCHEDTASK (
	schtasks /Query /V > "!CHECKLMS_REPORT_LOG_PATH!\schtasks.log" 2>&1
	schtasks /QUERY /V /TN \Siemens\ > "!CHECKLMS_REPORT_LOG_PATH!\schtasks_siemens.log" 2>&1
	echo Scheduled Tasks Definitions [for Siemens]                                                                           >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\schtasks_siemens.log" (
		Type "!CHECKLMS_REPORT_LOG_PATH!\schtasks_siemens.log"                                                               >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                               >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No scheduled task found.                                                                                    >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... get details for 'OnStartup' scheduled task ...
	echo Get details for 'OnStartup' scheduled task ...                                                                      >> %REPORT_LOGFILE% 2>&1
	schtasks /query /FO LIST /V /tn "\Siemens\Lms\OnStartup"                                                                 >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... get details for 'WeeklyTask' scheduled task ...
	echo Get details for 'WeeklyTask' scheduled task ...                                                                     >> %REPORT_LOGFILE% 2>&1
	schtasks /query /FO LIST /V /tn "\Siemens\Lms\WeeklyTask"                                                                >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED scheduled task section. The script didn't execute the scheduled task commands. [1;37m
	) else (
		echo     SKIPPED scheduled task section. The script didn't execute the scheduled task commands.
	)
	echo SKIPPED scheduled task section. The script didn't execute the scheduled task commands.                              >> %REPORT_LOGFILE% 2>&1
)
:windows_error_reporting
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   W I N D O W S   E R R O R   R E P O R T I N G  (W E R)                   =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... get crash dump settings ...
echo Get crash dump settings ...                                                                                             >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPWER (
	REM -- WER "DumpType" Registry Key
	set KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps
	set VALUE_NAME=DumpType
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set WER_DUMPTYPE=%%A
	)
	if defined WER_DUMPTYPE (
		echo     Dump type is !WER_DUMPTYPE! [0=Custom dump, 1=Mini dump, 2=Full dump]
		echo Dump type is !WER_DUMPTYPE! [0=Custom dump, 1=Mini dump, 2=Full dump]                                               >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     Dump type is NOT DEFINED, crash dumps are NOT enabled.
		echo     More information available on https://wiki.siemens.com/x/DiCNBg
		echo Dump type is NOT DEFINED, crash dumps are NOT enabled.                                                              >> %REPORT_LOGFILE% 2>&1
		echo More information available on https://wiki.siemens.com/x/DiCNBg                                                     >> %REPORT_LOGFILE% 2>&1
	)
	echo ... search crash dump files [*.dmp] [on c:\ only] ...
	echo Search crash dump files [*.dmp] [on c:\ only]:                                                                        >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_CRASH_DUMP_PATH!\CrashDumpFilesFound.txt >nul 2>&1
	FOR /r C:\ %%X IN (*.dmp) DO if "%%~dpX" NEQ "!CHECKLMS_CRASH_DUMP_PATH!\" echo %%~dpnxX >> !CHECKLMS_CRASH_DUMP_PATH!\CrashDumpFilesFound.txt
	IF EXIST "!CHECKLMS_CRASH_DUMP_PATH!\CrashDumpFilesFound.txt" (
		set CRASHDUMP_FILE_COUNT=0
		set CRASHDUMP_TOTAL_FILE_COUNT=0
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_CRASH_DUMP_PATH!\CrashDumpFilesFound.txt) DO ( 
			set name=%%~nxi
			set /A CRASHDUMP_TOTAL_FILE_COUNT += 1

			set "first=!name:~0,3!"
			if /I "!first!" EQU "alm" (
				set /A CRASHDUMP_FILE_COUNT += 1
				echo %%i copy to !CHECKLMS_CRASH_DUMP_PATH!\            >> %REPORT_LOGFILE% 2>&1   
				copy /Y "%%i" !CHECKLMS_CRASH_DUMP_PATH!\               >> %REPORT_LOGFILE% 2>&1
			)
			set "first=!name:~0,7!"
			if /I "!first!" EQU "Siemens" (
				set /A CRASHDUMP_FILE_COUNT += 1
				echo %%i copy to !CHECKLMS_CRASH_DUMP_PATH!\            >> %REPORT_LOGFILE% 2>&1   
				copy /Y "%%i" !CHECKLMS_CRASH_DUMP_PATH!\               >> %REPORT_LOGFILE% 2>&1
			)
			set "first=!name:~0,6!"
			if /I "!first!" EQU "SIEMBT" (
				set /A CRASHDUMP_FILE_COUNT += 1
				echo %%i copy to !CHECKLMS_CRASH_DUMP_PATH!\            >> %REPORT_LOGFILE% 2>&1   
				copy /Y "%%i" !CHECKLMS_CRASH_DUMP_PATH!\               >> %REPORT_LOGFILE% 2>&1
			)
			set "first=!name:~0,10!"
			if /I "!first!" EQU "SSUManager" (
				set /A CRASHDUMP_FILE_COUNT += 1
				echo %%i copy to !CHECKLMS_CRASH_DUMP_PATH!\            >> %REPORT_LOGFILE% 2>&1   
				copy /Y "%%i" !CHECKLMS_CRASH_DUMP_PATH!\               >> %REPORT_LOGFILE% 2>&1
			)
		)
		echo     Total !CRASHDUMP_FILE_COUNT! out of !CRASHDUMP_TOTAL_FILE_COUNT! crash dump files copied.
		echo     Total !CRASHDUMP_FILE_COUNT! out of !CRASHDUMP_TOTAL_FILE_COUNT! crash dump files copied.   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No crash dump files [*.dmp] found.
		echo     No crash dump files [*.dmp] found.                     >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                    >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED windows error reporting [WER] section. The script didn't execute the windows error reporting [WER] commands. [1;37m
	) else (
		echo     SKIPPED windows error reporting [WER] section. The script didn't execute the windows error reporting [WER] commands.
	)
	echo SKIPPED windows error reporting [WER] section. The script didn't execute the windows error reporting [WER] commands.             >> %REPORT_LOGFILE% 2>&1
)
:lms_section
echo ==============================================================================                                                                                    >> %REPORT_LOGFILE% 2>&1
echo =   L M S   S Y S T E M   I N F O R M A T I O N                              =                                                                                    >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                                                                    >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                                                                       >> %REPORT_LOGFILE% 2>&1
echo ... retrieve LMS Information ...
if not defined LMS_SKIPLMS (
	echo -------------------------------------------------------                                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo Measure execution time: [with LMU PowerShell command: Measure-Command {lmutool.exe /?}]                                                                           >> %REPORT_LOGFILE% 2>&1
	echo     Measure execution time: [with LMU PowerShell command: Measure-Command {lmutool.exe /?}]
	echo powershell -command "Measure-Command {lmutool.exe /?}"                                                                                                            >> %REPORT_LOGFILE% 2>&1
	powershell -command "Measure-Command {lmutool.exe /?}"                                                                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo -------------------------------------------------------                                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve LMS configuration [with LMU PowerShell command] ...
	IF EXIST "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" (
		echo LMS System ID: [read with LMU PowerShell command]                                                                                                             >> %REPORT_LOGFILE% 2>&1
		echo     LMS System ID: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -SystemId}"                                                      >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -SystemId}"                                                           >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -SystemId}"') do set LMS_PS_SYSTEMID=%%i              >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_SYSTEMID!" NEQ "" set LMS_PS_SYSTEMID=!LMS_PS_SYSTEMID: =!
		echo LMS_PS_SYSTEMID=[!LMS_PS_SYSTEMID!]                                                                                                                           >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Version: [read with LMU PowerShell command]                                                                                                               >> %REPORT_LOGFILE% 2>&1
		echo     LMS Version: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMSVersion}"                                                    >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMSVersion}"                                                         >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMSVersion}"') do set LMS_PS_LMSVERSION=%%i          >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_LMSVERSION!" NEQ "" set LMS_PS_LMSVERSION=!LMS_PS_LMSVERSION: =!
		echo LMS_PS_LMSVERSION=[!LMS_PS_LMSVERSION!]                                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo Installing Product and Version: [read with LMU PowerShell command]                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo     Installing Product and Version: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductName}"                                                   >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductName}"                                                        >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductName}"') do set LMS_PS_PRODUCTNAME=%%i        >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_PRODUCTNAME!" NEQ "" set LMS_PS_PRODUCTNAME=!LMS_PS_PRODUCTNAME: =!
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductVersion}"                                                >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductVersion}"                                                     >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -ProductVersion}"') do set LMS_PS_PRODUCTVERSION=%%i  >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_PRODUCTVERSION!" NEQ "" set LMS_PS_PRODUCTVERSION=!LMS_PS_PRODUCTVERSION: =!
		echo LMS_PS_PRODUCTNAME=[!LMS_PS_PRODUCTNAME!]  /  LMS_PS_PRODUCTVERSION=[!LMS_PS_PRODUCTVERSION!]                                                                 >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_PRODUCTNAME!" EQU "N/A" (
			echo NOTE: The configured installing product name [!LMS_PS_PRODUCTNAME!][!LMS_PS_PRODUCTVERSION!] is NOT set, it is the known default!                         >> %REPORT_LOGFILE% 2>&1
		) else (
			echo NOTE: The configured installing product name [!LMS_PS_PRODUCTNAME!][!LMS_PS_PRODUCTVERSION!] is set!                                                      >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Deployment: [read with LMU PowerShell command]                                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo     LMS Deployment: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Deployment}"                                                    >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Deployment}"                                                         >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Deployment}"') do set LMS_PS_DEPLOYMENT=%%i          >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_DEPLOYMENT!" NEQ "" set LMS_PS_DEPLOYMENT=!LMS_PS_DEPLOYMENT: =!
		echo LMS_PS_DEPLOYMENT=[!LMS_PS_DEPLOYMENT!]                                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Application Mode: [read with LMU PowerShell command]                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo     LMS Application Mode: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -AppMode}"                                                       >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -AppMode}"                                                            >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -AppMode}"') do set LMS_PS_APPMODE=%%i                >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_APPMODE!" NEQ "" set LMS_PS_APPMODE=!LMS_PS_APPMODE: =!
		echo LMS_PS_APPMODE=[!LMS_PS_APPMODE!]                                                                                                                             >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Is Virtual Machine: [read with LMU PowerShell command]                                                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     LMS Is Virtual Machine: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -IsVM}"                                                          >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -IsVM}"                                                               >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -IsVM}"') do set LMS_PS_ISVM=%%i                      >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_ISVM!" NEQ "" set LMS_PS_ISVM=!LMS_PS_ISVM: =!
		echo LMS_PS_ISVM=[!LMS_PS_ISVM!]                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS CSID: [read with LMU PowerShell command]                                                                                                                  >> %REPORT_LOGFILE% 2>&1
		echo     LMS CSID: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Csid}"                                                          >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Csid}"                                                               >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Csid}"') do set LMS_PS_CSID=%%i                      >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_CSID!" NEQ "" set LMS_PS_CSID=!LMS_PS_CSID: =!
		echo LMS_PS_CSID=[!LMS_PS_CSID!]                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Culture Id: [read with LMU PowerShell command]                                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo     LMS Culture Id: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"                                                     >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"                                                          >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"') do set LMS_PS_CULTUREID=%%i            >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_CULTUREID!" NEQ "" set LMS_PS_CULTUREID=!LMS_PS_CULTUREID: =!
		echo LMS_PS_CULTUREID=[!LMS_PS_CULTUREID!]  /  LMS_CFG_CULTUREID=[!LMS_CFG_CULTUREID!]                                                                             >> %REPORT_LOGFILE% 2>&1
		if defined LMS_CFG_CULTUREID (
			if /I !LMS_CFG_CULTUREID! EQU 0 (
				rem Show error message, that invalid culture id has been found
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    ERROR: Configured culture id [read with LMU PowerShell command] is NOT valid!  [1;37m
				) else (
					echo     ERROR: Configured culture id [read with LMU PowerShell command] is NOT valid! 
				)
				echo ERROR: Configured culture id [read with LMU PowerShell command] is NOT valid!                                                                         >> %REPORT_LOGFILE% 2>&1
				rem FIX wrong configured culture id
				if "!LMS_PS_CULTUREID!" == "en-US" (
					powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {set-lms -CultureId 1033}"                                         >> %REPORT_LOGFILE% 2>&1
					set LMS_CFG_CULTUREID=1033
					echo   Configured culture id has been set ENGLISH, based on "!LMS_PS_CULTUREID!"                                                                       >> %REPORT_LOGFILE% 2>&1
				) else (
					if "!LMS_PS_CULTUREID!" == "de-DE" (
						powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {set-lms -CultureId 1031}"                                     >> %REPORT_LOGFILE% 2>&1 
						set LMS_CFG_CULTUREID=1031
						echo   Configured culture id has been set GERMAN, based on "!LMS_PS_CULTUREID!"                                                                    >> %REPORT_LOGFILE% 2>&1
					) else (
						rem default, use "en-US"
						powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {set-lms -CultureId 1033}"                                     >> %REPORT_LOGFILE% 2>&1 
						set LMS_CFG_CULTUREID=1033
						echo   Configured culture id has been set ENGLISH [Default], based on "!LMS_PS_CULTUREID!"                                                         >> %REPORT_LOGFILE% 2>&1
					)
				)
				rem re-read configured culture id
				echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"                                             >> %REPORT_LOGFILE% 2>&1
				powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"                                                  >> %REPORT_LOGFILE% 2>&1 
				for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CultureId}"') do set LMS_PS_CULTUREID=%%i    >> %REPORT_LOGFILE% 2>&1
				if "!LMS_PS_CULTUREID!" NEQ "" set LMS_PS_CULTUREID=!LMS_PS_CULTUREID: =!
				echo LMS_PS_CULTUREID=[!LMS_PS_CULTUREID!]  /  LMS_CFG_CULTUREID=[!LMS_CFG_CULTUREID!]                                                                     >> %REPORT_LOGFILE% 2>&1
				if defined SHOW_COLORED_OUTPUT (
					echo [1;32m    FIXED: Configured culture id has been set to !LMS_CFG_CULTUREID! [!LMS_PS_CULTUREID!]  [1;37m
				) else (
					echo     FIXED: Configured culture id has been set to !LMS_CFG_CULTUREID! [!LMS_PS_CULTUREID!]
				)
				echo FIXED: Configured culture id has been set to !LMS_CFG_CULTUREID!  [!LMS_PS_CULTUREID!]                                                                >> %REPORT_LOGFILE% 2>&1
			)
		)
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Last Used Directory: [read with LMU PowerShell command]                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo     LMS Last Used Directory: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LastDir}"                                                       >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LastDir}"                                                            >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Data Storage Directory: [read with LMU PowerShell command]                                                                                                >> %REPORT_LOGFILE% 2>&1
		echo     LMS Data Storage Directory: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -DsPath}"                                                        >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -DsPath}"                                                             >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Certificate Directory: [read with LMU PowerShell command]                                                                                                 >> %REPORT_LOGFILE% 2>&1
		echo     LMS Certificate Directory: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CertPath}"                                                      >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CertPath}"                                                           >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Transfer Directory: [read with LMU PowerShell command]                                                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     LMS Transfer Directory: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -TransferFolder}"                                                >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -TransferFolder}"                                                     >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Token, used to authenticate at FNO server: [read with LMU PowerShell command]                                                                             >> %REPORT_LOGFILE% 2>&1
		echo     LMS Token, used to authenticate at FNO server: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"                                                         >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"                                                              >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"') do set LMS_PS_TOKEN=%%i                    >> %REPORT_LOGFILE% 2>&1
		rem remove spaces within LMS_PS_TOKEN
		if "!LMS_PS_TOKEN!" NEQ "" set LMS_PS_TOKEN=!LMS_PS_TOKEN: =!
		echo LMS_PS_TOKEN=[!LMS_PS_TOKEN!]                                                                                                                                 >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_TOKEN!" EQU "" (
			rem Show error message, that empty/invalid access token has been found
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    ERROR: Configured access token [read with LMU PowerShell command] is NOT valid!  [1;37m
			) else (
				echo     ERROR: Configured access token [read with LMU PowerShell command] is NOT valid! 
			)
			echo ERROR: Configured access token [read with LMU PowerShell command] is NOT valid!                                                                           >> %REPORT_LOGFILE% 2>&1
			rem FIX wrong configured access token
			powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {set-lms -Token act_imhg05mh_dmg4ufrigv03}"                                >> %REPORT_LOGFILE% 2>&1
			rem re-read configured access token
			echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"                                                     >> %REPORT_LOGFILE% 2>&1
			powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"                                                          >> %REPORT_LOGFILE% 2>&1 
			for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -Token}"') do set LMS_PS_TOKEN=%%i                >> %REPORT_LOGFILE% 2>&1
			rem remove spaces within LMS_PS_TOKEN
			if "!LMS_PS_TOKEN!" NEQ "" set LMS_PS_TOKEN=!LMS_PS_TOKEN: =!
			echo LMS_PS_TOKEN=[!LMS_PS_TOKEN!]                                                                                                                             >> %REPORT_LOGFILE% 2>&1
			if defined SHOW_COLORED_OUTPUT (
				echo [1;32m    FIXED: Configured access token has been set to [!LMS_PS_TOKEN!]  [1;37m
			) else (
				echo     FIXED: Configured access token has been set to [!LMS_PS_TOKEN!]
			)
			echo FIXED: Configured access token has been set to [!LMS_PS_TOKEN!]                                                                                           >> %REPORT_LOGFILE% 2>&1
		)
		if "!LMS_PS_TOKEN!" EQU "act_imhg05mh_dmg4ufrigv03" (
			echo NOTE: The configured access token [!LMS_PS_TOKEN!] is the known default token!                                                                            >> %REPORT_LOGFILE% 2>&1
		) else (
			echo NOTE: The configured access token [!LMS_PS_TOKEN!] is NOT the known default token!                                                                        >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS "Can Notify": [read with LMU PowerShell command]                                                                                                          >> %REPORT_LOGFILE% 2>&1
		echo     LMS "Can Notify": [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CanNotify}"                                                     >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -CanNotify}"                                                          >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Notification Period: [read with LMU PowerShell command]                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo     LMS Notification Period: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -NotificationPeriod}"                                            >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -NotificationPeriod}"                                                 >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo LMS Is SIEMBT Ready: [read with LMU PowerShell command]                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo     LMS Is SIEMBT Ready: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -IsSiembtReady}"                                                 >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -IsSiembtReady}"                                                      >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo Get LMS Application state: [read with LMU PowerShell command]                                                                                                 >> %REPORT_LOGFILE% 2>&1
		echo     Get LMS Application state: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMUWsState}"                                                    >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMUWsState}"                                                         >> %REPORT_LOGFILE% 2>&1 
		for /f %%i in ('powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {get-lms -LMUWsState}"') do set LMS_PS_LMUWSSTATE=%%i          >> %REPORT_LOGFILE% 2>&1
		if "!LMS_PS_LMUWSSTATE!" NEQ "" set LMS_PS_LMUWSSTATE=!LMS_PS_LMUWSSTATE: =!
		echo LMS_PS_LMUWSSTATE=[!LMS_PS_LMUWSSTATE!]                                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo Get Product List: [read with LMU PowerShell command]                                                                                                          >> %REPORT_LOGFILE% 2>&1
		echo     Get Product List: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -all}"                                            >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -all}"                                                 >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo Get Product Upgrades: [read with LMU PowerShell command]                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo     Get Product Upgrades: [read with LMU PowerShell command]
		echo powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -upgrades}"                                       >> %REPORT_LOGFILE% 2>&1
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -upgrades}"                                            >> %REPORT_LOGFILE% 2>&1 
		echo -------------------------------------------------------                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo Get Product Maintenance: [read with LMU PowerShell command]                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo     Get Product Maintenance: [read with LMU PowerShell command]
		powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {(Select-Product -report -upgrades)[0].Maintenance}"                           >> %REPORT_LOGFILE% 2>&1 
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ERROR: Cannot execute powershell commands due missing "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1".  [1;37m
		) else (
			echo     ERROR: Cannot execute powershell commands due missing "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1". 
		)
		echo ERROR: Cannot execute powershell commands due missing "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1".                >> %REPORT_LOGFILE% 2>&1
	)	
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Read-out "SUR expiration date" for this system, with LmuTool.exe /SUREDATE                                              >> %REPORT_LOGFILE% 2>&1
	echo     Read-out "SUR expiration date" for this system, with LmuTool.exe /SUREDATE
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! NEQ 721 (
			if /I !LMS_BUILD_VERSION! NEQ 610 (
				"!LMS_LMUTOOL!" /SUREDATE                                                                                        >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                       >> %REPORT_LOGFILE% 2>&1 
			)
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Read-out "site value" for this system, with LmuTool.exe /SITEVALUE                                                      >> %REPORT_LOGFILE% 2>&1
	echo     Read-out "site value" for this system, with LmuTool.exe /SITEVALUE
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! NEQ 721 (
			if /I !LMS_BUILD_VERSION! NEQ 610 (
				"!LMS_LMUTOOL!" /SITEVALUE                                                                                       >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                       >> %REPORT_LOGFILE% 2>&1 
			)
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Run health check, with LmuTool.exe /healthcheck                                                                         >> %REPORT_LOGFILE% 2>&1
	echo     Run health check, with LmuTool.exe /healthcheck
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! NEQ 721 (
			if /I !LMS_BUILD_VERSION! NEQ 610 (
				"!LMS_LMUTOOL!" /healthcheck                                                                                     >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                       >> %REPORT_LOGFILE% 2>&1 
			)
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Run TS clean-up, with LmuTool.exe /cleants                                                                              >> %REPORT_LOGFILE% 2>&1
	echo     Run TS clean-up, with LmuTool.exe /cleants
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! GEQ 800 (
			"!LMS_LMUTOOL!" /cleants                                                                                             >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo LMS License Mode: %LMS_LICENSE_MODE% [read from registry]                                                               >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve dongle driver information ...
	if defined DONGLE_DRIVER_PKG_VERSION (
		echo Dongle Driver: %DONGLE_DRIVER_VERSION% [%DONGLE_DRIVER_PKG_VERSION%] / Major=[!DONGLE_DRIVER_MAJ_VERSION!] / Minor=[!DONGLE_DRIVER_MIN_VERSION!] / installed %DONGLE_DRIVER_INST_COUNT% times     >> %REPORT_LOGFILE% 2>&1
		if /I !DONGLE_DRIVER_MAJ_VERSION! GTR !MOST_RECENT_DONGLE_DRIVER_MAJ_VERSION! (
			rem new major version of dongle driver is installed
			set DONGLE_DRIVER_MOST_RECENT_VERSION_INSTALLED=1
		) else if /I !DONGLE_DRIVER_MAJ_VERSION! EQU !MOST_RECENT_DONGLE_DRIVER_MAJ_VERSION! (
			if /I !DONGLE_DRIVER_MIN_VERSION! GEQ !MOST_RECENT_DONGLE_DRIVER_MIN_VERSION! (
				rem same major version, but most recent or newer minor version of dongle driver is installed
				set DONGLE_DRIVER_MOST_RECENT_VERSION_INSTALLED=1
				echo     Most recent or newer dongle driver !DONGLE_DRIVER_PKG_VERSION! installed on the system.                 >> %REPORT_LOGFILE% 2>&1
			) 
		)
		if not defined DONGLE_DRIVER_MOST_RECENT_VERSION_INSTALLED (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!. [1;37m
			) else (
				echo     WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!.
			)
			echo     WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!.     >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo ATTENTION: No Dongle Driver installed.                                                                              >> %REPORT_LOGFILE% 2>&1
	)
	rem analyse installed software; retrieved with 'wmic product get name, version, InstallDate, vendor'
	set DONGLE_DRIVER_UPDATE_TO781_BY_ATOS=
	IF EXIST "%REPORT_WMIC_INSTALLED_SW_LOGFILE%" for /f "tokens=1 eol=@ delims=<> " %%i in ('type %REPORT_WMIC_INSTALLED_SW_LOGFILE% ^|find /I "Sentinel Runtime R01"') do set DONGLE_DRIVER_UPDATE_TO781_BY_ATOS=%%i
	set DONGLE_DRIVER_UPDATE_TO792_BY_ATOS=
	IF EXIST "%REPORT_WMIC_INSTALLED_SW_LOGFILE%" for /f "tokens=1 eol=@ delims=<> " %%i in ('type %REPORT_WMIC_INSTALLED_SW_LOGFILE% ^|find /I "Sentinel License Manager R01"') do set DONGLE_DRIVER_UPDATE_TO792_BY_ATOS=%%i
	if defined DONGLE_DRIVER_UPDATE_TO781_BY_ATOS (
		echo     NOTE: There was a dongle driver update to version V7.81 at %DONGLE_DRIVER_UPDATE_TO781_BY_ATOS% provided by ATOS.    >> %REPORT_LOGFILE% 2>&1
	)
	if defined DONGLE_DRIVER_UPDATE_TO792_BY_ATOS (
		echo     NOTE: There was a dongle driver update to version V7.92 at %DONGLE_DRIVER_UPDATE_TO792_BY_ATOS% provided by ATOS.    >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST C:\ccmcache\ (
		rem search for dongle drivers downloaded by ATOS on C:\ccmcache\
		rem NOTE: the ccmcache has an overall size of xx GB. If this size is full, oldest downloaded packages will be erased automatically
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo Dongle Driver: Search on C:\ccmcache\ for drivers deliverd by ATOS.                                                 >> %REPORT_LOGFILE% 2>&1
		FOR /r C:\ccmcache %%X IN (HASP*) DO dir %%~dpX                                                                          >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST C:\ccmcache\ (
		rem search for LMS setup downloaded by ATOS on C:\ccmcache\
		rem NOTE: the ccmcache has an overall size of xx GB. If this size is full, oldest downloaded packages will be erased automatically
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo LMS Setup: Search on C:\ccmcache\ for drivers deliverd by ATOS [via Software Center].                               >> %REPORT_LOGFILE% 2>&1
		FOR /r C:\ccmcache %%X IN (*.msi) DO if "%%~nxX"=="Siemens License Management.msi" dir %%~dpX                            >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo LMS_HASPDRIVER_FOLDER='!LMS_HASPDRIVER_FOLDER!'                                                                         >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%LMS_HASPDRIVER_FOLDER%\lic_names.dat" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo lic_names.dat:                                                                                                      >> %REPORT_LOGFILE% 2>&1
		type "%LMS_HASPDRIVER_FOLDER%\\lic_names.dat"                                                                            >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "%LMS_HASPDRIVER_FOLDER%\hasplm.ini" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo hasplm.ini:                                                                                                         >> %REPORT_LOGFILE% 2>&1
		type "%LMS_HASPDRIVER_FOLDER%\\hasplm.ini"                                                                               >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Display the connected dongles, with LmuTool.exe /DONGLES                                                                >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! NEQ 721 (
			if /I !LMS_BUILD_VERSION! NEQ 610 (
				"!LMS_LMUTOOL!" /DONGLES                                                                                         >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                       >> %REPORT_LOGFILE% 2>&1 
			)
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	rem Retrieve diagnostic information from dongle driver "Sentinel LDK License Manager"
	rem Out of the available "pages" - see below - only diagnostics.html can be retrieved programmatically
	rem Diagnostic:     about.html, diag.html, diagnostics.html, log.html
	rem Operation:      devices.html, products.html, features.html, sessions.html
	rem Configuration:  config.html, config_users.html, config_to.html, config_from.html, config_detach.html, config_network.html

	rem Retrieve information: diagnostics.html
	set DONGLE_DOWNLOAD_FILE=http://localhost:1947/_int_/diagnostics.html
	set DONGLE_REPORT_FILE=!CHECKLMS_REPORT_LOG_PATH!\dongledriver_diagnostics.html
	powershell -Command "(New-Object Net.WebClient).DownloadFile('!DONGLE_DOWNLOAD_FILE!', '!DONGLE_REPORT_FILE!')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_dongledriverdiagnostics.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Retrieve information: PASSED
		echo     Retrieve diagnostic information of dongle driver PASSED, can access !DONGLE_DOWNLOAD_FILE!
		echo Retrieve diagnostic information of dongle driver PASSED, can access !DONGLE_DOWNLOAD_FILE!                          >> %REPORT_LOGFILE% 2>&1
		echo Full details see !DONGLE_REPORT_FILE!                                                                               >> %REPORT_LOGFILE% 2>&1
	) else if !ERRORLEVEL!==1 (
		rem Retrieve information: FAILED
		echo     Retrieve diagnostic information of dongle driver FAILED, cannot access !DONGLE_DOWNLOAD_FILE!
		echo Retrieve diagnostic information of dongle driver FAILED, cannot access !DONGLE_DOWNLOAD_FILE!                       >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_dongledriverdiagnostics.txt                                              >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem Check attached USB devices on this system, incl. attached dongles
	if defined USBDEVIEW_TOOL (
		echo Check USB devices with: !USBDEVIEW_TOOL! ...                                                                        >> %REPORT_LOGFILE% 2>&1
		"!USBDEVIEW_TOOL!" /stabular "!CHECKLMS_REPORT_LOG_PATH!\usb_dongles.txt"                                                >> %REPORT_LOGFILE% 2>&1
		echo ... see '!CHECKLMS_REPORT_LOG_PATH!\usb_dongles.txt'.                                                               >> %REPORT_LOGFILE% 2>&1
		"!USBDEVIEW_TOOL!" /shtml "!CHECKLMS_REPORT_LOG_PATH!\usb_dongles.html"                                                  >> %REPORT_LOGFILE% 2>&1
		echo ... see '!CHECKLMS_REPORT_LOG_PATH!\usb_dongles.html'.                                                              >> %REPORT_LOGFILE% 2>&1
		echo -- extract vendor id 'VID_0529' from usb_dongles.txt [start] --                                                     >> %REPORT_LOGFILE% 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\usb_dongles.txt" | findstr "VID_0529"                                                   >> %REPORT_LOGFILE% 2>&1
		echo -- extract vendor id 'VID_0529' from usb_dongles.txt [end] --                                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Cannot check USB devices with USBDeview.exe, because the tool is not available/installed.                           >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPLMS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED LMS section. The script didn't execute the LMS commands. [1;37m
	) else (
		echo     SKIPPED LMS section. The script didn't execute the LMS commands.
	)
	echo SKIPPED LMS section. The script didn't execute the LMS commands.                                                        >> %REPORT_LOGFILE% 2>&1
)
:alm_section
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPBTALMPLUGIN (
	echo ALM: %ALM_VERSION_STRING% [%ALM_VERSION%] -- %ALM_RELEASE% [%ALM_TECH_VERSION%]                                     >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SKIP_ALM_BT_PUGIN_INSTALLATION (
		echo     BT ALM Plugin is NOT handled/installed by LMS client!                                                       >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Retrieve list of installed ALM plugins                                                                              >> %REPORT_LOGFILE% 2>&1
	echo ... retrieve list of installed ALM plugins ...
	if exist "%ProgramFiles%\Common Files\Siemens\SWS\plugins\bt" (
		echo Content of folder: "%ProgramFiles%\Common Files\Siemens\SWS\plugins\bt"                                         >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%ProgramFiles%\Common Files\Siemens\SWS\plugins\bt"                                              >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No BT ALM Plugin installed at: %ProgramFiles%\Common Files\Siemens\SWS\plugins\bt                           >> %REPORT_LOGFILE% 2>&1
	)
	set BTALMPLUGINVersion=
	IF EXIST "%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.dll" (
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo wmic datafile where Name="%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.dll" get Manufacturer,Name,Version  /format:list    >> %REPORT_LOGFILE% 2>&1
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.dll" get Manufacturer,Name,Version  /format:list
		type %REPORT_WMIC_LOGFILE% >> %REPORT_LOGFILE% 2>&1
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "BTALMPLUGINVersion=%%i"
		echo     Installed BT ALM Plugin Version: !BTALMPLUGINVersion!
		echo --- Installed BT ALM Plugin Version: !BTALMPLUGINVersion!                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		reg query HKCR\CLSID /s /f "{F9D9C9A4-7729-4EC8-82E8-67898FCCF2DF}"                                                  >> %REPORT_LOGFILE% 2>&1
		if errorlevel 1 (
			echo --- BT ALM plugin is not registered!                                                                        >> %REPORT_LOGFILE% 2>&1
			regsvr32 /s "%LMS_ALMBTPLUGIN_FOLDER%\AlmBtPg.dll"                                                               >> %REPORT_LOGFILE% 2>&1
			echo --- Registration for "%LMS_ALMBTPLUGIN_FOLDER%\AlmBtPg.dll" done ...                                        >> %REPORT_LOGFILE% 2>&1
			reg query HKCR\CLSID /s /f "{F9D9C9A4-7729-4EC8-82E8-67898FCCF2DF}"                                              >> %REPORT_LOGFILE% 2>&1
			if errorlevel 1 (
				echo --- BT ALM plugin is STILL not registered!                                                              >> %REPORT_LOGFILE% 2>&1
			) else (
				echo --- BT ALM plugin is NOW correct registered!                                                            >> %REPORT_LOGFILE% 2>&1
			)
			echo --- Search in registry for "AlmBtPg.dll" entries ...                                                        >> %REPORT_LOGFILE% 2>&1
			reg query HKLM\SOFTWARE\Classes /s /f AlmBtPg.dll                                                                >> %REPORT_LOGFILE% 2>&1
		) else (
			echo --- BT ALM plugin is correct registered!                                                                    >> %REPORT_LOGFILE% 2>&1
		)
	)
	IF EXIST "%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.xml" (
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo "%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.xml":                                                                        >> %REPORT_LOGFILE% 2>&1
		type "%LMS_ALMBTPLUGIN_FOLDER%\\AlmBtPg.xml"                                                                         >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.dll" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo wmic datafile where Name="%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.dll" get Manufacturer,Name,Version  /format:list    >> %REPORT_LOGFILE% 2>&1
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.dll" get Manufacturer,Name,Version  /format:list
		type %REPORT_WMIC_LOGFILE% >> %REPORT_LOGFILE% 2>&1
		IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "BTALMPLUGINVersion=%%i"
		echo     Installed BT ALM Plugin Version: !BTALMPLUGINVersion!
		echo --- Installed BT ALM Plugin Version: !BTALMPLUGINVersion!                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		reg query HKCR\CLSID /s /f "{F9D9C9A4-7729-4EC8-82E8-67898FCCF2DF}"                                                  >> %REPORT_LOGFILE% 2>&1
		if errorlevel 1 (
			echo --- BT ALM plugin is not registered!                                                                        >> %REPORT_LOGFILE% 2>&1
			regsvr32 /s "%LMS_ALMBTPLUGIN_FOLDER_X86%\AlmBtPg.dll"                                                           >> %REPORT_LOGFILE% 2>&1
			echo --- Registration for "%LMS_ALMBTPLUGIN_FOLDER_X86%\AlmBtPg.dll" done ...                                    >> %REPORT_LOGFILE% 2>&1
			reg query HKCR\CLSID /s /f "{F9D9C9A4-7729-4EC8-82E8-67898FCCF2DF}"                                              >> %REPORT_LOGFILE% 2>&1
			if errorlevel 1 (
				echo --- BT ALM plugin is STILL not registered!                                                              >> %REPORT_LOGFILE% 2>&1
			) else (
				echo --- BT ALM plugin is NOW correct registered!                                                            >> %REPORT_LOGFILE% 2>&1
			)
			echo --- Search in registry for "AlmBtPg.dll" entries ...                                                        >> %REPORT_LOGFILE% 2>&1
			reg query HKLM\SOFTWARE\Classes /s /f AlmBtPg.dll                                                                >> %REPORT_LOGFILE% 2>&1
		) else (
			echo --- BT ALM plugin is correct registered!                                                                    >> %REPORT_LOGFILE% 2>&1
		)
	)
	IF EXIST "%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.xml" (
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo "%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.xml":                                                                    >> %REPORT_LOGFILE% 2>&1
		type "%LMS_ALMBTPLUGIN_FOLDER_X86%\\AlmBtPg.xml"                                                                     >> %REPORT_LOGFILE% 2>&1
	)
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED BT ALM plugin section. The script didn't execute the BT ALM plugin commands. [1;37m
	) else (
		echo     SKIPPED BT ALM plugin section. The script didn't execute the BT ALM plugin commands.
	)
	echo SKIPPED BT ALM plugin section. The script didn't execute the BT ALM plugin commands.                                >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPSIGCHECK (
	IF EXIST "%ProgramFiles%\Siemens\LMS\bin" (
		echo LMS - Get signature status for *.exe [%ProgramFiles%\Siemens\LMS\bin]                                           >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '%ProgramFiles%\Siemens\LMS\bin\*.exe'"                     >> %REPORT_LOGFILE% 2>&1
		echo LMS - Get signature status for *.dll [%ProgramFiles%\Siemens\LMS\bin]                                           >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '%ProgramFiles%\Siemens\LMS\bin\*.dll'"                     >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Check signature with: !SIGCHECK_TOOL! !SIGCHECK_OPTIONS! ...                                                    >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe"                                      >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "%ProgramFiles%\Siemens\LMS\bin\LicEnf.dll"                                       >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "%ProgramFiles%\Siemens\LMS\bin\Siemens.Gms.ApplicationFramework.exe"             >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No LMS binary folder [%ProgramFiles%\Siemens\LMS\bin] found.                                                >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!ProgramFiles_x86!\Siemens\LMS\bin" (
		echo LMS - Get signature status for 32-bit *.exe                                                                     >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '!ProgramFiles_x86!\Siemens\LMS\bin\*.exe'"                >> %REPORT_LOGFILE% 2>&1
		echo LMS - Get signature status for 32-bit *.dll                                                                     >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '!ProgramFiles_x86!\Siemens\LMS\bin\*.dll'"                >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Check signature with: !SIGCHECK_TOOL! !SIGCHECK_OPTIONS! ...                                                    >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "!ProgramFiles_x86!\Siemens\LMS\bin\LmuTool.exe"                                 >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "!ProgramFiles_x86!\Siemens\LMS\bin\LicEnf.dll"                                  >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "!ProgramFiles_x86!\Siemens\LMS\bin\Siemens.Gms.ApplicationFramework.exe"        >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No LMS binary 32-bit folder found.                                                                          >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED signature check section. The script didn't execute the signature check commands. [1;37m
	) else (
		echo     SKIPPED signature check section. The script didn't execute the signature check commands.
	)
	echo SKIPPED signature check section. The script didn't execute the signature check commands.                            >> %REPORT_LOGFILE% 2>&1
)
:flexera_fnp_information
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   F L E X E R A  (F N P)   I N F O R M A T I O N                           =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1

rem create powershell script to replace "><" with ">`r`n<"
set lms_ps_search="><"
set lms_ps_replace=">`r`n<"
set lms_ps_textFileIn=!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml
set lms_ps_textFileOut=!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml
SET lms_ps_script1=!CHECKLMS_REPORT_LOG_PATH!\tmpStrRplc1.ps1
ECHO (Get-Content "%lms_ps_textFileIn%").replace(%lms_ps_search%, %lms_ps_replace%) ^| Set-Content "%lms_ps_textFileOut%">"%lms_ps_script1%"
rem create powershell script to remove tabs "`t"
set lms_ps_search="`t"
set lms_ps_replace=""
set lms_ps_textFileIn=!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml
set lms_ps_textFileOut=!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml
SET lms_ps_script2=!CHECKLMS_REPORT_LOG_PATH!\tmpStrRplc2.ps1
ECHO (Get-Content "%lms_ps_textFileIn%").replace(%lms_ps_search%, %lms_ps_replace%) ^| Set-Content "%lms_ps_textFileOut%">"%lms_ps_script2%"

echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... retrieve Flexera (FNP) Information ...
if not defined LMS_SKIPFNP (
	IF EXIST "C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService64.exe" (
		echo wmic datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService64.exe" get Manufacturer,Name,Version  /format:list       >> %REPORT_LOGFILE% 2>&1
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService64.exe" get Manufacturer,Name,Version  /format:list
		type %REPORT_WMIC_LOGFILE% >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" (
		echo wmic datafile where Name="C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list   >> %REPORT_LOGFILE% 2>&1
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list
		type %REPORT_WMIC_LOGFILE% >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" (
		echo wmic datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list       >> %REPORT_LOGFILE% 2>&1
		wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="C:\\Program Files\\Common Files\\Macrovision Shared\\FlexNet Publisher\\FNPLicensingService.exe" get Manufacturer,Name,Version  /format:list
		type %REPORT_WMIC_LOGFILE% >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "!ProgramFiles_x86!\Siemens\LMS\server" (
		echo Content of folder: "!ProgramFiles_x86!\Siemens\LMS\server"                                                         >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "!ProgramFiles_x86!\Siemens\LMS\server"                                                              >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "%ProgramFiles%\Siemens\LMS\server" (
		echo Content of folder: "%ProgramFiles%\Siemens\LMS\server"                                                              >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%ProgramFiles%\Siemens\LMS\server"                                                                   >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo servercomptranutil.exe -version                                                                                         >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		if "!FNPVersion!" == "11.14.0.0" (
			echo     servercomptranutil.exe -version is not available for FNP=!FNPVersion!, cannot perform operation.            >> %REPORT_LOGFILE% 2>&1
		) else (
			"%LMS_SERVERCOMTRANUTIL%" -version                                                                                   >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo tsactdiags_SIEMBT_svr.exe --version                                                                                     >> %REPORT_LOGFILE% 2>&1
	if defined LMS_TSACTDIAGSSVR (
		"%LMS_TSACTDIAGSSVR%" --version                                                                                          >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     tsactdiags_SIEMBT_svr.exe doesn't exist, cannot perform operation.                                              >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo lmver.exe -fnls                                                                                                         >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMVER (
		"%LMS_LMVER%" -fnls                                                                                                      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmver.exe doesn't exist, cannot perform operation.                                                              >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo lmutil.exe lmpath -status                                                                                               >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTIL (
		"%LMS_LMUTIL%" lmpath -status                                                                                            >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmutil.exe doesn't exist, cannot perform operation.                                                             >> %REPORT_LOGFILE% 2>&1
	)
)
rem Run *always* even if LMS_SKIPFNP is set
echo -------------------------------------------------------                                                                                                    >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                                                                >> %REPORT_LOGFILE% 2>&1
echo Create offline activation request file [using servercomptranutil.exe -n "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" -activate fake_id] ...       >> %REPORT_LOGFILE% 2>&1
echo     Create offline activation request file ...
if defined LMS_SERVERCOMTRANUTIL (
	"%LMS_SERVERCOMTRANUTIL%" -n "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" ref=CheckLMS_CreateOffActRequestFile -activate fake_id                   >> %REPORT_LOGFILE% 2>&1

	Powershell -ExecutionPolicy Bypass -Command "& '%lms_ps_script1%'"
	Powershell -ExecutionPolicy Bypass -Command "& '%lms_ps_script2%'"
	
	rem read machine identifiers from offline request file
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<PublisherId>"') do set "LMS_TS_PUBLISHER=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<ClientVersion>"') do set "LMS_TS_CLIENT_VERSION=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<Revision>"') do set "LMS_TS_REVISION=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<MachineIdentifier>"') do set "LMS_TS_MACHINE_IDENTIFIER=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<TrustedStorageSerialNumber>"') do set "LMS_TS_SERIAL_NUMBER=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<SequenceNumber>"') do set "LMS_TS_SEQ_NUM=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml" for /f "tokens=2 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file_mod.xml ^|find /I "<Status>"') do set "LMS_TS_STATUS=%%i"	
	echo     PublisherId: !LMS_TS_PUBLISHER!  /  TS ClientVersion: !LMS_TS_CLIENT_VERSION!                                   >> %REPORT_LOGFILE% 2>&1
	echo     MachineIdentifier: !LMS_TS_MACHINE_IDENTIFIER!  /  TrustedStorageSerialNumber: !LMS_TS_SERIAL_NUMBER!           >> %REPORT_LOGFILE% 2>&1
	echo     TS Status: !LMS_TS_STATUS!  /  TS SequenceNumber: !LMS_TS_SEQ_NUM!  /  TS Revision: !LMS_TS_REVISION!           >> %REPORT_LOGFILE% 2>&1

	rem retreieve UMN values from offline request file
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" for /f "tokens=6 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ^|find /I "<Type>1"') do if "%%i" NEQ "/Value" set "UMN1_TS=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" for /f "tokens=6 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ^|find /I "<Type>2"') do if "%%i" NEQ "/Value" set "UMN2_TS=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" for /f "tokens=6 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ^|find /I "<Type>3"') do if "%%i" NEQ "/Value" set "UMN3_TS=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" for /f "tokens=6 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ^|find /I "<Type>4"') do if "%%i" NEQ "/Value" set "UMN4_TS=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml" for /f "tokens=6 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ^|find /I "<Type>5"') do if "%%i" NEQ "/Value" set "UMN5_TS=%%i"
	rem Evaluate number of UMN used for TS binding
	set /a UMN_COUNT_TS = 0
	if defined UMN1_TS SET /A UMN_COUNT_TS += 1
	if defined UMN2_TS SET /A UMN_COUNT_TS += 1
	if defined UMN3_TS SET /A UMN_COUNT_TS += 1
	if defined UMN4_TS SET /A UMN_COUNT_TS += 1
	if defined UMN5_TS SET /A UMN_COUNT_TS += 1
	echo     Number of UMN used to bind TS: !UMN_COUNT_TS!
	echo     Number of UMN used to bind TS: !UMN_COUNT_TS!                                                                   >> %REPORT_LOGFILE% 2>&1
	echo     UMN1=!UMN1_TS! / UMN2=!UMN2_TS! / UMN3=!UMN3_TS! / UMN4=!UMN4_TS! / UMN5=!UMN5_TS!                              >> %REPORT_LOGFILE% 2>&1
	echo     UMN1=!UMN1_TS! / UMN2=!UMN2_TS! / UMN3=!UMN3_TS! / UMN4=!UMN4_TS! / UMN5=!UMN5_TS! at !DATE! / !TIME! / retrieved from offline request file >> !REPORT_LOG_PATH!\UMN.txt 2>&1

	rem retrieve section break info
	findstr /m /c:"StorageBreakInfo" "!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml"                           >> %REPORT_LOGFILE% 2>&1
	if !ERRORLEVEL!==0 (
		echo     'StorageBreakInfo' section was found in !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ...     >> %REPORT_LOGFILE% 2>&1
		Set LMS_START_LOG=0
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml) DO ( 
			ECHO "%%i" | FINDSTR /C:"<StorageBreakInfo>" 1>nul 
			if !ERRORLEVEL!==0 (
				echo     Start of 'StorageBreakInfo' section found ...                                               >> %REPORT_LOGFILE% 2>&1
				Set LMS_START_LOG=1
			)
			if !LMS_START_LOG!==1 (
				echo     %%i                                                                                         >> %REPORT_LOGFILE% 2>&1
				
				rem check for end of 'StorageBreakInfo' section
				ECHO "%%i" | FINDSTR /C:"</StorageBreakInfo>" 1>nul 
				if !ERRORLEVEL!==0 (
					echo     End of 'StorageBreakInfo' section found ...                                             >> %REPORT_LOGFILE% 2>&1
					Set LMS_START_LOG=0
				)
			)
		)
	) else (
		echo     NO 'StorageBreakInfo' section was found in !CHECKLMS_REPORT_LOG_PATH!\fake_id_request_file.xml ...  >> %REPORT_LOGFILE% 2>&1
	)

) else (
	echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
)
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPFNP (
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	set HealthCheckOk=Unknown
	echo perform TS health check [using servercomptranutil.exe -healthCheck] ...                                                 >> %REPORT_LOGFILE% 2>&1
	echo     perform TS health check [using servercomptranutil.exe -healthCheck] ...
	if defined LMS_SERVERCOMTRANUTIL (
		if "!FNPVersion!" == "11.14.0.0" (
			echo     servercomptranutil.exe -healthCheck is not available for FNP=!FNPVersion!, cannot perform operation.        >> %REPORT_LOGFILE% 2>&1
		) else (
			"%LMS_SERVERCOMTRANUTIL%" -healthCheck > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_healthCheck.txt 2>&1   
			type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_healthCheck.txt                                                   >> %REPORT_LOGFILE% 2>&1
			
			findstr /m /c:"FAIL" "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_healthCheck.txt"                                 >> %REPORT_LOGFILE% 2>&1
			if !ERRORLEVEL!==0 (
				set HealthCheckOk=No
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    ATTENTION: HealthCheck FAILED. [1;37m
				) else (
					echo     ATTENTION: HealthCheck FAILED.
				)
				echo ATTENTION: HealthCheck FAILED.                                                                              >> %REPORT_LOGFILE% 2>&1
			) else (
				set HealthCheckOk=Yes
				echo     HealthCheck PASSED.
			)
		)
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
)
rem Execute always, even LMS_SKIPFNP is set!
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo retrieve license information [using servercomptranutil.exe -unique, is equal to: servercomptranutil.exe -umn] ...       >> %REPORT_LOGFILE% 2>&1
echo     retrieve license information [using servercomptranutil.exe -unique, is equal to: servercomptranutil.exe -umn] ...
if exist "!REPORT_LOG_PATH!\UMN_Latest.txt" (
	for /f "tokens=1,2,3,4,5,* eol=@ delims=,/ " %%A in ('type !REPORT_LOG_PATH!\UMN_Latest.txt ^|find /I "UMN1"') do (
		rem Load UMN values from previous run ...
		rem echo %%A / %%B / %%C // %%F
		for /f "tokens=1,2 delims==" %%a in ("%%A") do set UMN1_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%B") do set UMN2_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%C") do set UMN3_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%D") do set UMN4_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%E") do set UMN5_PREV=%%b
		set UMNINFO_PREV=%%F
	)
	rem Evaluate number of UMN used for TS binding
	set /a UMN_COUNT_PREV = 0
	if defined UMN1_PREV SET /A UMN_COUNT_PREV += 1
	if defined UMN2_PREV SET /A UMN_COUNT_PREV += 1
	if defined UMN3_PREV SET /A UMN_COUNT_PREV += 1
	if defined UMN4_PREV SET /A UMN_COUNT_PREV += 1
	if defined UMN5_PREV SET /A UMN_COUNT_PREV += 1
	echo Previous UMN values, collected !UMNINFO_PREV!                                                                   >> %REPORT_LOGFILE% 2>&1
	echo     Number of UMN used to bind TS: !UMN_COUNT_PREV!                                                             >> %REPORT_LOGFILE% 2>&1
	echo     UMN1=!UMN1_PREV! / UMN2=!UMN2_PREV! / UMN3=!UMN3_PREV! / UMN4=!UMN4_PREV! / UMN5=!UMN5_PREV!                >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_SERVERCOMTRANUTIL (
	if "!FNPVersion!" == "11.14.0.0" (
		echo     servercomptranutil.exe -unique is not available for FNP=!FNPVersion!, cannot perform operation.         >> %REPORT_LOGFILE% 2>&1
	) else (
		"%LMS_SERVERCOMTRANUTIL%" -unique > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt  2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt                                                    >> %REPORT_LOGFILE% 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt" for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt ^|find /I "UMN1"') do set "UMN1_A=%%B"   
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt" for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt ^|find /I "UMN2"') do set "UMN2_A=%%B"   
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt" for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt ^|find /I "UMN3"') do set "UMN3_A=%%B"   
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt" for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt ^|find /I "UMN4"') do set "UMN4_A=%%B"   
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt" for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_unique.txt ^|find /I "UMN5"') do set "UMN5_A=%%B"   
		rem Evaluate number of UMN used for TS binding
		set /a UMN_COUNT_A = 0
		if defined UMN1_A SET /A UMN_COUNT_A += 1
		if defined UMN2_A SET /A UMN_COUNT_A += 1
		if defined UMN3_A SET /A UMN_COUNT_A += 1
		if defined UMN4_A SET /A UMN_COUNT_A += 1
		if defined UMN5_A SET /A UMN_COUNT_A += 1
		echo Current UMN values, collected with servercomptranutil ...                                                                           >> %REPORT_LOGFILE% 2>&1
		echo     Number of UMN used to bind TS: !UMN_COUNT_A!
		echo     Number of UMN used to bind TS: !UMN_COUNT_A!                                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     UMN1=!UMN1_A! / UMN2=!UMN2_A! / UMN3=!UMN3_A! / UMN4=!UMN4_A! / UMN5=!UMN5_A!                                                   >> %REPORT_LOGFILE% 2>&1
		echo     UMN1=!UMN1_A! / UMN2=!UMN2_A! / UMN3=!UMN3_A! / UMN4=!UMN4_A! / UMN5=!UMN5_A! at !DATE! / !TIME! / using servercomptranutil.exe >> !REPORT_LOG_PATH!\UMN.txt 2>&1
		echo     UMN1=!UMN1_A! / UMN2=!UMN2_A! / UMN3=!UMN3_A! / UMN4=!UMN4_A! / UMN5=!UMN5_A! at !DATE! / !TIME! / using servercomptranutil.exe >  !REPORT_LOG_PATH!\UMN_Latest.txt 2>&1
		if !UMN_COUNT_A! leq 1 (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    ATTENTION: Only ONE UMN is used to bind TS. [1;37m
			) else (
				echo     ATTENTION: Only ONE UMN is used to bind TS.
			)
		)
	)
) else (
	echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo retrieve license information [using appactutil.exe -unique] ...                                                         >> %REPORT_LOGFILE% 2>&1
echo     retrieve license information [using appactutil.exe -unique] ...
if defined LMS_APPACTUTIL (
	"%LMS_APPACTUTIL%" -unique > !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt  2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt                                                                    >> %REPORT_LOGFILE% 2>&1
	
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt" for /f "tokens=1,7 eol=@ delims=:= " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt ^|find /I "one"')   do if "%%A" NEQ "ERROR" set "UMN1_B=%%B"   
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt" for /f "tokens=1,7 eol=@ delims=:= " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt ^|find /I "two"')   do if "%%A" NEQ "ERROR" set "UMN2_B=%%B"   
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt" for /f "tokens=1,7 eol=@ delims=:= " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt ^|find /I "three"') do if "%%A" NEQ "ERROR" set "UMN3_B=%%B"   
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt" for /f "tokens=1,7 eol=@ delims=:= " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt ^|find /I "four"')  do if "%%A" NEQ "ERROR" set "UMN4_B=%%B"   
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt" for /f "tokens=1,7 eol=@ delims=:= " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\appactutil_unique.txt ^|find /I "five"')  do if "%%A" NEQ "ERROR" set "UMN5_B=%%B"   
	rem Evaluate number of UMN used for TS binding
	set /a UMN_COUNT_B = 0
	if defined UMN1_B SET /A UMN_COUNT_B += 1
	if defined UMN2_B SET /A UMN_COUNT_B += 1
	if defined UMN3_B SET /A UMN_COUNT_B += 1
	if defined UMN4_B SET /A UMN_COUNT_B += 1
	if defined UMN5_B SET /A UMN_COUNT_B += 1
	echo Current UMN values, collected with appactutil ...                                                                           >> %REPORT_LOGFILE% 2>&1
	echo     Number of UMN used to bind TS: !UMN_COUNT_B!
	echo     Number of UMN used to bind TS: !UMN_COUNT_B!                                                                            >> %REPORT_LOGFILE% 2>&1
	echo     UMN1=!UMN1_B! / UMN2=!UMN2_B! / UMN3=!UMN3_B! / UMN4=!UMN4_B! / UMN5=!UMN5_B!                                           >> %REPORT_LOGFILE% 2>&1
	echo     UMN1=!UMN1_B! / UMN2=!UMN2_B! / UMN3=!UMN3_B! / UMN4=!UMN4_B! / UMN5=!UMN5_B! at !DATE! / !TIME! / using appactutil.exe >> !REPORT_LOG_PATH!\UMN.txt 2>&1
	if !UMN_COUNT_B! leq 1 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Only ONE UMN is used to bind TS. [1;37m
		) else (
			echo     ATTENTION: Only ONE UMN is used to bind TS.
		)
	)
	
) else (
	echo     appactutil.exe doesn't exist, cannot perform operation.                                                         >> %REPORT_LOGFILE% 2>&1
)

rem compare the UMNs read with the two commands
rem Moved the check to own section further down

echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo retrieve virtual information [using servercomptranutil.exe -virtual] ...                                                >> %REPORT_LOGFILE% 2>&1
echo     retrieve virtual information [using servercomptranutil.exe -virtual] ...
if exist "!REPORT_LOG_PATH!\VMID_Latest.txt" (
	for /f "tokens=1,2,3,4,5,* eol=@ delims=,/ " %%A in ('type !REPORT_LOG_PATH!\VMID_Latest.txt ^|find /I "VM_DETECTED"') do (
		rem echo %%A / %%B / %%C / %%D / %%E // %%F
		for /f "tokens=1,2 delims==" %%a in ("%%A") do set VM_DETECTED_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%B") do set VM_FAMILY_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%C") do set VM_NAME_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%D") do set VM_UUID_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%E") do set VM_GENID_PREV=%%b
		set VMINFO_PREV=%%F
	)
	echo Previous VM values, collected !VMINFO_PREV!                                                                         >> %REPORT_LOGFILE% 2>&1
	echo     VM_DETECTED=!VM_DETECTED_PREV! / VM_FAMILY=!VM_FAMILY_PREV! / VM_NAME=!VM_NAME_PREV! / VM_UUID=!VM_UUID_PREV! / VM_GENID=!VM_GENID_PREV!  >> %REPORT_LOGFILE% 2>&1
)
if defined LMS_SERVERCOMTRANUTIL (
	if "!FNPVersion!" == "11.14.0.0" (
		echo     servercomptranutil.exe -virtual is not available for FNP=!FNPVersion!, cannot perform operation.            >> %REPORT_LOGFILE% 2>&1
	) else (
		"%LMS_SERVERCOMTRANUTIL%" -virtual > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt  2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt                                                       >> %REPORT_LOGFILE% 2>&1

		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt" (
			for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "physical"') do set "VM_DETECTED=NO"   
			if not defined VM_DETECTED (
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "virtual"')  do set "VM_DETECTED=YES"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "FAMILY"')   do set "VM_FAMILY=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "NAME"')     do set "VM_NAME=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "UUID"')     do set "VM_UUID=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_virtual.txt ^|find /I "GENID"')    do set "VM_GENID=%%B"   
				rem Handle "  GENID    Not available on this platform"
				if "!VM_GENID!" == "Not" (
					set VM_GENID=
				)
			)
		)
	)
) else (
	echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
)
echo Current VM values, collected with servercomptranutil ...                                                                >> %REPORT_LOGFILE% 2>&1
REM echo     VM_DETECTED=!VM_DETECTED! / VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!
echo     VM_DETECTED=!VM_DETECTED! / VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!     >> %REPORT_LOGFILE% 2>&1
echo     VM_DETECTED=!VM_DETECTED! / VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!  at !DATE! / !TIME!  >> !REPORT_LOG_PATH!\VMID.txt 2>&1
echo     VM_DETECTED=!VM_DETECTED! / VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!  at !DATE! / !TIME!  >  !REPORT_LOG_PATH!\VMID_Latest.txt 2>&1

if not defined LMS_SKIPFNP (
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo retrieve virtual information [using appactutil.exe -virtual -long] ...                                                  >> %REPORT_LOGFILE% 2>&1
	echo     retrieve virtual information [using appactutil.exe -virtual -long] ...
	if defined LMS_APPACTUTIL (
		"%LMS_APPACTUTIL%" --virtual -long                                                                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     appactutil.exe doesn't exist, cannot perform operation.                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo serveractutil.exe -virtual                                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERACTUTIL (
		"%LMS_SERVERACTUTIL%" -virtual                                                                                           >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     serveractutil.exe doesn't exist, cannot perform operation.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo lmdiag.exe -c "!LMS_PROGRAMDATA!\Server Certificates\" -n                                                               >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMDIAG (
		"%LMS_LMDIAG%" -c "!LMS_PROGRAMDATA!\Server Certificates\" -n                                                            >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmdiag.exe doesn't exist, cannot perform operation.                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo lmstat.exe -c "!LMS_PROGRAMDATA!\Server Certificates\SIEMBT.lic" -A                                                     >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMSTAT (
		"%LMS_LMSTAT%" -c "!LMS_PROGRAMDATA!\Server Certificates\SIEMBT.lic" -A                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmstat.exe doesn't exist, cannot perform operation.                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo lmstat.exe -c "!LMS_PROGRAMDATA!\Server Certificates\SIEMBT.lic" -a                                                     >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMSTAT (
		"%LMS_LMSTAT%" -c "!LMS_PROGRAMDATA!\Server Certificates\SIEMBT.lic" -a                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmstat.exe doesn't exist, cannot perform operation.                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo retrieve virtual information [using lmvminfo.exe -long] ...                                                             >> %REPORT_LOGFILE% 2>&1
	echo     retrieve virtual information [using lmvminfo.exe -long] ...
	if defined LMS_LMVMINFO (
		"!LMS_LMVMINFO!" -long  > !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt  2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt                                                                        >> %REPORT_LOGFILE% 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt" (
			for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "Physical"') do set "VM_DETECTED_2=NO"   
			if not defined VM_DETECTED_2 (
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "Virtual"')  do set "VM_DETECTED_2=YES"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "FAMILY"')   do set "VM_FAMILY_2=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "NAME"')     do set "VM_NAME_2=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "UUID"')     do set "VM_UUID_2=%%B"   
				for /f "tokens=1,2 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\lmvminfo_long.txt ^|find /I "GENID"')    do set "VM_GENID_2=%%B"   
				rem Handle "GENID: ERROR - Unavailable."
				if "!VM_GENID_2!" == "ERROR" (
					set VM_GENID_2=
				)
			)
		)
	) else (
		echo     lmvminfo.exe doesn't exist, cannot perform operation.                                                           >> %REPORT_LOGFILE% 2>&1
	)
	REM echo     VM_DETECTED_2=!VM_DETECTED_2! / VM_FAMILY_2=!VM_FAMILY_2! / VM_NAME_2=!VM_NAME_2! / VM_UUID_2=!VM_UUID_2! / VM_GENID_2=!VM_GENID_2!
	echo Current VM values, collected with lmvminfo ...                                                                          >> %REPORT_LOGFILE% 2>&1
	echo VM_DETECTED_2=!VM_DETECTED_2! / VM_FAMILY_2=!VM_FAMILY_2! / VM_NAME_2=!VM_NAME_2! / VM_UUID_2=!VM_UUID_2! / VM_GENID_2=!VM_GENID_2! >> %REPORT_LOGFILE% 2>&1
	if not defined VM_DETECTED (
		REM For backward compatibility; in case virtual environment could not be determined so far; use lmvminfo output 
		if defined VM_DETECTED_2 (
			set VM_DETECTED=!VM_DETECTED_2!
			set VM_FAMILY=!VM_FAMILY_2!
			set VM_NAME=!VM_NAME_2!
			set VM_UUID=!VM_UUID_2!
			set VM_GENID=!VM_GENID_2!
		)
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo lmtpminfo.exe -long                                                                                                     >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMTPMINFO (
		"!LMS_LMTPMINFO!" -long                                                                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmtpminfo.exe doesn't exist, cannot perform operation.                                                          >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo tsreset_svr.exe -logreport verbose                                                                                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_TSRESETSVR (
		if "!FNPVersion!" == "11.14.0.0" (
			echo     tsreset_svr.exe -logreport verbose is not available for FNP=!FNPVersion!, cannot perform operation.         >> %REPORT_LOGFILE% 2>&1
		) else (
			del !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract.log >nul 2>&1
			rem logs to C:\ProgramData\FLEXnet\SIEMBT_8098d100_event.log
			"%LMS_TSRESETSVR%" -logreport verbose                                                                                >> %REPORT_LOGFILE% 2>&1
			rem read in last line the process id
			For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_8098d100_event.log") Do ( 
				Set messagedatetime=%%A  
				Set processid=%%B
				Set threadid=%%C
				Set fnpversionFromLogFile=%%D
				set message=%%E
			)
			rem read last lines which have been added with previous command
			For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_8098d100_event.log") Do if "%%B" EQU "!processid!" if "%%C" EQU "!threadid!" ( 
				echo Message: %%A [%%B] [%%C] [%%D] %%E  >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract.log
			)
			type !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract.log                                                    >> %REPORT_LOGFILE% 2>&1
			findstr /m /c:"orphans" "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract.log"                               >> %REPORT_LOGFILE% 2>&1
			if !ERRORLEVEL!==0 (
				if defined SHOW_COLORED_OUTPUT (
					echo [1;33m    WARNING: One or more orphan anchors have been found! [tsreset_svr.exe] [1;37m
				) else (
					echo     WARNING: One or more orphan anchors have been found! [tsreset_svr.exe]
				)
				echo     WARNING: One or more orphan anchors have been found! [tsreset_svr.exe]                                  >> %REPORT_LOGFILE% 2>&1
				echo     Remove orphan anchors with tsreset_svr.exe -anchors orphan                                              >> %REPORT_LOGFILE% 2>&1
				"%LMS_TSRESETSVR%" -anchors orphan                                                                               >> %REPORT_LOGFILE% 2>&1

				del !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract_retry.log >nul 2>&1
				rem logs to C:\ProgramData\FLEXnet\SIEMBT_8098d100_event.log
				"%LMS_TSRESETSVR%" -logreport verbose                                                                            >> %REPORT_LOGFILE% 2>&1
				rem read in last line the process id
				For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_8098d100_event.log") Do ( 
					Set messagedatetime=%%A  
					Set processid=%%B
					Set threadid=%%C
					Set fnpversionFromLogFile=%%D
					set message=%%E
				)
				rem read last lines which have been added with previous command
				For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_8098d100_event.log") Do if "%%B" EQU "!processid!" if "%%C" EQU "!threadid!" ( 
					echo Message: %%A [%%B] [%%C] [%%D] %%E  >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract_retry.log
				)
				type !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract_retry.log                                          >> %REPORT_LOGFILE% 2>&1
				findstr /m /c:"orphans" "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_8098d100_event_extract_retry.log"                     >> %REPORT_LOGFILE% 2>&1
				if !ERRORLEVEL!==0 (
					if defined SHOW_COLORED_OUTPUT (
						echo [1;33m    WARNING: Still one or more orphan anchors have been found! [tsreset_svr.exe] [1;37m
					) else (
						echo     WARNING: Still one or more orphan anchors have been found! [tsreset_svr.exe]
					)
					echo     WARNING: Still one or more orphan anchors have been found! [tsreset_svr.exe]                        >> %REPORT_LOGFILE% 2>&1
				)
			)
		)
	) else (
		echo     tsreset_svr.exe doesn't exist, cannot perform operation.                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo tsreset_app.exe -logreport verbose                                                                                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_TSRESETAPP (
		if "!FNPVersion!" == "11.14.0.0" (
			echo     tsreset_app.exe -logreport verbose is not available for FNP=!FNPVersion!, cannot perform operation.         >> %REPORT_LOGFILE% 2>&1
		) else (
			del !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract.log >nul 2>&1
			rem logs to C:\ProgramData\FLEXnet\SIEMBT_0098d100_event.log
			"%LMS_TSRESETAPP%" -logreport verbose                                                                                >> %REPORT_LOGFILE% 2>&1
			rem read in last line the process id
			For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_0098d100_event.log") Do ( 
				Set messagedatetime=%%A  
				Set processid=%%B
				Set threadid=%%C
				Set fnpversionFromLogFile=%%D
				set message=%%E
			)
			rem read last lines which have been added with previous command
			For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_0098d100_event.log") Do if "%%B" EQU "!processid!" if "%%C" EQU "!threadid!" ( 
				echo Message: %%A [%%B] [%%C] [%%D] %%E  >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract.log
			)
			type !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract.log                                                    >> %REPORT_LOGFILE% 2>&1
			findstr /m /c:"orphans" "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract.log"                               >> %REPORT_LOGFILE% 2>&1
			if !ERRORLEVEL!==0 (
				if defined SHOW_COLORED_OUTPUT (
					echo [1;33m    WARNING: One or more orphan anchors have been found! [tsreset_app.exe] [1;37m
				) else (
					echo     WARNING: One or more orphan anchors have been found! [tsreset_app.exe]
				)
				echo     WARNING: One or more orphan anchors have been found! [tsreset_app.exe]                                  >> %REPORT_LOGFILE% 2>&1
				echo     Remove orphan anchors with tsreset_app.exe -anchors orphan                                              >> %REPORT_LOGFILE% 2>&1
				"%LMS_TSRESETAPP%" -anchors orphan                                                                               >> %REPORT_LOGFILE% 2>&1

				del !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract_retry.log >nul 2>&1
				rem logs to C:\ProgramData\FLEXnet\SIEMBT_0098d100_event.log
				"%LMS_TSRESETAPP%" -logreport verbose                                                                            >> %REPORT_LOGFILE% 2>&1
				rem read in last line the process id
				For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_0098d100_event.log") Do ( 
					Set messagedatetime=%%A  
					Set processid=%%B
					Set threadid=%%C
					Set fnpversionFromLogFile=%%D
					set message=%%E
				)
				rem read last lines which have been added with previous command
				For /F "UseBackQ tokens=1,2,4,6,7 Delims=[]" %%A In ("%programdata%\FLEXnet\SIEMBT_0098d100_event.log") Do if "%%B" EQU "!processid!" if "%%C" EQU "!threadid!" ( 
					echo Message: %%A [%%B] [%%C] [%%D] %%E  >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract_retry.log
				)
				type !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract_retry.log                                          >> %REPORT_LOGFILE% 2>&1
				findstr /m /c:"orphans" "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_0098d100_event_extract_retry.log"                     >> %REPORT_LOGFILE% 2>&1
				if !ERRORLEVEL!==0 (
					if defined SHOW_COLORED_OUTPUT (
						echo [1;33m    WARNING: Still one or more orphan anchors have been found! [tsreset_app.exe] [1;37m
					) else (
						echo     WARNING: Still one or more orphan anchors have been found! [tsreset_app.exe]
					)
					echo     WARNING: Still one or more orphan anchors have been found! [tsreset_app.exe]                        >> %REPORT_LOGFILE% 2>&1
				)
			)
		)
	) else (
		echo     tsreset_app.exe doesn't exist, cannot perform operation.                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... collect host id's ...
	echo Collect host id's:                                                                                                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMHOSTID (
		echo ======== Host ID:                                                                                                   >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%"                                                                                                         >> %REPORT_LOGFILE% 2>&1
		echo ======== PHYSICAL Host ID:                                                                                          >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -user                                                                                                 >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -user                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ether                                                                                                >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ether                                                                                                  >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -internet v4                                                                                          >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -internet v4                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -internet v6                                                                                          >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -internet v6                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -utf8                                                                                                 >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -utf8                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -vsn                                                                                                  >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -vsn                                                                                                    >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -display                                                                                              >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -display                                                                                                >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -hostname                                                                                             >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -hostname                                                                                               >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -hostdomain                                                                                           >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -hostdomain                                                                                             >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -tpm_id1                                                                                              >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -tpm_id1                                                                                                >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -flexid                                                                                               >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -flexid                                                                                                 >> %REPORT_LOGFILE% 2>&1
		echo ======== VIRTUAL Host ID:                                                                                           >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ptype VM -uuid                                                                                       >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ptype VM -uuid                                                                                         >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ptype VM -genid                                                                                      >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ptype VM -genid                                                                                        >> %REPORT_LOGFILE% 2>&1
		echo ======== AMAZON Host ID:                                                                                            >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ptype AMZN -eip                                                                                      >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ptype AMZN -eip                                                                                        >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ptype AMZN -ami                                                                                      >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ptype AMZN -ami                                                                                        >> %REPORT_LOGFILE% 2>&1
		echo --- lmhostid: -ptype AMZN -iid                                                                                      >> %REPORT_LOGFILE% 2>&1
		"%LMS_LMHOSTID%" -ptype AMZN -iid                                                                                        >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     lmhostid.exe doesn't exist, cannot perform operation.                                                           >> %REPORT_LOGFILE% 2>&1
	)
)
rem Execute always, even LMS_SKIPFNP is set!
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1

if exist "!REPORT_LOG_PATH!\VMECMID_Latest.txt" (
	for /f "tokens=1,2,3,4,5,* eol=@ delims=,/ " %%A in ('type !REPORT_LOG_PATH!\VMECMID_Latest.txt ^|find /I "ECM_VM_FAMILY"') do (
		rem echo %%A / %%B / %%C / %%D / %%E // %%F
		for /f "tokens=1,2 delims==" %%a in ("%%A") do set ECM_VM_FAMILY_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%B") do set ECM_VM_NAME_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%C") do set ECM_VM_UUID_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%D") do set ECM_SMBIOS_UUID_PREV=%%b
		for /f "tokens=1,2 delims==" %%a in ("%%E") do set ECM_VM_GENID_PREV=%%b
		set ECMINFO_PREV=%%F
	)
	echo Previous ECM values, collected !ECMINFO_PREV! ...                                                                   >> %REPORT_LOGFILE% 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY_PREV! / ECM_VM_NAME=!ECM_VM_NAME_PREV! / ECM_VM_UUID=!ECM_VM_UUID_PREV! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID_PREV! / ECM_VM_GENID=!ECM_VM_GENID_PREV!  >> %REPORT_LOGFILE% 2>&1
)

echo ... read host id's [using ecmcommonutil.exe] ...
IF EXIST "%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" (
	rem log regular (non debug) output in general logfile
	echo Read host id: device [using ecmcommonutil.exe -l -f -d device]:                                                     >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f device                                                                     >> %REPORT_LOGFILE% 2>&1
	echo Read host id: net [using ecmcommonutil.exe -l -f -d net]:                                                           >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f net                                                                        >> %REPORT_LOGFILE% 2>&1
	echo Read host id: smbios [using ecmcommonutil.exe -l -f -d smbios]:                                                     >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f smbios                                                                     >> %REPORT_LOGFILE% 2>&1
	echo Read host id: vm [using ecmcommonutil.exe -l -f -d vm]:                                                             >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f vm                                                                         >> %REPORT_LOGFILE% 2>&1

	rem log debug output in a separate file
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_device.txt 2>&1
	echo Read host id: device [using ecmcommonutil.exe -l -f -d device] at !DATE! !TIME! ....        >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_device.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d device                                          >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_device.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d device                                          >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_device_Latest.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_net.txt 2>&1
	echo Read host id: net [using ecmcommonutil.exe -l -f -d net] at !DATE! !TIME! ....              >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_net.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d net                                             >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_net.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d net                                             >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_net_Latest.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios.txt 2>&1
	echo Read host id: smbios [using ecmcommonutil.exe -l -f -d smbios] at !DATE! !TIME! ....        >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d smbios                                          >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d smbios                                          >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios_Latest.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm.txt 2>&1
	echo Read host id: vm [using ecmcommonutil.exe -l -f -d vm] at !DATE! !TIME! ....                >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d vm                                              >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil.exe" -l -f -d vm                                              >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt 2>&1
	
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios_Latest.txt" for /f "tokens=1,2 eol=@ delims==" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_smbios_Latest.txt ^|find /I "Smbios UUID"') do set "ECM_SMBIOS_UUID=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt ^|findstr /I /B "FAMILY"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_FAMILY=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt ^|findstr /I /B "NAME"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_NAME=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt ^|findstr /I /B "UUID"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_UUID=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_vm_Latest.txt ^|findstr /I /B "GENID"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_GENID=%%B"
	
	rem echo     ECM_VM_FAMILY=!ECM_VM_FAMILY! / ECM_VM_NAME=!ECM_VM_NAME! / ECM_VM_UUID=!ECM_VM_UUID! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID! / ECM_VM_GENID=!ECM_VM_GENID! 
	echo Current ECM values, collected with ecmcommonutil ...                                                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY! / ECM_VM_NAME=!ECM_VM_NAME! / ECM_VM_UUID=!ECM_VM_UUID! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID! / ECM_VM_GENID=!ECM_VM_GENID!                      >> %REPORT_LOGFILE% 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY! / ECM_VM_NAME=!ECM_VM_NAME! / ECM_VM_UUID=!ECM_VM_UUID! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID! / ECM_VM_GENID=!ECM_VM_GENID!  at !DATE! / !TIME! / using ecmcommonutil.exe [V1.21] >> !REPORT_LOG_PATH!\VMECMID.txt 2>&1
	rem use latest values from ecmcommonutil V1.19 as they same more reliable on some virtual machines
	rem echo     ECM_VM_FAMILY=!ECM_VM_FAMILY! / ECM_VM_NAME=!ECM_VM_NAME! / ECM_VM_UUID=!ECM_VM_UUID! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID! / ECM_VM_GENID=!ECM_VM_GENID!  at !DATE! / !TIME! / using ecmcommonutil.exe [V1.21] >  !REPORT_LOG_PATH!\VMECMID_Latest.txt 2>&1
	
) else (
	echo     ecmcommonutil.exe doesn't exist, cannot perform operation.                                                      >> %REPORT_LOGFILE% 2>&1
)
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
echo ... read host id's [using ecmcommonutil_1.19.exe] ...
IF EXIST "%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" (
	rem log regular (non debug) output in general logfile
	echo Read host id: device [using ecmcommonutil_1.19.exe -l -f -d device]:                                                >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f device                                                                >> %REPORT_LOGFILE% 2>&1
	echo Read host id: net [using ecmcommonutil_1.19.exe -l -f -d net]:                                                      >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f net                                                                   >> %REPORT_LOGFILE% 2>&1
	echo Read host id: smbios [using ecmcommonutil_1.19.exe -l -f -d smbios]:                                                >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f smbios                                                                >> %REPORT_LOGFILE% 2>&1
	echo Read host id: vm [using ecmcommonutil_1.19.exe -l -f -d vm]:                                                        >> %REPORT_LOGFILE% 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f vm                                                                    >> %REPORT_LOGFILE% 2>&1

	rem log debug output in a separate file
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_device.txt 2>&1
	echo Read host id: device [using ecmcommonutil_1.19.exe -l -f -d device] at !DATE! !TIME! ....   >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_device.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d device                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_device.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_net.txt 2>&1
	echo Read host id: net [using ecmcommonutil_1.19.exe -l -f -d net] at !DATE! !TIME! ....         >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_net.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d net                                        >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_net.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios.txt 2>&1
	echo Read host id: smbios [using ecmcommonutil_1.19.exe -l -f -d smbios] at !DATE! !TIME! ....   >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d smbios                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d smbios                                     >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios_Latest.txt 2>&1
	echo -------------------------------------------------------                                     >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm.txt 2>&1
	echo Read host id: vm [using ecmcommonutil_1.19.exe -l -f -d vm] at !DATE! !TIME! ....           >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d vm                                         >> !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm.txt 2>&1
	"%DOWNLOAD_LMS_PATH%\ecmcommonutil_1.19.exe" -l -f -d vm                                         >  !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt 2>&1

	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios_Latest.txt" for /f "tokens=1,2 eol=@ delims==" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_smbios_Latest.txt ^|find /I "Smbios UUID"') do set "ECM_SMBIOS_UUID_2=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt ^|findstr /I /B "FAMILY"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_FAMILY_2=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt ^|findstr /I /B "NAME"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_NAME_2=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt ^|findstr /I /B "UUID"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_UUID_2=%%B"
	if exist "!CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt"     for /f "tokens=1,2 eol=@ delims==:" %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\ecmcommonutil_1.19_vm_Latest.txt ^|findstr /I /B "GENID"') do if not "%%B" == " ERROR - Unavailable." set "ECM_VM_GENID_2=%%B"
	
	rem echo     ECM_VM_FAMILY=!ECM_VM_FAMILY_2! / ECM_VM_NAME=!ECM_VM_NAME_2! / ECM_VM_UUID=!ECM_VM_UUID_2! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID_2! / ECM_VM_GENID=!ECM_VM_GENID_2! 
	echo Current ECM values, collected with ecmcommonutil ...                                                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY_2! / ECM_VM_NAME=!ECM_VM_NAME_2! / ECM_VM_UUID=!ECM_VM_UUID_2! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID_2! / ECM_VM_GENID=!ECM_VM_GENID_2!                      >> %REPORT_LOGFILE% 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY_2! / ECM_VM_NAME=!ECM_VM_NAME_2! / ECM_VM_UUID=!ECM_VM_UUID_2! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID_2! / ECM_VM_GENID=!ECM_VM_GENID_2!  at !DATE! / !TIME! / using ecmcommonutil.exe [V1.19] >> !REPORT_LOG_PATH!\VMECMID.txt 2>&1
	echo     ECM_VM_FAMILY=!ECM_VM_FAMILY_2! / ECM_VM_NAME=!ECM_VM_NAME_2! / ECM_VM_UUID=!ECM_VM_UUID_2! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID_2! / ECM_VM_GENID=!ECM_VM_GENID_2!  at !DATE! / !TIME! / using ecmcommonutil.exe [V1.19] >  !REPORT_LOG_PATH!\VMECMID_Latest.txt 2>&1

) else (
	echo     ecmcommonutil_1.19.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
)
if not defined LMS_SKIPFNP ( 
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... list available offline request files ...
	echo List available offline request files:                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "!LMS_PROGRAMDATA!\Requests"                                                                         >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "!LMS_PROGRAMDATA!\Requests"                                                                              >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\license_all_requests.txt >nul 2>&1
	FOR %%i IN ("!LMS_PROGRAMDATA!\Requests\*") DO (
		rem echo %%i:                                                                                                                >> %REPORT_LOGFILE% 2>&1
		rem Type "%%i"                                                                                                               >> %REPORT_LOGFILE% 2>&1
		rem echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		Type "%%i"                                                     >> !CHECKLMS_REPORT_LOG_PATH!\license_all_requests.txt 2>&1
		echo -------------------------------------------------------   >> !CHECKLMS_REPORT_LOG_PATH!\license_all_requests.txt 2>&1
	)
	echo More details, see '!CHECKLMS_REPORT_LOG_PATH!\license_all_requests.txt'                                                 >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... analyze installed/available local certificates ...
	echo Installed/available local certificates:                                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "!LMS_PROGRAMDATA!\Certificates"                                                                     >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "!LMS_PROGRAMDATA!\Certificates"                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\license_all_certificates.txt >nul 2>&1
	FOR %%i IN ("!LMS_PROGRAMDATA!\Certificates\*") DO (    
		echo %%i:                                                                                                                >> %REPORT_LOGFILE% 2>&1
		Type "%%i"                                                                                                               >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		Type "%%i"                                                     >> !CHECKLMS_REPORT_LOG_PATH!\license_all_certificates.txt 2>&1
		echo -------------------------------------------------------   >> !CHECKLMS_REPORT_LOG_PATH!\license_all_certificates.txt 2>&1
	)
	set certfeature=
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\license_all_certificates.txt" for /f "tokens=2 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\license_all_certificates.txt ^|find /I "INCREMENT"') do set "certfeature=%%i"   
	if defined LMS_LMUTOOL (
		if defined certfeature (
			echo Check certificate feature: %certfeature%, with LmuTool.exe /CHECK:%certfeature%                                 >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /CHECK:%certfeature%                                                                                 >> %REPORT_LOGFILE% 2>&1
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
			echo Check certificate feature: %certfeature%, with LmuTool.exe /FC:%certfeature%                                    >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /FC:%certfeature%                                                                                    >> %REPORT_LOGFILE% 2>&1
		) else (
			echo Check certificate feature: not possible, no feature found in certificates to test.                              >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... analyze installed/available server certificates ...
	echo Installed/available server certificates:                                                                                >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "!LMS_PROGRAMDATA!\Server Certificates"                                                              >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "!LMS_PROGRAMDATA!\Server Certificates"                                                                   >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\license_all_servercertificates.txt >nul 2>&1
	FOR %%i IN ("!LMS_PROGRAMDATA!\Server Certificates\*") DO (
		echo %%i:                                                                                                                >> %REPORT_LOGFILE% 2>&1
		Type "%%i"                                                                                                               >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		Type "%%i">> !CHECKLMS_REPORT_LOG_PATH!\license_all_servercertificates.txt 2>&1
		echo -------------------------------------------------------   >> !CHECKLMS_REPORT_LOG_PATH!\license_all_servercertificates.txt 2>&1
	)
	set servercertfeature=
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\license_all_servercertificates.txt" for /f "tokens=2 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\license_all_servercertificates.txt ^|find /I "INCREMENT"') do if not "%%i" == "Dummy_valid_feature" set "servercertfeature=%%i"
	if defined LMS_LMUTOOL (
		if defined servercertfeature (
			echo Check server certificate feature: %servercertfeature%, with LmuTool.exe /CHECK:%servercertfeature%              >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /CHECK:%servercertfeature%                                                                           >> %REPORT_LOGFILE% 2>&1
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
			echo Check server certificate feature: %servercertfeature%, with LmuTool.exe /FC:%servercertfeature%                 >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /FC:%servercertfeature%                                                                              >> %REPORT_LOGFILE% 2>&1
		) else (
			echo Check server certificate feature: not possible, no feature found in server certificates to test.                >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "%ALLUSERSPROFILE%\FLEXnet" [Trusted Store Folder]                                                   >> %REPORT_LOGFILE% 2>&1
	rem dir "%ALLUSERSPROFILE%\FLEXnet"                                                                                              >> %REPORT_LOGFILE% 2>&1
	rem dir /AH "%ALLUSERSPROFILE%\FLEXnet"                                                                                          >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "%ALLUSERSPROFILE%\FLEXnet"                                                                               >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo ... search trusted store files ...
	echo Search trusted store files:                                                                                             >> %REPORT_LOGFILE% 2>&1
	if exist "%ALLUSERSPROFILE%\FLEXnet\" (
		del !CHECKLMS_REPORT_LOG_PATH!\tfsFilesFound.txt >nul 2>&1
		cd %ALLUSERSPROFILE%\FLEXnet\
		FOR /r %ALLUSERSPROFILE%\FLEXnet\ %%X IN (*tsf.data) DO echo %%~dpnxX >> !CHECKLMS_REPORT_LOG_PATH!\tfsFilesFound.txt
		Type !CHECKLMS_REPORT_LOG_PATH!\tfsFilesFound.txt                                                                        >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No files found, the directory '%ALLUSERSPROFILE%\FLEXnet\' doesn't exist.                                       >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... decrypt Flexera logfiles ... 
	echo Decrypt Flexera logfiles:                                                                                             >> %REPORT_LOGFILE% 2>&1
	if defined LMS_TSACTDIAGSSVR (
		echo Call "%LMS_TSACTDIAGSSVR% --output !REPORT_LOG_PATH!\FlexeraDecryptedEventlog.log" to decrypt ....                  >> %REPORT_LOGFILE% 2>&1
		"%LMS_TSACTDIAGSSVR%" --output !REPORT_LOG_PATH!\FlexeraDecryptedEventlog.log
		
		rem Analyze the decrypted flexera logfile
		echo     Analyze the decrypted flexera logfile ...
		for /f "tokens=1,2,3,4,5,7,9,11,12,13,14,15,16,17,18,19,20,21,22,23,24 eol=@ delims=[], " %%A in ('type !REPORT_LOG_PATH!\FlexeraDecryptedEventlog.log') do (
			set TS_LOG_MSG="%%B %%A - %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"

			rem [Time] [Date] [Process Id] [Thread Id] [Version] build [Build Number] EventCode: [EventCode] Message: [....]
			rem [1]    [2]    [3]          [4]         [5]             [7]                       [9]                  [11,...]
			rem [A]    [B]    [C]          [D]         [E]             [F]                       [G]                  [H,...]
			rem echo [2]=%%B / [1]=%%A / [3]=%%C / [4]=%%D / [5]=%%E / [7]=%%F / [9]=%%G / [11]=%%H
			rem Determine start & end date/time of logfile content
			if not defined TS_LOG_START_DATE (
				set TS_LOG_START_DATE="%%B %%A"
			)
			set TS_LOG_END_DATE="%%B %%A"
			rem Check for "Transient break" [Event: 40000012]
			rem [Time] [Date] [Process Id] [Thread Id] [Version] build [Build Number] EventCode: [EventCode] Message: [Transient] [break.] [Timezone] [Validators] [TrustedId] [1=] [2=] [3=] [4=] [5=] [6=] [7=] [17=] [...]
			rem [1]    [2]    [3]          [4]         [5]             [7]                       [9]                  [11]        [12]     [13]       [14]         [15]        [16] [17] [18] [19] [20] [21] [22] [23]  [24...]
			rem [A]    [B]    [C]          [D]         [E]             [F]                       [G]                  [H]         [I]      [J]        [K]          [L]         [M]  [N]  [O]  [P]  [Q]  [R]  [S]  [T]   [U]

			if "%%G" EQU "40000012" (
				if not defined TS_LOG_TRANS_BRK_FOUND (
					set TS_LOG_TRANS_BRK_FOUND="%%B %%A - Transient break found - %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
					set TS_LOG_TRANS_BRK_FOUND_START_DATE="%%B %%A"
				)
				set TS_LOG_TRANS_BRK_FOUND_END_DATE="%%B %%A"
				
				rem check validator: The numbers for the validator are either "1" [Validator=1] for anchoring or "2" [Validator=2] for binding.
				if "%%K" EQU "Validator=1" (
					if not defined TS_LOG_TRANS_BRK_VAL1_FOUND (
						set TS_LOG_TRANS_BRK_VAL1_FOUND="%%B %%A - Transient break found in Anchoring - %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
						set TS_LOG_TRANS_BRK_VAL1_FOUND_START_DATE="%%B %%A"
					)
					set TS_LOG_TRANS_BRK_VAL1_FOUND_END_DATE="%%B %%A"
					
					echo !TS_LOG_MSG!|find " 1=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_TRACKZERO_FOUND=changed)
					echo !TS_LOG_MSG!|find " 1=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_TRACKZERO_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 2=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_REGISTRY_FOUND=changed)
					echo !TS_LOG_MSG!|find " 2=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_REGISTRY_FOUND=IsNotAvailable)
					
				)
				if "%%K" EQU "Validator=2" (
					if not defined TS_LOG_TRANS_BRK_VAL2_FOUND (
						set TS_LOG_TRANS_BRK_VAL2_FOUND="%%B %%A - Transient break found in Binding - %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
						set TS_LOG_TRANS_BRK_VAL2_FOUND_START_DATE="%%B %%A"
					)
					set TS_LOG_TRANS_BRK_VAL2_FOUND_END_DATE="%%B %%A"
					
					echo !TS_LOG_MSG!|find " 1=1" >nul
					if not errorlevel 1 set TS_LOG_TRANS_BRK_SYSTEM_FOUND=changed
					echo !TS_LOG_MSG!|find " 1=2" >nul
					if not errorlevel 1 set TS_LOG_TRANS_BRK_SYSTEM_FOUND=IsNotAvailable
					echo !TS_LOG_MSG!|find " 2=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_HARDDISK_FOUND=changed)
					echo !TS_LOG_MSG!|find " 2=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_HARDDISK_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 3=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_DISPLAY_FOUND=changed)
					echo !TS_LOG_MSG!|find " 3=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_DISPLAY_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 4=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_BIOS_FOUND=changed)
					echo !TS_LOG_MSG!|find " 4=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_BIOS_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 5=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_CPU_FOUND=changed)
					echo !TS_LOG_MSG!|find " 5=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_CPU_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 6=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_MEMORY_FOUND=changed)
					echo !TS_LOG_MSG!|find " 6=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_MEMORY_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 7=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_ETHERNET_FOUND=changed)
					echo !TS_LOG_MSG!|find " 7=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_ETHERNET_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 13=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_PUBLSIHER_FOUND=changed)
					echo !TS_LOG_MSG!|find " 13=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_PUBLSIHER_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 14=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_VMID_FOUND=changed)
					echo !TS_LOG_MSG!|find " 14=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_VMID_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 16=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_GENID_FOUND=changed)
					echo !TS_LOG_MSG!|find " 16=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_GENID_FOUND=IsNotAvailable)
					echo !TS_LOG_MSG!|find " 17=1" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_TPMID_FOUND=changed)
					echo !TS_LOG_MSG!|find " 17=2" >nul
					if not errorlevel 1 (set TS_LOG_TRANS_BRK_TPMID_FOUND=IsNotAvailable)
					
				)
				
			)
			rem Check for "Bad Anchor" [Event: 20000020]
			rem [Time] [Date] [Process Id] [Thread Id] [Version] build [Build Number] EventCode: [EventCode] Message: [Anchor] [x-xxxx] is bad [...]
			rem [1]    [2]    [3]          [4]         [5]             [7]                       [9]                  [11]     [12]            [13...]
			rem [A]    [B]    [C]          [D]         [E]             [F]                       [G]                  [H]      [I]             [J]
			rem
			rem Example:
			rem    19:23:36 11-08-2020  [P:7300],[T:7304],[V:11.17.0.0 build 264148] 	EventCode: 10000009, Message: Anchor 2-0x8098d101Not on system
			rem    19:23:36 11-08-2020  [P:7300],[T:7304],[V:11.17.0.0 build 264148] 	EventCode: 20000020, Message: Anchor 2-0x8098d101 is bad
			rem    19:23:36 11-08-2020  [P:7300],[T:7304],[V:11.17.0.0 build 264148] 	EventCode: 1000000f, Message: Anchor 2-0x8098d101 repaired (bad)
			if "%%G" EQU "20000020" (
				if not defined TS_LOG_BAD_ANCH_FOUND (
					set TS_LOG_BAD_ANCH_FOUND=1
					set TS_LOG_BAD_ANCH_FOUND_MESSAGE="'Bad Anchor' [Event: 20000020] found - %%B %%A - Bad anchor found - %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
					echo ATTENTION:  !TS_LOG_BAD_ANCH_FOUND_MESSAGE!                                                                       >> %REPORT_LOGFILE% 2>&1
					set TS_LOG_BAD_ANCH_FOUND_START_DATE="%%B %%A"
				)
			)
			if "%%G" EQU "1000000f" (
				if defined TS_LOG_BAD_ANCH_FOUND (
					set TS_LOG_BAD_ANCH_FOUND=
					set TS_LOG_BAD_ANCH_REP_FOUND_MESSAGE="'Bad Anchor Repair' [Event: 1000000f] found - %%B %%A - Bad anchor repair found - %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
					echo             !TS_LOG_BAD_ANCH_REP_FOUND_MESSAGE!                                                                   >> %REPORT_LOGFILE% 2>&1
					set TS_LOG_BAD_ANCH_FOUND_END_DATE="%%B %%A"
					rem create summary message
					set TS_LOG_BAD_ANCH_FOUND_MESSAGE="%%B %%A - Bad anchor REPAIRED - was bad from !TS_LOG_BAD_ANCH_FOUND_START_DATE! till !TS_LOG_BAD_ANCH_FOUND_END_DATE! (Version=%%E / Build=%%F)"
					echo             ---- !TS_LOG_BAD_ANCH_FOUND_MESSAGE!                                                                  >> %REPORT_LOGFILE% 2>&1
				)
			)
			
			rem Check for "Anchor not available" [Event: 1000000d]
			rem [Time] [Date] [Process Id] [Thread Id] [Version] build [Build Number] EventCode: [EventCode] Message: [xxxxx] n not available [...]
			rem [1]    [2]    [3]          [4]         [5]             [7]                       [9]                  [11]    [12]      [13...]
			rem [A]    [B]    [C]          [D]         [E]             [F]                       [G]                  [H]     [I]       [J]
			if "%%G" EQU "1000000d" (
				if not defined TS_LOG_ANCH_NOT_FOUND (
					set TS_LOG_ANCH_NOT_FOUND="%%B %%A - Anchor not available - %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U (Version=%%E / Build=%%F)"
					set TS_LOG_ANCH_NOT_FOUND_START_DATE="%%B %%A"
				)
				set TS_LOG_ANCH_NOT_FOUND_END_DATE="%%B %%A"
			)
		)	

		echo FlexeraDecryptedEventlog.log contains data from start date: !TS_LOG_START_DATE! till end date: !TS_LOG_END_DATE!              >> %REPORT_LOGFILE% 2>&1
		echo !REPORT_LOG_PATH!\FlexeraDecryptedEventlog.log: only last %LOG_FILE_LINES% lines                                              >> %REPORT_LOGFILE% 2>&1 
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\FlexeraDecryptedEventlog.log' | Select-Object -last %LOG_FILE_LINES%}"      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     tsactdiags_SIEMBT_svr.exe doesn't exist, cannot perform operation to create decrypted logfile!                            >> %REPORT_LOGFILE% 2>&1
	)

	echo     Check for break information within logfiles ...
	if defined TS_LOG_TRANS_BRK_FOUND (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: "Transient break" [Event: 40000012] found - !TS_LOG_TRANS_BRK_FOUND! [1;37m
		) else (
			echo     ATTENTION: "Transient break" [Event: 40000012] found - !TS_LOG_TRANS_BRK_FOUND!
		)
		echo ATTENTION: "Transient break" [Event: 40000012] found - !TS_LOG_TRANS_BRK_FOUND!                                               >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_VAL1_FOUND (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: "Transient break in Anchoring" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL1_FOUND! [1;37m
		) else (
			echo     ATTENTION: "Transient break in Anchoring" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL1_FOUND!
		)
		echo ATTENTION: "Transient break in Anchoring" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL1_FOUND!                             >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_VAL2_FOUND (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: "Transient break in Binding" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL2_FOUND! [1;37m
		) else (
			echo     ATTENTION: "Transient break in Binding" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL2_FOUND!
		)
		echo ATTENTION: "Transient break in Binding" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL2_FOUND!                               >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_BAD_ANCH_FOUND (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: !TS_LOG_BAD_ANCH_FOUND_MESSAGE! [1;37m
		) else (
			echo     ATTENTION: !TS_LOG_BAD_ANCH_FOUND_MESSAGE!
		)
		echo ATTENTION: !TS_LOG_BAD_ANCH_FOUND_MESSAGE!                                                                                    >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_ANCH_NOT_FOUND (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: "Anchor not available" [Event: 1000000d] found - !TS_LOG_ANCH_NOT_FOUND! [1;37m
		) else (
			echo     ATTENTION: "Anchor not available" [Event: 1000000d] found - !TS_LOG_ANCH_NOT_FOUND!
		)
		echo ATTENTION: "Anchor not available" [Event: 1000000d] found - !TS_LOG_ANCH_NOT_FOUND!                                           >> %REPORT_LOGFILE% 2>&1
	)

	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... search Flexera logfiles ...
	echo Search Flexera logfiles:                                                                                                >> %REPORT_LOGFILE% 2>&1
	if exist "%ALLUSERSPROFILE%\FLEXnet\" (
		del !CHECKLMS_REPORT_LOG_PATH!\FlexeraLogFilesFound.txt >nul 2>&1
		cd %ALLUSERSPROFILE%\FLEXnet\
		FOR /r %ALLUSERSPROFILE%\FLEXnet\ %%X IN (*.log) DO echo %%~dpnxX >> !CHECKLMS_REPORT_LOG_PATH!\FlexeraLogFilesFound.txt
		Type !CHECKLMS_REPORT_LOG_PATH!\FlexeraLogFilesFound.txt                                                                 >> %REPORT_LOGFILE% 2>&1
		FOR %%X IN (%ALLUSERSPROFILE%\FLEXnet\*.log) DO ( 
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
			echo %%X                                                                                                             >> %REPORT_LOGFILE% 2>&1 
			powershell -command "& {Get-Content '%%X' | Select-Object -last %LOG_FILE_LINES%}"                                   >> %REPORT_LOGFILE% 2>&1 
			copy %%X !CHECKLMS_REPORT_LOG_PATH!\                                                                                 >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     No files found, the directory '%ALLUSERSPROFILE%\FLEXnet\' doesn't exist.                                       >> %REPORT_LOGFILE% 2>&1
	)
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED FNP section. The script didn't execute the FNP commands. [1;37m
	) else (
		echo     SKIPPED FNP section. The script didn't execute the FNP commands.
	)
	echo SKIPPED FNP section. The script didn't execute the FNP commands.                                                        >> %REPORT_LOGFILE% 2>&1
)
rem Run *always* even if LMS_SKIPFNP is set
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo Analyze 'SIEMBT.log' ...                                                                                                >> %REPORT_LOGFILE% 2>&1
IF EXIST "!REPORT_LOG_PATH!\SIEMBT.log" (
	FOR /F "usebackq" %%A IN ('!REPORT_LOG_PATH!\SIEMBT.log') DO set SIEMBTLOG_FILESIZE=%%~zA
	echo     Filesize of SIEMBT.log is !SIEMBTLOG_FILESIZE! bytes !                                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
	if /I !SIEMBTLOG_FILESIZE! GEQ !LOG_FILESIZE_LIMIT! (
		echo     ATTENTION: Filesize of SIEMBT.log with !SIEMBTLOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!

		echo     ATTENTION: Filesize of SIEMBT.log with !SIEMBTLOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!   >> %REPORT_LOGFILE% 2>&1
		echo     Because filesize of SIEMBT.log with !SIEMBTLOG_FILESIZE! bytes exceeds critical limit it is not further processed!              >> %REPORT_LOGFILE% 2>&1
	) else (
		rem Extract important identifiers from SIEMBT.log
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\SIEMBT.log ^|find /I "Host used in license file"') do for /f "tokens=5* eol=@ delims=: " %%A in ("%%B") do set LMS_SIEMBT_HOSTNAME=%%B
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\SIEMBT.log ^|find /I "Running on Hypervisor"') do for /f "tokens=3* eol=@ delims=: " %%A in ("%%B") do set LMS_SIEMBT_HYPERVISOR=%%B
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\SIEMBT.log ^|find /I "HostID of the License Server"') do for /f "tokens=5* eol=@ delims=: " %%A in ("%%B") do set LMS_SIEMBT_HOSTIDS=%%B
		echo LMS_SIEMBT_HOSTNAME=!LMS_SIEMBT_HOSTNAME! / LMS_SIEMBT_HYPERVISOR=!LMS_SIEMBT_HYPERVISOR! / LMS_SIEMBT_HOSTIDS=!LMS_SIEMBT_HOSTIDS!  >> %REPORT_LOGFILE% 2>&1
		echo LMS_SIEMBT_HOSTNAME=!LMS_SIEMBT_HOSTNAME! / LMS_SIEMBT_HYPERVISOR=!LMS_SIEMBT_HYPERVISOR! / LMS_SIEMBT_HOSTIDS=!LMS_SIEMBT_HOSTIDS! at !DATE! / !TIME! / retrieved from SIEMBT.log file >> !REPORT_LOG_PATH!\SIEMBTID.txt 2>&1
		echo LMS_SIEMBT_HOSTNAME=!LMS_SIEMBT_HOSTNAME! / LMS_SIEMBT_HYPERVISOR=!LMS_SIEMBT_HYPERVISOR! / LMS_SIEMBT_HOSTIDS=!LMS_SIEMBT_HOSTIDS! at !DATE! / !TIME! / retrieved from SIEMBT.log file >  !REPORT_LOG_PATH!\SIEMBTID_Latest.txt 2>&1

		echo -- extract ERROR messages from SIEMBT.log [start] --                                                            >> %REPORT_LOGFILE% 2>&1
		Type "!REPORT_LOG_PATH!\SIEMBT.log" | findstr "ERROR:"                                                               >> %REPORT_LOGFILE% 2>&1
		echo -- extract ERROR messages from SIEMBT.log [end] --                                                              >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1

		if not defined LMS_CHECK_ID (
			rem Extract "Host Info"
			rem NOTE: The implementation below is VERY slow, we should move this part into /extend mode :-)
			Set LMS_START_LOG=0
			del "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt" >nul 2>&1
			FOR /F "eol=@ delims=" %%i IN ('type !REPORT_LOG_PATH!\SIEMBT.log') DO ( 
				ECHO "%%i" | FINDSTR /C:"=== Host Info ===" 1>nul 
				if !ERRORLEVEL!==0 (
					echo Start of 'Host Info' section found ... > !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt 2>&1
					Set LMS_START_LOG=1
				)
				if !LMS_START_LOG!==1 (
					echo %%i                                    >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt 2>&1
					
					rem check for end of 'Host Info' block
					ECHO "%%i" | FINDSTR /C:"===============================================" 1>nul 
					if !ERRORLEVEL!==0 (
						echo End of 'Host Info' section found ...   >> !CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt 2>&1
						Set LMS_START_LOG=0
					)
				)
			)
			IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt" (
				type "!CHECKLMS_REPORT_LOG_PATH!\SIEMBT_HostInfo.txt"                                                        >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     ATTENTION: No 'Host Info' found in '!REPORT_LOG_PATH!\SIEMBT.log'!                                  >> %REPORT_LOGFILE% 2>&1
			)

			rem SIEMBT.log
			echo Start at !DATE! !TIME! ....                                                                                 >> %REPORT_LOGFILE% 2>&1
			echo LOG FILE: SIEMBT.log [last %LOG_FILE_LINES% lines]                                                          >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '!REPORT_LOG_PATH!\SIEMBT.log' | Select-Object -last %LOG_FILE_LINES%}"      >> %REPORT_LOGFILE% 2>&1
		)
	)

) else (
	echo     !REPORT_LOG_PATH!\SIEMBT.log not found.                                                                         >> %REPORT_LOGFILE% 2>&1
)
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
echo Analyze 'demo_debuglog.txt' ...                                                                                         >> %REPORT_LOGFILE% 2>&1
IF EXIST "!REPORT_LOG_PATH!\demo_debuglog.txt" (
	rem This is the demo vendor daemon logfile, it is only available if demo vendor daemon has been started
	FOR /F "usebackq" %%A IN ('!REPORT_LOG_PATH!\demo_debuglog.txt') DO set DEMOVDLOG_FILESIZE=%%~zA
	echo     Filesize of demo_debuglog.txt is !DEMOVDLOG_FILESIZE! bytes !                                                   >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
	if /I !DEMOVDLOG_FILESIZE! GEQ !LOG_FILESIZE_LIMIT! (
		echo     ATTENTION: Filesize of demo_debuglog.txt with !DEMOVDLOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!

		echo     ATTENTION: Filesize of demo_debuglog.txt with !DEMOVDLOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!   >> %REPORT_LOGFILE% 2>&1
		echo     Because filesize of demo_debuglog.txt with !DEMOVDLOG_FILESIZE! bytes exceeds critical limit it is not further processed!              >> %REPORT_LOGFILE% 2>&1
	) else (
		rem Extract important identifiers from demo_debuglog.txt
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\demo_debuglog.txt ^|find /I "Host used in license file"') do for /f "tokens=5* eol=@ delims=: " %%A in ("%%B") do set LMS_DEMOVD_HOSTNAME=%%B
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\demo_debuglog.txt ^|find /I "Running on Hypervisor"') do for /f "tokens=3* eol=@ delims=: " %%A in ("%%B") do set LMS_DEMOVD_HYPERVISOR=%%B
		for /f "tokens=3* eol=@ delims= " %%A in ('type !REPORT_LOG_PATH!\demo_debuglog.txt ^|find /I "HostID of the License Server"') do for /f "tokens=5* eol=@ delims=: " %%A in ("%%B") do set LMS_DEMOVD_HOSTIDS=%%B
		echo LMS_DEMOVD_HOSTNAME=!LMS_DEMOVD_HOSTNAME! / LMS_DEMOVD_HYPERVISOR=!LMS_DEMOVD_HYPERVISOR! / LMS_DEMOVD_HOSTIDS=!LMS_DEMOVD_HOSTIDS!  >> %REPORT_LOGFILE% 2>&1

		echo -- extract ERROR messages from demo_debuglog.txt [start] --                                                     >> %REPORT_LOGFILE% 2>&1
		Type "!REPORT_LOG_PATH!\demo_debuglog.txt" | findstr "ERROR:"                                                        >> %REPORT_LOGFILE% 2>&1
		echo -- extract ERROR messages from demo_debuglog.txt [end] --                                                       >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1

		if not defined LMS_CHECK_ID (
			rem Extract "Host Info"
			rem NOTE: The implementation below is VERY slow, we should move this part into /extend mode :-)
			Set LMS_START_LOG=0
			del "!CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt" >nul 2>&1
			FOR /F "eol=@ delims=" %%i IN ('type !REPORT_LOG_PATH!\demo_debuglog.txt') DO ( 
				ECHO "%%i" | FINDSTR /C:"=== Host Info ===" 1>nul 
				if !ERRORLEVEL!==0 (
					echo Start of 'Host Info' section found ... > !CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt 2>&1
					Set LMS_START_LOG=1
				)
				if !LMS_START_LOG!==1 (
					echo %%i                                    >> !CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt 2>&1
					
					rem check for end of 'Host Info' block
					ECHO "%%i" | FINDSTR /C:"===============================================" 1>nul 
					if !ERRORLEVEL!==0 (
						echo End of 'Host Info' section found ...   >> !CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt 2>&1
						Set LMS_START_LOG=0
					)
				)
			)
			IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt" (
				type "!CHECKLMS_REPORT_LOG_PATH!\DEMOVD_HostInfo.txt"                                                        >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     ATTENTION: No 'Host Info' found in '!REPORT_LOG_PATH!\demo_debuglog.txt'!                           >> %REPORT_LOGFILE% 2>&1
			)

			rem demo_debuglog.txt
			echo Start at !DATE! !TIME! ....                                                                                 >> %REPORT_LOGFILE% 2>&1
			echo LOG FILE: demo_debuglog.txt [last %LOG_FILE_LINES% lines]                                                          >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '!REPORT_LOG_PATH!\demo_debuglog.txt' | Select-Object -last %LOG_FILE_LINES%}"      >> %REPORT_LOGFILE% 2>&1
		)
	)

) else (
	echo     !REPORT_LOG_PATH!\demo_debuglog.txt not found.                                                                         >> %REPORT_LOGFILE% 2>&1
)
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   L I C E N S E   S E R V E R                                              =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... analyze license server ...
if not defined LMS_SKIPLICSERV (
	echo servercomptranutil.exe -listRequests                                                                                    >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -listRequests > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_simple.xml 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_simple.xml                                               >> %REPORT_LOGFILE% 2>&1
		echo -- extract pending requests [start] --                                                                              >> %REPORT_LOGFILE% 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_simple.xml" | findstr "Pending"                         >> %REPORT_LOGFILE% 2>&1
		echo -- extract pending requests [end] --                                                                                >> %REPORT_LOGFILE% 2>&1
		for /f "tokens=1,2,3,4 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_simple.xml') do if "%%B" EQU "Pending" (
			echo     Pending request '%%A' found from %%C %%D
			echo     Pending request '%%A' found from %%C %%D, retrieve this request information in !CHECKLMS_REPORT_LOG_PATH!\pending_req_%%A.xml    >> %REPORT_LOGFILE% 2>&1
			"%LMS_SERVERCOMTRANUTIL%" -stored !CHECKLMS_REPORT_LOG_PATH!\pending_req_%%A.xml request=%%A                         >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo servercomptranutil.exe -listRequests format=long                                                                        >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -listRequests format=long > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_long.xml 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_long.xml                                                 >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo servercomptranutil.exe -listRequests format=xml                                                                         >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -listRequests format=xml > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml 2>&1
		echo     See !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml                                              >> %REPORT_LOGFILE% 2>&1

		rem retrieve section break info
		findstr /m /c:"StorageBreakInfo" "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml"                        >> %REPORT_LOGFILE% 2>&1
		if !ERRORLEVEL!==0 (
			echo     'StorageBreakInfo' section was found in !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml ...  >> %REPORT_LOGFILE% 2>&1
			Set LMS_START_LOG=0
			FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml) DO ( 
				ECHO "%%i" | FINDSTR /C:"<StorageBreakInfo>" 1>nul 
				if !ERRORLEVEL!==0 (
					echo     Start of 'StorageBreakInfo' section found ...                                                       >> %REPORT_LOGFILE% 2>&1
					Set LMS_START_LOG=1
				)
				if !LMS_START_LOG!==1 (
					echo     %%i                                                                                                 >> %REPORT_LOGFILE% 2>&1
					
					rem check for end of 'StorageBreakInfo' section
					ECHO "%%i" | FINDSTR /C:"</StorageBreakInfo>" 1>nul 
					if !ERRORLEVEL!==0 (
						echo     End of 'StorageBreakInfo' section found ...                                                     >> %REPORT_LOGFILE% 2>&1
						Set LMS_START_LOG=0
					)
				)
			)
		) else (
			echo     NO 'StorageBreakInfo' section was found in !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_listRequests_XML.xml ...  >> %REPORT_LOGFILE% 2>&1
		)

	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo servercomptranutil.exe -view                                                                                            >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -view > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_view.txt  2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_view.txt                                                              >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo servercomptranutil.exe -view format=long                                                                                >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -view format=long > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt  2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt                                                          >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	rem Search for an installed feature and test them
	set tsfeature=
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt" for /f "tokens=2 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "INCREMENT"') do set "tsfeature=%%i"
	if defined LMS_LMUTOOL (
		if defined tsfeature (
			echo Check trusted store feature: %tsfeature%, with LmuTool.exe /CHECK:%tsfeature%                                   >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /CHECK:%tsfeature%                                                                                   >> %REPORT_LOGFILE% 2>&1
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
			echo Check trusted store feature: %tsfeature%, with LmuTool.exe /FC:%tsfeature%                                      >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /FC:%tsfeature%                                                                                      >> %REPORT_LOGFILE% 2>&1
		) else (
			echo Check trusted store feature: not possible, no feature found in trusted store to test.                           >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	rem Analyze output regarding broken trusted store
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt" for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "**BROKEN**"') do set "TS_BROKEN=%%i"
	if defined TS_BROKEN (
		set /a TS_TF_TIME = 0
		set /a TS_TF_HOST = 0
		set /a TS_TF_RESTORE = 0
		for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "**BROKEN**"') do if "%%i" == "Time" SET /A TS_TF_TIME += 1
		for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "**BROKEN**"') do if "%%i" == "Host" SET /A TS_TF_HOST += 1
		for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "**BROKEN**"') do if "%%i" == "Restore" SET /A TS_TF_RESTORE += 1
		rem echo TS Broken ... TS_TF_TIME=!TS_TF_TIME! / TS_TF_HOST=!TS_TF_HOST! / TS_TF_RESTORE=!TS_TF_RESTORE!
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Trusted Store is BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE! [1;37m
		) else (
			echo     ATTENTION: Trusted Store is BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!
		)
		echo ATTENTION: Trusted Store is BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Trusted Store is NOT broken.                                                                                        >> %REPORT_LOGFILE% 2>&1
	)
	rem Analyze output regarding disabled licenses
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt" for /f "tokens=4 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "Viewed"') do set "TS_TOTAL_COUNT=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt" for /f "tokens=3 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "Disabled"') do set "TS_DISABLED=%%i"
	if defined TS_DISABLED (
		set /a TS_DISABLED_COUNT = 0
		for /f "tokens=3 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_viewlong.txt ^|find /I "Status"') do if "%%i" == "Disabled" SET /A TS_DISABLED_COUNT += 1
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT! [1;37m
		) else (
			echo     ATTENTION: Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT!
		)
		echo ATTENTION: Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT!                                >> %REPORT_LOGFILE% 2>&1
	) else (
		echo No disabled licenses found.                                                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo appactutil.exe -view -long                                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_APPACTUTIL (
		"%LMS_APPACTUTIL%" -view -long                                                                                           >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     appactutil.exe doesn't exist, cannot perform operation.                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo serveractutil.exe -view -long                                                                                           >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERACTUTIL (
		"%LMS_SERVERACTUTIL%" -view -long                                                                                        >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     serveractutil.exe doesn't exist, cannot perform operation.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Display the list of installed products, with LmuTool.exe /L                                                             >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /L                                                                                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPLICSERV
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED license server section. The script didn't execute the license server commands. [1;37m
	) else (
		echo     SKIPPED license server section. The script didn't execute the license server commands.
	)
	echo SKIPPED license server section. The script didn't execute the license server commands.                                  >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   L O C A L   L I C E N S E   S E R V E R                                  =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... analyze local license server on %LMS_LIC_SERVER% ...
if not defined LMS_SKIPLOCLICSERV (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    NOTE: In case default configuration has been changed, adapt setting %LMS_LIC_SERVER% for license server to be used. [1;37m
	) else (
		echo     NOTE: In case default configuration has been changed, adapt setting %LMS_LIC_SERVER% for license server to be used.
	)
	echo servercomptranutil.exe -serverView %LMS_LIC_SERVER%                                                                     >> %REPORT_LOGFILE% 2>&1
	echo NOTE: In case default configuration has been changed, adapt setting %LMS_LIC_SERVER% for license server to be used.     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -serverView %LMS_LIC_SERVER% > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverView.txt 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverView.txt"                                                      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo servercomptranutil.exe -serverView %LMS_LIC_SERVER% format=full                                                         >> %REPORT_LOGFILE% 2>&1
	echo NOTE: In case default configuration has been changed, adapt setting %LMS_LIC_SERVER% for license server to be used.     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -serverView %LMS_LIC_SERVER% format=full > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull.txt 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull.txt"                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo appactutil.exe -serverview -commServer %LMS_LIC_SERVER% -long                                                           >> %REPORT_LOGFILE% 2>&1
	echo NOTE: In case default configuration has been changed, adapt setting %LMS_LIC_SERVER% for license server to be used.     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	if defined LMS_APPACTUTIL (
		"%LMS_APPACTUTIL%" -serverview -commServer %LMS_LIC_SERVER% -long > !CHECKLMS_REPORT_LOG_PATH!\appactutil_serverViewLong.txt 2>&1
		Type "!CHECKLMS_REPORT_LOG_PATH!\appactutil_serverViewLong.txt"                                                          >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     appactutil.exe doesn't exist, cannot perform operation.                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	rem prepare answer file for RepairAll command, in case a user input is required
	del !CHECKLMS_REPORT_LOG_PATH!\yes.txt >nul 2>&1
	for /L %%n in (1,1,500) do echo y >> !CHECKLMS_REPORT_LOG_PATH!\yes.txt
	echo ... run repair command, using servercomptranutil, appactutil and serveractutil ...
	echo run repair command, using servercomptranutil, appactutil and serveractutil ...                                          >> %REPORT_LOGFILE% 2>&1
	echo     servercomptranutil.exe -n !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair_FID_xxx.xml fr=long -repair FID_xxx  >> %REPORT_LOGFILE% 2>&1
	echo     servercomptranutil.exe -n -t %LMS_FNO_SERVER% -repair FID_xxx                                                       >> %REPORT_LOGFILE% 2>&1
	echo     appactutil.exe -repair FID_xxx -gen !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair_FID_xxx.xml                        >> %REPORT_LOGFILE% 2>&1
	echo     appactutil.exe -repair FID_xxx                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     serveractutil.exe -repair FID_xxx -gen !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair_FID_xxx.xml                  >> %REPORT_LOGFILE% 2>&1
	echo     serveractutil.exe -repair FID_xxx                                                                                   >> %REPORT_LOGFILE% 2>&1
	set NeedRepair=Unknown
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverView.txt" (
		set NeedRepair=No
		del !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt >nul 2>&1
		del !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt >nul 2>&1
		del !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt >nul 2>&1
		for /f "tokens=1,6 eol=@ delims== " %%A in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverView.txt') do if "%%A" EQU "U" (
			if "%%B" NEQ "" (
				set NeedRepair=Yes
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    Try to repair %%B [1;37m
				) else (
					echo     Try to repair %%B
				)
				echo Try to repair %%B                                                                                          >> %REPORT_LOGFILE% 2>&1
				
				rem servercomptranutil.exe
				if defined LMS_SERVERCOMTRANUTIL (
					echo Start at !DATE! !TIME! ....                                                                                                      >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo servercomptranutil.exe -n !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair_%%B.xml fr=long -repair %%B                       >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					"%LMS_SERVERCOMTRANUTIL%" -n !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair_%%B.xml fr=long ref=CheckLMS_TryToRepair_Off -repair %%B     >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo servercomptranutil.exe -n -t %LMS_FNO_SERVER% -repair %%B                                                                        >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					"%LMS_SERVERCOMTRANUTIL%" -n ref=CheckLMS_TryToRepair1_FNO -t %LMS_FNO_SERVER% -repair %%B  < !CHECKLMS_REPORT_LOG_PATH!\yes.txt      >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo .                                                                                                                                >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
				) else (
					echo     servercomptranutil.exe doesn't exist, cannot perform operation for %%B.                                                      >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt 2>&1
				)
				
				rem appactutil.exe
				if defined LMS_APPACTUTIL (
					echo Start at !DATE! !TIME! ....                                                                                                      >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo appactutil.exe -repair %%B -gen !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair_%%B.xml                                             >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					"%LMS_APPACTUTIL%" -repair %%B -gen !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair_%%B.xml                                              >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo appactutil.exe -repair %%B                                                                                                       >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					"%LMS_APPACTUTIL%" -repair %%B                                                                                                        >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo .                                                                                                                                >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
				) else (
					echo     appactutil.exe doesn't exist, cannot perform operation for %%B.                                                              >> !CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt 2>&1
				)
				
				rem serveractutil.exe
				if defined LMS_SERVERACTUTIL (
					echo Start at !DATE! !TIME! ....                                                                                                      >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo serveractutil.exe -repair %%B -gen !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair_%%B.xml                                       >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					"%LMS_SERVERACTUTIL%" -repair %%B -gen !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair_%%B.xml                                        >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo serveractutil.exe -repair %%B                                                                                                    >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					"%LMS_SERVERACTUTIL%" -repair %%B                                                                                                     >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo .                                                                                                                                >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
					echo -------------------------------------------------------                                                                          >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
				) else (
					echo     serveractutil.exe doesn't exist, cannot perform operation for %%B.                                                           >> !CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt 2>&1
				)
			)
		)
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt" Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repair.txt"        >> %REPORT_LOGFILE% 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt" Type "!CHECKLMS_REPORT_LOG_PATH!\appactutil_repair.txt"                        >> %REPORT_LOGFILE% 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt" Type "!CHECKLMS_REPORT_LOG_PATH!\serveractutil_repair.txt"                  >> %REPORT_LOGFILE% 2>&1
	)
	echo Trusted Store needs Repair: %NeedRepair%                                                                                >> %REPORT_LOGFILE% 2>&1
	if "%NeedRepair%" == "Yes" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo servercomptranutil.exe -serverView %LMS_LIC_SERVER% format=full -- AFTER REPAIR                                     >> %REPORT_LOGFILE% 2>&1
		if defined LMS_SERVERCOMTRANUTIL (
			"%LMS_SERVERCOMTRANUTIL%" -serverView %LMS_LIC_SERVER% format=full > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt 2>&1
			Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt"                                  >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                             >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
		rem Analyze output regarding broken trusted store
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt" for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt ^|find /I "**BROKEN**"') do set "TS_BROKEN_AFTER_REPAIR=%%i"
		if defined TS_BROKEN_AFTER_REPAIR (
			set /a TS_TF_TIME = 0
			set /a TS_TF_HOST = 0
			set /a TS_TF_RESTORE = 0
			for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt ^|find /I "**BROKEN**"') do if "%%i" == "Time" SET /A TS_TF_TIME += 1
			for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt ^|find /I "**BROKEN**"') do if "%%i" == "Host" SET /A TS_TF_HOST += 1
			for /f "tokens=6 eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt ^|find /I "**BROKEN**"') do if "%%i" == "Restore" SET /A TS_TF_RESTORE += 1
			rem echo TS Broken ... TS_TF_TIME=!TS_TF_TIME! / TS_TF_HOST=!TS_TF_HOST! / TS_TF_RESTORE=!TS_TF_RESTORE!
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    ATTENTION: Trusted Store is BROKEN [AFTER REPAIR]. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE! [1;37m
			) else (
				echo     ATTENTION: Trusted Store is BROKEN [AFTER REPAIR]. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!
			)
			echo ATTENTION: Trusted Store is BROKEN [AFTER REPAIR]. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!     >> %REPORT_LOGFILE% 2>&1
		) else (
			echo Trusted Store is NOT broken [AFTER REPAIR].                                                                                           >> %REPORT_LOGFILE% 2>&1
		)
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... run repair all command using servercomptranutil.exe -n -t xxx -repairAll ...
	echo ... run repair all command using servercomptranutil.exe -n -t %LMS_FNO_SERVER% -repairAll ...                           >> %REPORT_LOGFILE% 2>&1
	echo     servercomptranutil.exe -n -t %LMS_FNO_SERVER% -repairAll                                                            >> %REPORT_LOGFILE% 2>&1
	set NeedRepairAll=Unknown
	if defined LMS_SERVERCOMTRANUTIL (
		del !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repairAll.txt >nul 2>&1
		rem call RepairAll command
		"%LMS_SERVERCOMTRANUTIL%" -n ref=CheckLMS_TryToRepair2_FNO -t %LMS_FNO_SERVER% -repairAll < !CHECKLMS_REPORT_LOG_PATH!\yes.txt >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repairAll.txt 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repairAll.txt" (
			Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repairAll.txt"                                                         >> %REPORT_LOGFILE% 2>&1
			findstr /m /c:"no fulfillments need repairing" "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_repairAll.txt"               >> %REPORT_LOGFILE% 2>&1
			rem echo ERRORLEVEL=!ERRORLEVEL!                                                                                         >> %REPORT_LOGFILE% 2>&1
			rem https://stackoverflow.com/questions/36237636/windows-batch-findstr-not-setting-errorlevel-within-a-for-loop 
			if !ERRORLEVEL!==0 (
				set NeedRepairAll=No
			) else (
			
				rem ***************
				rem TS needs repair
				rem ***************
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    ATTENTION: Repair was required. [1;37m
				) else (
					echo     ATTENTION: Repair was required.
				)
				echo ATTENTION: Repair was required.                                                                             >> %REPORT_LOGFILE% 2>&1
				set NeedRepairAll=Yes
				
			)
		)
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo Trusted Store needs Repair: %NeedRepairAll%                                                                             >> %REPORT_LOGFILE% 2>&1
	if "%NeedRepairAll%" == "Yes" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo servercomptranutil.exe -serverView %LMS_LIC_SERVER% format=full -- AFTER REPAIR ALL                                 >> %REPORT_LOGFILE% 2>&1
		if defined LMS_SERVERCOMTRANUTIL (
			"%LMS_SERVERCOMTRANUTIL%" -serverView %LMS_LIC_SERVER% format=full > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt 2>&1
			Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepair.txt"                                  >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                             >> %REPORT_LOGFILE% 2>&1
		)
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... run repair all command using LmuTool /REPALL /M:O ...
	echo ... run repair all command using LmuTool /REPALL /M:O ...                                                               >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		if /I !LMS_BUILD_VERSION! NEQ 721 (
			if /I !LMS_BUILD_VERSION! NEQ 610 (
				"!LMS_LMUTOOL!" /REPALL /M:O                                                                                     >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                       >> %REPORT_LOGFILE% 2>&1 
			)
		) else (
			echo     This operation is not supported with LMS !LMS_VERSION!, cannot perform operation.                           >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	if "%NeedRepairAll%" == "Yes" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo servercomptranutil.exe -serverView %LMS_LIC_SERVER% format=full -- AFTER REPAIR ALL WITH LMUTOOL                    >> %REPORT_LOGFILE% 2>&1
		if defined LMS_SERVERCOMTRANUTIL (
			"%LMS_SERVERCOMTRANUTIL%" -serverView %LMS_LIC_SERVER% format=full > !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepairWithLmuTool.txt 2>&1
			Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_serverViewFull_AfterRepairWithLmuTool.txt"                       >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                             >> %REPORT_LOGFILE% 2>&1
		)
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... resend all stored requests, using servercomptranutil.exe -t xxx -stored request=all ...
	echo ... resend all stored requests, using servercomptranutil.exe -t %LMS_FNO_SERVER% -stored request=all ...                >> %REPORT_LOGFILE% 2>&1
	echo     servercomptranutil.exe -t %LMS_FNO_SERVER% -stored request=all                                                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_SERVERCOMTRANUTIL (
		del !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_resend_stored_requests.txt >nul 2>&1
		rem call RepairAll command
		"%LMS_SERVERCOMTRANUTIL%" -t %LMS_FNO_SERVER% -stored request=all   < !CHECKLMS_REPORT_LOG_PATH!\yes.txt   >> !CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_resend_stored_requests.txt 2>&1
		IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_resend_stored_requests.txt" (
			Type "!CHECKLMS_REPORT_LOG_PATH!\servercomptranutil_resend_stored_requests.txt"                                      >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo servercomptranutil.exe -listRequests ...                                                                            >> %REPORT_LOGFILE% 2>&1
		"%LMS_SERVERCOMTRANUTIL%" -listRequests                                                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPLOCLICSERV
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED local license server section. The script didn't execute the local license server commands. [1;37m
	) else (
		echo     SKIPPED local license server section. The script didn't execute the local license server commands.
	)
	echo SKIPPED local license server section. The script didn't execute the local license server commands.                      >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   R E M O T E   L I C E N S E   S E R V E R                                =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... analyze remote license server on !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME! ...
if not defined LMS_SKIPREMLICSERV (
	if defined LMS_CFG_LICENSE_SRV_NAME (
		if not "!LMS_CFG_LICENSE_SRV_NAME!" == "localhost" (
			echo Configured license server: !LMS_CFG_LICENSE_SRV_NAME! with port !LMS_CFG_LICENSE_SRV_PORT!                      >> %REPORT_LOGFILE% 2>&1
			echo servercomptranutil.exe -serverView !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME!                        >> %REPORT_LOGFILE% 2>&1
			if defined LMS_SERVERCOMTRANUTIL (
				"%LMS_SERVERCOMTRANUTIL%" -serverView !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME!                      >> %REPORT_LOGFILE% 2>&1
				echo ==============================================================================                              >> %REPORT_LOGFILE% 2>&1
				echo Start at !DATE! !TIME! ....                                                                                 >> %REPORT_LOGFILE% 2>&1
				echo servercomptranutil.exe -serverView !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME! format=full        >> %REPORT_LOGFILE% 2>&1
				"%LMS_SERVERCOMTRANUTIL%" -serverView !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME! format=full          >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                         >> %REPORT_LOGFILE% 2>&1
			)
			echo ==============================================================================                                  >> %REPORT_LOGFILE% 2>&1
			echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1

			echo appactutil.exe -serverview -commServer !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME! -long              >> %REPORT_LOGFILE% 2>&1
			if defined LMS_APPACTUTIL (
				"%LMS_APPACTUTIL%" -serverview -commServer !LMS_CFG_LICENSE_SRV_PORT!@!LMS_CFG_LICENSE_SRV_NAME! -long           >> %REPORT_LOGFILE% 2>&1
			) else (
				echo     appactutil.exe doesn't exist, cannot perform operation.                                                 >> %REPORT_LOGFILE% 2>&1
			)
		) else (
			echo Configured license server: localhost as server configured; do not perform operations.                           >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo Configured license server: no server configured; do not perform operations.                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPREMLICSERV
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED remote license server section. The script didn't execute the remote license server commands. [1;37m
	) else (
		echo     SKIPPED remote license server section. The script didn't execute the remote license server commands.
	)
	echo SKIPPED remote license server section. The script didn't execute the remote license server commands.                    >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   L M S   C O N F I G U R A T I O N   F I L E S                            =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ... analyze configuration files ...
if not defined LMS_CHECK_ID (
	echo Get LmuTool Configuration: [read with LmuTool]                                                                          >> %REPORT_LOGFILE% 2>&1
	echo     Get LmuTool Configuration: [read with LmuTool]
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "LmsConfigVersion"') do set "LMS_CFG_VERSION=%%i"
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt" for /f "tokens=3 delims=<> eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\LmsCfg.txt ^|find /I "CsidConfigVersion"') do set "LMS_CSID_CFG_VERSION=%%i"
	echo     LmsConfigVersion: '!LMS_CFG_VERSION!'  /  CsidConfigVersion: '!LMS_CSID_CFG_VERSION!'                               >> %REPORT_LOGFILE% 2>&1 
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /??                                                                                                      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\Siemens\LMS' | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_registry.txt 2>&1
	echo Content of registry key: "HKLM:\SOFTWARE\Siemens\LMS" ...                                                               >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_REPORT_LOG_PATH!\lms_hklm_registry.txt                                                                        >> %REPORT_LOGFILE% 2>&1
	rem echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	rem if /I !LMS_BUILD_VERSION! GEQ 681 (
	rem 	echo Write Log Message: LmuTool /LOG:"Run CheckLMS.bat 64-Bit"                                                           >> %REPORT_LOGFILE% 2>&1
	rem 	if exist "%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe" (
	rem 		"%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe" /LOG:"Run CheckLMS.bat 64-Bit"                                          >> %REPORT_LOGFILE% 2>&1
	rem 	) else (
	rem 		echo     LmuTool [64-Bit] is not available with LMS !LMS_VERSION!, cannot perform operation.                         >> %REPORT_LOGFILE% 2>&1 
	rem 	)
	rem ) else (
	rem 	echo Write Log Message: Not supported in this LMS version !LMS_VERSION! - LmuTool /LOG:"Run CheckLMS.bat 64-Bit"         >> %REPORT_LOGFILE% 2>&1
	rem )	
	rem echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	rem if /I !LMS_BUILD_VERSION! GEQ 681 (
	rem 	echo Write Log Message: LmuTool /LOG:"Run CheckLMS.bat 32-Bit"                                                           >> %REPORT_LOGFILE% 2>&1
	rem 	if exist "%ProgramFiles%\Siemens\LMS\bin\LmuTool.exe" (
	rem 		"!ProgramFiles_x86!\Siemens\LMS\bin\LmuTool.exe" /LOG:"Run CheckLMS.bat 32-Bit"                                     >> %REPORT_LOGFILE% 2>&1
	rem 	) else (
	rem 		echo     LmuTool [32-Bit] is not available with LMS !LMS_VERSION!, cannot perform operation.                         >> %REPORT_LOGFILE% 2>&1 
	rem 	)
	rem ) else (
	rem 	echo Write Log Message: Not supported in this LMS version !LMS_VERSION! - LmuTool /LOG:"Run CheckLMS.bat 32-Bit"         >> %REPORT_LOGFILE% 2>&1
	rem )	
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "!LMS_PROGRAMDATA!\Config"                                                                           >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "!LMS_PROGRAMDATA!\Config"                                                                                >> %REPORT_LOGFILE% 2>&1
	mkdir !CHECKLMS_REPORT_LOG_PATH!\Config\  >nul 2>&1
	xcopy "!LMS_PROGRAMDATA!\Config\*" !CHECKLMS_REPORT_LOG_PATH!\Config\ /E /Y /H /I                                            >> %REPORT_LOGFILE% 2>&1 
	echo --- Files automatically copied from '!LMS_PROGRAMDATA!\Config\*' to '!CHECKLMS_REPORT_LOG_PATH!\Config\' at !DATE! !TIME! --- > !CHECKLMS_REPORT_LOG_PATH!\Config\__README.txt 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: CSID CONFIG '!LMS_PROGRAMDATA!\Config\CsidCfg'                                                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /DEC2:!LMS_PROGRAMDATA!\Config\CsidCfg >nul 2>&1
		if exist "!LMS_PROGRAMDATA!\Config\CsidCfg.dec" (
			Type !LMS_PROGRAMDATA!\Config\CsidCfg.dec                                                                            >> %REPORT_LOGFILE% 2>&1
			del !LMS_PROGRAMDATA!\Config\CsidCfg.dec >nul 2>&1
			echo .                                                                                                               >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     Cannot decrypt file '!LMS_PROGRAMDATA!\Config\CsidCfg', cannot show content.                                >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: LICENSE CONFIG '!LMS_PROGRAMDATA!\Config\LicCfg'                                                    >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /DEC2:!LMS_PROGRAMDATA!\Config\LicCfg  >nul 2>&1
		if exist "!LMS_PROGRAMDATA!\Config\LicCfg.dec" (
			Type !LMS_PROGRAMDATA!\Config\LicCfg.dec                                                                             >> %REPORT_LOGFILE% 2>&1
			del !LMS_PROGRAMDATA!\Config\LicCfg.dec >nul 2>&1
			echo .                                                                                                               >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     Cannot decrypt file '!LMS_PROGRAMDATA!\Config\LicCfg', cannot show content.                                 >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	if defined LMS_CFG_LICENSE_SRV_NAME (
		echo Configured license server: !LMS_CFG_LICENSE_SRV_NAME! with port !LMS_CFG_LICENSE_SRV_PORT!                          >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Configured license server: no server configured.                                                                    >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: SUR HISTORY '!LMS_PROGRAMDATA!\Config\SurHistory'                                                   >> %REPORT_LOGFILE% 2>&1
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /DEC2:!LMS_PROGRAMDATA!\Config\SurHistory >nul 2>&1
		if exist "!LMS_PROGRAMDATA!\Config\SurHistory.dec" (
			Type !LMS_PROGRAMDATA!\Config\SurHistory.dec                                                                         >> %REPORT_LOGFILE% 2>&1
			del !LMS_PROGRAMDATA!\Config\SurHistory.dec >nul 2>&1
			echo .                                                                                                               >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     Cannot decrypt file '!LMS_PROGRAMDATA!\Config\SurHistory', cannot show content.                             >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                      >> %REPORT_LOGFILE% 2>&1 
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: LMU PROFILE [%ProgramFiles%\Siemens\LMS\bin\LmuTool.profile]                                        >> %REPORT_LOGFILE% 2>&1
	Type "%ProgramFiles%\Siemens\LMS\bin\LmuTool.profile"                                                                        >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: LMU SETTINGS [!LMS_PROGRAMDATA!\Config\LmuSettings]                                                 >> %REPORT_LOGFILE% 2>&1
	Type !LMS_PROGRAMDATA!\Config\LmuSettings                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo .                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	set backuppath=
	IF EXIST "!LMS_PROGRAMDATA!\Config\LmuSettings" for /f "tokens=3 delims=<> eol=@" %%i in ('type !LMS_PROGRAMDATA!\Config\LmuSettings ^|find /I "BackupRestorePath"') do set "backuppath=%%i"
	if defined backuppath (
		echo Configured backup path: %backuppath%                                                                                >> %REPORT_LOGFILE% 2>&1
		echo Configured backup path, show content of %backuppath%\LMU_Backup                                                     >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%backuppath%\LMU_Backup"                                                                             >> %REPORT_LOGFILE% 2>&1
		echo Configured backup path, show content of %backuppath%\LMU_Backup.old                                                 >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%backuppath%\LMU_Backup.old"                                                                         >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Configured backup path: no path configured, cannot perform operation.                                               >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo Configuration File: Siemens.Gms.ApplicationFramework.exe.config                                                         >> %REPORT_LOGFILE% 2>&1
	Type "%ProgramFiles%\Siemens\LMS\bin\Siemens.Gms.ApplicationFramework.exe.config"                                            >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_CHECK_ID
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED LMS config section. The script didn't execute the LMS config commands. [1;37m
	) else (
		echo     SKIPPED LMS config section. The script didn't execute the LMS config commands.
	)
	echo SKIPPED LMS config section. The script didn't execute the LMS config commands.                                      >> %REPORT_LOGFILE% 2>&1
)
:ssu_update_information
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   S O F T W A R E   U P D A T E   I N F O R M A T I O N                    =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
echo UserID=8:%SSU_SYSTEMID%                                                                                                 >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPSSU (
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... get content of SSU log-file folder ...
	echo Content of folder: %ALLUSERSPROFILE%\Siemens\SSU\Logs                                                                   >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "%ALLUSERSPROFILE%\Siemens\SSU\Logs"                                                                      >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log" (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo SSU - setup log-file found in %ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log                                       >> %REPORT_LOGFILE% 2>&1
		Type "%ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log"                                                                   >> %REPORT_LOGFILE% 2>&1

		copy "%ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log" "!CHECKLMS_SSU_PATH!\SSUSetup.log"                                                      >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log to !CHECKLMS_SSU_PATH!\SSUSetup.log ---                >> !CHECKLMS_SSU_PATH!\SSUSetup.log 2>&1
		powershell -Command "get-childitem '%ALLUSERSPROFILE%\Siemens\SSU\Logs\SSUSetup.log' | select Name,CreationTime,LastAccessTime,LastWriteTime"  >> %REPORT_LOGFILE% 2>&1
	)

	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem NOTE: The logfiles on %TEMP% [e.g. C:\Users\imfeldc\AppData\Local\Temp] are periodically deleted by opertaing system
	echo ... search MSI and SSU setup logfiles [MSI*.log]  [on %TEMP%] ...
	del !CHECKLMS_SSU_PATH!\MSISetupLogFilesFound.txt >nul 2>&1
	del !CHECKLMS_SSU_PATH!\SSUSetupLogFilesFound.txt >nul 2>&1
	cd %TEMP%
	FOR /r %TEMP% %%X IN (MSI*.log) DO (
		set SSU_SETUP_LOGFILE_FOUND=
		echo %%~dpnxX >> !CHECKLMS_SSU_PATH!\MSISetupLogFilesFound.txt
		for /f "tokens=1 delims= eol=@" %%i in ('type %%~dpnxX ^|find /I "******* Product:"') do echo %%i >> !CHECKLMS_SSU_PATH!\MSISetupLogFilesFound.txt
		for /f "tokens=1 delims= eol=@" %%i in ('type %%~dpnxX ^|find /I "SSU_Setupx64.msi"') do set SSU_SETUP_LOGFILE_FOUND=1
		if defined SSU_SETUP_LOGFILE_FOUND (
			echo %%~dpnxX >> !CHECKLMS_SSU_PATH!\SSUSetupLogFilesFound.txt
		)
	)
	IF EXIST "!CHECKLMS_SSU_PATH!\MSISetupLogFilesFound.txt" (
		echo MSI setup logfiles [MSI*.log] [on %TEMP%]:                                                                          >> %REPORT_LOGFILE% 2>&1
		Type !CHECKLMS_SSU_PATH!\MSISetupLogFilesFound.txt                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
	)
	IF EXIST "!CHECKLMS_SSU_PATH!\SSUSetupLogFilesFound.txt" (
		echo SSU setup logfiles [MSI*.log] [on %TEMP%]:                                                                          >> %REPORT_LOGFILE% 2>&1
		Type !CHECKLMS_SSU_PATH!\SSUSetupLogFilesFound.txt                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
		set LOG_FILE_COUNT=0
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_SSU_PATH!\SSUSetupLogFilesFound.txt) DO ( 
			set /A LOG_FILE_COUNT += 1
			echo %%i copy to !CHECKLMS_SSU_PATH!\%%~nxi                                                                          >> %REPORT_LOGFILE% 2>&1   
			copy /Y "%%i" !CHECKLMS_SSU_PATH!\%%~nxi                                                                             >> %REPORT_LOGFILE% 2>&1
			rem powershell -command "& {Get-Content '%%i' | Select-Object -last %LOG_FILE_LINES%}"                                   >> %REPORT_LOGFILE% 2>&1 
			Type "%%i"                                                                                                           >> %REPORT_LOGFILE% 2>&1 
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
		)
		echo     !LOG_FILE_COUNT! SSU setup logfile [MSI*.log] found on %TEMP%.                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No SSU setup logfile [MSI*.log] found on %TEMP%.                                                                >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... check SSU registry permission ...
	echo Retrieve registry permissison for !SSU_MAIN_REGISTRY_KEY! [with "Get-Acl HKLM:\SOFTWARE\Siemens\SSU | Format-List"]     >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-Acl HKLM:\SOFTWARE\Siemens\SSU | Format-List"                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\Siemens\SSU' | Format-List" > !CHECKLMS_SSU_PATH!\ssu_hklm_registry.txt 2>&1
	echo Content of registry key: "HKLM:\SOFTWARE\Siemens\SSU" ...                                                               >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_SSU_PATH!\ssu_hklm_registry.txt                                                                               >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	Powershell -command "Get-ItemProperty 'HKCU:\SOFTWARE\Siemens\SSU' | Format-List" > !CHECKLMS_SSU_PATH!\ssu_hkcu_registry.txt 2>&1
	echo Content of registry key: "HKCU:\SOFTWARE\Siemens\SSU" ...                                                               >> %REPORT_LOGFILE% 2>&1
	type !CHECKLMS_SSU_PATH!\ssu_hkcu_registry.txt                                                                               >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... test connection to OSD server ...
	echo Test connection to OSD server                                                                                           >> %REPORT_LOGFILE% 2>&1 
	rem Connection Test to OSD server
	powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.automation.siemens.com/swdl/servertest/', '%TEMP%\OSD_servertest.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_osd_swdl.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access https://www.automation.siemens.com/swdl/servertest/
		echo Connection Test PASSED, can access https://www.automation.siemens.com/swdl/servertest/                              >> %REPORT_LOGFILE% 2>&1                
		set OSDServerConnectionTestStatus=Passed
		rem type %TEMP%\OSD_servertest.txt
		rem echo .
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access https://www.automation.siemens.com/swdl/servertest/
		echo Connection Test FAILED, cannot access https://www.automation.siemens.com/swdl/servertest/                           >> %REPORT_LOGFILE% 2>&1            
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_osd_swdl.txt                                                             >> %REPORT_LOGFILE% 2>&1
		set OSDServerConnectionTestStatus=Failed
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1 
	echo ... test connection to OSD software udpate server ...
	echo Test connection to OSD software udpate server                                                                           >> %REPORT_LOGFILE% 2>&1                                                                                            
	rem Connection Test to OSD software udpate server
	powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.automation.siemens.com/softwareupdater/servertest.aspx', '%TEMP%\OSD_softwareudpateservertest.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_osd_softwareupdate.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access https://www.automation.siemens.com/softwareupdater/servertest.aspx
		echo Connection Test PASSED, can access https://www.automation.siemens.com/softwareupdater/servertest.aspx               >> %REPORT_LOGFILE% 2>&1                           
		set OSDSoftwareUpdateServerConnectionTestStatus=Passed
		rem type %TEMP%\OSD_softwareudpateservertest.txt
		rem echo .
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access https://www.automation.siemens.com/softwareupdater/servertest.aspx
		echo Connection Test FAILED, cannot access https://www.automation.siemens.com/softwareupdater/servertest.aspx            >> %REPORT_LOGFILE% 2>&1                       
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_osd_softwareupdate.txt                                                   >> %REPORT_LOGFILE% 2>&1
		set OSDSoftwareUpdateServerConnectionTestStatus=Failed
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo ... test connection to FNC cloud ...
	echo Test connection to FNC cloud                                                                                            >> %REPORT_LOGFILE% 2>&1
	rem Connection Test to FNC Cloud
	powershell -Command "(New-Object Net.WebClient).DownloadFile('http://updates.installshield.com/ClientInterfaces.asp', '%TEMP%\ClientInterfaces.txt')" >!CHECKLMS_REPORT_LOG_PATH!\connection_test_fnccloud.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access http://updates.installshield.com/ClientInterfaces.asp
		echo Connection Test PASSED, can access http://updates.installshield.com/ClientInterfaces.asp                            >> %REPORT_LOGFILE% 2>&1
		set FNCCloudConnectionTestStatus=Passed
		rem type %TEMP%\ClientInterfaces.txt
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access http://updates.installshield.com/ClientInterfaces.asp
		echo Connection Test FAILED, cannot access http://updates.installshield.com/ClientInterfaces.asp                         >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_fnccloud.txt                                                             >> %REPORT_LOGFILE% 2>&1
		set FNCCloudConnectionTestStatus=Failed
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo **** Siemens Software Updater [SSU] ****                                                                                >> %REPORT_LOGFILE% 2>&1
	echo ... read products registered for updates [via SSU] ...
	echo Products Registered for Updates [via SSU]                                                                               >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\SSU\SiemensSoftwareUpdater.ini" (
		echo SSU Configuration file found, see %ALLUSERSPROFILE%\Siemens\SSU\SiemensSoftwareUpdater.ini                          >> %REPORT_LOGFILE% 2>&1
		Type "%ALLUSERSPROFILE%\Siemens\SSU\SiemensSoftwareUpdater.ini"                                                          >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No SSU Configuration file [%ALLUSERSPROFILE%\Siemens\SSU\SiemensSoftwareUpdater.ini] found.                     >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: %ALLUSERSPROFILE%\Siemens\SSU\Database                                                               >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "%ALLUSERSPROFILE%\Siemens\SSU\Database"                                                                  >> %REPORT_LOGFILE% 2>&1
	FOR %%i IN ("%ALLUSERSPROFILE%\Siemens\SSU\Database\*.ini") DO (
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo %%i:                                                                                                                >> %REPORT_LOGFILE% 2>&1
		Type %%i                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: %TEMP%\SSU                                                                                           >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "%TEMP%\SSU"                                                                                              >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Check SSU Test Mode [for multi-platform clients]                                                                        >> %REPORT_LOGFILE% 2>&1
	IF EXIST "c:\TestUpdate.pin" (
		echo SSU Test file found, see c:\TestUpdate.pin                                                                          >> %REPORT_LOGFILE% 2>&1
		Type "c:\TestUpdate.pin"                                                                                                 >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No SSU Test file [c:\TestUpdate.pin] found.                                                                     >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ProgramFiles%\Siemens\SSU\bin" (
		echo SSU - Get signature status for *.exe [%ProgramFiles%\Siemens\SSU\bin]                                               >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '%ProgramFiles%\Siemens\SSU\bin\*.exe'"                         >> %REPORT_LOGFILE% 2>&1
		echo SSU - Get signature status for *.dll [%ProgramFiles%\Siemens\SSU\bin]                                               >> %REPORT_LOGFILE% 2>&1
		powershell -command "Get-AuthenticodeSignature -FilePath '%ProgramFiles%\Siemens\SSU\bin\*.dll'"                         >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		echo Check signature with: !SIGCHECK_TOOL! !SIGCHECK_OPTIONS! ...                                                        >> %REPORT_LOGFILE% 2>&1
		!SIGCHECK_TOOL! !SIGCHECK_OPTIONS! "%ProgramFiles%\Siemens\SSU\bin\SSUManager.exe"                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No SSU binary folder [%ProgramFiles%\Siemens\SSU\bin] found.                                                    >> %REPORT_LOGFILE% 2>&1
	)
	IF EXIST "%ProgramFiles%\Siemens\SSU\bin" (
		IF EXIST "%ProgramFiles%\Siemens\SSU\bin\debug.log" (
			echo -------------------------------------------------------                                                                            >> %REPORT_LOGFILE% 2>&1
			echo SSU - CRASH FILE debug.log found in '%ProgramFiles%\Siemens\SSU\bin\'                                                              >> %REPORT_LOGFILE% 2>&1
			rem Type "%ProgramFiles%\Siemens\SSU\bin\debug.log"                                                                                     >> %REPORT_LOGFILE% 2>&1
			echo LOG FILE: debug.log [last %LOG_FILE_LINES% lines]                                                                                  >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '%ProgramFiles%\Siemens\SSU\bin\debug.log' | Select-Object -last %LOG_FILE_LINES%}"                 >> %REPORT_LOGFILE% 2>&1

			copy "%ProgramFiles%\Siemens\SSU\bin\debug.log" !CHECKLMS_SSU_PATH!\ssu_debug.log                                                       >> %REPORT_LOGFILE% 2>&1
			echo --- File automatically copied from %ProgramFiles%\Siemens\SSU\bin\debug.log to !CHECKLMS_SSU_PATH!\ssu_debug.log ---               >> !CHECKLMS_SSU_PATH!\ssu_debug.log 2>&1
			powershell -Command "get-childitem '%ProgramFiles%\Siemens\SSU\bin\debug.log' | select Name,CreationTime,LastAccessTime,LastWriteTime"  >> %REPORT_LOGFILE% 2>&1

			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    ATTENTION: SSU - CRASH FILE debug.log found! [1;37m
			) else (
				echo     ATTENTION: SSU - CRASH FILE debug.log found!
			)
			echo ATTENTION: SSU - CRASH FILE debug.log found!                                                                    >> %REPORT_LOGFILE% 2>&1
		)
		IF EXIST "%ProgramFiles%\Siemens\SSU\bin\SSUManager.exe" (
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
			echo SSU - Start SSU Manager ....                                                                                    >> %REPORT_LOGFILE% 2>&1
			start "Start SSU Manager" "%ProgramFiles%\Siemens\SSU\bin\SSUManager.exe"
		)
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
		set LMS_SSU_CONSISTENCY_CHECK=0
		IF NOT EXIST "%ProgramFiles%\Siemens\SSU\bin\icudtl.dat" (
			echo SSU - File "icudtl.dat" is missing in %ProgramFiles%\Siemens\SSU\bin\                                           >> %REPORT_LOGFILE% 2>&1
			set /A LMS_SSU_CONSISTENCY_CHECK += 1
		)
		IF NOT EXIST "%ProgramFiles%\Siemens\SSU\bin\v8_context_snapshot.bin" (
			echo SSU - File "v8_context_snapshot.bin" is missing in %ProgramFiles%\Siemens\SSU\bin\                              >> %REPORT_LOGFILE% 2>&1
			set /A LMS_SSU_CONSISTENCY_CHECK += 1
		)
		if /I !LMS_SSU_CONSISTENCY_CHECK! NEQ 0 (
			echo SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!                              >> %REPORT_LOGFILE% 2>&1
			if defined SHOW_COLORED_OUTPUT (
				echo [1;31m    ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing! [1;37m
			) else (
				echo     ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!
			)
			echo ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!                   >> %REPORT_LOGFILE% 2>&1
		) else (
			echo SSU - Installation is consistent, NO file missing in %ProgramFiles%\Siemens\SSU\bin\                            >> %REPORT_LOGFILE% 2>&1
		)
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo **** FNC Windows Client [FNC] ****                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo ... read products registered for updates [via FNC] ...
	echo Products Registered for Updates [via FNC]                                                                               >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\FLEXnet\Connect\Database\" (
		echo Content of folder: %ALLUSERSPROFILE%\FLEXnet\Connect\Database                                                       >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%ALLUSERSPROFILE%\FLEXnet\Connect\Database"                                                          >> %REPORT_LOGFILE% 2>&1

		IF EXIST "%ALLUSERSPROFILE%\FLEXnet\Connect\Database\update.ini" (
			Type "%APPDATA%\FLEXnet\Connect\Database\update.ini" | findstr "UserID="                                             >> %REPORT_LOGFILE% 2>&1
			FOR %%i IN ("%ALLUSERSPROFILE%\FLEXnet\Connect\Database\*.ini") DO (
				echo -------------------------------------------------------                                                     >> %REPORT_LOGFILE% 2>&1
				echo %%i:                                                                                                        >> %REPORT_LOGFILE% 2>&1
				Type %%i                                                                                                         >> %REPORT_LOGFILE% 2>&1
			)
		) else (
			echo     No User FNC Database found [%ALLUSERSPROFILE%\FLEXnet\Connect\Database\update.ini].                         >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     No User FNC Database found [%ALLUSERSPROFILE%\FLEXnet\Connect\Database\].                                       >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%APPDATA%\FLEXnet\Connect\Database\" (
		echo Content of folder: %APPDATA%\FLEXnet\Connect\Database\                                                              >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%APPDATA%\FLEXnet\Connect\Database\"                                                                 >> %REPORT_LOGFILE% 2>&1
		FOR %%i IN ("%APPDATA%\FLEXnet\Connect\Database\*.ini") DO (
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
			echo %%i:                                                                                                            >> %REPORT_LOGFILE% 2>&1
			Type %%i                                                                                                             >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     No Application FNC Database found [%APPDATA%\FLEXnet\Connect\Database\].                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	echo Check FNC Test Mode [for windows-based FNC agents]                                                                      >> %REPORT_LOGFILE% 2>&1
	IF EXIST "c:\FCTest.ini" (
		echo FNC Test file found, see c:\FCTest.ini                                                                              >> %REPORT_LOGFILE% 2>&1
		Type "c:\FCTest.ini"                                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo .                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No FNC Test file [FCTest.ini] found.                                                                            >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED SSU section. The script didn't execute the SSU commands. [1;37m
	) else (
		echo     SKIPPED SSU section. The script didn't execute the SSU commands.
	)
	echo SKIPPED SSU section. The script didn't execute the SSU commands.                                                        >> %REPORT_LOGFILE% 2>&1
)
:lms_log_files
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   L M S   L O G   F I L E S                                                =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
if not defined LMS_CHECK_ID (
	echo Start at !DATE! !TIME! ....                                                                                         >> %REPORT_LOGFILE% 2>&1
	echo Content of folder: "!REPORT_LOG_PATH!" [LOGS]                                                                       >> %REPORT_LOGFILE% 2>&1
	dir /S /A /X /4 /W "!REPORT_LOG_PATH!"                                                                                   >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_CHECK_ID
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED LMS logfile section. The script didn't execute the LMS logfile commands. [1;37m
	) else (
		echo     SKIPPED LMS logfile section. The script didn't execute the LMS logfile commands.
	)
	echo SKIPPED LMS logfile section. The script didn't execute the LMS logfile commands.                                    >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
set LMS_SETUP_LOGFILE_NAME=LMSSetup
echo ... search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only] ...
echo Search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only]:                                                 >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPSETUP (
	del !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt >nul 2>&1
	FOR /r C:\ %%X IN (*.log) DO if "%%~nxX"=="!LMS_SETUP_LOGFILE_NAME!.log" echo %%~dpnxX >> !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt
	IF EXIST "!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt" (
		Type !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt                                                   >> %REPORT_LOGFILE% 2>&1
		set LOG_FILE_COUNT=0
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt) DO ( 
			set /A LOG_FILE_COUNT += 1
			echo %%i copy to !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                             >> %REPORT_LOGFILE% 2>&1   
			copy /Y "%%i" !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                                >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '%%i' | Select-Object -last %LOG_FILE_LINES%}"                                   >> %REPORT_LOGFILE% 2>&1 
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     No LMS setup logfile [!LMS_SETUP_LOGFILE_NAME!.log] found.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	set LMS_SETUP_LOGFILE_NAME=LMSSetupIS
	echo ... search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only] ...
	echo Search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only]:                                               >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt >nul 2>&1
	FOR /r C:\ %%X IN (*.log) DO if "%%~nxX"=="!LMS_SETUP_LOGFILE_NAME!.log" echo %%~dpnxX >> !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt
	IF EXIST "!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt" (
		Type !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt                                                   >> %REPORT_LOGFILE% 2>&1
		set LOG_FILE_COUNT=0
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt) DO ( 
			set /A LOG_FILE_COUNT += 1
			echo %%i copy to !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                             >> %REPORT_LOGFILE% 2>&1   
			copy /Y "%%i" !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                                >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '%%i' | Select-Object -last %LOG_FILE_LINES%}"                                   >> %REPORT_LOGFILE% 2>&1 
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     No LMS setup logfile [!LMS_SETUP_LOGFILE_NAME!.log] found.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	set LMS_SETUP_LOGFILE_NAME=LMSSetupMSI
	echo ... search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only] ...
	echo Search LMS setup logfiles [!LMS_SETUP_LOGFILE_NAME!.log] [on c:\ only]:                                                 >> %REPORT_LOGFILE% 2>&1
	del !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt >nul 2>&1
	FOR /r C:\ %%X IN (*.log) DO if "%%~nxX"=="!LMS_SETUP_LOGFILE_NAME!.log" echo %%~dpnxX >> !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt
	IF EXIST "!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt" (
		Type !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt                                                   >> %REPORT_LOGFILE% 2>&1
		set LOG_FILE_COUNT=0
		echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1 
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!_FilesFound.txt) DO ( 
			set /A LOG_FILE_COUNT += 1
			echo %%i copy to !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                             >> %REPORT_LOGFILE% 2>&1   
			copy /Y "%%i" !CHECKLMS_SETUP_LOG_PATH!\!LMS_SETUP_LOGFILE_NAME!.!LOG_FILE_COUNT!.log                                >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '%%i' | Select-Object -last %LOG_FILE_LINES%}"                                   >> %REPORT_LOGFILE% 2>&1 
			echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     No LMS setup logfile [!LMS_SETUP_LOGFILE_NAME!.log] found.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	rem NOTE: the ccmcache (incl. ManagedPC folder) has an overall size of xx GB. If this size is full, oldest downloaded packages will be erased automatically
	echo ... search LMS setup logfiles [*LicenseManagementSystem*.log]  [on C:\Windows\Logs\ManagedPC\Applications] ...
	echo Search LMS setup logfiles [*LicenseManagementSystem*.log] [on C:\Windows\Logs\ManagedPC\Applications]:                  >> %REPORT_LOGFILE% 2>&1
	del %CHECKLMS_SETUP_LOG_PATH%\LicenseManagementSystemSetupLogFilesFound.txt >nul 2>&1
	FOR /r C:\Windows\Logs\ManagedPC\Applications\ %%X IN (*LicenseManagementSystem*.log) DO echo %%~dpnxX >> %CHECKLMS_SETUP_LOG_PATH%\LicenseManagementSystemSetupLogFilesFound.txt
	IF EXIST "%CHECKLMS_SETUP_LOG_PATH%\LicenseManagementSystemSetupLogFilesFound.txt" (
		Type %CHECKLMS_SETUP_LOG_PATH%\LicenseManagementSystemSetupLogFilesFound.txt                                             >> %REPORT_LOGFILE% 2>&1
		FOR /r C:\Windows\Logs\ManagedPC\Applications\ %%X IN (*LicenseManagementSystem*.log) DO (
		  set myline=%%~dpX
		  for /f "delims=" %%y in ("!myline:\=.!") do set folder=%%~xy
		  echo %%~dpX* copy to %CHECKLMS_SETUP_LOG_PATH%\ManagedPC\!folder:~1!\ ...                                              >> %REPORT_LOGFILE% 2>&1
		  xcopy %%~dpX*  %CHECKLMS_SETUP_LOG_PATH%\ManagedPC\!folder:~1!\ /E /Y /H /I                                            >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo     No LMS setup logfile [*LicenseManagementSystem*.log] found.                                                     >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo ... search further setup logfiles ...
	echo Search further setup logfiles:                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%temp%\setup_LMS_IS_x64.log" (
		echo %temp%\setup_LMS_IS_x64.log found.                                                                                  >> %REPORT_LOGFILE% 2>&1
		copy %temp%\setup_LMS_IS_x64.log %CHECKLMS_SETUP_LOG_PATH%\                                                              >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %temp%\setup_LMS_IS_x64.log to %CHECKLMS_SETUP_LOG_PATH%\ ---  >> %CHECKLMS_SETUP_LOG_PATH%\setup_LMS_IS_x64.log 2>&1
	) else (
		echo     %temp%\setup_LMS_IS_x64.log not found.                                                                          >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                 >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%temp%\setup_LMS_x64.log" (
		echo %temp%\setup_LMS_x64.log found.                                                                                     >> %REPORT_LOGFILE% 2>&1
		copy %temp%\setup_LMS_x64.log %CHECKLMS_SETUP_LOG_PATH%\                                                                 >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %temp%\setup_LMS_x64.log to %CHECKLMS_SETUP_LOG_PATH%\ ---  >> %CHECKLMS_SETUP_LOG_PATH%\setup_LMS_x64.log 2>&1
	) else (
		echo     %temp%\setup_LMS_x64.log not found.                                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\" (
		IF EXIST "%ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupIS.log" (
			echo %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupIS.log found.                                                                   >> %REPORT_LOGFILE% 2>&1
			copy %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupIS.log %CHECKLMS_SETUP_LOG_PATH%\                                               >> %REPORT_LOGFILE% 2>&1
			echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupIS.log to %CHECKLMS_SETUP_LOG_PATH%\ ---  >> %CHECKLMS_SETUP_LOG_PATH%\LMSSetupIS.log 2>&1
		) else (
			echo     %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupIS.log not found.                                                           >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                                                                                    >> %REPORT_LOGFILE% 2>&1
		IF EXIST "%ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupMSI.log" (
			echo %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupMSI.log found.                                                                  >> %REPORT_LOGFILE% 2>&1
			copy %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupMSI.log %CHECKLMS_SETUP_LOG_PATH%\                                              >> %REPORT_LOGFILE% 2>&1
			echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupMSI.log to %CHECKLMS_SETUP_LOG_PATH%\ ---  >> %CHECKLMS_SETUP_LOG_PATH%\LMSSetupMSI.log 2>&1
		) else (
			echo      %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\LMSSetupMSI.log not found.                                                         >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		rem echo     No GMS installation! Folder %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\ not found.
		echo No GMS installation! Folder %ALLUSERSPROFILE%\Siemens\GMS\InstallerFramework\GMS_Prerequisites_Install_Log\ not found.                                                     >> %REPORT_LOGFILE% 2>&1
	)	
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupIS.log" (
		echo %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupIS.log found.                                                                                                  >> %REPORT_LOGFILE% 2>&1
		copy %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupIS.log %CHECKLMS_SETUP_LOG_PATH%\                                                                              >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupIS.log to %CHECKLMS_SETUP_LOG_PATH%\ ---   >> %CHECKLMS_SETUP_LOG_PATH%\LMSSetupIS.log 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupIS.log not found.                                                                                          >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupMSI.log" (
		echo %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupMSI.log found.                                                                                                 >> %REPORT_LOGFILE% 2>&1
		copy %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupMSI.log %CHECKLMS_SETUP_LOG_PATH%\                                                                             >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupMSI.log to %CHECKLMS_SETUP_LOG_PATH%\ ---  >> %CHECKLMS_SETUP_LOG_PATH%\LMSSetupMSI.log 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\LMSSetupMSI.log not found.                                                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\Reports" (
		echo Content of folder: "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\Reports"                                                                                           >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\Reports"                                                                                                >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\Reports not found.                                                                                                 >> %REPORT_LOGFILE% 2>&1
	)
) else (
	rem LMS_SKIPSETUP
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED LMS Setup Files section. The script didn't execute the LMS Setup Files commands. [1;37m
	) else (
		echo     SKIPPED LMS Setup Files section. The script didn't execute the LMS Setup Files commands.
	)
	echo SKIPPED LMS Setup Files section. The script didn't execute the LMS Setup Files commands.                                                                                       >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                                                                 >> %REPORT_LOGFILE% 2>&1
echo ... read LMS logfiles [last %LOG_FILE_LINES% lines] ...
if not defined LMS_SKIPLOGS (
	echo LOG FILE: LMU.log [last %LOG_FILE_LINES% lines]                                                                                                                                >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!REPORT_LOG_PATH!\LMU.log" (
		FOR /F "usebackq" %%A IN ('!REPORT_LOG_PATH!\LMU.log') DO set LMULOG_FILESIZE=%%~zA
		if /I !LMULOG_FILESIZE! GEQ !LOG_FILESIZE_LIMIT! (
			echo     ATTENTION: Filesize of LMU.log with !LMULOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!                                            >> %REPORT_LOGFILE% 2>&1
			echo     ATTENTION: Filesize of LMU.log with !LMULOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!
		)
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\LMU.log' | Select-Object -last %LOG_FILE_LINES%}"                                                                        >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !REPORT_LOG_PATH!\LMU.log not found.                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: licenf.log [last %LOG_FILE_LINES% lines]                                                                                                                             >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!REPORT_LOG_PATH!\licenf.log" (
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\licenf.log' | Select-Object -last %LOG_FILE_LINES%}"                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !REPORT_LOG_PATH!\licenf.log not found.                                                                                                                                >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: LMUTool.log [last %LOG_FILE_LINES% lines]                                                                                                                            >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!REPORT_LOG_PATH!\LMUTool.log" (
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\LMUTool.log' | Select-Object -last %LOG_FILE_LINES%}"                                                                    >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !REPORT_LOG_PATH!\LMUTool.log not found.                                                                                                                               >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: LMUPowerShell.log [last %LOG_FILE_LINES% lines]                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!REPORT_LOG_PATH!\LMUPowerShell.log" (
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\LMUPowerShell.log' | Select-Object -last %LOG_FILE_LINES%}"                                                              >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !REPORT_LOG_PATH!\LMUPowerShell.log not found.                                                                                                                         >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo ... read further logfiles [last %LOG_FILE_LINES% lines] ...
	echo LOG FILE: AlmBt.log [last %LOG_FILE_LINES% lines]                                                                                                                              >> %REPORT_LOGFILE% 2>&1
	IF EXIST "!REPORT_LOG_PATH!\AlmBt.log" (
		powershell -command "& {Get-Content '!REPORT_LOG_PATH!\AlmBt.log' | Select-Object -last %LOG_FILE_LINES%}"                                                                      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !REPORT_LOG_PATH!\AlmBt.log not found.                                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT [last %LOG_FILE_LINES% lines]                                                                      >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT" (
		powershell -command "& {Get-Content '%ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT' | Select-Object -last %LOG_FILE_LINES%}"                                >> %REPORT_LOGFILE% 2>&1
		copy %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT !CHECKLMS_ALM_PATH!\                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT to !CHECKLMS_ALM_PATH!\ --- >> !CHECKLMS_ALM_PATH!\ALM64_LOG.TXT 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Logfiles\Setup\ALM64_LOG.TXT not found.                                                                                           >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log [last %LOG_FILE_LINES% lines]                                                >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log" (
		powershell -command "& {Get-Content '%ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log' | Select-Object -last %LOG_FILE_LINES%}"          >> %REPORT_LOGFILE% 2>&1
		copy "%ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log" !CHECKLMS_ALM_PATH!\                                                             >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log to !CHECKLMS_ALM_PATH!\ --- >> !CHECKLMS_ALM_PATH!\alm_service_log 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\logging\alm_service_log not found.                                                                     >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: Copy all files from %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\*  to  !CHECKLMS_ALM_PATH!\ALM\                                                  >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\" (
		mkdir !CHECKLMS_ALM_PATH!\ALM\  >nul 2>&1
		xcopy "%ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\*" !CHECKLMS_ALM_PATH!\ALM\ /E /Y /H /I                                                                  >> %REPORT_LOGFILE% 2>&1 
		echo --- Files automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\* to !CHECKLMS_ALM_PATH!\ALM\ --- > !CHECKLMS_ALM_PATH!\ALM\__README.txt 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\ folder not found.                                                                                     >> %REPORT_LOGFILE% 2>&1
	)
	echo LOG FILE: Copy all files from %ALLUSERSPROFILE%\Siemens\Automation\sws\*  to  !CHECKLMS_ALM_PATH!\sws\                                                                         >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%ALLUSERSPROFILE%\Siemens\Automation\sws\" (
		mkdir !CHECKLMS_ALM_PATH!\sws\  >nul 2>&1
		xcopy "%ALLUSERSPROFILE%\Siemens\Automation\sws\*" !CHECKLMS_ALM_PATH!\sws\ /E /Y /H /I                                                                                         >> %REPORT_LOGFILE% 2>&1 
		echo --- Files automatically copied from %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\* to !CHECKLMS_ALM_PATH!\sws\ --- > !CHECKLMS_ALM_PATH!\sws\__README.txt 2>&1
	) else (
		echo     %ALLUSERSPROFILE%\Siemens\Automation\sws\ folder not found.                                                                                                            >> %REPORT_LOGFILE% 2>&1
	)
) else (
	rem LMS_SKIPLOGS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED logfile section. The script didn't execute the logfile commands. [1;37m
	) else (
		echo     SKIPPED logfile section. The script didn't execute the logfile commands.
	)
	echo SKIPPED logfile section. The script didn't execute the logfile commands.                                            >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                                                                 >> %REPORT_LOGFILE% 2>&1
rem NOTE: the ccmcache (incl. ManagedPC folder) has an overall size of xx GB. If this size is full, oldest downloaded packages will be erased automatically
echo ... search dongle driver setup logfiles [*SentinelLicenseManager*.log] [on C:\Windows\Logs\ManagedPC\Applications] ...
echo Search dongle driver setup logfiles [*SentinelLicenseManager*.log] [on C:\Windows\Logs\ManagedPC\Applications]:                                                              >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPDDSETUP (
	del !CHECKLMS_REPORT_LOG_PATH!\DongleDriverSetupLogFilesFound.txt >nul 2>&1
	FOR /r C:\Windows\Logs\ManagedPC\Applications\ %%X IN (*SentinelLicenseManager*.log) DO echo %%~dpnxX >> !CHECKLMS_REPORT_LOG_PATH!\DongleDriverSetupLogFilesFound.txt
	IF EXIST "!CHECKLMS_REPORT_LOG_PATH!\DongleDriverSetupLogFilesFound.txt" (
		Type !CHECKLMS_REPORT_LOG_PATH!\DongleDriverSetupLogFilesFound.txt                                                                                                              >> %REPORT_LOGFILE% 2>&1
		set LOG_FILE_COUNT=0
		echo -------------------------------------------------------                                                                                                                    >> %REPORT_LOGFILE% 2>&1 
		FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_REPORT_LOG_PATH!\DongleDriverSetupLogFilesFound.txt) DO ( 
			set /A LOG_FILE_COUNT += 1
			echo %%i copy to !CHECKLMS_REPORT_LOG_PATH!\%%~nxi                                                                                                                          >> %REPORT_LOGFILE% 2>&1   
			copy /Y "%%i" !CHECKLMS_REPORT_LOG_PATH!\%%~nxi                                                                                                                             >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\%%~nxi' | Select-Object -last %LOG_FILE_LINES%}"                                                            >> %REPORT_LOGFILE% 2>&1 
			echo -------------------------------------------------------                                                                                                                >> %REPORT_LOGFILE% 2>&1 
		)
	) else (
		echo     No dongle driver setup logfile [*SentinelLicenseManager*.log] found.                                                                                                   >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	rem aksdrvsetup.log is the dongle driver setup/installation logfile
	echo LOG FILE: %windir%\aksdrvsetup.log [last %LOG_FILE_LINES% lines]                                                                                                               >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%windir%\aksdrvsetup.log" (
		powershell -command "& {Get-Content '%windir%\aksdrvsetup.log' | Select-Object -last %LOG_FILE_LINES%}"                                                                         >> %REPORT_LOGFILE% 2>&1
		copy %windir%\aksdrvsetup.log !CHECKLMS_REPORT_LOG_PATH!\                                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo --- File automatically copied from %windir%\aksdrvsetup.log to !CHECKLMS_REPORT_LOG_PATH!\ --- >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup.log 2>&1
	) else (
		echo     No dongle driver setup logfile [%windir%\aksdrvsetup.log] found.                                                                                                       >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo LOG FILE: !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log [last %LOG_FILE_LINES% lines]                                                                                     >> %REPORT_LOGFILE% 2>&1
	IF EXIST "%windir%\aksdrvsetup.log" (
		rem Extract dongle driver logfile, for specific entries
		del !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log >nul 2>&1
		for /f "tokens=1,2 eol=@ delims=[]" %%A in (%windir%\aksdrvsetup.log) do (
			rem echo [%%A] [%%B]
			set LOGFILE_LINE_DATE=%%A
			set LOGFILE_LINE_TEXT=%%B
			if not defined LOGFILE_LINE_PREV_DATE set LOGFILE_LINE_PREV_DATE=!LOGFILE_LINE_DATE!
			if "!LOGFILE_LINE_TEXT!" NEQ "" (
				rem echo valid line [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_PREV_DATE!]
				if /I "!LOGFILE_LINE_DATE:~0,5!" NEQ "!LOGFILE_LINE_PREV_DATE:~0,5!" (
					echo ------------------------------------------   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
				)
			)
			if /I "!LOGFILE_LINE_TEXT:~0,10!" EQU "Running on" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,9!" EQU "haspdinst" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,17!" EQU "branded Installer" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,9!" EQU "ret value" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,7!" EQU "upgrade" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,13!" EQU "Start Install" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~-14!" EQU "do not install" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,13!" EQU "Windows error" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,5!" EQU "ERROR" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,14!" EQU "Uninstall done" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,18!" EQU "Uninstall returned" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			if /I "!LOGFILE_LINE_TEXT:~0,16!" EQU "Install returned" (
				echo [!LOGFILE_LINE_DATE!] [!LOGFILE_LINE_TEXT!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
				echo .             >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			rem check for "The following files could not be deleted"
			if /I "!LOGFILE_LINE_DATE:~0,3!" EQU "The" (
				echo [!LOGFILE_LINE_PREV_DATE!] [--- !LOGFILE_LINE_DATE!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			rem check for "Delete these files manually"
			if /I "!LOGFILE_LINE_DATE:~0,6!" EQU "Delete" (
				echo [!LOGFILE_LINE_PREV_DATE!] [--- !LOGFILE_LINE_DATE!]   >> !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log 2>&1
			)
			rem store date of "previous" line, in case a valid "date" has been found
			if "!LOGFILE_LINE_TEXT!" NEQ "" (
				set LOGFILE_LINE_PREV_DATE=!LOGFILE_LINE_DATE!
			)
		)
		echo     Extract of dongle driver setup logfile done. [see !CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log]                                                              >> %REPORT_LOGFILE% 2>&1
		powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\aksdrvsetup_extract.log' | Select-Object -last %LOG_FILE_LINES%}"                                           >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     No dongle driver setup logfile [%windir%\aksdrvsetup.log] found.                                                                                                   >> %REPORT_LOGFILE% 2>&1
	)
) else (
	rem LMS_SKIPDDSETUP
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED dongle driver setup section. The script didn't execute the dongle driver setup commands. [1;37m
	) else (
		echo     SKIPPED dongle driver setup section. The script didn't execute the dongle driver setup commands.
	)
	echo SKIPPED dongle driver setup section. The script didn't execute the dongle driver setup commands.                                                                           >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                                                                 >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPUCMS (
	rem copied from UCMS-LogcollectorDWP.ini
	echo Several additional logfiles collected [based on UCMS-LogcollectorDWP.ini] ...                                                                                                                          >> %REPORT_LOGFILE% 2>&1
	robocopy.exe %SystemRoot%  "!CHECKLMS_REPORT_LOG_PATH!\UCMS\WINDOWS" IE*.log cbs*.log WU_IE10_LangPacks.log    /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log                                  >> %REPORT_LOGFILE% 2>&1
	robocopy.exe %SystemRoot%\debug "!CHECKLMS_REPORT_LOG_PATH!\UCMS\WINDOWS\debug" *.log      /S /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log                                                   >> %REPORT_LOGFILE% 2>&1
	robocopy.exe %systemroot%\logs\ManagedPC\Applications "!CHECKLMS_REPORT_LOG_PATH!\UCMS\WINDOWS\logs\ManagedPC\Applications" *.log  /S /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log           >> %REPORT_LOGFILE% 2>&1
	robocopy.exe %systemroot%\logs "!CHECKLMS_REPORT_LOG_PATH!\UCMS\WINDOWS\logs" *.log       /NP /R:1 /W:1 /LOG+:!CHECKLMS_REPORT_LOG_PATH!\robocopy.log                                                       >> %REPORT_LOGFILE% 2>&1
	echo     see folder '!CHECKLMS_REPORT_LOG_PATH!\UCMS\' for more details.                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                                                                                            >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPUCMS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED UCMS section. The script didn't execute the UCMS commands. [1;37m
	) else (
		echo     SKIPPED UCMS section. The script didn't execute the UCMS commands.
	)
	echo SKIPPED UCMS section. The script didn't execute the UCMS commands.                                                                                                                                     >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                                                                                             >> %REPORT_LOGFILE% 2>&1
echo =   W I N D O W S   E V E N T   L O G                                        =                                                                                                                             >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                                                                                                             >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                                                                                                                >> %REPORT_LOGFILE% 2>&1
echo ... read-out windows event log [first %LOG_EVENTLOG_EVENTS% lines] ...
if not defined LMS_SKIPWINEVENT (
	echo     Windows Event Log: Application ['License Management Utility']
	echo Windows Event Log: Application ['License Management Utility']                                                                                                                                              >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_lms.txt                                                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='License Management Utility']]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_lms.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_lms.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Application Errors
	echo Windows Event Log: Application Errors                                                                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_errors.txt                                                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[(Level=1  or Level=2)]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_errors.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_app_errors.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                              >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: System Errors
	echo Windows Event Log: System Errors                                                                                                                                                                           >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_errors.txt                                                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events System /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[(Level=1  or Level=2)]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_errors.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_errors.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                              >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Application ['Siemens Software Updater']
	echo Windows Event Log: Application ['Siemens Software Updater']                                                                                                                                                >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_SSU_PATH!\eventlog_app_ssu.txt                                                                                                                                                           >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Siemens Software Updater']]]" > !CHECKLMS_SSU_PATH!\eventlog_app_ssu.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_SSU_PATH!\eventlog_app_ssu.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                        >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Siemens ['SiemensSoftwareUpdater']
	echo Windows Event Log: Siemens ['SiemensSoftwareUpdater']                                                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_SSU_PATH!\eventlog_ssu.txt                                                                                                                                                               >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Siemens /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='SiemensSoftwareUpdater']]]" > !CHECKLMS_SSU_PATH!\eventlog_ssu.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_SSU_PATH!\eventlog_ssu.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                            >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Microsoft-Windows-Bits-Client/Operational ['Microsoft-Windows-Bits-Client']
	echo Windows Event Log: Microsoft-Windows-Bits-Client/Operational ['Microsoft-Windows-Bits-Client']                                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_SSU_PATH!\eventlog_bitsclient.txt                                                                                                                                                        >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Microsoft-Windows-Bits-Client/Operational /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Microsoft-Windows-Bits-Client']]]" > !CHECKLMS_SSU_PATH!\eventlog_bitsclient.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_SSU_PATH!\eventlog_bitsclient.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                     >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Microsoft-Windows-NetworkProfile/Operational ['Microsoft-Windows-NetworkProfile']
	echo Windows Event Log: Microsoft-Windows-NetworkProfile/Operational ['Microsoft-Windows-NetworkProfile']                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_SSU_PATH!\eventlog_networkprofile.txt                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Microsoft-Windows-NetworkProfile/Operational /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Microsoft-Windows-NetworkProfile']]]" > !CHECKLMS_SSU_PATH!\eventlog_networkprofile.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_SSU_PATH!\eventlog_networkprofile.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                 >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Application ['Automation License Manager API']
	echo Windows Event Log: Application ['Automation License Manager API']                                                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo     see %CHECKLMS_ALM_PATH%\eventlog_app_alm_api.txt                                                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Automation License Manager API']]]" > %CHECKLMS_ALM_PATH%\eventlog_app_alm_api.txt 2>&1
	powershell -command "& {Get-Content '%CHECKLMS_ALM_PATH%\eventlog_app_alm_api.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Application ['Automation License Manager Service']
	echo Windows Event Log: Application ['Automation License Manager Service']                                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     see %CHECKLMS_ALM_PATH%\eventlog_app_alm_service.txt                                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Automation License Manager Service']]]" > %CHECKLMS_ALM_PATH%\eventlog_app_alm_service.txt 2>&1
	powershell -command "& {Get-Content '%CHECKLMS_ALM_PATH%\eventlog_app_alm_service.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: System ['Service Control Manager']
	echo Windows Event Log: System ['Service Control Manager']                                                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_scm.txt                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events System /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Service Control Manager']]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_scm.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_scm.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                                 >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: System ['hasplms']
	echo Windows Event Log: System ['hasplms']                                                                                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_hasplms.txt                                                                                                                                                >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events System /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='hasplms']]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_hasplms.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_hasplms.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                             >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo     Windows Event Log: Application ['MsiInstaller']
	echo Windows Event Log: Application ['MsiInstaller']                                                                                                                                                            >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_MsiInstaller.txt                                                                                                                                           >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='MsiInstaller']]]" > !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_MsiInstaller.txt 2>&1
	powershell -command "& {Get-Content '!CHECKLMS_REPORT_LOG_PATH!\eventlog_app_MsiInstaller.txt' | Select-Object -first %LOG_FILE_LINES%}"                                                                        >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	echo ... at !DATE! !TIME! ....                                                                                                                                                                                  >> %REPORT_LOGFILE% 2>&1
	echo ... read-out full windows event log [first %LOG_EVENTLOG_FULL_EVENTS% lines] ...
	echo     Windows Event Log: Application
	echo Windows Event Log: Application                                                                                                                                                                             >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_full.txt                                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events Application /count:%LOG_EVENTLOG_FULL_EVENTS% /rd:true /format:text > !CHECKLMS_REPORT_LOG_PATH!\eventlog_app_full.txt 2>&1
	echo     Windows Event Log: System
	echo Windows Event Log: System                                                                                                                                                                                  >> %REPORT_LOGFILE% 2>&1
	echo     see !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_full.txt                                                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	WEVTUtil query-events System /count:%LOG_EVENTLOG_FULL_EVENTS% /rd:true /format:text > !CHECKLMS_REPORT_LOG_PATH!\eventlog_sys_full.txt 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                                                                                                >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                                                                                                    >> %REPORT_LOGFILE% 2>&1
	rem copied from UCMS-LogcollectorDWP.ini
	echo Several event viewer exports made [based on UCMS-LogcollectorDWP.ini] ...                                                                                                                                  >> %REPORT_LOGFILE% 2>&1
	wevtutil epl System         "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_System.evtx"      /ow:true /q:"*[System[TimeCreated[timediff(@SystemTime) <= 1296000000]]]"                                         >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Application    "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_Application.evtx" /ow:true /q:"*[System[TimeCreated[timediff(@SystemTime) <= 1296000000]]]"                                         >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Microsoft-Windows-NetworkProfile/Operational       "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_NetworkProfile.evtx" /ow:true                                                                   >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Microsoft-Windows-NTLM/Operational                 "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_NTLM.evtx" /ow:true                                                                             >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Microsoft-Windows-WindowsUpdateClient/Operational  "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_WindowsUpdateClient.evtx" /ow:true                                                              >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Microsoft-Windows-Wired-AutoConfig/Operational     "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_Wired-AutoConfig.evtx" /ow:true                                                                 >> %REPORT_LOGFILE% 2>&1
	wevtutil epl Microsoft-Windows-WLAN-AutoConfig/Operational      "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_WLAN-AutoConfig.evtx" /ow:true                                                                  >> %REPORT_LOGFILE% 2>&1
	wevtutil epl "Microsoft-Windows-Folder Redirection/Operational" "!CHECKLMS_REPORT_LOG_PATH!\UCMS\%COMPUTERNAME%_FolderRedirection.evtx" /ow:true                                                                >> %REPORT_LOGFILE% 2>&1
	echo     see folder '!CHECKLMS_REPORT_LOG_PATH!\UCMS\' for more details.                                                                                                                                        >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_SKIPWINEVENT
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED Windows Events section. The script didn't execute the Windows Events commands. [1;37m
	) else (
		echo     SKIPPED Windows Events section. The script didn't execute the Windows Events commands.
	)
	echo SKIPPED Windows Events section. The script didn't execute the Windows Events commands.                                           >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                       >> %REPORT_LOGFILE% 2>&1
echo =   L M S   N O T I F I C A T I O N   R E P O R T                            =                                                       >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                                       >> %REPORT_LOGFILE% 2>&1
echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
echo ... get 'LMS Notifications Report' ...
echo Get 'LMS Notifications Report'                                                                                                       >> %REPORT_LOGFILE% 2>&1
if not defined LMS_CHECK_ID (
	IF EXIST "!LMS_PROGRAMDATA!\Documentation\reports\report.htm" (
		Type !LMS_PROGRAMDATA!\Documentation\reports\report.htm                                                                           >> %REPORT_LOGFILE% 2>&1
		copy !LMS_PROGRAMDATA!\Documentation\reports\report.htm !CHECKLMS_REPORT_LOG_PATH!\                                               >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     !LMS_PROGRAMDATA!\Documentation\reports\report.htm not found.                                                            >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
) else (
	rem LMS_CHECK_ID
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED notification report section. The script didn't execute the notification report commands. [1;37m
	) else (
		echo     SKIPPED notification report section. The script didn't execute the notification report commands.
	)
	echo SKIPPED notification report section. The script didn't execute the notification report commands.                                 >> %REPORT_LOGFILE% 2>&1
)
:connection_test
echo ==============================================================================                                                       >> %REPORT_LOGFILE% 2>&1
echo =   C O N N E C T I O N   T E S T                                            =                                                       >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                                       >> %REPORT_LOGFILE% 2>&1
echo ... start connection test at !DATE! !TIME! ...
echo Start at !DATE! !TIME! ....                                                                                                              >> %REPORT_LOGFILE% 2>&1
if not defined LMS_SKIPCONTEST (
	rem Connection Test to Siemens site
	set CONNECTION_TEST_URL=http://new.siemens.com/global/en/general/legal.html
	powershell -Command "(New-Object Net.WebClient).DownloadFile('!CONNECTION_TEST_URL!', '%temp%\downloadtest.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\connection_test_siemens.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access !CONNECTION_TEST_URL!
		echo Connection Test PASSED, can access !CONNECTION_TEST_URL!                                                                         >> %REPORT_LOGFILE% 2>&1
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access !CONNECTION_TEST_URL!
		echo Connection Test FAILED, cannot access !CONNECTION_TEST_URL!                                                                      >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_siemens.txt                                                                           >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	set CONNECTION_TEST_URL=https://lms.bt.siemens.com/flexnet/services/ActivationService
	powershell -Command "(New-Object Net.WebClient).DownloadFile('!CONNECTION_TEST_URL!', '%temp%\downloadtest.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\connection_test_btlms_activationservice.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access !CONNECTION_TEST_URL!
		echo Connection Test PASSED, can access !CONNECTION_TEST_URL!                                                                         >> %REPORT_LOGFILE% 2>&1
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access !CONNECTION_TEST_URL!
		echo Connection Test FAILED, cannot access !CONNECTION_TEST_URL!                                                                      >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_btlms_activationservice.txt                                                           >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		set CONNECTION_TEST_URL=https://lms-quality.bt.siemens.com/flexnet/services/ActivationService
		powershell -Command "(New-Object Net.WebClient).DownloadFile('!CONNECTION_TEST_URL!', '%temp%\downloadtest.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\connection_test_btqual_activationservice.txt 2>&1
		if !ERRORLEVEL!==0 (
			rem Connection Test: PASSED
			echo     Connection Test PASSED, can access !CONNECTION_TEST_URL!
			echo Connection Test PASSED, can access !CONNECTION_TEST_URL!                                                                     >> %REPORT_LOGFILE% 2>&1
		) else if !ERRORLEVEL!==1 (
			rem Connection Test: FAILED
			echo     Connection Test FAILED, cannot access !CONNECTION_TEST_URL!
			echo Connection Test FAILED, cannot access !CONNECTION_TEST_URL!                                                                  >> %REPORT_LOGFILE% 2>&1
			type !CHECKLMS_REPORT_LOG_PATH!\connection_test_btqual_activationservice.txt                                                      >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo Skipped 'Connection Test to Quality System', to execute this test run with /extend otion.                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	set CONNECTION_TEST_URL=http://194.138.12.72/flexnet/services/ActivationService
	powershell -Command "(New-Object Net.WebClient).DownloadFile('!CONNECTION_TEST_URL!', '%temp%\downloadtest.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\connection_test_1941381272.txt 2>&1
	if !ERRORLEVEL!==0 (
		rem Connection Test: PASSED
		echo     Connection Test PASSED, can access !CONNECTION_TEST_URL!
		echo Connection Test PASSED, can access !CONNECTION_TEST_URL!                                                                         >> %REPORT_LOGFILE% 2>&1
	) else if !ERRORLEVEL!==1 (
		rem Connection Test: FAILED
		echo     Connection Test FAILED, cannot access !CONNECTION_TEST_URL!
		echo Connection Test FAILED, cannot access !CONNECTION_TEST_URL!                                                                      >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_1941381272.txt                                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		set CONNECTION_TEST_URL=http://158.226.135.60/flexnet/services/ActivationService
		powershell -Command "(New-Object Net.WebClient).DownloadFile('!CONNECTION_TEST_URL!', '%temp%\downloadtest.txt')"  >!CHECKLMS_REPORT_LOG_PATH!\connection_test_15822613560.txt 2>&1
		if !ERRORLEVEL!==0 (
			rem Connection Test: PASSED
			echo     Connection Test PASSED, can access !CONNECTION_TEST_URL!
			echo Connection Test PASSED, can access !CONNECTION_TEST_URL!                                                                     >> %REPORT_LOGFILE% 2>&1
		) else if !ERRORLEVEL!==1 (
			rem Connection Test: FAILED
			echo     Connection Test FAILED, cannot access !CONNECTION_TEST_URL!
			echo Connection Test FAILED, cannot access !CONNECTION_TEST_URL!                                                                  >> %REPORT_LOGFILE% 2>&1
			type !CHECKLMS_REPORT_LOG_PATH!\connection_test_15822613560.txt                                                                   >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		echo Skipped 'Connection Test to 158.226.135.60', to execute this test run with /extend otion.                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Ping [using LmuTool /ping] ...                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo     Ping [using LmuTool /ping] ...
	if defined LMS_LMUTOOL (
		"!LMS_LMUTOOL!" /ping                                                                                                                 >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                                   >> %REPORT_LOGFILE% 2>&1 
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Ping %COMPUTERNAME% ...                                                                                                              >> %REPORT_LOGFILE% 2>&1
	echo     Ping %COMPUTERNAME% ...
	ping %COMPUTERNAME%                                                                                                                       >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Start enhanced connection test [using 'act_connection_test'] ...                                                                     >> %REPORT_LOGFILE% 2>&1
	echo     Start enhanced connection test [using 'act_connection_test'] ...
	del !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log >nul 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log >nul 2>&1
	del !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log >nul 2>&1
	if defined LMS_LMUTOOL (
		rem Execute each step of enhanced connection test
		echo         -[Step 1 of 3] Activate 'act_connection_test' ...
		echo          Started at !DATE! !TIME! ...
		echo Started at !DATE! !TIME! ....                      >  !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log 2>&1
		"!LMS_LMUTOOL!" /A:act_connection_test /M:O /Partial:1  >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log 2>&1
		rem supress error message: "Der Prozess kann nicht auf die Datei zugreifen, da sie von einem anderen Prozess verwendet wird."
		rem delaying - doesn't work -- powershell.exe -Command "Start-Sleep -Seconds 15"
		echo Finished at !DATE! !TIME! ....                     >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log 2>&1
		echo          Finished at !DATE! !TIME!!
		echo         -[Step 2 of 3] Check 'act_connection_test' ...
		echo          Started at !DATE! !TIME! ...
		echo Started at !DATE! !TIME! ....                      >  !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log 2>&1
		"!LMS_LMUTOOL!" /CHECK:sbt_lms_connection_test          >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log 2>&1
		rem supress error message: "Der Prozess kann nicht auf die Datei zugreifen, da sie von einem anderen Prozess verwendet wird."
		rem delaying - doesn't work -- powershell.exe -Command "Start-Sleep -Seconds 15"
		echo Finished at !DATE! !TIME! ....                     >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log 2>&1
		echo          Finished at !DATE! !TIME!!
		echo         -[Step 3 of 3] Return 'act_connection_test' ...
		echo          Started at !DATE! !TIME! ...
		echo Started at !DATE! !TIME! ....                      >  !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log 2>&1
		"!LMS_LMUTOOL!" /RA:act_connection_test                 >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log 2>&1
		rem supress error message: "Der Prozess kann nicht auf die Datei zugreifen, da sie von einem anderen Prozess verwendet wird."
		rem delaying - doesn't work -- powershell.exe -Command "Start-Sleep -Seconds 15"
		echo Finished at !DATE! !TIME! ....                     >> !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log 2>&1
		echo          Finished at !DATE! !TIME!!
		rem add output of each step to common logfile
		echo -[Step 1 of 3] Activate 'act_connection_test' -------------------                                                                >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log                                                                             >> %REPORT_LOGFILE% 2>&1
		echo -[Step 2 of 3] Check 'act_connection_test' ----------------------                                                                >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log                                                                             >> %REPORT_LOGFILE% 2>&1
		echo -[Step 3 of 3] Return 'act_connection_test' ---------------------                                                                >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log                                                                             >> %REPORT_LOGFILE% 2>&1
		echo -----------------------------------------------------------------                                                                >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		rem check status of each step
		for /f "tokens=1 delims= eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step1.log ^|find /I "Success"') do set LMS_CON_TEST_STEP1_PASSED=1
		for /f "tokens=1 delims= eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step2.log ^|find /I "Success"') do set LMS_CON_TEST_STEP2_PASSED=1
		for /f "tokens=1 delims= eol=@" %%i in ('type !CHECKLMS_REPORT_LOG_PATH!\connection_test_step3.log ^|find /I "Success"') do set LMS_CON_TEST_STEP3_PASSED=1
		echo Connection Test Status:                                                                                                          >> %REPORT_LOGFILE% 2>&1
		if defined LMS_CON_TEST_STEP1_PASSED (
			echo -[Step 1 of 3] PASSED                                                                                                        >> %REPORT_LOGFILE% 2>&1
		) else (
			echo -[Step 1 of 3] FAILED *******                                                                                                >> %REPORT_LOGFILE% 2>&1
			set LMS_CON_TEST_FAILED=1
		)
		if defined LMS_CON_TEST_STEP2_PASSED (
			echo -[Step 2 of 3] PASSED                                                                                                        >> %REPORT_LOGFILE% 2>&1
		) else (
			echo -[Step 2 of 3] FAILED *******                                                                                                >> %REPORT_LOGFILE% 2>&1
			set LMS_CON_TEST_FAILED=1
		)
		if defined LMS_CON_TEST_STEP3_PASSED (
			echo -[Step 3 of 3] PASSED                                                                                                        >> %REPORT_LOGFILE% 2>&1
		) else (
			echo -[Step 3 of 3] FAILED *******                                                                                                >> %REPORT_LOGFILE% 2>&1
			set LMS_CON_TEST_FAILED=1
		)
	) else (
		echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                                                   >> %REPORT_LOGFILE% 2>&1 
	)
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Try 'fake' activation [using servercomptranutil.exe -n -t %LMS_FNO_SERVER% -activate Some_fake_activation_id] ...                    >> %REPORT_LOGFILE% 2>&1
	echo     Try 'fake' activation using %LMS_FNO_SERVER% ...
	if defined LMS_SERVERCOMTRANUTIL (
		"%LMS_SERVERCOMTRANUTIL%" -n ref=CheckLMS_TryActivation -t %LMS_FNO_SERVER% -activate Some_fake_activation_id  < !CHECKLMS_REPORT_LOG_PATH!\yes.txt        >> %REPORT_LOGFILE% 2>&1
		echo NOTE: The activation above has to fail, as used activation id is not present on FNO server.                                      >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     servercomptranutil.exe doesn't exist, cannot perform operation.                                                              >> %REPORT_LOGFILE% 2>&1
	)
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_CFG_LICENSE_SRV_NAME (
		echo Check connection to configured license server:                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                          >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo nslookup configured license server: !LMS_CFG_LICENSE_SRV_NAME! ...                                                               >> %REPORT_LOGFILE% 2>&1
		echo     nslookup configured license server: !LMS_CFG_LICENSE_SRV_NAME! ...
		nslookup !LMS_CFG_LICENSE_SRV_NAME!                                                                                                   >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                          >> %REPORT_LOGFILE% 2>&1
		echo Ping configured license server: !LMS_CFG_LICENSE_SRV_NAME! ...                                                                   >> %REPORT_LOGFILE% 2>&1
		echo     Ping configured license server: !LMS_CFG_LICENSE_SRV_NAME! ...
		ping !LMS_CFG_LICENSE_SRV_NAME!                                                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                          >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo Trace route IPv4 configured license server [max. 20 hops] ...                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     Trace route IPv4 configured license server [max. 20 hops] ...
		tracert -h 20  -4 !LMS_CFG_LICENSE_SRV_NAME!                                                                                          >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                          >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo Trace route IPv6 configured license server [max. 20 hops] ...                                                                    >> %REPORT_LOGFILE% 2>&1
		echo     Trace route IPv6 configured license server [max. 20 hops] ...
		tracert -h 20  -6 !LMS_CFG_LICENSE_SRV_NAME!                                                                                          >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                                          >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo     retrieve system time information from !LMS_CFG_LICENSE_SRV_NAME! ...
		echo Retrieve system time information [using w32tm /stripchart /computer:!LMS_CFG_LICENSE_SRV_NAME! /dataonly /samples:2]:            >> %REPORT_LOGFILE% 2>&1
		w32tm /stripchart /computer:!LMS_CFG_LICENSE_SRV_NAME! /dataonly /samples:2                                                           >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Check connection to configured license server: no server configured, cannot perform operation.                                   >> %REPORT_LOGFILE% 2>&1
	)
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Ping lms.bt.siemens.com ...                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo     Ping lms.bt.siemens.com ...
	ping lms.bt.siemens.com                                                                                                                   >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Trace route IPv4 to lms.bt.siemens.com [max. 10 hops] ...                                                                            >> %REPORT_LOGFILE% 2>&1
	echo     Trace route IPv4 to lms.bt.siemens.com [max. 10 hops] ...
	tracert -h 10  -4 lms.bt.siemens.com                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	echo Start at !DATE! !TIME! ....                                                                                                          >> %REPORT_LOGFILE% 2>&1
	echo Trace route IPv6 to lms.bt.siemens.com [max. 10 hops] ...                                                                            >> %REPORT_LOGFILE% 2>&1
	echo     Trace route IPv6 to lms.bt.siemens.com [max. 10 hops] ...
	tracert -h 10  -6 lms.bt.siemens.com                                                                                                      >> %REPORT_LOGFILE% 2>&1
	echo -------------------------------------------------------                                                                              >> %REPORT_LOGFILE% 2>&1
	if defined LMS_EXTENDED_CONTENT (
		echo Start at !DATE! !TIME! ....                                                                                                      >> %REPORT_LOGFILE% 2>&1
		echo Ping lms-quality.bt.siemens.com ...                                                                                              >> %REPORT_LOGFILE% 2>&1
		echo     Ping lms-quality.bt.siemens.com ...
		ping lms-quality.bt.siemens.com                                                                                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Skipped 'Ping Test to Quality System', to execute this test run with /extend otion.                                              >> %REPORT_LOGFILE% 2>&1
	)
) else (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED connection test. The script didn't execute the connections tests. [1;37m
	) else (
		echo     SKIPPED connection test. The script didn't execute the connections tests.
	)
	echo SKIPPED connection test. The script didn't execute the connections tests.                                                            >> %REPORT_LOGFILE% 2>&1
)
echo Start at !DATE! !TIME! ....                                                                                                              >> %REPORT_LOGFILE% 2>&1
:collect_product_info
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo =   P R O D U C T   S P E C I F I C   I N F O R M A T I O N                  =                                          >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                          >> %REPORT_LOGFILE% 2>&1
echo ... start to collect product specific information ...
if not defined LMS_SKIPPRODUCTS (
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   D E S I G O   C C                                                        =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- Desigo CC (GMS) Registry Keys --
	set KEY_NAME=HKLM\Software\Siemens\Siemens_GMS
	set VALUE_NAME=Version
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set GMS_VERSION=%%A
	)
	if defined GMS_VERSION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     Desigo CC [!GMS_VERSION!] found ...
		echo Desigo CC [!GMS_VERSION!] found ...                                                                             >> %REPORT_LOGFILE% 2>&1
		set CHECKLMS_GMS_PATH=!CHECKLMS_REPORT_LOG_PATH!\GMS
		rmdir /S /Q "!CHECKLMS_GMS_PATH!\" >nul 2>&1
		IF NOT EXIST "!CHECKLMS_GMS_PATH!\" (
			echo Create folder: '!CHECKLMS_GMS_PATH!\'                                                                      >> %REPORT_LOGFILE% 2>&1
			mkdir "!CHECKLMS_GMS_PATH!\"                                                                                    >> %REPORT_LOGFILE% 2>&1
		)
		Powershell -command "Get-ItemProperty HKLM:\SOFTWARE\Siemens\Siemens_GMS | Format-List" > !CHECKLMS_GMS_PATH!\desigocc_registry.txt 2>&1
		IF EXIST "!CHECKLMS_GMS_PATH!\desigocc_registry.txt" (
			for /f "tokens=1* eol=@ delims=<>: " %%A in ('type !CHECKLMS_GMS_PATH!\desigocc_registry.txt ^|find /I "GMSActiveProject"') do set GMS_ActiveProject=%%B
			for /f "tokens=1* eol=@ delims=<>: " %%A in ('type !CHECKLMS_GMS_PATH!\desigocc_registry.txt ^|find /I "InstallDir"') do set GMS_InstallDir=%%B
			for /f "tokens=1* eol=@ delims=<>: " %%A in ('type !CHECKLMS_GMS_PATH!\desigocc_registry.txt ^|find /I "InstallDir"') do set GMS_InstallDrive=%%~dB
		)
		echo Desigo CC Version                : !GMS_VERSION!                                                                >> %REPORT_LOGFILE% 2>&1
		echo Desigo CC Installation drive     : !GMS_InstallDrive!                                                           >> %REPORT_LOGFILE% 2>&1
		echo Desigo CC Installation directory : !GMS_InstallDir!                                                             >> %REPORT_LOGFILE% 2>&1
		echo Desigo CC Active Project         : !GMS_ActiveProject!                                                          >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_GMS_PATH!\desigocc_registry.txt >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo     Read list of installed Extensions Modules of Desigo CC from registry ...
		echo Read list of installed Extensions Modules of Desigo CC from registry                                            >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty HKLM:\Software\Siemens\Siemens_GMS\EM\* | Select-Object DisplayName, DisplayVersion, ExtensionSuite, InstallationMode, IsEMWithoutMsi | Format-List" > !CHECKLMS_GMS_PATH!\desigocc_installed_EM.txt 2>&1
		type !CHECKLMS_GMS_PATH!\desigocc_installed_EM.txt >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo     Search for desigo cc logfiles [PVSS_II.log, WCCOActrl253.log] [in '!GMS_InstallDir!'] ...
		echo Search for desigo cc logfiles [PVSS_II.log, WCCOActrl253.log] [in '!GMS_InstallDir!' on drive !GMS_InstallDrive!] ...  >> %REPORT_LOGFILE% 2>&1
		del !CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt >nul 2>&1
		rem NOTE: The term 'PVSS_II.log' within IN doesn't work, make sure to have at least one * in it; e.g. 'PVSS_II.*'
		rem NOTE: If the [drive:]path are not specified they will default to the current drive:path.
		rem Somehow strange for /r "!GMS_InstallDir!" didn't work, because of that I use the workaound to search in current path nad change path before
		!GMS_InstallDrive!       >> %REPORT_LOGFILE% 2>&1
		cd !GMS_InstallDrive!    >> %REPORT_LOGFILE% 2>&1
		cd !GMS_InstallDir!      >> %REPORT_LOGFILE% 2>&1
		for /r "." %%X in (PVSS_II.l?g) do echo %%~dpnxX >> !CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt
		for /r "." %%X in (WCCOActrl253.l?g) do echo %%~dpnxX >> !CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt
		IF EXIST "!CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt" (
			echo List of desigo cc logfiles found [in '!GMS_InstallDir!' on drive !GMS_InstallDrive!] ...                    >> %REPORT_LOGFILE% 2>&1
			Type !CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt                                                               >> %REPORT_LOGFILE% 2>&1                                                      
			set LOG_FILE_COUNT=0
			echo -------------------------------------------------------                                                     >> %REPORT_LOGFILE% 2>&1                                                                
			FOR /F "eol=@ delims=@" %%i IN (!CHECKLMS_GMS_PATH!\DesigoCCLogFilesFound.txt) DO ( 
				set /A LOG_FILE_COUNT += 1
				echo %%i copy to !CHECKLMS_GMS_PATH!\%%~ni.!LOG_FILE_COUNT!%%~xi                                             >> %REPORT_LOGFILE% 2>&1                                                                                           
				copy /Y "%%i" "!CHECKLMS_GMS_PATH!\%%~ni.!LOG_FILE_COUNT!%%~xi"                                              >> %REPORT_LOGFILE% 2>&1                                                                                        
				powershell -command "& {Get-Content '!CHECKLMS_GMS_PATH!\%%~ni.!LOG_FILE_COUNT!%%~xi' | Select-Object -last %LOG_FILE_LINES%}"  >> %REPORT_LOGFILE% 2>&1                                  
				echo -------------------------------------------------------                                                 >> %REPORT_LOGFILE% 2>&1                                                                
			)
		) else (
			echo     No desigo cc logfiles [PVSS_II.log, WCCOActrl253.log] on '!GMS_InstallDir!' found.                      >> %REPORT_LOGFILE% 2>&1                                                                             
		)
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Desigo CC not installed on this machine.                                                                        >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   S E N T R O N   P O W E R M A N A G E R                                  =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- Sentron powermanager Registry Keys --
	set KEY_NAME=HKLM\SOFTWARE\Siemens\powermanager\V4.20
	set VALUE_NAME=Version
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set PM_VERSION=%%A
	)
	if defined PM_VERSION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     Sentron powermanager [!PM_VERSION!] found ...
		echo Sentron powermanager [!PM_VERSION!] found ...                                                                   >> %REPORT_LOGFILE% 2>&1
		echo Sentron powermanager Version: !PM_VERSION!                                                                      >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty HKLM:\SOFTWARE\Siemens\powermanager\V4.20 | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\pm_installed_versions.txt 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\pm_installed_versions.txt >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Content of folder: "%programdata%\\Siemens Energy\powermanager\Logs\" incl. sub-folders                         >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%programdata%\\Siemens Energy\powermanager\Logs\"                                                >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Sentron powermanager not installed on this machine.                                                             >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   X W O R K S  P L U S  [ X W P ]                                          =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- XWorks Plus (XWP) Registry Keys --
	set KEY_NAME=HKLM\SOFTWARE\WOW6432Node\Siemens\DESIGO\XWP
	set VALUE_NAME=Version
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set XWP_VERSION=%%A
	)
	if defined XWP_VERSION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     XWorksPlus XWP [!XWP_VERSION!] found ...
		echo XWorksPlus XWP [!XWP_VERSION!] found ...                                                                        >> %REPORT_LOGFILE% 2>&1
		echo XWorks Plus [XWP] Version: !XWP_VERSION!                                                                        >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Siemens\DESIGO\XWP | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\xwp_installed_versions.txt 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\xwp_installed_versions.txt >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Content of folder: "%TEMP%\setup*.log"                                                                          >> %REPORT_LOGFILE% 2>&1
		dir /A /X /4 /W "%TEMP%\setup*.log"                                                                                  >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Content of folder: "%TEMP%\DESIGO\LogFiles\*.log"                                                               >> %REPORT_LOGFILE% 2>&1
		dir /A /X /4 /W "%TEMP%\DESIGO\LogFiles\*.log"                                                                       >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo XWorks Plus [XWP] not installed on this machine.                                                                >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   A U T O M A T I O N   B U I L D I N G   T O O L   [ A B T ]              =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- Automation Building Tool (ABT) Registry Keys --
	set KEY_NAME=HKLM\SOFTWARE\Siemens\ABTSite
	set VALUE_NAME=Version
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set ABT_VERSION=%%A
	)
	if defined ABT_VERSION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     ABT [!ABT_VERSION!] found ...
		echo ABT [!ABT_VERSION!] found ...                                                                                   >> %REPORT_LOGFILE% 2>&1
		set KEY_NAME=HKLM\SOFTWARE\Siemens\ABTSite
		set VALUE_NAME=VersionString
		for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
			set ABT_VERSION_STRING=%%A
		)
		echo Automation Building Tool [ABT] Version: !ABT_VERSION_STRING! [!ABT_VERSION!]                                    >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty HKLM:\SOFTWARE\Siemens\ABTSite | Format-List" > !CHECKLMS_REPORT_LOG_PATH!\abt_installed_versions.txt 2>&1
		type !CHECKLMS_REPORT_LOG_PATH!\abt_installed_versions.txt >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Automation Building Tool [ABT] not installed on this machine.                                                   >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   S I V E I L L A N C E   I D E N T I T Y  [SiID]                          =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- Siveillance Identity (SiID) Registry Keys --
	set KEY_NAME=HKLM\SOFTWARE\Siemens\SiID
	set VALUE_NAME=Version
	for /F "usebackq tokens=3" %%A IN (`reg query "!KEY_NAME!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
		set SiID_VERSION=%%A
	)
	if defined SiID_VERSION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     Siveillance Identity [SiID] [!SiID_VERSION!] found ...
		echo Siveillance Identity [SiID] [!SiID_VERSION!]  found ...                                                         >> %REPORT_LOGFILE% 2>&1
		if exist "%programfiles%\Siemens\SiId\Siemens.SiId.Diagnostics.exe" (
			echo ... run diagnostic tool of SiID ...
			echo Run diagnostic tool of SiID [%programfiles%\Siemens\SiId\Siemens.SiId.Diagnostics.exe]                      >> %REPORT_LOGFILE% 2>&1
			rem add "any" parameter that it doesn't ask to press "enter" at the end
			"%programfiles%\Siemens\SiId\Siemens.SiId.Diagnostics.exe" /?                                                    >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Content of folder: "%programdata%\Siemens\SiId\Log\"                                                            >> %REPORT_LOGFILE% 2>&1
		dir /S /A /X /4 /W "%programdata%\Siemens\SiId\Log\"                                                                 >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		if exist "%programdata%\Siemens\SiId\Log\Diagnostics.log" (
			echo Content of file: "%programdata%\Siemens\SiId\Log\Diagnostics.log"                                           >> %REPORT_LOGFILE% 2>&1
			type %programdata%\Siemens\SiId\Log\Diagnostics.log                                                              >> %REPORT_LOGFILE% 2>&1
			echo -------------------------------------------------------                                                     >> %REPORT_LOGFILE% 2>&1
		)
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Siveillance Identity [SiID] not installed on this machine.                                                      >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   S I V E I L L A N C E   P A S S  [SiPass]                                =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- SiPass integrated  (SiPass) Registry Keys --
	for /F "usebackq tokens=3" %%A IN (`reg query "HKLM\SOFTWARE\WOW6432Node\Landis & Staefa\ADVANTAGE\Version4\Server" /v "DefaultConfiguration" 2^>nul ^| find /I "DefaultConfiguration"`) do (
		echo registry value "DefaultConfiguration" found ....                                                                >> %REPORT_LOGFILE% 2>&1
		set SIPASS_CONFIGURATION=%%A
		echo SIPASS_CONFIGURATION=!SIPASS_CONFIGURATION!                                                                     >> %REPORT_LOGFILE% 2>&1
	)
	if defined SIPASS_CONFIGURATION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     Siveillance Pass [SiPass] found ...
		echo Siveillance Pass [SiPass] found ...                                                                             >> %REPORT_LOGFILE% 2>&1
		set CHECKLMS_SIPASS_PATH=!CHECKLMS_REPORT_LOG_PATH!\SiPass
		rmdir /S /Q !CHECKLMS_SIPASS_PATH!\ >nul 2>&1
		IF NOT EXIST "!CHECKLMS_SIPASS_PATH!\" (
			rem echo Create new folder: !CHECKLMS_SIPASS_PATH!\
			echo Create folder: '!CHECKLMS_SIPASS_PATH!\'                                                                    >> %REPORT_LOGFILE% 2>&1
			mkdir "!CHECKLMS_SIPASS_PATH!\"                                                                                  >> %REPORT_LOGFILE% 2>&1
		)
		set VALUE_NAME=AdvantageDirectory
		rem "Read registry value that contains spaces using batch file", see https://stackoverflow.com/questions/16281185/read-registry-value-that-contains-spaces-using-batch-file/16282323
		for /F "usebackq tokens=2*" %%A IN (`reg query "HKLM\SOFTWARE\WOW6432Node\Landis & Staefa\ADVANTAGE\Version4\Server\ServerConfigurations\!SIPASS_CONFIGURATION!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
			set SIPASS_DIRECTORY=%%B
		)
		rem “Version” was just implemented for 2.80 builds and beyond
		set VALUE_NAME=Version
		for /F "usebackq tokens=3" %%A IN (`reg query "HKLM\SOFTWARE\Wow6432Node\Landis & Staefa\ADVANTAGE\Version4\Server\ServerConfigurations\!SIPASS_CONFIGURATION!" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
			set SIPASS_VERSION=%%A
		)

		echo SiPass default configuation: !SIPASS_CONFIGURATION!                                                             >> %REPORT_LOGFILE% 2>&1
		echo SiPass advantage directory : !SIPASS_DIRECTORY!                                                                 >> %REPORT_LOGFILE% 2>&1
		echo SiPass version             : !SIPASS_VERSION!                                                                   >> %REPORT_LOGFILE% 2>&1
		
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Landis & Staefa\ADVANTAGE\Version4\Server' | Format-List" > !CHECKLMS_SIPASS_PATH!\sipass_registry.txt 2>&1
		echo Content of registry key: "HKLM:\SOFTWARE\Wow6432Node\Landis & Staefa\ADVANTAGE\Version4\Server" ...             >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_SIPASS_PATH!\sipass_registry.txt                                                                      >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Landis & Staefa\ADVANTAGE\Version4\Server\ServerConfigurations\!SIPASS_CONFIGURATION!' | Format-List" > !CHECKLMS_SIPASS_PATH!\sipass_configuration_registry.txt 2>&1
		echo Content of registry key: "HKLM:\SOFTWARE\Wow6432Node\Landis & Staefa\ADVANTAGE\Version4\Server\ServerConfigurations\!SIPASS_CONFIGURATION!" ... >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_SIPASS_PATH!\sipass_configuration_registry.txt                                                        >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		IF EXIST "!SIPASS_DIRECTORY!\SiServer-log-file.txt" (
			echo LOG FILE: SiServer-log-file.txt [last %LOG_FILE_LINES% lines]                                               >> %REPORT_LOGFILE% 2>&1
			powershell -command "& {Get-Content '!SIPASS_DIRECTORY!\SiServer-log-file.txt' | Select-Object -last %LOG_FILE_LINES%}"  >> %REPORT_LOGFILE% 2>&1
			echo -------------------------------------------------------                                                     >> %REPORT_LOGFILE% 2>&1
			echo copy !SIPASS_DIRECTORY!\SiServer-log-file.txt.* to !CHECKLMS_SIPASS_PATH!\                                  >> %REPORT_LOGFILE% 2>&1   
			copy /Y "!SIPASS_DIRECTORY!\SiServer-log-file.txt.*" !CHECKLMS_SIPASS_PATH!\                                     >> %REPORT_LOGFILE% 2>&1
		) else (
			echo     !SIPASS_DIRECTORY!\SiServer-log-file.txt not found.                                                     >> %REPORT_LOGFILE% 2>&1
		)
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo SiPass integrated [SiPass] not installed on this machine.                                                       >> %REPORT_LOGFILE% 2>&1
	)
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	echo =   A P O G E E   D A T A M A T E   A D V A N C E D [DMA, Insight, CommTool] =                                      >> %REPORT_LOGFILE% 2>&1
	echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
	REM -- Apogee Datamate Advanced (DMA) Registry Keys --
	rem - Stores the product name (Insight, DMA or CommTool) \HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup\ProductLine
	rem - Stores the revision: \HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup\AsyncRevString
	rem - Stores the Product path: HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Configuration\Application
	for /F "usebackq tokens=3" %%A IN (`reg query "HKLM\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup" /v "ProductLine" 2^>nul ^| find /I "ProductLine"`) do (
		echo registry value "ProductLine" found ....                                                                         >> %REPORT_LOGFILE% 2>&1
		set DMA_CONFIGURATION=%%A
		echo DMA_CONFIGURATION=!DMA_CONFIGURATION!                                                                           >> %REPORT_LOGFILE% 2>&1
	)
	if defined DMA_CONFIGURATION (
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
		echo     Apogee Datamate Advanced [DMA] found ...
		echo Apogee Datamate Advanced [DMA] found ...                                                                        >> %REPORT_LOGFILE% 2>&1
		set CHECKLMS_DMA_PATH=!CHECKLMS_REPORT_LOG_PATH!\DMA
		rmdir /S /Q !CHECKLMS_DMA_PATH!\ >nul 2>&1
		IF NOT EXIST "!CHECKLMS_DMA_PATH!\" (
			echo Create folder: '!CHECKLMS_DMA_PATH!\'                                                                       >> %REPORT_LOGFILE% 2>&1
			mkdir "!CHECKLMS_DMA_PATH!\"                                                                                     >> %REPORT_LOGFILE% 2>&1
		)
		set VALUE_NAME=Application
		rem "Read registry value that contains spaces using batch file", see https://stackoverflow.com/questions/16281185/read-registry-value-that-contains-spaces-using-batch-file/16282323
		for /F "usebackq tokens=2*" %%A IN (`reg query "HKLM\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Configuration" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
			set DMA_DIRECTORY=%%B
		)
		set VALUE_NAME=AsyncRevString
		rem "Read registry value that contains spaces using batch file", see https://stackoverflow.com/questions/16281185/read-registry-value-that-contains-spaces-using-batch-file/16282323
		for /F "usebackq tokens=2*" %%A IN (`reg query "HKLM\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup" /v "!VALUE_NAME!" 2^>nul ^| find /I "!VALUE_NAME!"`) do (
			set DMA_VERSION=%%B
		)
		echo Apogee Datamate Advanced [DMA] configuation: !DMA_CONFIGURATION!                                                >> %REPORT_LOGFILE% 2>&1
		echo Apogee Datamate Advanced [DMA] directory   : !DMA_DIRECTORY!                                                    >> %REPORT_LOGFILE% 2>&1
		echo Apogee Datamate Advanced [DMA] version     : !DMA_VERSION!                                                      >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Configuration' | Format-List" > !CHECKLMS_DMA_PATH!\dma_configuration_registry.txt 2>&1
		echo Content of registry key: "HKLM:\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Configuration" ...     >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_DMA_PATH!\dma_configuration_registry.txt                                                              >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		Powershell -command "Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup' | Format-List" > !CHECKLMS_DMA_PATH!\dma_setup_registry.txt 2>&1
		echo Content of registry key: "HKLM:\SOFTWARE\WOW6432Node\LANDIS & GYR\Insight\CurrentVersion\Setup" ...             >> %REPORT_LOGFILE% 2>&1
		type !CHECKLMS_DMA_PATH!\dma_setup_registry.txt                                                                      >> %REPORT_LOGFILE% 2>&1
		echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
		if exist "!DMA_DIRECTORY!\Main.exe" (
			echo Run diagnostic tool of DMA [!DMA_DIRECTORY!\Main.exe]                                                       >> %REPORT_LOGFILE% 2>&1
			rem As creation of MainMenuUnitTest.txt takes some time, start Main.exe as early as possible
			rem start "Start DMA" "!DMA_DIRECTORY!\Main.exe" /test
			rem The creation of MainMenuUnitTest.txt takes approx. 15[s]
			if defined SHOW_COLORED_OUTPUT (
				echo [1;34m    -------------------------------------------- [1;37m
				echo [1;34m    NOTE: Execute the following command "!DMA_DIRECTORY!\Main.exe /test" and provide C:\MainMenuUnitTest.txt. [1;37m
				echo [1;34m    -------------------------------------------- [1;37m
			) else (
				echo     --------------------------------------------
				echo     NOTE: Execute the following command "!DMA_DIRECTORY!\Main.exe /test" and provide C:\MainMenuUnitTest.txt.
				echo     --------------------------------------------
			)
			echo     --------------------------------------------                                                                >> %REPORT_LOGFILE% 2>&1
			echo     NOTE: Execute the following command "!DMA_DIRECTORY!\Main.exe /test" and provide C:\MainMenuUnitTest.txt.   >> %REPORT_LOGFILE% 2>&1
			echo     --------------------------------------------                                                                >> %REPORT_LOGFILE% 2>&1
		)
		rem check presence of "C:\MainMenuUnitTest.txt"
		if exist "C:\MainMenuUnitTest.txt" (
			echo ... diagnostic ouput of DMA found [C:\MainMenuUnitTest.txt] ...
			echo Diagnostic ouput of DMA found [C:\MainMenuUnitTest.txt] ...                                                 >> %REPORT_LOGFILE% 2>&1
			echo copy C:\MainMenuUnitTest.txt to !CHECKLMS_DMA_PATH!\                                                        >> %REPORT_LOGFILE% 2>&1   
			copy /Y "C:\MainMenuUnitTest.txt" !CHECKLMS_DMA_PATH!\                                                           >> %REPORT_LOGFILE% 2>&1
			type "!CHECKLMS_DMA_PATH!\MainMenuUnitTest.txt"                                                                  >> %REPORT_LOGFILE% 2>&1
			powershell -Command "get-childitem 'C:\MainMenuUnitTest.txt' | select Name,CreationTime,LastAccessTime,LastWriteTime"  >> %REPORT_LOGFILE% 2>&1
		)
		echo Start at !DATE! !TIME! ....                                                                                     >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Apogee Datamate Advanced [DMA] not installed on this machine.                                                   >> %REPORT_LOGFILE% 2>&1
	)	
) else (
	rem LMS_SKIPPRODUCTS
	if defined SHOW_COLORED_OUTPUT (
		echo [1;33m    SKIPPED products section. The script didn't execute the product specific commands. [1;37m
	) else (
		echo     SKIPPED products section. The script didn't execute the product specific commands.
	)
	echo SKIPPED products section. The script didn't execute the product specific commands.                                  >> %REPORT_LOGFILE% 2>&1
)
echo ... perform check on different id's ...
echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
echo =   C H E C K - I D                                                          =                                      >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1

echo     compare the UMNs read with the two commands ...
echo Compare the UMNs read with the two commands                                                                         >> %REPORT_LOGFILE% 2>&1
set UMN_CHECK_STATUS=Unknown
if defined UMN_COUNT_A (
	set UMN_CHECK_STATUS=Ok
	if /I !UMN_COUNT_A! NEQ !UMN_COUNT_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN count differs between servercomptranutil = !UMN_COUNT_A! and appactutil = !UMN_COUNT_B! [1;37m
		) else (
			echo     ATTENTION: UMN count differs between servercomptranutil = !UMN_COUNT_A! and appactutil = !UMN_COUNT_B!
		)
		echo     ATTENTION: UMN count differs between servercomptranutil = !UMN_COUNT_A! and appactutil = !UMN_COUNT_B!  >> %REPORT_LOGFILE% 2>&1
	) else (
		set /a UMN_COUNT = !UMN_COUNT_A!
	)
	if /I !UMN1_A! NEQ !UMN1_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN1 differs between servercomptranutil = !UMN1_A! and appactutil = !UMN1_B! [1;37m
		) else (
			echo     ATTENTION: UMN1 differs between servercomptranutil = !UMN1_A! and appactutil = !UMN1_B!
		)
		echo     ATTENTION: UMN1 differs between servercomptranutil = !UMN1_A! and appactutil = !UMN1_B!                 >> %REPORT_LOGFILE% 2>&1
	) else (
		set UMN1=!UMN1_A!
	)
	if /I !UMN2_A! NEQ !UMN2_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN2 differs between servercomptranutil = !UMN2_A! and appactutil = !UMN2_B! [1;37m
		) else (
			echo     ATTENTION: UMN2 differs between servercomptranutil = !UMN2_A! and appactutil = !UMN2_B!
		)
		echo     ATTENTION: UMN2 differs between servercomptranutil = !UMN2_A! and appactutil = !UMN2_B!                 >> %REPORT_LOGFILE% 2>&1
	) else (
		set UMN2=!UMN2_A!
	)
	if /I !UMN3_A! NEQ !UMN3_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN3 differs between servercomptranutil = !UMN3_A! and appactutil = !UMN3_B! [1;37m
		) else (
			echo     ATTENTION: UMN3 differs between servercomptranutil = !UMN3_A! and appactutil = !UMN3_B!
		)
		echo     ATTENTION: UMN3 differs between servercomptranutil = !UMN3_A! and appactutil = !UMN3_B!                 >> %REPORT_LOGFILE% 2>&1
	) else (
		set UMN3=!UMN3_A!
	)
	if /I !UMN4_A! NEQ !UMN4_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN4 differs between servercomptranutil = !UMN4_A! and appactutil = !UMN4_B! [1;37m
		) else (
			echo     ATTENTION: UMN4 differs between servercomptranutil = !UMN4_A! and appactutil = !UMN4_B!
		)
		echo     ATTENTION: UMN4 differs between servercomptranutil = !UMN4_A! and appactutil = !UMN4_B!                 >> %REPORT_LOGFILE% 2>&1
	) else (
		set UMN4=!UMN4_A!
	)
	if /I !UMN5_A! NEQ !UMN5_B! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN5 differs between servercomptranutil = !UMN5_A! and appactutil = !UMN5_B! [1;37m
		) else (
			echo     ATTENTION: UMN5 differs between servercomptranutil = !UMN5_A! and appactutil = !UMN5_B!
		)
		echo     ATTENTION: UMN5 differs between servercomptranutil = !UMN5_A! and appactutil = !UMN5_B!                 >> %REPORT_LOGFILE% 2>&1
	) else (
		set UMN5=!UMN5_A!
	)
) else (
	set UMN_CHECK_STATUS=n/a
	if defined UMN_COUNT_B (
		rem only the command appactutil executed, use those results
		set /a UMN_COUNT = !UMN_COUNT_B!
		set UMN1=!UMN1_B!
		set UMN2=!UMN2_B!
		set UMN3=!UMN3_B!
		set UMN4=!UMN4_B!
		set UMN5=!UMN5_B!
	)
)
echo     compare the UMNs read from offline request file ...
echo Compare the UMNs read from offline request file                                                                         >> %REPORT_LOGFILE% 2>&1
if defined UMN_COUNT_TS (
	if /I !UMN_COUNT_TS! NEQ !UMN_COUNT! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN count differs between offline request file = !UMN_COUNT_TS! and command line tool = !UMN_COUNT! [1;37m
		) else (
			echo     ATTENTION: UMN count differs between offline request file = !UMN_COUNT_TS! and command line tool = !UMN_COUNT!
		)
		echo     ATTENTION: UMN count differs between offline request file = !UMN_COUNT_TS! and command line tool = !UMN_COUNT!  >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN1_TS! NEQ !UMN1! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN1 differs between offline request file = !UMN1_TS! and command line tool = !UMN1! [1;37m
		) else (
			echo     ATTENTION: UMN1 differs between offline request file = !UMN1_TS! and command line tool = !UMN1!
		)
		echo     ATTENTION: UMN1 differs between offline request file = !UMN1_TS! and command line tool = !UMN1!                 >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN2_TS! NEQ !UMN2! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN2 differs between offline request file = !UMN2_TS! and command line tool = !UMN2! [1;37m
		) else (
			echo     ATTENTION: UMN2 differs between offline request file = !UMN2_TS! and command line tool = !UMN2!
		)
		echo     ATTENTION: UMN2 differs between offline request file = !UMN2_TS! and command line tool = !UMN2!                 >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN3_TS! NEQ !UMN3! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN3 differs between offline request file = !UMN3_TS! and command line tool = !UMN3! [1;37m
		) else (
			echo     ATTENTION: UMN3 differs between offline request file = !UMN3_TS! and command line tool = !UMN3!
		)
		echo     ATTENTION: UMN3 differs between offline request file = !UMN3_TS! and command line tool = !UMN3!                 >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN4_TS! NEQ !UMN4! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN4 differs between offline request file = !UMN4_TS! and command line tool = !UMN4! [1;37m
		) else (
			echo     ATTENTION: UMN4 differs between offline request file = !UMN4_TS! and command line tool = !UMN4!
		)
		echo     ATTENTION: UMN4 differs between offline request file = !UMN4_TS! and command line tool = !UMN4!                 >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN5_TS! NEQ !UMN5! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN5 differs between offline request file = !UMN5_TS! and command line tool = !UMN5! [1;37m
		) else (
			echo     ATTENTION: UMN5 differs between offline request file = !UMN5_TS! and command line tool = !UMN5!
		)
		echo     ATTENTION: UMN5 differs between offline request file = !UMN5_TS! and command line tool = !UMN5!                 >> %REPORT_LOGFILE% 2>&1
	)
)
echo     compare the UMNs read from previous run ...
echo Compare the UMNs read from previous run                                                                                     >> %REPORT_LOGFILE% 2>&1
if defined UMN_COUNT_PREV (
	if /I !UMN_COUNT_PREV! NEQ !UMN_COUNT! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN count differs between previous run = !UMN_COUNT_PREV! and current run = !UMN_COUNT! [1;37m
		) else (
			echo     ATTENTION: UMN count differs between previous run = !UMN_COUNT_PREV! and current run = !UMN_COUNT!
		)
		echo     ATTENTION: UMN count differs between previous run = !UMN_COUNT_PREV! and current run = !UMN_COUNT!              >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN1_PREV! NEQ !UMN1! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN1 differs between previous run = !UMN1_PREV! and current run = !UMN1! [1;37m
		) else (
			echo     ATTENTION: UMN1 differs between previous run = !UMN1_PREV! and current run = !UMN1!
		)
		echo     ATTENTION: UMN1 differs between previous run = !UMN1_PREV! and current run = !UMN1!                             >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN2_PREV! NEQ !UMN2! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN2 differs between previous run = !UMN2_PREV! and current run = !UMN2! [1;37m
		) else (
			echo     ATTENTION: UMN2 differs between previous run = !UMN2_PREV! and current run = !UMN2!
		)
		echo     ATTENTION: UMN2 differs between previous run = !UMN2_PREV! and current run = !UMN2!                             >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN3_PREV! NEQ !UMN3! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN3 differs between previous run = !UMN3_PREV! and current run = !UMN3! [1;37m
		) else (
			echo     ATTENTION: UMN3 differs between previous run = !UMN3_PREV! and current run = !UMN3!
		)
		echo     ATTENTION: UMN3 differs between previous run = !UMN3_PREV! and current run = !UMN3!                             >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN4_PREV! NEQ !UMN4! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN4 differs between previous run = !UMN4_PREV! and current run = !UMN4! [1;37m
		) else (
			echo     ATTENTION: UMN4 differs between previous run = !UMN4_PREV! and current run = !UMN4!
		)
		echo     ATTENTION: UMN4 differs between previous run = !UMN4_PREV! and current run = !UMN4!                             >> %REPORT_LOGFILE% 2>&1
	)
	if /I !UMN5_PREV! NEQ !UMN5! (
		set UMN_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: UMN5 differs between previous run = !UMN5_PREV! and current run = !UMN5! [1;37m
		) else (
			echo     ATTENTION: UMN5 differs between previous run = !UMN5_PREV! and current run = !UMN5!
		)
		echo     ATTENTION: UMN5 differs between previous run = !UMN5_PREV! and current run = !UMN5!                             >> %REPORT_LOGFILE% 2>&1
	)
)

echo     check VM values collected with servercomptranutil ...
echo Check VM values collected with servercomptranutil                                                                                     >> %REPORT_LOGFILE% 2>&1
rem check VM values (also on physical machine!)
if "!VM_FAMILY!" == "UNKNOWNVM" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ATTENTION: Unknown VM family detected. [1;37m
	) else (
		echo     ATTENTION: Unknown VM family detected.
	)
	echo ATTENTION: Unknown VM family detected.                                                                              >> %REPORT_LOGFILE% 2>&1
)
if "!VM_NAME!" == "UNKNOWNVM" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ATTENTION: Unknown VM name detected. [1;37m
	) else (
		echo     ATTENTION: Unknown VM name detected.
	)
	echo ATTENTION: Unknown VM name detected.                                                                                >> %REPORT_LOGFILE% 2>&1
)
echo     check VM values collected with lmvminfo ...
echo Check VM values collected with lmvminfo                                                                                     >> %REPORT_LOGFILE% 2>&1
if "%VM_FAMILY_2%" == "UNKNOWNVM" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ATTENTION: Unknown VM family detected. [1;37m
	) else (
		echo     ATTENTION: Unknown VM family detected.
	)
	echo ATTENTION: Unknown VM family detected.                                                                              >> %REPORT_LOGFILE% 2>&1
)
if "%VM_NAME_2%" == "UNKNOWNVM" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ATTENTION: Unknown VM name detected. [1;37m
	) else (
		echo     ATTENTION: Unknown VM name detected.
	)
	echo ATTENTION: Unknown VM name detected.                                                                                >> %REPORT_LOGFILE% 2>&1
)
REM Compare output of two VM detections with servercomptranutil and lmvminfo
if defined VM_DETECTED if defined VM_DETECTED_2 (
	set VM_DETECTION_CHECK_STATUS=Ok
	if /I "!VM_FAMILY!" NEQ "!VM_FAMILY_2!" (
		set VM_DETECTION_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM family detection differs between servercomptranutil = !VM_FAMILY! and lmvminfo = !VM_FAMILY_2! [1;37m
		) else (
			echo     ATTENTION: VM family differs detection between servercomptranutil = !VM_FAMILY! and lmvminfo = !VM_FAMILY_2!
		)
		echo     ATTENTION: VM family detection differs between servercomptranutil = !VM_FAMILY! and lmvminfo = !VM_FAMILY_2!     >> %REPORT_LOGFILE% 2>&1
	)
	if /I "!VM_NAME!" NEQ "!VM_NAME_2!" (
		set VM_DETECTION_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM name detection differs between servercomptranutil = !VM_NAME! and lmvminfo = !VM_NAME_2! [1;37m
		) else (
			echo     ATTENTION: VM name differs detection between servercomptranutil = !VM_NAME! and lmvminfo = !VM_NAME_2!
		)
		echo     ATTENTION: VM name detection differs between servercomptranutil = !VM_NAME! and lmvminfo = !VM_NAME_2!      >> %REPORT_LOGFILE% 2>&1
	)
	if /I "!VM_UUID!" NEQ "!VM_UUID_2!" (
		set VM_DETECTION_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM UUID detection differs between servercomptranutil = !VM_UUID! and lmvminfo = !VM_UUID_2! [1;37m
		) else (
			echo     ATTENTION: VM UUID differs detection between servercomptranutil = !VM_UUID! and lmvminfo = !VM_UUID_2!
		)
		echo     ATTENTION: VM UUID detection differs between servercomptranutil = !VM_UUID! and lmvminfo = !VM_UUID_2!      >> %REPORT_LOGFILE% 2>&1
	)
	if /I "!VM_GENID!" NEQ "!VM_GENID_2!" (
		set VM_DETECTION_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM GENID detection differs between servercomptranutil = !VM_GENID! and lmvminfo = !VM_GENID_2! [1;37m
		) else (
			echo     ATTENTION: VM GENID differs detection between servercomptranutil = !VM_GENID! and lmvminfo = !VM_GENID_2!
		)
		echo     ATTENTION: VM GENID detection differs between servercomptranutil = !VM_GENID! and lmvminfo = !VM_GENID_2!   >> %REPORT_LOGFILE% 2>&1
	)
)

set VM_CHECK_STATUS=Unknown
if defined VMINFO_PREV (
	echo     compare the VM values read from previous run ...
	echo Compare the VM values read from previous run                                                                                     >> %REPORT_LOGFILE% 2>&1
	set AWS_CHECK_STATUS=Ok

	rem compare current VM values with previous values
	if /I !VM_DETECTED! NEQ !VM_DETECTED_PREV! (
		set VM_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM detection differs between previous run = !VM_DETECTED_PREV! and current run = !VM_DETECTED! [1;37m
		) else (
			echo     ATTENTION: VM detection differs between previous run = !VM_DETECTED_PREV! and current run = !VM_DETECTED!
		)
		echo     ATTENTION: VM detection differs between previous run = !VM_DETECTED_PREV! and current run = !VM_DETECTED!   >> %REPORT_LOGFILE% 2>&1
	)
	if /I !VM_FAMILY! NEQ !VM_FAMILY_PREV! (
		set VM_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM family differs between previous run = !VM_FAMILY_PREV! and current run = !VM_FAMILY! [1;37m
		) else (
			echo     ATTENTION: VM family differs between previous run = !VM_FAMILY_PREV! and current run = !VM_FAMILY!
		)
		echo     ATTENTION: VM family differs between previous run = !VM_FAMILY_PREV! and current run = !VM_FAMILY!          >> %REPORT_LOGFILE% 2>&1
	)
	if /I !VM_NAME! NEQ !VM_NAME_PREV! (
		set VM_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM name differs between previous run = !VM_NAME_PREV! and current run = !VM_NAME! [1;37m
		) else (
			echo     ATTENTION: VM name differs between previous run = !VM_NAME_PREV! and current run = !VM_NAME!
		)
		echo     ATTENTION: VM name differs between previous run = !VM_NAME_PREV! and current run = !VM_NAME!                >> %REPORT_LOGFILE% 2>&1
	)
	if /I !VM_UUID! NEQ !VM_UUID_PREV! (
		set VM_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM UUID differs between previous run = !VM_UUID_PREV! and current run = !VM_UUID! [1;37m
		) else (
			echo     ATTENTION: VM UUID differs between previous run = !VM_UUID_PREV! and current run = !VM_UUID!
		)
		echo     ATTENTION: VM UUID differs between previous run = !VM_UUID_PREV! and current run = !VM_UUID!                >> %REPORT_LOGFILE% 2>&1
	)
	if /I !VM_GENID! NEQ !VM_GENID_PREV! (
		set VM_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: VM GENID differs between previous run = !VM_GENID_PREV! and current run = !VM_GENID! [1;37m
		) else (
			echo     ATTENTION: VM GENID differs between previous run = !VM_GENID_PREV! and current run = !VM_GENID!
		)
		echo     ATTENTION: VM GENID differs between previous run = !VM_GENID_PREV! and current run = !VM_GENID!             >> %REPORT_LOGFILE% 2>&1
	)
)

set AWS_CHECK_STATUS=Unknown
if /I "!LMS_IS_VM!"=="true" (
	rem call further commands only, when running on a virtual machine, wthin a hypervisor.

	echo     compare the AWS instance identify document values read from previous run ...
	echo Compare the AWS instance identify document values read from previous run                                                >> %REPORT_LOGFILE% 2>&1
	set AWS_CHECK_STATUS=Ok

	rem compare current AWS instance identify document values with previous values
	if /I !AWS_ACCID! NEQ !AWS_ACCID_PREV! (
		set AWS_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: AWS Account ID differs between previous run = !AWS_ACCID_PREV! and current run = !AWS_ACCID! [1;37m
		) else (
			echo     ATTENTION: AWS Account ID differs between previous run = !AWS_ACCID_PREV! and current run = !AWS_ACCID!
		)
		echo     ATTENTION: AWS Account ID differs between previous run = !AWS_ACCID_PREV! and current run = !AWS_ACCID!         >> %REPORT_LOGFILE% 2>&1
	)
	if /I !AWS_IMGID! NEQ !AWS_IMGID_PREV! (
		set AWS_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: AWS Image ID differs between previous run = !AWS_IMGID_PREV! and current run = !AWS_IMGID! [1;37m
		) else (
			echo     ATTENTION: AWS Image ID differs between previous run = !AWS_IMGID_PREV! and current run = !AWS_IMGID!
		)
		echo     ATTENTION: AWS Image ID differs between previous run = !AWS_IMGID_PREV! and current run = !AWS_IMGID!           >> %REPORT_LOGFILE% 2>&1
	)
	if /I !AWS_INSTID! NEQ !AWS_INSTID_PREV! (
		set AWS_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: AWS Instance ID differs between previous run = !AWS_INSTID_PREV! and current run = !AWS_INSTID! [1;37m
		) else (
			echo     ATTENTION: AWS Instance ID differs between previous run = !AWS_INSTID_PREV! and current run = !AWS_INSTID!
		)
		echo     ATTENTION: AWS Instance ID differs between previous run = !AWS_INSTID_PREV! and current run = !AWS_INSTID!      >> %REPORT_LOGFILE% 2>&1
	)
	if /I !AWS_PENTIME! NEQ !AWS_PENTIME_PREV! (
		set AWS_CHECK_STATUS=Failed
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: AWS Pending Time differs between previous run = !AWS_PENTIME_PREV! and current run = !AWS_PENTIME! [1;37m
		) else (
			echo     ATTENTION: AWS Pending Time differs between previous run = !AWS_PENTIME_PREV! and current run = !AWS_PENTIME!
		)
		echo     ATTENTION: AWS Pending Time differs between previous run = !AWS_PENTIME_PREV! and current run = !AWS_PENTIME!   >> %REPORT_LOGFILE% 2>&1
	)
)

:summary
echo ... summarize collected information ...
echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
echo =   S U M M A R Y                                                            =                                      >> %REPORT_LOGFILE% 2>&1
echo ==============================================================================                                      >> %REPORT_LOGFILE% 2>&1
echo LMS Status Report for LMS Version: !LMS_VERSION! (on %COMPUTERNAME%) installed at %LMS_INSTALL_DATE%                >> %REPORT_LOGFILE% 2>&1
echo     Date: !DATE! / Time: !TIME!                                                                                     >> %REPORT_LOGFILE% 2>&1
echo     LMS System Id: !LMS_SYSTEMID!                                                                                   >> %REPORT_LOGFILE% 2>&1
echo     Machine GUID : %OS_MACHINEGUID%                                                                                 >> %REPORT_LOGFILE% 2>&1
echo     Check Script Version: %LMS_SCRIPT_VERSION% (!LMS_SCRIPT_BUILD!)                                                 >> %REPORT_LOGFILE% 2>&1
echo     Hypervisor Present  : !LMS_IS_VM!                                                                               >> %REPORT_LOGFILE% 2>&1
echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
echo     PublisherId: !LMS_TS_PUBLISHER!  /  TS ClientVersion: !LMS_TS_CLIENT_VERSION!                                   >> %REPORT_LOGFILE% 2>&1
echo     MachineIdentifier: !LMS_TS_MACHINE_IDENTIFIER!  /  TrustedStorageSerialNumber: !LMS_TS_SERIAL_NUMBER!           >> %REPORT_LOGFILE% 2>&1
echo     TS Status: !LMS_TS_STATUS!  /  TS SequenceNumber: !LMS_TS_SEQ_NUM!  /  TS Revision: !LMS_TS_REVISION!           >> %REPORT_LOGFILE% 2>&1
echo     SIEMBT Hostname: !LMS_SIEMBT_HOSTNAME! / SIEMBT HostID: !LMS_SIEMBT_HOSTIDS!                                    >> %REPORT_LOGFILE% 2>&1
if "!LMS_SIEMBT_HOSTIDS!" == "ffffffff" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ERROR: Invalid HostID found in SIEMBT.log. SIEMBT HostID: !LMS_SIEMBT_HOSTIDS! [1;37m
	) else (
		echo     ERROR: Invalid HostID found in SIEMBT.log. SIEMBT HostID: !LMS_SIEMBT_HOSTIDS!
	)
	echo ERROR: Invalid HostID found in SIEMBT.log. SIEMBT HostID: !LMS_SIEMBT_HOSTIDS!                                  >> %REPORT_LOGFILE% 2>&1
)
if "!LMS_SIEMBT_HYPERVISOR!" == "Unknown Hypervisor" (
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    ERROR: Unknown Hypervisor found in SIEMBT.log. Running on Hypervisor: !LMS_SIEMBT_HYPERVISOR! [1;37m
	) else (
		echo     ERROR: Unknown Hypervisor found in SIEMBT.log. Running on Hypervisor: !LMS_SIEMBT_HYPERVISOR!
	)
	echo ERROR: Unknown Hypervisor found in SIEMBT.log. Running on Hypervisor: !LMS_SIEMBT_HYPERVISOR!                   >> %REPORT_LOGFILE% 2>&1
)
IF EXIST "%DOCUMENTATION_PATH%\\info.txt" (
	echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
	Type "%DOCUMENTATION_PATH%\\info.txt"                                                                                >> %REPORT_LOGFILE% 2>&1
)
echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
if not defined LMS_CHECK_ID (
	echo Connection Test Status: !ConnectionTestStatus! [ https://static.siemens.com/btdownloads/ ]                      >> %REPORT_LOGFILE% 2>&1
	if defined LMS_CON_TEST_FAILED (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Enhanced Connection Test Status: FAILED! [1;37m
		) else (
			echo     ATTENTION: Enhanced Connection Test Status: FAILED!
		)
		echo ATTENTION: Enhanced Connection Test Status: FAILED!                                                         >> %REPORT_LOGFILE% 2>&1
	) else (
		echo Enhanced Connection Test Status: PASSED!                                                                    >> %REPORT_LOGFILE% 2>&1
	)
)
echo Installed FNP Version: !FNPVersion! (!fnpversionFromLogFile!)                                                       >> %REPORT_LOGFILE% 2>&1
echo Installed .NET Version: %NETVersion%                                                                                >> %REPORT_LOGFILE% 2>&1
echo Configured license server: !LMS_CFG_LICENSE_SRV_NAME! with port !LMS_CFG_LICENSE_SRV_PORT!                          >> %REPORT_LOGFILE% 2>&1
if defined LMS_CFG_LICENSE_SRV_NAME if not "!LMS_CFG_LICENSE_SRV_NAME!" == "localhost" (
	echo     Remote License Server Configuration                                                                         >> %REPORT_LOGFILE% 2>&1
) else (
	echo     Local License Server Configuration                                                                          >> %REPORT_LOGFILE% 2>&1
)
if defined VM_DETECTED (
	if "!VM_DETECTED!" == "NO" (
		echo Physical machine detected.                                                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		if "!VM_DETECTED!" == "YES" (
			echo Virtual machine detected!                                                                                                                                     >> %REPORT_LOGFILE% 2>&1
			echo     AWS_ACCID=!AWS_ACCID! / AWS_IMGID=!AWS_IMGID! / AWS_INSTID=!AWS_INSTID! / AWS_PENTIME=!AWS_PENTIME!                                                       >> %REPORT_LOGFILE% 2>&1   
			echo     VM_DETECTED=!VM_DETECTED! / VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!                                           >> %REPORT_LOGFILE% 2>&1
			echo     ECM_VM_FAMILY=!ECM_VM_FAMILY! / ECM_VM_NAME=!ECM_VM_NAME! / ECM_VM_UUID=!ECM_VM_UUID! / ECM_SMBIOS_UUID=!ECM_SMBIOS_UUID! / ECM_VM_GENID=!ECM_VM_GENID!   >> %REPORT_LOGFILE% 2>&1
		) else (
			echo Detection of physical or virtual machine failed. Not able to determine.                                 >> %REPORT_LOGFILE% 2>&1
			echo     ATTENTION: VM detection failed. VM_DETECTED=!VM_DETECTED!                                           >> %REPORT_LOGFILE% 2>&1
		)
		if "!VM_FAMILY!" == "UNKNOWNVM" (
			echo     ATTENTION: Unknown VM family detected.                                                              >> %REPORT_LOGFILE% 2>&1
		)
		if "!VM_NAME!" == "UNKNOWNVM" (
			echo     ATTENTION: Unknown VM name detected.                                                                >> %REPORT_LOGFILE% 2>&1
		)
	)
) else (
	echo Detection of physical or virtual machine failed. Not able to determine.                                         >> %REPORT_LOGFILE% 2>&1
	echo     ATTENTION: VM detection failed.                                                                             >> %REPORT_LOGFILE% 2>&1
)
echo     SIEMBT Virtual Environment: !LMS_SIEMBT_HYPERVISOR!                                                             >> %REPORT_LOGFILE% 2>&1
echo Number of UMN used to bind TS: !UMN_COUNT!                                                                          >> %REPORT_LOGFILE% 2>&1
echo     UMN1=!UMN1! / UMN2=!UMN2! / UMN3=!UMN3! / UMN4=!UMN4! / UMN5=!UMN5!                                             >> %REPORT_LOGFILE% 2>&1
if not defined LMS_CHECK_ID (
	if defined DONGLE_DRIVER_PKG_VERSION (
		echo Dongle Driver: %DONGLE_DRIVER_VERSION% [%DONGLE_DRIVER_PKG_VERSION%] installed %DONGLE_DRIVER_INST_COUNT% times >> %REPORT_LOGFILE% 2>&1
		if defined DONGLE_DRIVER_MOST_RECENT_VERSION_INSTALLED (
			echo     Most recent or newer dongle driver !DONGLE_DRIVER_PKG_VERSION! installed on the system.                 >> %REPORT_LOGFILE% 2>&1
		) else (
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!. [1;37m
			) else (
				echo     WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!.
			)
			echo     WARNING: There is not the most recent dongle driver !MOST_RECENT_DONGLE_DRIVER_VERSION! installed on the system. Installed driver is !DONGLE_DRIVER_PKG_VERSION!.   >> %REPORT_LOGFILE% 2>&1
		)
		if defined DONGLE_DRIVER_UPDATE_TO781_BY_ATOS (
			echo     NOTE: There was a dongle driver update to version V7.81 at %DONGLE_DRIVER_UPDATE_TO781_BY_ATOS% provided by ATOS.  >> %REPORT_LOGFILE% 2>&1
		)
		if defined DONGLE_DRIVER_UPDATE_TO792_BY_ATOS (
			echo     NOTE: There was a dongle driver update to version V7.92 at %DONGLE_DRIVER_UPDATE_TO792_BY_ATOS% provided by ATOS.  >> %REPORT_LOGFILE% 2>&1
		)
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: No Dongle Driver installed. [1;37m
		) else (
			echo     ATTENTION: No Dongle Driver installed.
		)
		echo ATTENTION: No Dongle Driver installed.                                                                          >> %REPORT_LOGFILE% 2>&1

		if exist "%DOWNLOAD_LMS_PATH%\haspdinst.exe" (
			set TARGETFILE=%DOWNLOAD_LMS_PATH%\haspdinst.exe
			set TARGETFILE=!TARGETFILE:\=\\!
			wmic /output:%REPORT_WMIC_LOGFILE% datafile where Name="!TARGETFILE!" get Manufacturer,Name,Version  /format:list
			IF EXIST "%REPORT_WMIC_LOGFILE%" for /f "tokens=2 delims== eol=@" %%i in ('type %REPORT_WMIC_LOGFILE% ^|find /I "Version"') do set "haspdinstVersion=%%i"
			echo     Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!
			echo Dongle driver: %DOWNLOAD_LMS_PATH%\haspdinst.exe [!haspdinstVersion!] available!                            >> %REPORT_LOGFILE% 2>&1
			if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
				rem install dongle driver downloaded by this script
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    --- Install newest dongle driver !haspdinstVersion! just downloaded by this script. [1;37m
				) else (
					echo     --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.
				)
				echo --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.                     >> %REPORT_LOGFILE% 2>&1
				start "Install dongle driver" "%DOWNLOAD_LMS_PATH%\haspdinst.exe" -install -killprocess
				echo --- Installation started in an own process/shell.                                                       >> %REPORT_LOGFILE% 2>&1
			) else (
				rem show message to install dongle driver downloaded by this script
				if defined SHOW_COLORED_OUTPUT (
					echo [1;31m    --- Install newest dongle driver !haspdinstVersion! just downloaded by this script. [1;37m
					echo [1;31m    --- Execute '"%DOWNLOAD_LMS_PATH%\haspdinst.exe" -install -killprocess' with administrator priviledge. [1;37m
				) else (
					echo     --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.
					echo     --- Execute '"%DOWNLOAD_LMS_PATH%\haspdinst.exe" -install -killprocess' with administrator priviledge.
				)
				echo --- Install newest dongle driver !haspdinstVersion! just downloaded by this script.                     >> %REPORT_LOGFILE% 2>&1
				echo --- Execute '"%DOWNLOAD_LMS_PATH%\haspdinst.exe" -install -killprocess' with administrator priviledge.  >> %REPORT_LOGFILE% 2>&1
			)
		)
	)
)
if defined ALM_VERSION_STRING (
	echo ALM: %ALM_VERSION_STRING% [%ALM_VERSION%] - %ALM_RELEASE% [%ALM_TECH_VERSION%]                                  >> %REPORT_LOGFILE% 2>&1
) else (
	echo No ALM installed.                                                                                               >> %REPORT_LOGFILE% 2>&1
)
if defined BTALMPLUGINVersion (
	echo Installed BT ALM Plugin Version: !BTALMPLUGINVersion!                                                           >> %REPORT_LOGFILE% 2>&1
	if "!BTALMPLUGINVersion!" == "!MOST_RECENT_BT_ALM_PLUGIN!" (
		echo     Most recent BT ALM plugin !MOST_RECENT_BT_ALM_PLUGIN! installed on the system.                          >> %REPORT_LOGFILE% 2>&1
	) else (
		echo     There is not the most recent BT ALM plugin !MOST_RECENT_BT_ALM_PLUGIN! installed on the system.         >> %REPORT_LOGFILE% 2>&1
	)
)
if not defined LMS_CHECK_ID (
	if not defined backuppath (
		echo No Backup path defined!                                                                                     >> %REPORT_LOGFILE% 2>&1
	)
)
if not defined LMS_CHECK_ID (
	rem This part is not processed written to logfile if /checkid is set!
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	if /I !FIPS_MODE_ENABLED! NEQ 0 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: FIPS mode is ENABLED. [1;37m
		) else (
			echo     WARNING: FIPS mode is ENABLED.
		)
		echo WARNING: FIPS mode is ENABLED.                                                                                  >> %REPORT_LOGFILE% 2>&1
	) else (
		echo INFO: FIPS mode is NOT enabled.                                                                                 >> %REPORT_LOGFILE% 2>&1
	)
	if defined NON_STANDARD_OS_LANGUAGE (
		rem Non standard OS language (1031, 1033) found
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    WARNING: The OS language !OS_LANGUAGE! is not a - per default - supported language. [1;37m
		) else (
			echo     WARNING: The OS language !OS_LANGUAGE! is not a - per default - supported language.
		)
		echo WARNING: The OS language !OS_LANGUAGE! is not a - per default - supported language.                             >> %REPORT_LOGFILE% 2>&1
	) else (
		echo INFO: The OS language !OS_LANGUAGE! is a fully supported language.                                              >> %REPORT_LOGFILE% 2>&1
	)
	if defined NON_STANDARD_LOCAL_LANGUAGE (
		rem Non standard local language (1031, 1033) found
		if defined SHOW_COLORED_OUTPUT (
			echo [1;33m    The local language !LOCAL_LANGUAGE! is not a - per default - supported language. [1;37m
		) else (
			echo     WARNING: The local language !LOCAL_LANGUAGE! is not a - per default - supported language.
		)
		echo WARNING: The local language !LOCAL_LANGUAGE! is not a - per default - supported language.                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo INFO: The local language !LOCAL_LANGUAGE! is a fully supported language.                                        >> %REPORT_LOGFILE% 2>&1
	)
)
if defined TS_BROKEN (
	echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
	if defined TS_BROKEN_AFTER_REPAIR (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Trusted Store is still BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE! [1;37m
		) else (
			echo     ATTENTION: Trusted Store is still BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!
		)
		echo ATTENTION: Trusted Store is still BROKEN. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!                  >> %REPORT_LOGFILE% 2>&1
	) else (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Trusted Store was BROKEN, but has been FIXED. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE! [1;37m
		) else (
			echo     ATTENTION: Trusted Store was BROKEN, but has been FIXED. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!
		)
		echo ATTENTION: Trusted Store was BROKEN, but has been FIXED. Time Flag=!TS_TF_TIME! / Host Flag=!TS_TF_HOST! / Restore Flag=!TS_TF_RESTORE!   >> %REPORT_LOGFILE% 2>&1
	)
)
if defined TS_DISABLED (
	echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
	if defined SHOW_COLORED_OUTPUT (
		echo [1;31m    Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT! [1;37m
	) else (
		echo     ATTENTION: Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT!
	)
	echo ATTENTION: Disabled licenses found. Disabled=!TS_DISABLED_COUNT! of !TS_TOTAL_COUNT!                            >> %REPORT_LOGFILE% 2>&1
)
if defined PROC_STOPPED (
	echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
	if /I !PROC_STOPPED! NEQ 0 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: !PROC_STOPPED! relevant services are stopped. [1;37m
		) else (
			echo     ATTENTION: !PROC_STOPPED! relevant services are stopped.
		)
		echo ATTENTION: !PROC_STOPPED! relevant services are stopped.                                                    >> %REPORT_LOGFILE% 2>&1
	)
	if /I !PROC_FOUND! NEQ 4 (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: Only !PROC_FOUND! relevant services found. [1;37m
		) else (
			echo     ATTENTION: Only !PROC_FOUND! relevant services found.
		)
		echo ATTENTION: Only !PROC_FOUND! relevant services found.                                                       >> %REPORT_LOGFILE% 2>&1
	) else (
		echo INFO: All !PROC_FOUND! relevant services found.                                                             >> %REPORT_LOGFILE% 2>&1
	)
)
if defined LMS_SSU_CONSISTENCY_CHECK (
	echo -------------------------------------------------------                                                         >> %REPORT_LOGFILE% 2>&1
	if /I !LMS_SSU_CONSISTENCY_CHECK! NEQ 0 (
		echo SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!                          >> %REPORT_LOGFILE% 2>&1
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing! [1;37m
		) else (
			echo     ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!
		)
		echo ATTENTION: SSU - Installation is NOT consistent, !LMS_SSU_CONSISTENCY_CHECK! file[s] missing!               >> %REPORT_LOGFILE% 2>&1
	) else (
		echo SSU - Installation is consistent, NO file missing in %ProgramFiles%\Siemens\SSU\bin\                        >> %REPORT_LOGFILE% 2>&1
	)
)
if defined TS_LOG_START_DATE (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo FlexeraDecryptedEventlog.log contains data from start date: !TS_LOG_START_DATE! till end date: !TS_LOG_END_DATE!    >> %REPORT_LOGFILE% 2>&1
	if defined TS_LOG_TRANS_BRK_FOUND (
		echo ATTENTION: "Transient break" [Event: 40000012] found - !TS_LOG_TRANS_BRK_FOUND!                                 >> %REPORT_LOGFILE% 2>&1
		echo            Started at !TS_LOG_TRANS_BRK_FOUND_START_DATE! till !TS_LOG_TRANS_BRK_FOUND_END_DATE!                >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_VAL1_FOUND (
		echo ATTENTION: "Transient break in Anchoring" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL1_FOUND!               >> %REPORT_LOGFILE% 2>&1
		echo            Started at !TS_LOG_TRANS_BRK_VAL1_FOUND_START_DATE! till !TS_LOG_TRANS_BRK_VAL1_FOUND_END_DATE!      >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_VAL2_FOUND (
		echo ATTENTION: "Transient break in Binding" [Event: 40000012] found - !TS_LOG_TRANS_BRK_VAL2_FOUND!                 >> %REPORT_LOGFILE% 2>&1
		echo            Started at !TS_LOG_TRANS_BRK_VAL2_FOUND_START_DATE! till !TS_LOG_TRANS_BRK_VAL2_FOUND_END_DATE!      >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_BAD_ANCH_FOUND (
		echo ATTENTION: !TS_LOG_BAD_ANCH_FOUND_MESSAGE!                                                                      >> %REPORT_LOGFILE% 2>&1
		echo            Started at !TS_LOG_BAD_ANCH_FOUND_START_DATE! till !TS_LOG_BAD_ANCH_FOUND_END_DATE!                  >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_ANCH_NOT_FOUND (
		echo ATTENTION: "Anchor not available" [Event: 1000000d] found - !TS_LOG_ANCH_NOT_FOUND!                             >> %REPORT_LOGFILE% 2>&1
		echo            Started at !TS_LOG_ANCH_NOT_FOUND_START_DATE! till !TS_LOG_ANCH_NOT_FOUND_END_DATE!                  >> %REPORT_LOGFILE% 2>&1
	)
	rem binding identities: ANCHORS (Validator=1)
	rem    Value 1 (0x1) Track Zero; Value 2 (0x2) Registry
	if defined TS_LOG_TRANS_BRK_TRACKZERO_FOUND (
		echo ATTENTION: TRACK ZERO anchor break detected. - Value 1 [0x1] Track Zero - !TS_LOG_TRANS_BRK_TRACKZERO_FOUND!    >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_REGISTRY_FOUND (
		echo ATTENTION: REGISTRY anchor break detected. - Value 2 [0x2] Registry - !TS_LOG_TRANS_BRK_REGISTRY_FOUND!         >> %REPORT_LOGFILE% 2>&1
	)
	rem binding identities: BINDING (Validator=2)
	rem    Value 1 (0x1) System; Value 2 (0x2) Hard Disk; Value 3 (0x3) Display; Value 4 (0x4) Bios; Value 5 (0x5) CPU; Value 6 (0x6) Memory; Value 7 (0x7) Ethernet; 
	rem    Value 13 (0xd) Publisher; Value 14 (0xe) VMID; Value 16 (0x10) GENID; Value 17 (0x11) TPMID
	if defined TS_LOG_TRANS_BRK_SYSTEM_FOUND (
		echo ATTENTION: SYSTEM binding break detected. - Value 1 [0x1] System - !TS_LOG_TRANS_BRK_SYSTEM_FOUND!              >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_HARDDISK_FOUND (
		echo ATTENTION: HARD DISK binding break detected. - Value 2 [0x2] Hard Disk - !TS_LOG_TRANS_BRK_HARDDISK_FOUND!      >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_DISPLAY_FOUND (
		echo ATTENTION: DISPLAY binding break detected. - Value 3 [0x3] Display - !TS_LOG_TRANS_BRK_DISPLAY_FOUND!           >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_BIOS_FOUND (
		echo ATTENTION: BIOS binding break detected. - Value 4 [0x4] Bios - !TS_LOG_TRANS_BRK_BIOS_FOUND!                    >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_CPU_FOUND (
		echo ATTENTION: CPU binding break detected. - Value 5 [0x5] CPU - !TS_LOG_TRANS_BRK_CPU_FOUND!                       >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_MEMORY_FOUND (
		echo ATTENTION: MEMORY binding break detected. - Value 6 [0x6] Memory - !TS_LOG_TRANS_BRK_MEMORY_FOUND!              >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_ETHERNET_FOUND (
		echo ATTENTION: ETHERNET binding break detected. - Value 7 [0x7] Ethernet - !TS_LOG_TRANS_BRK_ETHERNET_FOUND!        >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_PUBLSIHER_FOUND (
		echo ATTENTION: PUBLISHER binding break detected. - Value 13 [0xd] Publisher - !TS_LOG_TRANS_BRK_PUBLSIHER_FOUND!    >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_VMID_FOUND (
		echo ATTENTION: VMID binding break detected. - Value 14 [0xe] VMID - !TS_LOG_TRANS_BRK_VMID_FOUND!                   >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_GENID_FOUND (
		echo ATTENTION: VM GENID binding break detected. - Value 16 [0x10] GENID - !TS_LOG_TRANS_BRK_GENID_FOUND!            >> %REPORT_LOGFILE% 2>&1
	)
	if defined TS_LOG_TRANS_BRK_TPMID_FOUND (
		echo ATTENTION: TPMID binding break detected. - Value 17 [0x11] TPMID - !TS_LOG_TRANS_BRK_TPMID_FOUND!               >> %REPORT_LOGFILE% 2>&1
	)
)
if defined HealthCheckOk (
	echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
	echo Trusted Store HealthCheck Passed: !HealthCheckOk!                                                                   >> %REPORT_LOGFILE% 2>&1
	echo Trusted Store needs Repair:       NeedRepairAll=%NeedRepairAll% / NeedRepair=%NeedRepair%                           >> %REPORT_LOGFILE% 2>&1
	echo UMN Check Status:                 %UMN_CHECK_STATUS%                                                                >> %REPORT_LOGFILE% 2>&1
	echo VM Detection Check Status:        %VM_DETECTION_CHECK_STATUS%                                                       >> %REPORT_LOGFILE% 2>&1
	if /I !LMS_BUILD_VERSION! GEQ 681 (
		if defined LMS_LMUTOOL (
			echo -------------------------------------------------------                                                     >> %REPORT_LOGFILE% 2>&1
			"!LMS_LMUTOOL!" /LOG:"UMN1=!UMN1! / UMN2=!UMN2! / UMN3=!UMN3! / UMN4=!UMN4! / UMN5=!UMN5!"                       >> %REPORT_LOGFILE% 2>&1
			if defined VM_FAMILY (
				"!LMS_LMUTOOL!" /LOG:"VM_FAMILY=!VM_FAMILY! / VM_NAME=!VM_NAME! / VM_UUID=!VM_UUID! / VM_GENID=!VM_GENID!"   >> %REPORT_LOGFILE% 2>&1
			)
		) else (
			echo     LmuTool is not available with LMS !LMS_VERSION!, cannot perform operation.                              >> %REPORT_LOGFILE% 2>&1 
		)
	)
)
echo -------------------------------------------------------                                                             >> %REPORT_LOGFILE% 2>&1
if defined NUM_OF_INSTALLED_SW_FROM_SIEMENS (
	rem check bumber of installed siemens software, see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/822161
	if /I !NUM_OF_INSTALLED_SW_FROM_SIEMENS! GEQ !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1! (
		if defined SHOW_COLORED_OUTPUT (
			echo [1;31m    NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation. [1;37m
		) else (
			echo     NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation.
		)
		echo NOTE: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_1!. This will cause problems during activation.              >> %REPORT_LOGFILE% 2>&1
	) else (
		if /I !NUM_OF_INSTALLED_SW_FROM_SIEMENS! GEQ !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2! (
				if defined SHOW_COLORED_OUTPUT (
					echo [1;33m    WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation. [1;37m
				) else (
					echo     WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation.
				)
				echo WARNING: The number of installed Siemens software is !NUM_OF_INSTALLED_SW_FROM_SIEMENS! and exceeds the limit of !NUM_OF_INSTALLED_SW_FROM_SIEMENS_LIMIT_2!. This may cause problems during activation. >> %REPORT_LOGFILE% 2>&1
		)
	)
)
if /I !LMULOG_FILESIZE! GEQ !LOG_FILESIZE_LIMIT! (
	echo     ATTENTION: Filesize of LMU.log with !LMULOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!            >> %REPORT_LOGFILE% 2>&1
)
if /I !SIEMBTLOG_FILESIZE! GEQ !LOG_FILESIZE_LIMIT! (
	echo     ATTENTION: Filesize of SIEMBT.log with !SIEMBTLOG_FILESIZE! bytes, is exceeding critical limit of !LOG_FILESIZE_LIMIT! bytes!      >> %REPORT_LOGFILE% 2>&1
)
echo ==============================================================================                                                             >> %REPORT_LOGFILE% 2>&1
echo Report end at !DATE! !TIME!, report started at !LMS_REPORT_START! ....                                                                     >> %REPORT_LOGFILE% 2>&1

rem save (single) report in full report file
Type %REPORT_LOGFILE% >> %REPORT_FULL_LOGFILE%

rem copy default logfile to specified <LMS_LOGFILENAME>
if defined LMS_LOGFILENAME (
	Type %REPORT_LOGFILE% >> !LMS_LOGFILENAME!
)

if not defined LMS_CHECK_ID (
	set LMS_BALLOON_TIP_TITLE=CheckLMS Script
	set LMS_BALLOON_TIP_TEXT=Script CheckLMS ended, on %COMPUTERNAME% with LMS Version !LMS_VERSION!, see %REPORT_LOGFILE%. Send this log file togther with zipped archive of !REPORT_LOG_PATH! to your local system supplier. 
	set LMS_BALLOON_TIP_ICON=Information
	powershell -Command "[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $objNotifyIcon=New-Object System.Windows.Forms.NotifyIcon; $objNotifyIcon.BalloonTipText='!LMS_BALLOON_TIP_TEXT!'; $objNotifyIcon.Icon=[system.drawing.systemicons]::!LMS_BALLOON_TIP_ICON!; $objNotifyIcon.BalloonTipTitle='!LMS_BALLOON_TIP_TITLE!'; $objNotifyIcon.BalloonTipIcon='None'; $objNotifyIcon.Visible=$True; $objNotifyIcon.ShowBalloonTip(5000);"
	if defined LMS_SCRIPT_RUN_AS_ADMINISTRATOR (
		EVENTCREATE /T INFORMATION /L Siemens /so CheckLMS /ID 302 /D "!LMS_BALLOON_TIP_TEXT!"  >nul 2>&1
	)
)

:create_archive
echo Script finished!                  >> %REPORT_LOGFILE% 2>&1
echo End at !DATE! !TIME! ....         >> %REPORT_LOGFILE% 2>&1
rem ----- avoid access to the main logfile after ths line -----

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
			if defined SHOW_COLORED_OUTPUT (
				echo [1;33m    be patient, the upload of the archive requires some time, up to several hours [1;37m
			) else (
				echo    be patient, the upload of the archive requires some time, up to several hours
			)
			echo     start upload '!REPORT_LOGARCHIVE!' to '!CHECKLMS_PUBLIC_SHARE!' at !DATE! !TIME! ...
			xcopy "!REPORT_LOGARCHIVE!" "!CHECKLMS_PUBLIC_SHARE!" /Y /H /I                     >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo     ... '!REPORT_LOGARCHIVE!' copied to '!CHECKLMS_PUBLIC_SHARE!'!            >> !CHECKLMS_REPORT_LOG_PATH!\zip_logfile_archive.log 2>&1
			echo     ... copied to '!CHECKLMS_PUBLIC_SHARE!' at !DATE! !TIME!!
		)
		echo .
		echo .
		echo ... finished, see '!REPORT_LOGARCHIVE!'!
	) else (
		echo .
		echo .
		echo ... finished, see '%REPORT_LOGFILE%'!
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
	
	exit
)
