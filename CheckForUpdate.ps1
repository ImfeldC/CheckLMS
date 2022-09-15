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
$scriptVersion = '20220915'


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

Log-Message "Script Execution started ..."
if( $Verbose ) {
	Log-Message "Parameters: operatingsystem=$operatingsystem / language=$language / SkipSiemensSoftware=$SkipSiemensSoftware / DownloadSoftware=$DownloadSoftware / Verbose=$Verbose / productversion=$productversion / productcode=$productcode"
}

$ExitCode=0
# Old API URL -> $OSD_APIURL="https://www.automation.siemens.com/softwareupdater/public/api/updates"
$OSD_APIURL="https://osd-ak.automation.siemens.com/softwareupdater/public/api/updates"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# set client type ..
$clientType = 'CheckForUpdate'
$clientVersion = $scriptVersion

# retrieve product information ...
if ( $productcode -eq '' )
{
	$productcode = get-lms -ProductCode | select -expand Guid
}
if ( $productversion -eq '' )
{
	$productversion = get-lms -LMSVersion
}
$lmssystemid = get-lms -SystemId

# retrieve standard client info ....
$timezone_displayname = Get-TimeZone | select -expand DisplayName
$region = Get-WinHomeLocation | select -expand HomeLocation
$display_language = Get-Culture | select -expand Name

# retrieve client info ....
$LMS_PS_CSID = get-lms -Csid
$LMS_IS_VM = (gcim Win32_ComputerSystem).HypervisorPresent
$OS_MACHINEGUID = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' | select -expand MachineGuid
$OS_PRODUCTNAME = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName' | select -expand ProductName
$OS_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentVersion' | select -expand CurrentVersion
$OS_MAJ_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMajorVersionNumber' | select -expand CurrentMajorVersionNumber
$OS_MIN_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMinorVersionNumber' | select -expand CurrentMinorVersionNumber
$OS_BUILD_NUM = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber' | select -expand CurrentBuildNumber

# retrieve operating system information ...
if ( $operatingsystem -eq '' )
{
	#determine correct OS string, and map to https://wiki.siemens.com/display/en/OSD+Types
	if ( $OS_BUILD_NUM -eq 22000 ) {
		# For Windows 11, the ProductName is not unique so instead of comparing the ProductName , we get the CurrentBuildNumber from registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuildNumber  and compare it.
		# The CurrentBuildNumber for Windows 11 is 22000
		# For more information on Windows 11 refer the release notes:  https://docs.microsoft.com/en-us/windows/release-health/windows11-release-information
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
$A = Get-ChildItem -Path C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log | Select-String -Pattern 'Running on Hypervisor:(.+)'
if( $A[0] -match 'Running on Hypervisor:\s(?<Hypervisor>.+)' )
{
	$LMS_SIEMBT_HYPERVISOR = $Matches.Hypervisor
}

Log-Message "Check for updates on client '$lmssystemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."

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
        `"timeZone`":`"$timezone_displayname`",
        `"region`":`"$region`",
        `"language`":`"$display_language`",
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

if ( $Verbose ) {
	Log-Message "Message Body ... `n'$body'"
}
Try {
	$response = Invoke-RestMethod $OSD_APIURL -Method 'POST' -Headers $headers -Body $body
} Catch {
	$ExitCode=$_.Exception.Response.StatusCode.value__
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

if( $Verbose ) {
	if( $response ) {
		Log-Message "Message Response ..."
		$response | ConvertTo-Json -depth 100
	}
}

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
			$finalurl, $options = ($downloadurl -Split '\?')[0,1]
			if( $Verbose ) {
				Log-Message "Title: $title / Description: $description / Download URL: $downloadurl / options: $options"
			}
			
			if( $downloadurl ) {
				# download the software udpate
				Log-Message "Start to download ... '$finalurl' to '$Path'"
				Start-BitsTransfer -Source "$finalurl" -Destination "$Path"
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

	if ( $Verbose ) {
		Log-Message "Message Body (with Siemens Software) ... `n'$body'"
	}
	Try {
		$response = Invoke-RestMethod $OSD_APIURL -Method 'POST' -Headers $headers -Body $body
	} Catch {
		$ExitCode=$_.Exception.Response.StatusCode.value__
		Log-Message "Error Response (after sending Siemens Software) ... Error Code: $ExitCode"
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
		Log-Message "Message Response (after sending Siemens Software) ..."
		$response | ConvertTo-Json -depth 100
	}
}

Log-Message "Script Execution ended ..."
Log-Message "Exit with '$ExitCode'"
exit $ExitCode

