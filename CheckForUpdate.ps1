#region Parameters
param(
	[string]$operatingsystem = '',
	[string]$language = 'en-us',
	[bool]$SkipSiemensSoftware = $true,
	[bool]$DownloadSoftware = $false,
	[bool]$Verbose = $true,
	[string]$productversion = '',
	[string]$productcode = ''
)
#endregion

# '20220420': Add installed Siemens Software 
# '20220421': try/catch rest method call, read addtional data, see https://github.com/MicrosoftDocs/PowerShell-Docs/issues/4456 
# '20220504': Add option $SkipSiemensSoftware, to skip sending installed Siemens Software. Disable per default.
#             Add return code; any value > 0 means an error.
#             Add option $Verbose, to enable/disable additional output. Enabled per default.
# '20220506': Use new API URL: https://osd-ak.automation.siemens.com/softwareupdater/public/api/updates
# '20220516': Add <date> and <time> information of script execution to logfile output.
#             Add script version to logfile output.
# '20220905': Add new command line parameters: productversion & productcode
#             Add new command line option: DownloadSoftware (default: 0), if set it downloads the software
#             Adjust the message output, display most only when 'Verbose' option is set
# '20220905': Fix issue in case product version is not available.
# '20220915': Add $OS_BUILD_NUM to request
#             Add mapping for OS identifiers, see https://wiki.siemens.com/display/en/Points+to+consider+when+configuring+update+in+OSD & https://wiki.siemens.com/display/en/OSD+Types
# '20220919': Implement automatic retrieval for SSU and LMS for product code and version. The same script can be used for both products.
# '20220920': Finalize, to include in LMS 2.7.861
# '20220922': Consider Widnows 11 22H2 with build number 22621
#             Determine "ssuupdateinterval" correct on trigger settings of scheduled task "SSUScheduledTask"
# '20220928': Check if regsitry key 'HKCU:\SOFTWARE\Siemens\SSU' exists (Fix: Defect 2113818)
# '20221003': Check if 'SIEMBT.log' exists (Fix: Defect 2116265)
#             Check that 'get-lms' commandlet is available (Fix: Defect 2116265)
# '20221005': Use Net.WebClient to download file from OSD, instead of Start-BitsTransfer
$scriptVersion = '20221005'

$global:ExitCode=0
# Old API URL -> $OSD_APIURL="https://www.automation.siemens.com/softwareupdater/public/api/updates"
$OSD_APIURL="https://osd-ak.automation.siemens.com/softwareupdater/public/api/updates"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")


# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("[$scriptName/$scriptVersion] {0} - {1}" -f (Get-Date), $LogMessage)
}

# Function to send request to OSD server
function Invoke-OSDRequest
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$body,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$header
    )

	if ( $Verbose ) {
		Log-Message "Message Body ... `n'$body'"
	}
	Try {
		$global:response = Invoke-RestMethod $OSD_APIURL -Method 'POST' -Headers $headers -Body $body
	} Catch {
		$global:ExitCode=$_.Exception.Response.StatusCode.value__
		Log-Message "Error Response ... Error Code: $ExitCode"
		#Log-Message "StatusCode: $_.Exception.Response.StatusCode.value__"
		#Log-Message "StatusDescription: $_.Exception.Response.StatusDescription"
		if($_.ErrorDetails.Message) {
			Log-Message "$_.ErrorDetails.Message"
		} else {
			Log-Message "$_"
		}
		# read addtional data, see https://github.com/MicrosoftDocs/PowerShell-Docs/issues/4456
		$reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$reader.ReadToEnd() 
	}
	if ( $Verbose ) {
		if( $response ) {
			Log-Message "Message Response ..."
			$response | ConvertTo-Json -depth 100
		}
	}
}

