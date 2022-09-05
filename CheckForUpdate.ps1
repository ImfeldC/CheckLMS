#region Parameters
param(
	[string]$operatingsystem = 'Windows10',
	[string]$language = 'en-us',
	[bool]$SkipSiemensSoftware = $true,
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
$scriptVersion = '20220905'


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
Log-Message "Parameters: operatingsystem=$operatingsystem / language=$language / SkipSiemensSoftware=$SkipSiemensSoftware / Verbose=$Verbose / productversion=$productversion / productcode=$productcode"

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
        `"OS_MACHINEGUID`":`"$OS_MACHINEGUID`"
    }
}"

if ( $Verbose ) {
	Log-Message "Message Body ... `n'$body'"
}
Try {
	$response = Invoke-RestMethod $OSD_APIURL -Method 'POST' -Headers $headers -Body $body
} Catch {
	Log-Message "Error Response ..."
	Log-Message "StatusCode:" $_.Exception.Response.StatusCode.value__
	Log-Message "StatusDescription:" $_.Exception.Response.StatusDescription
	$ExitCode=$_.Exception.Response.StatusCode.value__
    if($_.ErrorDetails.Message) {
        Log-Message $_.ErrorDetails.Message
    } else {
        Log-Message $_
    }
	# read addtional data, see https://github.com/MicrosoftDocs/PowerShell-Docs/issues/4456
	$reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
	$reader.BaseStream.Position = 0
	$reader.DiscardBufferedData()
	$reader.ReadToEnd() | ConvertFrom-Json
}
if ( $Verbose ) {
	Log-Message "Message Response ..."
	$response | ConvertTo-Json -depth 100
}

if (-not $SkipSiemensSoftware) {
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
		Log-Message "Message Body ... `n'$body'"
	}
	Try {
		$response = Invoke-RestMethod $OSD_APIURL -Method 'POST' -Headers $headers -Body $body
	} Catch {
		Log-Message "Error Response ..."
		Log-Message "StatusCode:" $_.Exception.Response.StatusCode.value__
		Log-Message "StatusDescription:" $_.Exception.Response.StatusDescription
		$ExitCode=$_.Exception.Response.StatusCode.value__
		if($_.ErrorDetails.Message) {
			Log-Message $_.ErrorDetails.Message
		} else {
			Log-Message $_
		}
		# read addtional data, see https://github.com/MicrosoftDocs/PowerShell-Docs/issues/4456
		$reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$reader.ReadToEnd() | ConvertFrom-Json
	}
	if ( $Verbose ) {
		Log-Message "Message Response ..."
		$response | ConvertTo-Json -depth 100
	}
}

Log-Message "Script Execution ended ..."
Log-Message "Exit with '$ExitCode'"
exit $ExitCode

