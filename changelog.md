```
rem
rem CheckLMS.bat ChangeLog
rem
rem Changelog:
rem     24-Jul-2018: 
rem        - Initial version
rem     25-Jul-2018:
rem        - add start/end timestamp to report
rem        - add list of installed products (can be used to check VC++ redistributable)
rem     26-Jul-2018
rem        - Add list of installed VC++ redistributable binaries
rem        - Add list of registered products (to receive update notifications)
rem        - Add extracts of available logfiles
rem        - Add read-out of windows event log
rem     27-Jul-2018
rem        - Limit number of rows copied from windows event log
rem        - Increase number of events in dedicated windows event log files (new 2000 events per file)
rem        - Read 'LMS Notifications Report'
rem     28-Jul-2018
rem        - Check that target log path exists
rem        - Wait to press <enter> at the end
rem        - Mark copied log files (add a note that these files are copied)         
rem     28-Jul-2018 (LMS 2.2.714)
rem        - Final version, to be integrated into LMS 2.2.714 (see BTQ00315192)
rem     31-Jul-2018:
rem        - Add further ALM logfile (alm_service_log)
rem     02-Aug-2018:
rem        - Add calls to appactutil.exe
rem        - Add setting for local license server (incl. message to adapt if default configuration has changed)
rem        - Add content of local servered certificates (C:\ProgramData\Siemens\LMS\Certificates)
rem     03-Aug-2018 (LMS 2.2.715)
rem        - Final version, to be integrated into LMS 2.2.715 (see BTQ00315503)
rem     04-Aug-2018:
rem        - Add content of SSU database folder
rem        - search and type LMS setup logfile (LMSSetup.log)
rem        - search for further setup logfiles (e.g. from XWP, ABT, Desigo CC)
rem     07-Aug-2018:
rem        - Analyze installed/available server certificates
rem        - Handle spaces correct in LMS setup logfiles and path to certificates (local & server)
rem        - Add LMU powershell command to read LMS version & deployment
rem     08-Aug-2018:
rem        - Adjust order of checks, to have "clear" sections
rem        - Add "Siemens Software Updater" to be read from windows event log
rem        - Analyze content of backup folder (configured in LmuSettings)
rem     09-Aug-2018:
rem        - Add content of trusted store folder
rem        - Supress error message during deltion of help log-files
rem        - Add tracer route (tracert) for LMS production server
rem        - Add check function for (at least) one trusted store feature
rem     10-Aug-2018:
rem        - Check if a log-file exists (prevent from throwing an error)
rem        - Add extract of scheduled tasks
rem        - Add version information from Flexera (servercomptranutil.exe –version)
rem     13-Aug-2018:
rem        - Check availablity of Flexera tools
rem        - Check that at least one feature exists to test, otherwise print error message.
rem        - Check existence of LMS backup path
rem        - Check that at least one [LMSSetup.log] has been found
rem        - Add check for certficate & server certifcate feature (similar like already done for TS feature)
rem     14-Aug-2018:
rem        - Further check availablity of Flexera tools (appactutil.exe, lmhostid.exe)
rem        - Adjust "file not found" message (add 4 spaces)
rem        - Read-out and check remote server settings
rem        - Add check for existence of files used in for loop (for /F), avoid error messages in case nothing has been found
rem     15-Aug-2018:
rem        - Final version, to be integrated into LMS 2.2.720 (see BTQ00315644)
rem     17-Aug-2018:
rem        - Slightly adapt output for host id's (in case command doesn't exist)
rem        - Add server view commands for configured license server
rem        - Add (almost) complete list of get-LMS command [-Csid],[-LastDir],[-DsPath],[-CertPath],[-Token],[-IsVM],[-Deployment],
rem          [-CanNotify],[-NotificationPeriod],[-SystemId],[-TransferFolder],[-IsSiembtReady],[-CultureId],[-AppMode],[-LMSVersion]
rem        - Add NETSTAT [-a] [-b] [-e] [-f] [-o] [-r] [-s] [-x] [-t] output
rem        - Add task list (process information)
rem        - Check test files for FNC & SSU agents
rem        - Ignore Dummy_valid_feature for feature check (as this doesn't work through LEL)
rem     18-Aug-2018:
rem        - Final version, to be integrated into LMS 2.2.720 (see BTQ00316058)
rem     21-Aug-2018:
rem        - Add further information of (old) FNC agents (update.ini)
rem     30-Aug-2018:
rem        - List ALL programs (https://community.spiceworks.com/topic/647939-show-all-programs-using-wmic-command)
rem          Problem: wmic unfortunately doesn't show all the programs installed on the pc, it only show some of the programs.
rem          That command uses the Win32_Product class, which according to MS (http://msdn.microsoft.com/en-us/library/aa394378%28VS.85%29.aspx?), only "represents products as they are installed by Windows Installer."?
rem          The venerable "Uninstall" key in the registry is the be-all/end-all of installed software.  
rem          You can do this at the Command Prompt using:?          
rem               reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /B ".*DisplayName"
rem               reg query "??HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /B ".*DisplayName"? (Wow6432Node for capturing 32-bit programs)
rem          or Powershell
rem               gp HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString |ogv
rem     06-Sep-2018:
rem        - Check if Desigo CC (GMS) is installed on the system
rem        - Read installed GMS Version
rem        - Read list of installed Extensions Modules (EM) of Desigo CC (from registry), use HKLM\Software\Siemens\Siemens_GMS\EM
rem        - Limit output for configured backup path (in case somebody configures root folder, e.g. <BackupRestorePath>D:\</BackupRestorePath>)
rem     14-Sep-2018:
rem        - Add new PowerShell command to get LMS application state (see BTQ00317299)
rem        - Change lms configuration read-out (use /?? instead decryption function)
rem        - Add new line after SSU and FNC test file
rem        - Add system reboot time
rem        - Track/log also LmuTool.profile
rem        - Add user id for SSU client (used in FNC cloud to identify SSU client)
rem        - Clean-up usage of LmuTool, use LMS_LMUTOOL
rem        - Call LmuTool from both bin directories (32-bit & 64-bit)
rem        - Display environment variables (using set command)
rem        - Final version, to be integrated into LMS 2.2.721 (see BTQ00316140)
rem        **** "CheckLMS Script 14-Sep-2018" integrated into LMS 2.2.721 ****
rem 
rem     19-Sep-2018:
rem        - Improve output of hostnames/hostids 
rem        - Add LmuTool /F output
rem     20-Sep-2018:
rem        - Add "wmic baseboard get manufacturer, product, Serialnumber, version"
rem     01-Oct-2018:
rem        - Check where servercomptranutil is installed; it seem on Win7 machines it get installed on "C:\Program Files\Siemens\LMS\server" and not as on all other systems on "C:\Program Files (x86)\Siemens\LMS\server"
rem     04-Oct-2018:
rem        - Add TS diagnostic tool, to decrypt Flexera log-file
rem     15-Oct-2018:
rem        - Read version of installed FNP licensing service(s)
rem     16-Oct-2018:
rem        - Download SiemensFNP-11.16.0.0-Distr01 and unpack them
rem     17-Oct-2018:
rem        - Download SiemensFNP-11.16.0.0-Distr02 and unpack them
rem        - Improve behavior in case a flexera tool is not available
rem        - Include tsreset_svr.exe (support executiuon from downloaded package)
rem        - Support FNP 11.14.0.0 (used in LMS 2.1), download SiemensFNP-11.14.0.0-Distr01 and unpack them
rem        - Use for flexera tools a variable, try to match to correct path
rem     18-Oct-2018:
rem        - reduce hops on connection test from 30 to 15
rem     19-Oct-2018:
rem        - Adapt read of version of installed FNP licensing service(s) for 32-bit machines (Win7-32bit)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     26-Oct-2018:
rem        - Add summary section at the end of the log-file
rem        - Add repair command: servercomptranutil.exe -t 27000@localhost -repairAll 
rem     31-Oct-2018
rem        - Read installed .NET framework(s), see https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
rem     06-Nov-2018
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     13-Nov-2018
rem        - Adjust ouput of RepairAll command. Provide user input file (yes.txt) in case user input is requested by the RepairAll command.
rem        - Handle return value of findstr correct (see https://stackoverflow.com/questions/36237636/windows-batch-findstr-not-setting-errorlevel-within-a-for-loop)
rem        - Add further information to "wmic BIOS GET"
rem        - Add color to text output (http://www.robvanderwoude.com/ansi.php#AnsiColor) (works only on Win10)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     15-Nov-2018
rem        - Adjust output of download into logfile (especially in case download failed)
rem        - Add note to the Ref parameter (used for stored requests in trusted store)
rem        - Redirect output of servercomptranutil.exe -listRequests format=xml to an own logfile; don't add them to the common logfile anymore
rem        - Redirect tasklist in an own logfile; don't add them to the common logfile anymore
rem        - Add full ouput of wmic commands in own logfiles (for further analysis)
rem        - Detect Win10 version from registry (see https://stackoverflow.com/questions/31072543/reliable-way-to-get-windows-version-from-registry)
rem        - Print color ouput only on Win10
rem        - Add check for FLEXnet\Connect\Database\update.ini, to avaoid error message
rem        - Create separate file for output by servercomptranutil_healthCheck.txt (and add them to common logfile as well)
rem        - Analyze output of health check, provide summary message if check FAILED 
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     16-Nov-2018
rem        - Add LMU powershell command: powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -all}"
rem        - Add LMU powershell command: powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {Select-Product -report -upgrades}"
rem     17-Nov-2018
rem        - Read full list of installed software (from registry) with all attributes into separate log-file (check InstalledProgramsReport.log)
rem     21-Nov-2018
rem        - redirect servercomptranutil.exe -unique into a log-file
rem        - Evaluate available UMN (used for TS binding)
rem        - Extend summary section, list number of UMN used to bind TS; list all UMNs
rem     22-Nov-2018
rem        - Create UMN.txt to track UMN values over time; add at each execution one new line (with date and time)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     23-Nov-2018
rem        - Check FNP Version, execute for 11.14.0.0 only those commands which are available in this FNP version
rem        - Adjust logic for 11.14.0.0
rem        - Compare UMN results for the two commands
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     24-Nov-2018
rem        - Add UMN check status to summary section
rem        - Copy TS file to "final package"; the backup file contain less information. Use xcopy to ensure hidden files are also copied.
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     27-Nov-2018
rem        - Create a TS backup; keep previous backup(s)
rem     29-Nov-2018
rem        - Read BT ALM plugin version, with wmic
rem        - Add installed BT ALM plugin version to summary section
rem        - Add further ouptut from windows event log, for 'Automation License Manager API', 'Automation License Manager Service' & 'Service Control Manager'
rem     30-Nov-2018
rem        - change extract of windows event log; print first (and not last) lines (as newest entry is first in log-file)
rem        - Fix: List only major event log-files of flexera (do not consider files in sub-folders anymore)
rem     03-Dec-2018
rem        - Add check for most recent BT ALM plugin (e.g. 1.1.41.0, see https://wiki.siemens.com/display/en/LMS+-+Release+Overview)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     06-Dec-2018
rem        - Adapt output of servercomptranutil.exe -serverView & appactutil.exe -serverview; redirect into own log-files (for sub-sequent processing)
rem        - Support new FNP distribution: SiemensFNP-11.16.0.0-Distr03 (for FNP 11.16.0.0); add serveractutil.exe & appcomptranutil.exe
rem        - Add calls for serveractutil.exe (-view / -virtual / -repair / -served)
rem        - Add repair of fullfillments: (1) servercomptranutil.exe -t %LMS_LIC_SERVER% -repair FID_xxx / (2)appactutil.exe -repair FID_xxx / (3) serveractutil.exe -repair FID_xxx  
rem     19-Dec-2018
rem        - Remove decrypted config files (after they have been merged into common log-file)
rem     08-Jan-2019
rem        - Type ALM BT plugin configuration file; to allow to check content (and correct configuration)
rem     09-Jan-2019
rem        - Add directory output of Flexera command line tools (to be able to check that proper tools are used)
rem        - Add LMU powershell command: powershell -PSConsoleFile "%ProgramFiles%\Siemens\LMS\scripts\lmu.psc1" -command "& {(Select-Product -report -upgrades)[0].Maintenance}"
rem     10-Jan-2019
rem        - correct typo "W I D O W S" to "W I N D O W S" (credit to Andreas)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     15-Jan-2019
rem        - Support FNP kit 11.16.2.0 (SiemensFNP-11.16.2.0-Binaries.exe) to download from akamai download server
rem     17-Jan-2019
rem        - Run server view after repair command, to check if repair was successful
rem        - Add connection test to download server ( https://static.siemens.com/btdownloads/lms/ReadMe.txt )
rem        - Add call to decyrpt Flexera logfile to the log-file
rem     22-Jan-2019
rem        - Read-out installing product; with "get-lms -ProductName" and "get-lms -ProductVersion"
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     01-Apr-2019
rem        - Add list of attached dongles, using LmuTool.exe /DONGLES
rem        - Read-out "site value" for this system, using LmuTool.exe /SITEVALUE
rem        - Read-out "SUR expiration date" for this system, with LmuTool.exe /SUREDATE
rem        - Renamed LOG_FILE_LAST_LINES to LOG_FILE_LINES
rem     02-Apr-2019
rem        - Add list of services using powershell -command "& {Get-Service -Name *}"
rem          This allows to check for VM support, see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/Manage-Hyper-V-integration-services
rem        - Create servercomptranutil_virtual.txt, for further processing
rem        - Add summary of detected environment; either physical or virtual; and further details in case of virtual environment 
rem        - Print warning message in case "UNKNOWNVM" is found!
rem     03-Apr-2019
rem        - Add delimiter between certificate files within license_all_servercertificates.txt
rem        - Do not perform LmuTool /DONGLES & /SITEVALUE & /SUREDATE for LMS systems of version 2.1.610 and 2.2.721
rem        - Add check for LMS version; show note in case of deprecated versions.
rem     04-Apr-2019
rem        - Add VM detection evaluation also for lmvminfo and compare results with servercomptranutil (backward compatibility with FNP 11.14.x.x)
rem        - Log vm detection result and UMN summary to LMUPowerShell.log
rem        - Extend wmic DISKDRIVE command, to meet Flexera's expectation (wmic diskdrive get Name, Manufacturer, Model, InterfaceType, MediaType, SerialNumber)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     05-Apr-2019
rem        - Support info.txt; in case the file exists, the content is added to log-file (helps to keep track of different machines in a large system or test environment)
rem        - Add "wmic csproduct get UUID" (see https://www.nextofwindows.com/the-best-way-to-uniquely-identify-a-windows-machine)
rem        - Read machine GUID from HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MachineGuid
rem          Find the key called “MachineGuid” this key is generated uniquely during the installation of Windows and it won’t change regardless of any hardware swap 
rem          (apart from replacing the boot-able hard drive where the OS are installed on). That means if you want to keep tracking installation per OS this is another alternative. 
rem          It won’t change unless you do a fresh reinstall of Windows.) (see https://www.nextofwindows.com/the-best-way-to-uniquely-identify-a-windows-machine)
rem        - Analyze output of "servercomptranutil.exe -view format=long" and count untrusted trust flag (**BROKEN**)
rem        - Anaylze output of "servercomptranutil.exe -view format=long" for disabled licenses
rem        - Run LmuTool /LOG only on LMS versions 2.1.681 and higher
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     08-Apr-2019
rem        - List content of SiemensSoftwareUpdater.ini (in C:\ProgramData\Siemens\SSU)
rem     09-Apr-2019:
rem        - Support new windows event log used by SSU -> Windows Event Log: SSU ('SiemensSoftwareUpdater')
rem     10-Apr-2019:
rem        - Read "\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" to get version of installed VC++ redistributable package(s)
rem     15-Apr-2019:
rem        - Add PS command: Get-Module -ListAvailable -All; to retreive installed PS commandlets (see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-module?view=powershell-6)
rem     16-Apr-2019:
rem        - Added progress output to cmd box, for "retrieve LMS configuration" section
rem        - Determine range of FlexeraDecryptedEventlog.log; start & end date/time
rem        - Check decrypted flexera log-file, for "Transient break" (Event: 40000012)
rem        - Check decrypted flexera log-file, for "Bad Anchor" (Event: 20000020)
rem        - Check decrypted flexera log-file, for "Anchor not available" (Event: 1000000d)
rem     17-Apr-2019:
rem        - Beautify summary ouptut for FlexeraDecryptedEventlog.log analysis result
rem        - Extend wmic command: wmic csproduct get name,identifyingnumber,uuid (see https://communities.vmware.com/thread/582729)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     18-Apr-2019:
rem        - Retrieve list of drivers, using driverquery /FO list /v (see https://www.thewindowsclub.com/list-device-drivers-driverquery-command-prompt)
rem        - Download GetVMGenerationIdentifier.exe
rem     24-Apr-2019:
rem        - Support also appcomptranutil.exe
rem        - Read installed products and version (with wmic, for vendor=Siemens)
rem        - Adjust windows event log "Siemens" (instead of "SSU")
rem        - List relevant installed services (Siemens BT Licensing Server, FlexNet Licensing Service, FlexNet Licensing Service 64)
rem        - Add check that relevant services are running (and not stopped)
rem     25-Apr-2019:
rem        - retreive installation date of LMS client (and show them in summary)
rem     26-Apr-2019:
rem        - Add command to read firewall settings (netsh advfirewall firewall show rule name=all verbose)
rem        - Analyze configured firewall rules and check that LMS settings are available.
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     29-Apr-2019
rem        - Correct repair all command; use servercomptranutil.exe -n -t https://lms.bt.siemens.com/flexnet/services/ActivationService -repairAll
rem        - read configured FNO server from LmuTool configuration
rem        - Published on https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/778107
rem        - Published on https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/771031
rem        - Published on https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/700547
rem     30-Apr-2019
rem        - Check that decrypted files are available CsidCfg.dec & LicCfg.dec
rem     01-May-2019
rem        - Add fake activation, as additional connection test (using: servercomptranutil.exe -n -t https://lms.bt.siemens.com/flexnet/services/ActivationService -activate Some_fake_activation_id)
rem        - Collect user information
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     03-May-2019
rem        - Add date & time outputs, to track duration 
rem        - Handle user input during 'fake' activation, to prevent that script doesn't run through
rem        - Increase number of "lines" in yes.txt (from 100 to 500), to ensure that script also runs on large systems
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     04-May-2019
rem        - Retrieve information regarding system time (see https://superuser.com/questions/451018/how-can-i-query-an-ntp-server-under-windows)
rem          NOTE: W32TM Error 0x800705B4. W32TM Error 0x800705B4 occurs when the calling NTP Client program, W32TM in this case, can't connect to the destination time server, either because that time server isn't running NTP server software, or UDP port 123 is blocked on the server.
rem     13-May-2019
rem        - Add further traces to log duration of a command
rem     14-May-2019
rem        - Add further traces to log duration of a command (in section "L M S   C O N F I G U R A T I O N   F I L E S")
rem     17-May-2019
rem        - Add repair all command using LmuTool (LmuTool /REPALL /M:O)
rem     28-May-2019
rem        - Add a note to each line of UMN.txt, with which tool it was created
rem        - Add Windows Event Log: System ('hasplms')
rem        - Check and display "%LMS_HASPDRIVER_FOLDER%\lic_names.dat" and "%LMS_HASPDRIVER_FOLDER%\hasplm.ini"
rem     29-May-2019
rem        - Adjust output of "break information" due strange error. The ESC characters to display the text red were not working :-(
rem        - Handle case on virtual environments, where GENID is not available and reading them returns different error messages: (1) "GENID    Not available on this platform" and (2) "GENID: ERROR - Unavailable."
rem          Credit to Tongaonkar, Amogh (IOT DS AA SB CMS SYO PM) <amogh.tongaonkar@siemens.com>, see also https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/786742
rem     01-Jun-2019
rem        - use full instead of long for "serverView" in "servercomptranutil.exe -serverView %LMS_LIC_SERVER% format=full"
rem        - new collect informatiuon from "ipconfig /all"
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     03-Jun-2019
rem        - Remove duplicate call for windows event log entries for "SiemensSoftwareUpdater"
rem     04-Jun-2019
rem        - Check that dongle driver is running: hasplms - Sentinel LDK License Manager
rem        - Check that 4 services are running (Siemens BT Licensing Server, 2x FlexNet Licensing Service, Sentinel LDK License Manager)
rem        - Retrieve diagnostic information from dongle driver (http://localhost:1947/_int_/diagnostics.html) stored at %REPORT_LOG_PATH%\diagnostics.html
rem     06-Jun-2019
rem        - Add check to FNC cloud (http://updates.installshield.com/ClientInterfaces.asp)
rem        - Re-arrange ouptut in section "S O F T W A R E   U P D A T E   I N F O R M A T I O N"
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     12-Jun-2019
rem        - check validator: The numbers for the validator are either "1" (Validator=1) for anchoring or "2" (Validator=2) for binding.
rem     13-Jun-2019
rem        - Add command to read current ephemeral port range (netsh int ipv4 show dynamicport tcp)
rem          https://blogs.msdn.microsoft.com/drnick/2008/09/19/ephemeral-port-limits/
rem     16-Jul-2019
rem        - Check that dongle driver is installed; show warning message if driver is not installed
rem     19-Jul-2019
rem        - Copy LMSSetup.log files into common logfolder. Add a numrice value to its name, to dinstguish between different files.
rem        - Add check for most recent dongle driver installed on system. Currently: 7.92
rem        - Adapt check "less than 2.2.735" for static LMS version check
rem        - Call LMUTool /healthcheck (see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/798446)
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     20-Jul-2019
rem        - List content of "C:\ProgramData\Siemens\LMS\Requests\" (see PCR https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/804986 )
rem        - Upload this version to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        **** "CheckLMS Script 20-Jul-2019" integrated into LMS 2.2.737 ****
rem
rem     21-Jul-2019
rem        - Slightly adapt output of (local) certificates. Make the ouptut similar to server certificates output.
rem     23-Jul-2019
rem        - Read-out instalation count for dongle driver (HKLM\SOFTWARE\Aladdin Knowledge Systems\HASP\Driver\Installer\InstCount)
rem     24-Jul-2019
rem        - Count number of installed Siemens software, to avoid issue of exceeded request size
rem          see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/822161
rem        - Add check for ATOS updates provided by ATOS:
rem          - If a machine has been updated to V7.92 with the dongle driver provided by ATOS, you can see this under installed programs “Sentinel License Manager R01” (from “Gemalto” with Version “7.92.28470.60000”). It has been published at 16-Jul-2019.
rem          - If a machine has been updated to V7.81 with the dongle driver provided by ATOS, you can see this under installed programs “Sentinel Runtime R01” (from “Gemalto” with Version “7.81.20638.60000”). It has been published at 14-Feb-2019.
rem        - Adjust IF statement with /I with LEQ, GEQ and EQU (remove unecessary "-sign)
rem     26-Jul-2019
rem        - read-out more information of windows version (see https://stackoverflow.com/questions/14648796/currentversion-value-in-registry-for-each-windows-operating-system)
rem        - read-out "CurrentVersion" (see https://docs.microsoft.com/en-us/windows/win32/sysinfo/operating-system-version)
rem        - adjust logic of "colored" output in command window (set SHOW_COLORED_OUTPUT)
rem        - check LMS version for "field test version" (up to 2.2.736)
rem     31-Jul-2019:
rem        - Correct wrong handling of "end date" for transient breaks, like "Transient break in Anchoring" and "Transient break in Binding" (use correct variable: TS_LOG_TRANS_BRK_VAL1_FOUND_END_DATE)
rem     02-Aug-2019:
rem        - Add script build number (easier to check for newest script)
rem        - Adapt check for LMS build, use MOST_RECENT_LMS_BUILD
rem     02-Aug-2019:
rem        - Add download function of CheckLMS.exe (a self-extracting zip archive)
rem        - Populate new CheckLMS.bat script, as self-extracting CheckLMS.exe zip Archive on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS this makes them
rem          public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     06-Aug-2019:
rem        - Adjust behavior in case newer script is found. Stop current execution. save (single) report in full report file. Start newer script.
rem     08-Aug-2019:
rem        - adjust logic to retrieve script build number (avoid multiple matches)
rem        - Convert .NET version from hex to decimal
rem        - Add supoort for ".NET Framework 4.8"
rem        - Download of "newer" script tested and seems working.
rem          How to populate a new script:
rem            1. Update the CheckLMS.bat script, make sure to increase LMS SCRIPT BUILD variable.
rem            2. Create CheckLMS.exe as self-extracting ZIP archive, e.g. with 7zip (must support: CheckLMS.exe -y -o"%DOWNLOAD_LMS_PATH%\")
rem            3. Copy CheckLMS.exe to \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS
rem            4. After some time the update of akamai download cache has been performed and it is available via https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe
rem            5. Now each script with internet access, will download this script. In case it is newer then the executed script, it is automatically started.
rem     13-Aug-2019:
rem        - check "change items" in trace message for 7 (ETHERNET), 14 (VMID) and 16 (GENID)
rem     19-Aug-2019:
rem        - enhance check for "change items", based on feedback from Flexera in case #01899733
rem          binding identities: ANCHORS (Validator=1)
rem                Value 1 (0x1) Track Zero; Value 2 (0x2) Registry
rem          binding identities: BINDING (Validator=2)
rem                Value 1 (0x1) System; Value 2 (0x2) Hard Disk; Value 3 (0x3) Display; Value 4 (0x4) Bios; Value 5 (0x5) CPU; Value 6 (0x6) Memory; Value 7 (0x7) Ethernet; 
rem                Value 13 (0xd) Publisher; Value 14 (0xe) VMID; Value 16 (0x10) GENID; Value 17 (0x11) TPMID
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     20-Aug-2019:
rem        - Differentiate between status "=1" == "Changed" and "=2" == "IsNotAvailable"
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     21-Aug-2019:
rem        - Adjust errornous ouptut of anchor and binding breaks; based on tests done for https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/847931
rem          Script adapted, fixed in "21-Aug-2019":
rem          - Don't use "!" in echo output
rem          - Use correct text for TPM
rem          - Use correct serach pattern, add a space in front.
rem          - Adjust wrong "IF ERRORLEVEL" usage
rem            ==> IF ERRORLEVEL construction has one strange feature, that can be used to our advantage: it returns TRUE if the return code was equal to or higher than the specified errorlevel. 
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation (at 28-Aug-2019)
rem     29-Aug-2019:
rem        - Add new section "W I N D O W S   E R R O R   R E P O R T I N G  (W E R)"
rem        - Dump content of folder %LOCALAPPDATA%\CrashDumps
rem        - Copy known crash dumps to %REPORT_LOG_PATH%
rem        - Update message at the end, to display udpated information (https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/855731)
rem     09-Sep-2019:
rem        - Copy content of ALM logging folder (Automation License Manager\logging)
rem        - read "DumpType" from “HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps”
rem          >> add/change with regedit under “HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps” are REG_DOWRD subkey with name “DumpType” and value “2” 
rem          >> (see also https://docs.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps )
rem        - Change crash dump location to %REPORT_LOG_PATH%\CrashDumps\
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     10-Sep-2019:
rem        - Read crash dump folder only if it exists (it seems it is not available per default)
rem        - Search on c: for crash dump files and copy "known" files to LMS log folder.
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     12-Sep-2019:
rem        - Collect also SIEMBT crash dumps (e.g. SIEMBT.exe.6008.dmp)
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     13-Sep-2019:
rem        - copy full ALM folder: %ALLUSERSPROFILE%\Siemens\Automation\Automation License Manager\ 
rem        - copy full ALM folder: %ALLUSERSPROFILE%\Siemens\Automation\sws\
rem        - read-out windows event log (w/o query filter), limit to LOG_EVENTLOG_FULL_EVENTS events
rem     16-Sep-2019:
rem        - Add note, that 'servercomptranutil.exe -unique'  is equal to 'servercomptranutil.exe -umn'
rem        - enhance: wmic NIC get Description,MACAddress,NetEnabled,Speed,PhysicalAdapter,PNPDeviceID; with PhysicalAdapter and PNPDeviceID
rem     18-Sep-2019:
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     19-Sep-2019:
rem        - use "dir /X" instead of "dir" only, this displays the short names generated for non-8dot3 file names. See also issue https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/862137
rem        - Add specific output of tasklist for "lmgrd" and "SIEMBT"
rem     23-Sep-2019
rem        - Add more info to output of tasklist
rem        - Check existence of "C:\Program Files\Siemens\LMS\scripts\lmu.psc1"
rem     30-Sep-2019
rem        - See Win10: https://en.wikipedia.org/wiki/Windows_10_version_history
rem     01-Oct-2019
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on \\khed452a.ww004.siemens.net\webservices$\www\10330\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Distributed as part of LMS 2.3.743
rem     21-Oct-2019
rem        - Get signature status for SSU binaries (*.exe & *.dll)
rem        - Get signature status for LMS binaries (%ProgramFiles%\Siemens\LMS\bin, *.exe & *.dll)
rem        - Get signature status for LMS binaries (%ProgramFiles(x86)%\Siemens\LMS\bin, *.exe & *.dll)
rem     24-Oct-2019
rem        - Consider newest dongle driver 7.101 (https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/893661)
rem        - Add connection test to http://new.siemens.com/global/en/general/legal.html
rem     07-Nov-2019:
rem        - Add further exports from windows event log, mainly to collect information about (automatic) dongle driver installations, like Application ('MsiInstaller')
rem        - increase LOG_EVENTLOG_EVENTS from 2000 to 5000
rem     13-Nov-2019:
rem        - Set most recent dongle driver version to 7.102
rem        - Analyze content of aksdrvsetup.log (dongle driver setup logfile)
rem     15-Nov-2019:
rem        - Copy also crash dumps of SSU Manager
rem        - search for dongle drivers downloaded by ATOS on C:\ccmcache\
rem        - set MOST_RECENT_BT_ALM_PLUGIN to 1.1.42.0
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     20-Nov-2019:
rem        - Adapt output of number of installed Siemens software.
rem     21-Nov-2019:
rem        - Check for "Start Install" in dongle driver logfile
rem     26-Nov-2019:
rem        - Add "lmutil lmpath -status"
rem        - Add "nslookup %LicenseSrvName%" to connection test section (15-Jan-2020: renamed to LMS_CFG_LICENSE_SRV_NAME)
rem     05-Dec-2019:
rem        - Fix misuse of DATE (during analysis of dongle driver logfile)
rem     06-Dec-2019:
rem        - Adjust static check for supported LMS versions: Check: not 2.2.737 AND less or equal than 2.2.736  --> DEPRECATED (per Dec-2019)
rem        - set MOST_RECENT_LMS_BUILD=744
rem        - add output of several whoami commands: whoami /user  &  whoami /groups /fo list  &  whoami /all
rem     09-Dec-2019:
rem        - Add Windows Event Log: Application ('Automation License Manager API') (was part in the past, but seems to be lost)
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     11-Dec-2019:
rem        - Check for debug.log in SSU binary folder; if available, type its content
rem        - Copy debug.log file to %REPORT_LOG_PATH%\ssu_debug.log
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     12-Dec-2019:
rem        - Show "creation date" and "last write date" for debug.log
rem        - set MOST_RECENT_LMS_BUILD=745
rem        - Adjust output in case crash dumps are not enabled
rem        - Adjust ouput in case "No disabled licenses found."
rem     13-Dec-2019:
rem        - extract ERROR messages from SIEMBT.log
rem        - Move SIEMBT.log to FNP information section
rem     18-Dec-2019:
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        **** "CheckLMS Script 18-Dec-2019" integrated into LMS 2.3.745 ****
rem 
rem     15-Jan-2020:
rem        - Improve section with powershell commands, store return values in environment variables (ready for further processing)
rem        - FIX wrong culture id, set them accordignly (see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/948637 )
rem          The script supports GERMAN (1031) and ENGLISH (1033); in case of “unknown” culture id, it uses ENGLISH (1033) per default 
rem        - Add colored ouptut in green (https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line )
rem     16-Jan-2020:
rem        - Check for empty/invalid access token (see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/846744)
rem        - FIX empty/invalid access token, set to act_imhg05mh_dmg4ufrigv03
rem        - Add a check (and print a note) if default access token is used or not.
rem        - Add a check (and print a note) if installed product name is used or not.
rem     17-Jan-2020:
rem        - FIX wrong comparison of dongle driver version (e.g. 7.92 is considered as newer than 7.102)
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     27-Jan-2020:
rem        - Check if FIPS mode is enabled or not (see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/960858)
rem        - Print content of TEMP environment vriable (see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/960557)
rem     28-Jan-2020:
rem        - Adjust the output of "system boot time", as it depends on the OS language
rem        - Check OS language and show a warning message in case the OS language is not - per default - supported.
rem        - Search for further setup log-files, with name LMSSetupIS.log and LMSSetupMSI.log
rem        - Copy setup log-files new into subfolder %REPORT_LOG_PATH%\LMSSetupLogs\
rem        - Copy additonal log-files created by CheckLMS.bat script into subfolder %REPORT_LOG_PATH%\CheckLMSLogs\
rem        - Clean-up script to use variables to access log-file folder.
rem        - Create missing folder: %REPORT_LOG_PATH%\Automation\sws\
rem     30-Jan-2020:
rem        - corrret typo "deafult" -> "default"
rem        - search for LMS setup downloaded by ATOS on C:\ccmcache\
rem        - introduce CHECKLMS_ALM_PATH to store files from ALM
rem     31-Jan-2020:
rem        - Adjust that script runs also on systems w/o installed LMS
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     06-Feb-2020:
rem        - print-out the path for "where" and "find"; just for the case of path variable has been mixed-up (e.g. by cygwin installation)
rem     13-Feb-2020:
rem        - check if Siveillance Identity (SiID) is installed on the system
rem        - run "%programfiles%\Siemens\SiId\Siemens.SiId.Diagnostics.exe" and trace output in logfile
rem        - show content of "%programdata%\Siemens\SiId\Log\"
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     24-Feb-2020:
rem        - Support new FNP Version: 11.16.6.0, see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/957192
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     25-Feb-2020:
rem        - Call new LmuTool command: "LmuTool /cleants", see https://bt-clmserver01.hqs.sbt.siemens.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/969905
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     26-Feb-2020:
rem        - adjust ouptut text of VM GENID app
rem        - check registration of BT ALM plugin, and - if not registered - register them.
rem          NOTE: The script must run in administrator mode, to register the BT ALM plugin successful
rem     28-Feb-2020:
rem        - disable /cleants option (see "25-Feb-2020")
rem        - Make script runable on "none" valid LMS systems
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     02-Mar-2020:
rem        - check for existence of scheduled tasks
rem        - redirect output for errors (add  2>&1)
rem     10-Mar-2020:
rem        - add detail output of scheduled tasks "onStartup" (schtasks /query /FO LIST /V /tn "\Siemens\Lms\OnStartup")
rem     19-Mar-2020:
rem        - Add connection test for FNO server (https://lms.bt.siemens.com/flexnet/services/ActivationService , https://194.138.12.72/flexnet/services/ActivationService , https://158.226.135.60/flexnet/services/ActivationService )
rem     24-Mar-2020:
rem        - add "netsh firewall show state"
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.803 build (Sprint 2)
rem     25-Mar-2020:
rem        - add possibility to pass comand line options to script
rem        - add command line option /nouserinput; which disables any user input request
rem     30-Mar-2020:
rem        - read-out permission on LMS registry key
rem        - read-out permission on SSU registry key
rem     07-Apr-2020:
rem        - prepare for publishing newest script in LMS 2.4
rem        - add parameter "nowait" with same function as "nouserinput"
rem        - print-out %PROCESSOR_ARCHITECTURE% (near the machine name)
rem        - add command line option: logfilename
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.804 build (Sprint 3)
rem     08-Apr-2020:
rem        - optimize "netstat" section, allow to skip with option "skipnetstat" (because "netstat -a -f " took a long time to execute on some machines)
rem        - add lmstat -A; which "list all active licenses" (in additon to existing lmstat -a; which "display everything")
rem     09-Apr-2020:
rem        - use OS_LANGUAGE for system start time (instead of LMS_CFG_CULTUREID)
rem     17-Apr-2020:
rem        - add balloon tips when script starts and ends (as preparation for "window-less" execution), see https://stackoverflow.com/questions/50927132/show-balloon-notifications-from-batch-file
rem     20-Apr-2020:
rem        - set most recent dongle driver to 7.103 (for LMS 2.4)
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.805 build (Sprint 4)
rem     21-Apr-2020:
rem        - add detail output of scheduled tasks "WeeklyTask" (schtasks /query /FO LIST /V /tn "\Siemens\Lms\WeeklyTask")
rem     22-Apr-2020:
rem        - check administrator priviledge (see https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights)
rem        - pass command line options to checklms.bat script, in case newer script has been downloaded
rem     23-Apr-2020:
rem        - add message at the very end of the script (in case it has been run un-attended)
rem        - add EXIT command at the end, to close command window after script execution
rem        - add entries in windows event log (in case script runs with administrator priviledge)
rem     23-Apr-2020:
rem        - adjust final message send to ballon tips and windows event viewer
rem     30-Apr-2020:
rem        - support FNP 11.17.0.0 SDK: SiemensFNP-11.17.0.0-Binaries.exe
rem        - Requested to integrate into LMS 2.4.806 build (Sprint 5)
rem     06-May-2020:
rem        - analyze and extract output of "tsreset_svr.exe -logreport verbose" and "tsreset_app.exe -logreport verbose"
rem        - check for orphan anchors
rem     07-May-2020:
rem        - try to fix (remove) orphan anchors with "tsreset_svr.exe -anchors orphan" and "tsreset_app.exe -anchors orphan"
rem     13-May-2020:
rem        - add also output of "simple" servercomptranutil.exe -listRequests output (currently only format=long was executed)
rem     15-May-2020:
rem        - retrieve TS serial number, sequence number, machine identifier out of offline activation reqeust file
rem        - add the TS details to the summary at file end.
rem        - adjust final message, use "create support request https://support.industry.siemens.com/cs/my/src"
rem     18-May-2020:
rem        - enable /cleants command for LSM 2.4
rem        - rename "servercomptranutil_listRequests_XML.txt" to "servercomptranutil_listRequests.xml"
rem        - extract break information (StorageBreakInfo) from servercomptranutil_listRequests.xml and fake_id_request_file.xml 
rem        - introduce /skipcontest option, to skip connection test(s)
rem     19-May-2020:
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.808 build (Sprint 6)
rem     20-May-2020:
rem        - fix bug in connection test section
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.808 build (Sprint 6)
rem     04-Jun-2020:
rem        - use correct LMS build number when newer script get started.
rem        - option "donotstartnewerscript" introduced; don't start newer script even if available.
rem     05-Jun-2020:
rem        - add support for XWP, read installed version and list available logfiles
rem        - do nor process SIEMBT.log which exceeds critical limit
rem     10-Jun-2020:
rem        - add support for SiPass
rem     12-Jun-2020:
rem        - fix issue with SiPass registry key, which contains space (see https://stackoverflow.com/questions/16281185/read-registry-value-that-contains-spaces-using-batch-file/16282323 ) 
rem     15-Jun-2020:
rem        - fix issue with SiPass logfiles, copy all rolling files (SiServer-log-file.txt, SiServer-log-file.txt.1, SiServer-log-file.txt.2, ....)
rem        - add "goto" command line option to simplify testing of the script.
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     16-Jun-2020:
rem        - support ABT tool
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.810 build (Sprint 8)
rem     17-Jun-2020:
rem        - Add screen output in case products have been found.
rem     13-Jul-2020:
rem        - Adjust check for most recent dongle driver version (consider also major version)
rem        - set most recent dongle driver version to V8.11
rem        - extend version check for .NET framework, consdier "On Windows 10 May 2020 Update: 528372"
rem        - donwload newest dongle driver installer from download Link: https://static.siemens.com/btdownloads/lms/hasp/<version>/haspdinst.exe
rem     14-Jul-2020:
rem        - read-out registry property SkipALMBtPluginInstallation under key HKEY_LOCAL_MACHINE\SOFTWARE\Siemens\LMS 
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     22-Jul-2020:
rem        - Install dongle driver in case driver is not installed on the system.
rem     23-Jul-2020:
rem        - Check if DMA is installed on the machine, retreive some basic information about DMA
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.813 build (Sprint 10)
rem     24-Jul-2020:
rem        - Adjust LMS version check, consider LMS 2.4 (2.4.814)
rem        - run MainMenu.exe program with a command line parameter “/test” which generates the debugs including the LMU error messages (MainMenuUnitTest.txt). 
rem     27-Jul-2020:
rem        - Call hasp driver with option to supress dialog messages: haspdinst.exe -install -killprocess -cm
rem        - Check for "C:\MainMenuUnitTest.txt" and list them if available (as part of DMA product)
rem     28-Jul-2020:
rem        - remove "MainMenu.exe", support "Main.exe" only for DMA
rem        - use "start" command to launch "Main.exe"
rem        - start "Main.exe" (for DMA) in non-blocking state at script start, this allows them to create the debug output, which is processed at script end.
rem     29-Jul-2020:
rem        - start dongle driver installation in an own process/shell, to avoid that checklms script is blocked.
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     30-Jul-2020:
rem        - get file details for C:\MainMenuUnitTest.txt
rem        - copy C:\MainMenuUnitTest.txt to DMA log-folder
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     31-Jul-2020:
rem        - Finalize DMA; do no longer start Main.exe; instead write a (blue) message that end customer shall start main.exe manually and provide C:\MainMenuUnitTest.txt
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     03-Aug-2020:
rem        - Add "dotnet --info" to system information section
rem     04-Aug-2020:
rem        - Add enhanced connection test using known activation id
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.814 build (Sprint 11)
rem     11-Aug-2020 (was released as version "Script 04-Aug-2020":
rem        - Adjust LMS version check, consider LMS 2.4 (2.4.815)
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.4.815 build
rem        **** "CheckLMS Script 04-Aug-2020" integrated into LMS 2.4.815 ****
rem
rem     12-Aug-2020:
rem        - Adjust script version to "Script 12-Aug-2020"
rem     19-Aug-2020:
rem        - Add command to measure command execution time: powershell /command "Measure-Command {lmutool.exe /?}"
rem     25-Aug-2020:
rem        - start ssumanager (if available)
rem     31-Aug-2020:
rem        - check for consitency of SSU installation; are the files "icudtl.dat" and "v8_context_snapshot.bin" available? If NOT, write warning message
rem        - Retrieve time zone information (using 'powershell /command "Get-TimeZone"')
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     02-Sep-2020:
rem        - support and check for sentron powermanager installed on the system
rem        - retrieve and show registry key: HKLM:\SOFTWARE\Siemens\Siemens_GMS
rem     03-Sep-2020:
rem        - Execute: PowerShell $PSVersionTable as part of CheckLMS.bat
rem     07-Sep-2020:
rem        - Requested to integrate into LMS 2.5.816 build
rem     14-Sep-2020:
rem        - read version of installed SiID product, include diagnostic ouptut
rem        - Handle Flexera message "20000020" correct
rem     25-Sep-2020:
rem        - adjust output during "improved connection test", to avoid "The process cannot access the file because it is being used by another process" issue
rem        - add command to resend stored requests (mainly created due connection problems during activation and return of licenses): servercomptranutil.exe -transaction https://lms.bt.siemens.com/flexnet/services/ActivationService -stored request=all
rem        - re-run command "servercomptranutil.exe -listRequests" after resending all stored requests
rem        - Requested to integrate into LMS 2.5.817 build
rem     28-Sep-2020:
rem        - Add output of 'dir /S /A /X /4 /W "%TEMP%\SSU"'
rem        - Adjust all 'dir' commands accordignly, to align output format: use "/S /A /X /4 /W"
rem        - Add content of folder: "%ALLUSERSPROFILE%\Siemens\SSU\Logs"
rem        - Copy SSU setup log-file to common LMS log folder.
rem        - Copy SSU files new in an own subfolder: CHECKLMS_SSU_PATH
rem     29-Sep-2020:
rem        - Adjust MSI and SSU logfile search. Determine if MIS logfile is a SSU logfile.
rem        - Add connection test to OSD server: https://www.automation.siemens.com/softwareupdater/servertest.aspx and https://www.automation.siemens.com/swdl/servertest/
rem     30-Sep-2020:
rem        - Add start and end time to enhanced connection test.
rem        - Add message for enhanced connection test to summary (at logfile end)
rem     01-Oct-2020:
rem        - handle empty values correct, retrieved from offline request file. Fixes wrong "UMN Check Status: Failed" check!
rem     05-Oct-2020:
rem        - Added Connection Test to http://ip4only.me/api/ , to retrieve public IP address (see also http://ip4.me/)
rem     06-Oct-2020:
rem        - read installed software with 'wmic' command and deliver output as 'csv' (is better to pharse)
rem        - analyze installed software (csv file created above)
rem        - create separate ouptut file 'WMIC_Installed_SW_Report.log'
rem        - read-out registry key "HKLM\SOFTWARE\LicenseManagementSystem\IsInstalled" (is set to "1" if LMS has been installed by ATOS) (2nd package of lMS 2.4.815)
rem        - Requested to integrate into LMS 2.5.818 build
rem     07-Oct-2020:
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem     08-Oct-2020:
rem        - adjust ouptut of "enhanced connection test", redirect error output to logfile (2>&1)
rem        - provide input "y" to command "servercomptranutil.exe -t %LMS_FNO_SERVER% -stored request=all"
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.5.819 build (Sprint 17)
rem     20-Oct-2020:
rem        - Download https://download.sysinternals.com/files/Sigcheck.zip
rem        - Support 7z tool to unzip archives, installed by SSU: "C:\Program Files\Siemens\SSU\bin\7z.exe"
rem     21-Oct-2020:
rem        - extend signature check and use SigCheck tool
rem     23-Oct-2020:
rem        - use CHECKLMS_REPORT_LOG_PATH to store ip_address.txt
rem        - download https://www.7-zip.org/a/7zr.exe (7zip command line tool) 
rem        - create 7zip archive at the end of the script execution
rem     26-Oct-2020:
rem        - check for "_CheckLMS_ReadMe_.txt" in folder \\ch1w43110.ad001.siemens.net\ASSIST_SR_Attachements\CheckLMS
rem        - Copy ZIP archive to public CheckLMS share: \\ch1w43110.ad001.siemens.net\ASSIST_SR_Attachements\CheckLMS
rem        - support 7-zip tool installed locally ("%ProgramFiles%\7-Zip\7z.exe")
rem     28-Oct-2020:
rem        - add "netsh wlan show all"
rem        - add "Get-WindowsUpdateLog" (PowerShell command), move "%desktop%\WindowsUpdate.log" to CheckLMS report log path
rem        - add "Gpresult /R" and "Gpresult /H "GpresultUser.html""
rem        - add command line option /extend
rem        - disable 'system start' time, see output of 'systeminfo' further down
rem     29-Oct-2020:
rem        - Remove content from common log-file to maje them smaller, see below ....
rem        - do not include %CHECKLMS_REPORT_LOG_PATH%\InstalledProgramsReport.log in commen log anaymore
rem        - store 'whoami /groups /fo list' result in %CHECKLMS_REPORT_LOG_PATH%\whoami_groups.log
rem        - store 'whoami /all' result in %CHECKLMS_REPORT_LOG_PATH%\whoami_all.log
rem        - store 'Gpresult /R' result in %CHECKLMS_REPORT_LOG_PATH%\gpresult_r.log
rem        - store 'netsh wlan show all' result in %CHECKLMS_REPORT_LOG_PATH%\netsh_wlan.log
rem        - store the different results of netstat commands on separate log files, do not include them any longer in common log-file.
rem        - limit output of SSU crash file ('debug.log')
rem     03-Nov-2020:
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Requested to integrate into LMS 2.5.820 build (Sprint 18)
rem     06-Nov-2020:
rem        - Fixed typos in script: Retrieving Instead of Retrieveing; doesn't Instead of does't ((credit to Konrad)
rem     09-Nov-2020:
rem        - Download "ecmcommonutil.exe" (similar to "GetVMGenerationIdentifier.exe") from 'https://static.siemens.com/btdownloads/lms/FNP/ecmcommonutil.exe'
rem        - Execute in script the commands: ecmcommonutil.exe -l -f -d device; ecmcommonutil.exe -l -f -d net; ecmcommonutil.exe -l -f -d smbios; ecmcommonutil.exe -l -f -d vm
rem        - add powershell -c Get-WmiObject -class Win32_BIOS
rem        - consider "lmver.exe" from FNP toolkit
rem     10-Nov-2020:
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     13-Nov-2020:
rem        - Support "SiemensFNP-11.17.2.0-Binaries", as new FNP library for LMS 2.5
rem        - switch for FNP libraries from (self-extracting) EXE to ZIP; this allows to use "-spe" option, which "eliminate duplication of root folder for extract command"
rem          see also https://www.dotnetperls.com/7-zip-examples and https://sourceforge.net/p/sevenzip/discussion/45798/thread/8cb61347/?limit=25 
rem     14-Nov-2020:
rem        - Consider new dongle driver 8.13 in checklms script; download the driver new always to ensure that older driver gets overwritten
rem     17-Nov-2020:
rem        - Retrieve powershell version [using 'powershell -command "Get-Host"']
rem        - Retrieve powershell execution policy [using 'Get-ExecutionPolicy']
rem        - change powershell execution from "/command" to "-command"
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Requested to integrate into LMS 2.5.821 build (Sprint 19)
rem     25-Nov-2020:
rem        - adjust command window output at end during copying ZIP archive to internal share
rem        - Requested to integrate into LMS 2.5.822 build (Sprint 20)
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     02-Dec-2020:
rem        - Add some addtional command window output at start of script execution.
rem     03-Dec-2020:
rem        - clean-up logfiles created with older CheckLMS script
rem     10-Dec-2020:
rem        - collect “Bits Client” and “NetworkProfile” event log
rem        - extract SSU registry keys for HKLM and HKCU: \SOFTWARE\Siemens\SSU
rem     14-Dec-2020:
rem        - Adjust LMS version check, consider LMS 2.5 (2.5.823)
rem        - set MOST_RECENT_LMS_BUILD=823
rem        - Check: not 2.4.815 AND not 2.3.745 AND less or equal than 2.3.744  --> DEPRECATED (per Oct-2020)
rem     16-Dec-2020:
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Requested to integrate into LMS 2.5.823 build (Sprint 21)
rem
rem     07-Jan-2021:
rem        - Adjust LMS version check, consider LMS 2.5 (2.5.824)
rem        - corrected small typo "Measure exection"
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem        - Upload CheckLMS.bat to https://wiki.siemens.com/display/en/LMS%3A+How+to+check+LMS+installation
rem        - Requested to integrate into LMS 2.5.824 build (Sprint 21)
rem        - Move CheckLMS script (Version: 07-Jan-2021) under source control: https://github.com/ImfeldC/CheckLMS
rem     11-Jan-2021:
rem        - Check if newer CheckLMS.bat is available in C:\ProgramData\Siemens\LMS\Download (see task 1046557)
rem        - Create new download folder for download from github: !LMS_DOWNLOAD_PATH!\git\
rem     12-Jan-2021:
rem        - Support USBDeview tool (see task 1198261)
rem     13-Jan-2021: (see also 09-Nov-2020)
rem        - Consider “ecmcommonutil.exe” (V1.19) (see task 1200154)
rem        - Download "ecmcommonutil_1.19.exe" (similar to "GetVMGenerationIdentifier.exe") from 'https://static.siemens.com/btdownloads/lms/FNP/ecmcommonutil_1.19.exe'
rem        - Execute in script the commands: ecmcommonutil_1.19.exe -l -f -d device; ecmcommonutil_1.19.exe -l -f -d net; ecmcommonutil_1.19.exe -l -f -d smbios; ecmcommonutil_1.19.exe -l -f -d vm
rem     14-Jan-2021:
rem        - show message at file upload
rem        - add 'ping !COMPUTERNAME!' to connection test section
rem        - Retrieve content of %WinDir%\System32\Drivers\Etc folder (see task 1202358)
rem     15-Jan-2021:
rem        - investigate some suspect crash of CheckLMS.bat in case newer script is downloaded (seen on Christian's laptop)
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     16-Jan-2021:
rem        - rename "servercomptranutil_listRequests.xml" to "servercomptranutil_listRequests_XML.xml"
rem        - store information retrieved with -listrequests in separate files: servercomptranutil_listRequests_simple.xml and servercomptranutil_listRequests_long.xml
rem        - retrieve pending requests and store them in separate files; e.g. pending_req_41272.xml
rem     18-Jan-2021:
rem        - add script name and path to header output
rem        - consider script name (%0) when newer script is downloaded; do not replace script itself
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
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
rem        - improved output on clean/new machines, check existence of '!ALLUSERSPROFILE!\FLEXnet\'
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
rem        - use separate logfile for checkid: LMSStatusReport_!COMPUTERNAME!_checkid
rem     30-Mar-2021:
rem        - execute 'LmuTool.exe /MULTICSID' if LMS 2.5.816 or newer
rem     06-Apr-2021:
rem        - Skip download from akamai share, download of 'CheckLMS.exe' is no longer supported.
rem        - add output of registry key: 'HKLM:\SOFTWARE\Siemens\LMS'
rem        - add content of the three services (fnls, fnls64 and vd) of 'HKLM:\SYSTEM\CurrentControlSet\Services\'
rem        - collect vendor daemon specific values from SIEMBT in 'SIEMBTID.txt'
rem        - re-enable download from akamai share, download of 'CheckLMS.exe' is again supported.
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     07-Apr-2021:
rem        - add 'HKLM:\SYSTEM\CurrentControlSet\Services\hasplms'
rem     08-Apr-2021:
rem        - disable and re-enable scheduled tasks CheckID during normal script execution
rem        - add some enviornment variables to the output of Desigo CC section
rem        - reset installation counter of hasp driver, to make sure that dongle driver get removed, when using /removedongledriver option
rem        - Upload CheckLMS.exe on <internalshare>\bt\lms\CheckLMS public available on https://static.siemens.com/btdownloads/lms/CheckLMS/CheckLMS.exe 
rem     09-Apr-2021:
rem        - change exit behavior of several command line options, instead of exit goto end of script :script_end 
rem          (/checkdownload, /setfirewall, /installdongledriver, /removedongledriver, /setcheckidtask, /delcheckidtask, /startdemovd, /stopdemovd)
rem     12-Apr-2021:
rem        - check errorcode afetr download checklms from github, show approbiate message instead of real error code.
rem        - remove name of internal share name
rem        - added additional output to analyze issue during creation of offline activation request file
rem     14-Apr-2021:
rem        - retrieve content of !ProgramFiles!\Siemens\SSU\bin\
rem     15-Apr-2021:
rem        - add 'Start-Date' of SIEMBT.log to log-files
rem     16-Apr-2021:
rem        - add 'Start-Date' of demo VD to log-files
rem     20-Apr-2021:
rem        - set 2.6.830 as field test version
rem     23-Apr-2021:
rem        - retrieve listening ports from SIEMBT.log
rem     05-May-2021:
rem        - add support for Desigo Insight, read-out licenses registry key: HKLM\SOFTWARE\Landis & Staefa\Licenses
rem     18-May-2021:
rem        - remove temporary created powershell scripts (Task 1289686)
rem        - Store status of "CheckLMS_CheckID" scheduled task (Task 1294691)
rem        - replace at several places %-characters with !-charaters; as they would not work within IF expression (Task 1294840)
rem     19-May-2021:
rem        - set most recent lms field test version: 2.6.831 (per 20-May-2021)
rem     20-May-2021:
rem        - replace at further places %-characters with !-charaters; as they would not work within IF expression
rem     26-May-2021:
rem        - set most recent lms field test version: 2.6.832 (per 21-May-2021)
rem     28-May-2021:
rem        - re-arrange script start; check first for newer script and - in case avaiulable them - start the before running unzip commands.
rem        - adjust "reg query" command for products to avoid error message in windows command shell, if regitsr entry doesn't exist
rem     02-Jun-2021:
rem        - replace at further places %-characters with !-charaters; as they would not work within IF expression
rem        - check for presence of "!ProgramFiles!\Siemens\LMS\scripts\lmu.psc1" before executing powershell command
rem        - suppress any error during unzip, write them into specific logfile (add 2>&1 to command output)
rem     07-Jun-2021:
rem        - read AZURE identify information document (see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service?tabs=windows )
rem     09-Jul-2021:
rem        - set 2.6.834 as field test version
rem     12-Jul-2021:
rem        - set most recent drongle driver to 8.21
rem     14-Jul-2021:
rem        - Add support to install and remove LMS client; ... 
rem        - use /installlms to install or udpate LMS client to most recent released client version.
rem        - use /installftlms to install or udpate LMS client to newest field test client version.
rem        - use /removelms to remove/uninstall installed LMS client
rem        - remove !-sign at the end of console ouput, it causes problems, when colored output follows.
rem     20-Jul-2021:
rem        - set 2.6.835 as field test version
rem     05-Aug-2021:
rem        - retrieve metadata for VMs running on Google Cloud Platform (GCP)
rem     06-Aug-2021:
rem        - suppress error output on conosle during retreieving GCP metadata.
rem     10-Aug-2021:
rem        - set 2.6.836 as field test version
rem     11-Aug-2021:
rem        - add message in case field test version is already installed.
rem        - replace %certfeature% with !certfeature!; fixes LmuTool.exe /CHECK  and LmuTool.exe /FC
rem        - replace %servercertfeature% with !servercertfeature!; fixes LmuTool.exe /CHECK  and LmuTool.exe /FC
rem        - replace %tsfeature% with !tsfeature!; fixes LmuTool.exe /CHECK  and LmuTool.exe /FC
rem     12-Aug-2021:
rem        - add '!LMS_PROGRAMDATA!\Config\LELCfg' and show content
rem     16-Aug-2021:
rem        - download BGInfo.exe from https://live.sysinternals.com/Bginfo.exe into C:\ProgramData\Siemens\LMS\Download\BgInfo
rem        - support option: setbginfo & clearbginfo
rem     17-Aug-2021:
rem        - keep setbginfo; once set, udpate bginfo at each run; till clearbginfo is called
rem     18-Aug-2021:
rem        - adjust download check, check for "!LMS_DOWNLOAD_PATH!\ReadMe.txt"
rem        - change download folder for background info from "lms\CheckLMS" to "lms\BgInfo"
rem        - download further VBS scripts for bginfo
rem        - delete local bginfo vbs scripts (temporary, to clean-up all test sites)
rem        - pack all vbs scripts into a zip archive, download and unzip them into C:\ProgramData\Siemens\LMS\Download\BgInfo
rem     19-Aug-2021:
rem        - set 2.6.838 as field test version
rem     20-Aug-2021:
rem        - adjust download messages, remove messages in case nothing is downloaded because it exists already
rem        - do not download single vbs scripts anymore, downlaod zipped archive (BgInfo_vbs_scripts.zip) and unzip them.
rem     23-Aug-2021:
rem        - set LMS_DATA_PATH - if not set - to C:\ProgramData\Siemens\LMS\
rem     26-Aug-2021:
rem        - align CheckLMS script, to support bginfo introdusced with LMS 2.6 (located in C:\ProgramData\Siemens\LMS\BgInfo)
rem        - Download bginfo.zip and unzip into C:\ProgramData\Siemens\LMS\BgInfo
rem        - Store info about "setbginfo" mode new in file !REPORT_LOG_PATH!\BgInfo\setbginfo.lock
rem        - adjust command line options setbginfo & clearbginfo, first try to start downloaded bginfo, if not available start pre-installed bginfo.
rem     27-Aug-2021:
rem        - use 'call' command to execute (sub-)batch files, see https://stackoverflow.com/questions/1103994/how-to-run-multiple-bat-files-within-a-bat-file
rem     31-Aug-2021:
rem        - start support for CloudFront: https://d32nyvdepsrb0n.cloudfront.net/lms/ ( https://licensemanagementsystem.s3.eu-west-1.amazonaws.com/lms/ )
rem        - replace 'https://static.siemens.com/btdownloads/' with 'https://d32nyvdepsrb0n.cloudfront.net/'
rem        - replace 'akamai' with 'download share'
rem        - adjust the donwload section, check for newer script version BEFORE downloading further libraries.
rem        - move (internal) folder from !LMS_DOWNLOAD_PATH!\git to !LMS_DOWNLOAD_PATH!\CheckLMS\git
rem        - remove support to download 'CheckLMS.exe', 'CheckLMS.bat' instead
rem        - add option to show CheckLMS script version: /showversion
rem        - change script behavior for /showversion, /setbginfo and /clearbginfo; stop script execution after the command has been executed.
rem     01-Sep-2021:
rem        - clean-up files, which have been downloaded with previous scripts.
rem     02-Sep-2021:
rem        - adjust handling of bginfo download package(s)
rem        - add otpions to set and delete scheduled task to set bginfo
rem     06-Sep-2021:
rem        - add support for "LmuTool.exe /SurEDateAll" (for LMS 2.6.839 or newer)
rem        - add support for "Get-Lms -DefaultFamily" (for LMS 2.6.839 or newer)
rem        - set 2.6.839 as field test version
rem     07-Sep-2021:
rem        - no change, same file as "06-Sep-2021"
rem     08-Sep-2021:
rem        - adjust build number passed when startign newer checklms script.
rem        - add missing powershell comandlets: https://wiki.siemens.com/display/en/LMS+-+Powershell+Commandlets+Reference+Guide
rem             - added LMU PowerShell command: Get-Lms -Version
rem             - added LMU PowerShell command: get-lms -DisableClientInfo
rem             - added LMU PowerShell command: get-lms -BorrowDays
rem             - added LMU PowerShell command: get-lms -ProductCode
rem             - added LMU PowerShell command: Get-Lms -SurExpirationDate
rem     20-Sep-2021:
rem        - support ecmcommonutil V1.23 (see 1605134: CheckLMS: Consider “ecmcommonutil.exe” (v:1.23.0.279766))
rem        - retrieve further available information with ecmcommonutil V1.23: dongle, hostid, docker, tpm, wmi
rem        - run full test, suing: ecmcommonutil_x64_n6_V1.23.exe" -t -f
rem        - add summary section, with results of all three available ecmcommonutil tools (V1.19, V1.21 and V1.23)
rem     21-Sep-2021:
rem        - DO NOT DELETE, AS OLDER SCRIPTS STILL START THOSE FILES
rem     22-Sep-2021:
rem        - disable FT version, publish script for LMS 2.6.840
rem     27-Sep-2021:
rem        - fixed issue with '!ALLUSERSPROFILE!' term in for loops, replaced them with '%ALLUSERSPROFILE%'
rem        - fixed issue with '!temp!' term in for loops, replaced them with '%temp%'
rem     13-Oct-2021:
rem        - add command "Get-ComputerInfo -property 'HyperV*'"
rem     14-Oct-2021:
rem        - detect manufacturer of network adapter; this allows to determine the hypervisor
rem     08-Nov-2021:
rem        - add "WEVTUtil query-events Microsoft-Windows-Hyper-V-Compute-Operational /count:%LOG_EVENTLOG_EVENTS% /rd:true /format:text /query:"*[System[Provider[@Name='Microsoft-Windows-Hyper-V-Compute']]]""
rem        - add powershell -command "Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V"
rem        - add powershell -command "Get-WindowsOptionalFeature -Online -FeatureName *Hyper-V*"
rem        - add powershell -command "get-service | findstr vmcompute"
rem     15-Nov-2021:
rem        - adjust most recent BT ALM plugin version: 1.1.43.0
rem        - adjust most recent dongle driver version: 8.31
rem     30-Nov-2021:
rem        - align bginfo, use dedicated bginfo config batch file (remove content from CheckLMS)
rem     07-Dec-2021:
rem        - add Windows Event Log: Siemens ['LMS Setup'] (see 1644407)
rem        - use correct path for eventlog_lms_setup.txt
rem     09-Dec-2021:
rem        - adjust handling of bginfo download package(s)
rem        - clean-up bginfo before unzipping new downloaded package
rem     10-Dec-2021:
rem        - Add console output: Analyze 'SIEMBT.log'
rem        - Adjust 'Host Info' extraction from SIEMBT.log; imporve them in regards of speed.
rem        - support ifconfig.io
rem        - add further connection tests, using e.g. powershell -Command "Test-NetConnection www.automation.siemens.com -port 443"
rem     13-Dec-2021:
rem        - leave host-info foor loop "faster"
rem        - change handling of 'setbginfo.lock' (requires bginfo package V0.96 of 12-Dec-2021, or newer)
rem        - use S3 bucket direct download (from https://licensemanagementsystem.s3.eu-west-1.amazonaws.com/) instead of CloudFront (via https://d32nyvdepsrb0n.cloudfront.net/)
rem        - extend .NET detection; added "528449"; see https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
rem     14-Dec-2021:
rem        - Publish and integrate into LMS 2.6.847 (Sprint 46)
rem     12-Jan-2022:
rem        - Analyze the ALM version, inform about no longer supported ALM versions. See "1680356: CheckLMS: Check installed ALM version and announce incompatibility"
rem        - remove leading zeroes: https://stackoverflow.com/questions/14762813/remove-leading-zeros-in-batch-file
rem     13-Jan-2022:
rem        - Add "Get-ExecutionPolicy -List" to script
rem     21-Jan-2022:
rem        - Publish and integrate into LMS 2.6.849 (Sprint 48)
rem        - Final script, released for LMS 2.6
rem     24-Jan-2022:
rem        - Support ecmcommonutil_V1.25.exe from Flexera (see Task 1693224)
rem        - Move output of ecmcommonutil -t -f into separate debug logfile
rem        - adjust and streamline handling of ecmcommonutil
rem        - Publish and integrate into LMS 2.6.849 (Sprint 48)
rem        - Final script, released for LMS 2.6
rem 
rem     31-Jan-2022:
rem        - Adjusted check of supported LMS versions, added LMS 2.5.824
rem        - Adjusted error message in case dongle driver hasn't been downloaded
rem     01-Feb-2022:
rem        - fix typo 'udpate' to 'update' (credit to Konrad)
rem        - Check ALM version only for LMS 2.6.xxx [>LMS 2.5.824]
rem     02-Feb-2022:
rem        - download and execute WmiRead.exe
rem        - adjust ordering in wmic section. Add more explanation output.
rem     04-Feb-2022:
rem        - Download LMS SDK (for installed LMS version)
rem     10-Feb-2022:
rem        - replace %-sign with !-sign
rem     11-Feb-2022:
rem        - replace !CHECKLMS_ALM_PATH!\ALM\ with !CHECKLMS_ALM_PATH!\Automation License Manager\
rem        - replace %CHECKLMS_ALM_PATH% with !CHECKLMS_ALM_PATH!
rem     12-Feb-2022:
rem        - replace %CHECKLMS_SETUP_LOG_PATH% with !CHECKLMS_SETUP_LOG_PATH!
rem     13-Feb-2022:
rem        - The script copies 'C:\ProgramData\Siemens\Automation\Logfiles\*' to 'C:\ProgramData\Siemens\LMS\Logs\CheckLMSLogs\Automation\Logfiles\*'
rem     14-Feb-2022:
rem        - check installed VC++ runtime, before calling WmiRead.exe
rem        - read «PendingFileRenameOperations» registry key (under Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager)
rem     15-Feb-2022:
rem        - do no longer type 200 [=LOG_FILE_LINES] lines of Desigo CC logfiles within main logfile [will shorten main logfile]; just 20 [=LOG_FILE_SNIPPET]
rem        - list content of three additional logfile folder: [1] !GMS_InstallDir!\!GMS_ActiveProject!\log\* / [2] !GMS_InstallDir!\Log\* / [3] !GMS_PVSSInstallLocation!\log\*
rem        - replace %LOG_FILE_LINES% with !LOG_FILE_LINES!
rem     17-Feb-2022:
rem        - shorten output of SSU setup logfile [MSI*.log], do no longer list whole file(s), list just 20 [=LOG_FILE_SNIPPET] lines [this will shorten main logfile]
rem        - adjust output of echo, in case a file has been copied.
rem        - fixed issue, when collecting Desigo CC logfiles (see 1707310)
rem     21-Feb-2022:
rem        - check V2C file in !LMS_V2C_FOLDER!
rem        - show warning message when V2C is not available.
rem        - copy/analyze HASP error.log located in C:\Program Files (x86)\Common Files\Aladdin Shared\HASP\*
rem     23-Feb-2022:
rem        - add further external URL to perform a connection test; use https://webhook.site/54ced032-9f1a-427a-8eab-24e2329cb8cc
rem          see dashboard at: https://webhook.site/#!/54ced032-9f1a-427a-8eab-24e2329cb8cc/7e4ec314-dbb8-421f-b210-1de546a3d65b/1
rem     24-Feb-2022:
rem        - Fix issue: 'The system cannot find the batch label specified - break_hostinfo_for_loop'
rem     08-Mar-2022:
rem        - add LMS_SYSTEMID and LMS_SCRIPT_BUILD to webhook connection test 
rem     09-Mar-2022:
rem        - add reqeust to OSD server (at the end of the script). Add new section 'S E N D   S T A T I S T I C   D A T A'
rem        - Initial file for !LMS_DOWNLOAD_PATH!\CheckLMS.ps1; with LMS_SCRIPT_BUILD, LMS_SYSTEMID, OS_MAJ_VERSION, OS_MIN_VERSION, LMS_IS_VM and OS_MACHINEGUID
rem        - adjust ouptut when using 'goto' option 
rem        - adjust check if WmiRead shall be executed, execute always when LMS 2.6.849 (or highr) is installed; otherwise execuet only when VC++ V14.29 (or higher) is installed (see 1722921)
rem     10-Mar-2022:
rem        - fix issue 1713700: make sure that files downloaded from git have 'windows style' line endings (CR LF)
rem        - use solution from https://ss64.com/ps/syntax-set-eol.html: Get-Content $OldFile | Set-Content -Path $NewFile
rem        - implement check at script startup (after required folders have been created), and - if needed - convert script and restart them.
rem     11-Mar-2022:
rem        - add running script name to logfile.
rem        - add execution of script 'CheckForUpdate.ps1' - if available - to retrieve software updates and messages for installed LMS client.
rem     14-Mar-2022:
rem        - simplify colored output of CheckLMS script
rem        - Move 'Collection of additional logfiles [based on UCMS-LogcollectorDWP.ini]' into /extend section
rem     21-Mar-2022:
rem        - copy/analyze HASP access.log located in C:\Program Files (x86)\Common Files\Aladdin Shared\HASP\*
rem        - type HASP pid file located in C:\Program Files (x86)\Common Files\Aladdin Shared\HASP\*
rem     30-Mar-2022:
rem        - support 'ecmcommonutil.exe' V1.27
rem     13-Apr-2022:
rem        - remove 'CheckLMS.ps1' (and whole part of sending statistic data), use 'CheckForUpdate.ps1' instead
rem     14-Apr-2022:
rem        - add 'powershell -command "Get-Culture"'
rem        - add 'powershell -command "Get-WinHomeLocation"'
rem        - add option /skipdownload
rem     19-Apr-2022:
rem        - read-out installed SW from '\CurrentVersion\Uninstall\*' for Siemens products
rem        - move 'Read installed products and version [from registry]' in another section, closer to same command using WMI 
rem        - use 'Format-Table' option to format output of 'extended' logfiles to list all installed software on a PC.
rem     20-Apr-2022:
rem        - add InstallSource, ModifyPath, UninstallString, PSChildName as new parameters of Get-ItemProperty command
rem        - add IdentifyingNumber as new parameter of wmic command 
rem     21-Apr-2022:
rem        - set width to 1024 for 'Format-Table' 
rem     27-Apr-2022:
rem        - delete !CHECKLMS_REPORT_LOG_PATH!\pending_req_*.xml
rem        - fix dispaly issue of SHOW_NORMAL in ALM message.
rem     28-Apr-2022:
rem        - added 'netsh winhttp show proxy' (see https://support.microsoft.com/en-us/topic/how-the-windows-update-client-determines-which-proxy-server-to-use-to-connect-to-the-windows-update-website-08612ae5-3722-886c-f1e1-d012516c22a1 )
rem     03-May-2022:
rem        - move execution of several ecmcommonutil tools into /extend section: V1.19, V1.21 and V1.23
rem        - use for VMECMID_Latest.txt new the ecmcommonutil tool V1.25 
rem        - add check command: LmuTool.exe /check
rem        - Do not show error message anymore, when accessing: 'https://www.whoismyisp.org/'
rem        - Do no longer show/display output of "servercomptranutil.exe -listRequests format=long" in main logfile.
rem        - Do no longer show/display ouptut of "servercomptranutil.exe -view format=long" in main logfile
rem        - Do no longer show/display output of "serveractutil.exe -view -long" in main logfile.
rem        - Do no longer show/display output of "appactutil.exe -serverview -commServer <Port@Server> -long" in main logfile.
rem        - Do no longer show/display the output of the LOGS folder in main logfile.
rem        - LMS_LIC_SERVER uses new the configured port number, no longer the default 27000
rem        - reuse already retrieved information from pending requests in files like pending_request_*.xml
rem     04-May-2022:
rem        - 'Test connection to FNC cloud' moved to extended content.
rem        - Add connection test to OSD software updater using CheckForUpdate.ps1 [API URL], requires CheckForUpdate.ps1 Version '20220504' or newer
rem     05-May-2022:
rem        - move 'resend all stored requests, using servercomptranutil.exe' into extend section, use /extend to execute
rem     06-May-2022:
rem        - use new URL  https://softwareupdater.osd.universe.eb.siemens.cloud/servertest.aspx (instead of old: https://www.automation.siemens.com/softwareupdater/servertest.aspx)
rem        - 'Test connection to OSD server' moved to extended content.
rem     11-May-2022:
rem        - Search for McAfee Logfiles, on %programdata%\McAfee\Endpoint Security\Logs\
rem     12-May-2022:
rem        - Improve dongle driver download, do not downloaded again, when it has been downloaded earlier
rem     13-May-2022:
rem        - List available sleep states of power configuration [using powercfg /AVAILABLESLEEPSTATES], as 'hybernate' can potentially cause issues.
rem        - add further output to command line window, when analyzing the trusted store.
rem     01-Jun-2022:
rem        - Added DataExecutionPrevention_Available & DataExecutionPrevention_SupportPolicy to wmic os get locale, oslanguage, codeset, DataExecutionPrevention_Available, DataExecutionPrevention_SupportPolicy /format:list
rem          See also https://docs.microsoft.com/en-us/troubleshoot/windows-client/performance/determine-hardware-dep-available
rem     08-Jun-2022:
rem        - Adjust, Search crash dump files [*.dmp]; copy only when /extend is set.
rem     13-Jun-2022:
rem        - Prepare for 2032330: CheckLMS: Publish script "XX-XXX-2022" as part of LMS 2.7.856 (Sprint 58)
rem     17-Aug-2022:
rem        - Added LmuTool /RMS
rem        - Show content of 'C:\ProgramData\Siemens\LMS\OnlineCheckTokens'
rem        - Show content of all json files in 'C:\ProgramData\Siemens\LMS\OnlineCheckTokens'
rem        - Added LmuTool /ONLINECHECK for all installed online licenses
rem     18-Aug-2022:
rem        - Check: not 2.5.824 AND not 2.6.849 AND less or equal than 2.6.848  --> DEPRECATED (per Aug-2022)
rem        - set most recent dongle driver version to 8.43 (per 18-Aug-2022, LMS 2.7)
rem        - remove check for LMS_IS_VM, as it was not working properly on physical machines.
rem     22-Aug-2022:
rem        - remove support for 'setbginfo.lock'; use registry key instead 'HKEY_LOCAL_MACHINE\SOFTWARE\Siemens\LMS\ShowBGInfo' instead
rem        - Fixed minor issue: Handle handle 'HKLM\SOFTWARE\LicenseManagementSystem\IsInstalled' correct, as it never deleted by ATOS installation.
rem        - Fixed minor issue: handle WMIC_Installed_SW_Report.log correct, consider new field 'IdentifyingNumber'
rem        - Publish CheckLMS "22-Aug-2022" to be part of LMS 2.7.859, collect all changes after "8-Jun-2022" up to "22-Aug-2022"
rem     31-Aug-2022:
rem        - Add LmuToolError.log to general logfile
rem     02-Sep-2022:
rem        - Analyze demo_debuglog.txt only with when /extend option is set.
rem        - Analyze FNC Windows Client [FNC] content only when /extend option is set.
rem        - Collection of additional logfiles for ALM skipped; only executed when /extend option is set.
rem        - Add LMUError.log to general logfile
rem     05-Sep-2022:
rem        - Use CheckForUpdate.ps1 script to download newest CheckLMS script.
rem        - Publish CheckLMS "05-Sep-2022" to be part of LMS 2.7.860, collect all changes after "22-Aug-2022" up to "05-Sep-2022"
rem     12-Sep-2022:
rem        - Adjust 'No GMS installation' message; see '2088686: Wrong message in CheckLMS; ALLUSERSPROFILE is not correct written.'
rem        - Move 'Several event viewer exports made [based on UCMS-LogcollectorDWP.ini]' into extended section, only executed when /extend option is set.
rem        - Adjust 'Retrieve Windows Update Log' funtion, pass robocopy path variables within ""
rem        - Add progress information to 'analyze crash dump files'
rem     13-Sep-2022:
rem        - Add more output in case dongle driver files do not exist. See 'Defect 1570582'
rem     20-Sep-2022:
rem        - Publish CheckLMS "20-Sep-2022" to be part of LMS 2.7.861, collect all changes after "05-Sep-2022" up to "20-Sep-2022"
rem     22-Sep-2022:
rem        - Use new 'https://ipinfo.io/org' instead of 'https://www.whoismyisp.org/' to retrieve ISP name
rem     30-Sep-2022:
rem        - Check existence of 'HKCU:\SOFTWARE\Siemens\SSU' (Fix: Defect 2114646)
rem        - Download LMS SDK only for official supported versions. (Fix: Defect 2114776)
rem        - Add content of '!ALLUSERSPROFILE!\FLEXnet\Connect\Database\umupdts.log' to main logfile.
rem        - Disable 'analyze crash dump file' message on command shell window
rem        - Disable 'Pending request '%%A' found from' message on command shell window
rem     02-Oct-2022:
rem        - Shorten scetion to retrieve McAfee logfile.
rem     03-Oct-2022:
rem        - Show content of AWS_EXECUTION_ENV
rem     04-Oct-2022:
rem        - Publish CheckLMS "04-Oct-2022" to be part of LMS 2.7.862, collect all changes after "20-Sep-2022" up to "04-Oct-2022"
rem     07-Oct-2022:
rem        - Do not install dongle driver automatically, when no dongle driver is installed.
rem        - Support new dongle driver (NEW: https://licensemanagementsystem.s3.eu-west-1.amazonaws.com/lms/hasp/8.43/DongleDriver.zip) (Fix: Defect 2118970)
rem     09-Oct-2022:
rem        - Support 'CheckForUpdate.ps1' also delivered with SSU client, stored in C:\Program Files\Siemens\SSU\bin (Fix: Defect 2116265)
rem     10-Oct-2022:
rem        - Fix issue to set LMS_VERSION_IS_SUPPORTED correct 
rem     12-Oct-2022:
rem        - Adjust 'Test connection to OSD software update server', do not show full error, when it fails.
rem        - Issue in script of '09-Oct-2022'; fixed now: Support 'CheckForUpdate.ps1' also delivered with SSU client, stored in C:\Program Files\Siemens\SSU\bin (Fix: Defect 2116265)
rem        - Use script 'CheckForUpdate.ps1' delivered with SSU client, to perform connection test; this allows to check if messages and/or updates are available for the SSU client.
rem     13-Oct-2022:
rem        - Simplify check on LMS_BUILD_VERSION for LmuTool operations.
rem        - Check return value when getting product upgrades and maintenance. (Fix: Defect 2116121)
rem        - Suppress error message with '-ErrorAction SilentlyContinue' when getting registry key with Get-ItemProperty.
rem     14-Oct-2022:
rem        - remove dependency to 'lmu.psc1' when calling CheckForUpdate powershell.
rem        - in case when !ALLUSERSPROFILE!\Siemens\LMS doesn't exist, create them. To better support machines w/o LMS installed.
rem        - Added the content of several logfile folders of ABT to the CheckLMS logfile
rem        - in case 'Get-WindowsUpdateLog' doesn't work, do not show full error output, just mention to check dedicated logfile.
rem     17-Oct-2022:
rem        - Publish CheckLMS "17-Oct-2022" to be part of LMS 2.7.863, collect all changes after "04-Oct-2022" up to "17-Oct-2022" 
rem     24-Oct-2022:
rem        - Pass correct options when starting CheckForUpdate.ps1 (see LMS_CHECKFORUPDATE_OPTIONS) (Fix: Defect 2129454)
rem     02-Nov-2022:
rem        - Publish CheckLMS "02-Nov-2022" to be part of LMS 2.7.865, collect all changes after "17-Oct-2022" up to "02-Nov-2022" 
rem     14-Nov-2022:
rem        - Add (new) comment {get-lms -ClientID}
rem        - Publish CheckLMS "14-Nov-2022" to be part of LMS 2.7.867, collect all changes after "02-Nov-2022" up to "14-Nov-2022" 
rem     24-Nov-2022:
rem        - Add serialnumber to wmic OS get Caption,CSDVersion,OSArchitecture,Version, serialnumber
rem        - Add Machine ID, using reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SQMClient /v MachineId
rem        - Add CurrentClockSpeed & MaxClockSpeed to wmic CPU get Name,NumberOfCores,NumberOfLogicalProcessors, CurrentClockSpeed, MaxClockSpeed
rem          for more info, check https://www.nextofwindows.com/the-best-way-to-uniquely-identify-a-windows-machine
rem                         and https://stackoverflow.com/questions/47603786/where-do-windows-product-id-and-device-id-values-come-from-are-they-useful
rem     25-Nov-2022:
rem        - Add several commands to get status nad jobs of BITS downloader (fix: Defect 2145133)
rem        - Add new option /cleanup to remove all running BITS jobs.
rem        - Fix typo: priviledge -> privilege
rem     28-Nov-2022:
rem        - Replace /RMS with /REQTOK (Fix: Story 2145456)
rem        - Fix minor issue in "Skip download archive, as it was created on this machine." function
rem        - Publish CheckLMS "28-Nov-2022" to be part of LMS 2.7.868, collect all changes after "14-Nov-2022" up to "28-Nov-2022" 
rem     01-Dec-2022:
rem        - Check that correct VC++ package is installed, before calling WmiRead.exe (Fix: Defect 2152576)
rem        - set LMS_BUILD_VERSION=0 (instead of 'N/A')
rem        - Add further checks, to test existence of lmu.psc1; to avoid error messages on non-LMS systems.
rem        - Remove spaces at line end for several sections.
rem        - Add warning message, when VC++ library is not installed and SSU client get started!
rem        - Add command to check that SSU task is running.
rem     06-Dec-2022:
rem        - Adjust the output of 'Get Product List'
rem        - Add new 'Get Feature List'
```