#Function to read installed software incl. product GUID
function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Retrieves a list of all software installed
    .EXAMPLE
        Get-InstalledSoftware
    .PARAMETER Name
        The software title you'd like to limit the query to.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    $UninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
    $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
    if (-not $UninstallKeys) {
        Write-Verbose -Message 'No software registry keys found'
    } else {
        foreach ($UninstallKey in $UninstallKeys) {
            if ($PSBoundParameters.ContainsKey('Name')) {
                $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName') -like "$Name*") -and ($_.GetValue('DisplayVersion').Substring(0, ($_.GetValue('DisplayVersion')).IndexOf('.')) -gt 1.3)}
            } else {
                $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName'))}
            }
            $gciParams = @{
                Path        = $UninstallKey
                ErrorAction = 'SilentlyContinue'
            }
            $selectProperties =
            @{
                n='GUID'; e={$_.PSChildName}
            }
            Get-ChildItem @gciParams | Where $WhereBlock | Select-Object -Property $selectProperties
        }
    }
}



# start logging
Log-Message "Script Execution started from path '$PSScriptRoot' ..."
if( $Verbose ) {
	Log-Message "Parameters: operatingsystem=$operatingsystem / language=$language / SkipSiemensSoftware=$SkipSiemensSoftware / DownloadSoftware=$DownloadSoftware / Verbose=$Verbose / productversion=$productversion / productcode=$productcode"
}

# set client type ..
$clientType = 'CheckForUpdate'
$clientVersion = $scriptVersion

# determine for which product this script is running ...
if( $PSScriptRoot.Contains("\Siemens\LMS\") ) { 
	# retrieve LMS client info ....
	$lmsproductcode = get-lms -ProductCode | select -expand Guid
	$lmsproductversion = get-lms -LMSVersion
	$lmssystemid = get-lms -SystemId
	if( $Verbose ) {
		Log-Message "LMS Client Info: lmsproductversion=$lmsproductversion / lmsproductcode=$lmsproductcode / lmssystemid=$lmssystemid"
	}
	if ( $productcode -eq '' )
	{
		$productcode = $lmsproductcode
	}
	if ( $productversion -eq '' )
	{
		$productversion = $lmsproductversion
	}
	$systemid = $lmssystemid
} elseif ( $PSScriptRoot.Contains("\Siemens\SSU\") ) { 
	# retrieve SSU client info ....
	$TEMPPRODUCTCODE = Get-InstalledSoftware  -Name 'Siemens Software Updater' 
	$ssuproductcode = $TEMPPRODUCTCODE.GUID-replace '\{(.*)\}','$1';
	$ssuproductversion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'Version' | select -expand Version
	$ssusystemid = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'SystemId' | select -expand SystemId
	if( $Verbose ) {
		Log-Message "SSU Client Info: ssuproductversion=$ssuproductversion / ssuproductcode=$ssuproductcode / ssusystemid=$ssusystemid"
	}
	if ( $productcode -eq '' )
	{
		$productcode = $ssuproductcode
	}
	if ( $productversion -eq '' )
	{
		$productversion = $ssuproductversion
	}
	$systemid = $ssusystemid
}

# check product code and version ...
if ( $productcode -eq '' )
{
	Log-Message "Warning! Product code not defined."
}
if ( $productversion -eq '' )
{
	Log-Message "Warning! Product version not defined."
}

# retrieve standard client info ....
$timezone_displayname = Get-TimeZone | select -expand DisplayName
$region = Get-WinHomeLocation | select -expand HomeLocation
$display_language = Get-Culture | select -expand Name

# retrieve client info ....
if( Get-Command 'get-lms' -errorAction SilentlyContinue ) {
	$LMS_PS_CSID = get-lms -Csid
} else {
	$LMS_PS_CSID = "n/a"
}
$LMS_IS_VM = (gcim Win32_ComputerSystem).HypervisorPresent
$OS_MACHINEGUID = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' | select -expand MachineGuid
$OS_PRODUCTNAME = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName' | select -expand ProductName
$OS_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentVersion' | select -expand CurrentVersion
$OS_MAJ_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMajorVersionNumber' | select -expand CurrentMajorVersionNumber
$OS_MIN_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMinorVersionNumber' | select -expand CurrentMinorVersionNumber
$OS_BUILD_NUM = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber' | select -expand CurrentBuildNumber

$SSU_UPDATE_ENABLED = (ScheduledTask -TaskName "SSUScheduledTask").Triggers.Enabled
if( $SSU_UPDATE_ENABLED -eq "True" )
{
	if( (ScheduledTask -TaskName "SSUScheduledTask").Triggers.DaysInterval -eq 1 ) {
		# Daily
		$SSU_UPDATE_INTERVAL = "Daily"
	} elseif ( (ScheduledTask -TaskName "SSUScheduledTask").Triggers.WeeksInterval -eq 1 ) {
		$SSU_UPDATE_INTERVAL = "Weekly"
	} else {
		$SSU_UPDATE_INTERVAL = "Monthly"
	}
}
if ( Test-Path 'HKCU:\SOFTWARE\Siemens\SSU' ) {
	$SSU_UPDATE_TYPE =  Get-ItemProperty -Path 'HKCU:\SOFTWARE\Siemens\SSU' -Name 'InstallUpdateType' | select -expand InstallUpdateType
} else {
	# Default: 'Automatic', see https://wiki.siemens.com/pages/viewpage.action?pageId=390630467
	$SSU_UPDATE_TYPE = "Automatic"
}
$SSU_UPDATE_TIME = (Get-ScheduledTask SSUScheduledTask | Get-ScheduledTaskInfo).NextRunTime.DateTime.split(' ')[4] 

# retrieve operating system information ...
if ( $operatingsystem -eq '' )
{
	#determine correct OS string, and map to https://wiki.siemens.com/display/en/OSD+Types

	# For Windows 11, the ProductName is not unique so instead of comparing the ProductName , we get the CurrentBuildNumber from registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuildNumber  and compare it.
	# For more information on Windows 11 refer the release notes:  https://docs.microsoft.com/en-us/windows/release-health/windows11-release-information
	if ( $OS_BUILD_NUM -eq 22621 ) {
		# 22H2
		$operatingsystem = "Windows11"
	} elseif ( $OS_BUILD_NUM -eq 22000 ) {
		# 21H2 (original release)
		$operatingsystem = "Windows11"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows 10") ) { 
		$operatingsystem = "Windows10"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows Server 2022") ) { 
		$operatingsystem = "WindowsServer2022"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows Server 2019") ) { 
		# this is the only exception, where OS identifier contains spaces
		$operatingsystem = "Windows Server 2019"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows Server 2016") ) { 
		$operatingsystem = "WindowsServer2016"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows Server 2012 R2") ) { 
		$operatingsystem = "WindowsServer2012R2"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows Server 2012") ) { 
		$operatingsystem = "WindowsServer2012"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows 8.1") ) { 
		$operatingsystem = "Windows8.1"
	} elseif ( $OS_PRODUCTNAME.Contains("Windows 7") ) { 
		$operatingsystem = "Windows7"
	} elseif ( $operatingsystem -eq '' ) {
		$operatingsystem = $OS_PRODUCTNAME
	}
}

# Determine hypervisor (using SIEMBT logfile)
if ( Test-Path 'C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log' ) {
	$A = Get-ChildItem -Path C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log | Select-String -Pattern 'Running on Hypervisor:(.+)'
	if( $A[0] -match 'Running on Hypervisor:\s(?<Hypervisor>.+)' )
	{
		$LMS_SIEMBT_HYPERVISOR = $Matches.Hypervisor
	}
} else {
	$LMS_SIEMBT_HYPERVISOR = "n/a"
}
Log-Message "Check for updates on client '$systemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."

$body = "{
    `"ProductCode`": `"$productcode`",
    `"ProductVersion`": `"$productversion`",
    `"OperationSystem`": `"$operatingsystem`",
    `"Language`": `"$language`",
    `"clientType`":`"$clientType`",
    `"clientVersion`":`"$clientVersion`",
    `"clientGUID`":`"$systemid`",
    `"clientInfo`":
    {
        `"timeZone`":`"$timezone_displayname`",
        `"region`":`"$region`",
        `"language`":`"$display_language`",
        `"ssuupdateinterval`":`"$SSU_UPDATE_INTERVAL`",
        `"ssuupdatetime`":`"$SSU_UPDATE_TIME`",
        `"ssuupdatetype`":`"$SSU_UPDATE_TYPE`",
        `"CSID`":`"$LMS_PS_CSID`",
        `"LMS_IS_VM`":`"$LMS_IS_VM`",
        `"LMS_SIEMBT_HYPERVISOR`":`"$LMS_SIEMBT_HYPERVISOR`",
        `"OS_PRODUCTNAME`":`"$OS_PRODUCTNAME`",
        `"OS_VERSION`":`"$OS_VERSION`",
        `"OS_MAJ_VERSION`":`"$OS_MAJ_VERSION`",
        `"OS_MIN_VERSION`":`"$OS_MIN_VERSION`",
        `"OS_BUILD_NUM`":`"$OS_BUILD_NUM`",
        `"OS_MACHINEGUID`":`"$OS_MACHINEGUID`"
    }
}"

# send (first) request to OSD server
Invoke-OSDRequest $body $headers

if( $DownloadSoftware ) {
	if( $response ) {
		# start further processing or repsone, e.g. extract  "downloadURL"
		if( $Verbose ) {
			Log-Message "Start to analyze the Response ..."
		}
		
		foreach ($swupdate in $response.softwareUpdates) {
			if( $Verbose ) {
				Log-Message "Software Update: $swupdate"  
			}
			
			$title = $swupdate.title
			$description = $swupdate.description
			$downloadurl = [URI]$swupdate.downloadURL
			$Path = $env:ProgramData + '\Siemens\LMS\Download'
			$shorturl, $options = ($downloadurl -Split '\?')[0,1]
			$filename = ($shorturl -Split '/')[-1]
			if( $Verbose ) {
				Log-Message "Title: $title / Description: $description / Download URL: $shorturl / filename: $filename / options: $options"
			}
			
			if( $downloadurl ) {
				# download the software udpate
				Log-Message "Start to download ... '$downloadurl' to '$Path\$filename'"
				#Start-BitsTransfer -Source "$downloadurl" -Destination "$Path"
				(New-Object Net.WebClient).DownloadFile($downloadurl, $Path + "\\" + $filename)
				Log-Message "End of download ..."
			}
		}	
	} else {
		Log-Message "Skip download, no valid response received ..."
	}
}

if (-not $SkipSiemensSoftware) {
	if ( $Verbose ) {
		Log-Message "Retrieve installed Siemens Software ... "
	}
	# Read-out installed Siemens software and convert then into json 
	$SiemensInstalledSoftware1 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSChildName | Where-Object{$_.Publisher -like '*Siemens*'} | ConvertTo-Json
	$SiemensInstalledSoftware2 = Get-CimInstance Win32_Product | Sort-Object -property Name | Where-Object{$_.Vendor -like '*Siemens*'} | Select-Object Name, Version, InstallDate, Vendor, IdentifyingNumber | ConvertTo-Json

	$body = "{
		`"ProductCode`": `"$productcode`",
		`"ProductVersion`": `"$productversion`",
		`"OperationSystem`": `"$operatingsystem`",
		`"Language`": `"$language`",
		`"clientType`":`"$clientType`",
		`"clientVersion`":`"$clientVersion`",
		`"clientGUID`":`"$lmssystemid`",
		`"clientInfo`":
		{
			`"siemens_installed_software`": $SiemensInstalledSoftware1,
			`"siemens_installed_software`": $SiemensInstalledSoftware2
		}
	}"

	# send (second) request to OSD server
	Invoke-OSDRequest $body $headers
}

Log-Message "Script Execution ended ..."
Log-Message "Exit with '$ExitCode'"
exit $ExitCode

