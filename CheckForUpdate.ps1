#region Parameters
param(
	[string]$operatingsystem = '',
	[string]$language = 'en-us',
	[bool]$SkipSiemensSoftware = $true,
	[bool]$DownloadSoftware = $false,
	[bool]$Verbose = $true,
	[string]$productversion = '',
	[string]$productcode = '',
	[bool]$stagesystem = $false
)
#endregion
# ---------------------------------------------------------------------------------------
# © Siemens 2022 - 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
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
# '20221012': Check existence of several registry keys. (Fix: Defect 2122172)
#             Determine systemid (if not already done) (Fix: Defect 2117302)
#             Use '-ErrorAction SilentlyContinue' when reading registry value to suppress any error.
# '20221024': Check that 'get-lms' commandlet is available (Fix: Defect 2129454)
# '20221201': Check that 'Get-ScheduledTask' doesn't throw an error (Fix: Defect 2153318)
# '20221202': Add OS check "$OS_BUILD_NUM -gt 22621", to be prepared for future Win11 releases.
# '20230502': Add URL for stage (test) system of OSD backend server
#             Add script version to console output
#             Add parameter to choose between productive (=default) or stage system
# '20230511': Support 'SkipCheckForUpdate' registry entry; if set to '1' do not perform check for updates.
# '20230804': Revert back to use Start-BitsTransfer to download file from OSD, instead of Net.WebClient (see also '20221005')
# '20230913': Add copyright notice of Siemens 
# '20230921': Fix: 2355024: 'Running on Hypervisor' NOT found
# '20230926': Read "program data" path from environment
#             Consider 'SIEMBT_HostInfo.txt' to read-out host info (in case it doesn't exist in 'SIEMBT.log')
#
$scriptVersion = '20230026'

$global:ExitCode=0
# Old API URL -> $OSD_APIURL="https://www.automation.siemens.com/softwareupdater/public/api/updates"
if( $stagesystem ) {
	# Stage API URL -> 
	$OSD_APIURL="https://osd-akstage.automation.siemens.com/softwareupdater/public/api/updates"
} else {
	# Productive API URL -> 
	$OSD_APIURL="https://osd-ak.automation.siemens.com/softwareupdater/public/api/updates"
}

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
Log-Message "Script Execution '$scriptVersion' started from path '$PSScriptRoot' ..."
if( $Verbose ) {
	Log-Message "Parameters: operatingsystem=$operatingsystem / language=$language / SkipSiemensSoftware=$SkipSiemensSoftware / DownloadSoftware=$DownloadSoftware / Verbose=$Verbose / productversion=$productversion / productcode=$productcode / StageSystem=$stagesystem"
	Log-Message "API URL: '$OSD_APIURL'"
}

# set client type ..
$clientType = 'CheckForUpdate'
$clientVersion = $scriptVersion

# determine for which product this script is running ...
if( $PSScriptRoot.Contains("\Siemens\LMS\") ) { 
	if( Get-Command 'get-lms' -errorAction SilentlyContinue ) {
		# retrieve LMS client info ....
		$lmsproductcode = get-lms -ProductCode | select -expand Guid
		$lmsproductversion = get-lms -LMSVersion
		$lmssystemid = get-lms -SystemId
		$SkipCheckForUpdate  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\LMS' -Name 'SkipCheckForUpdate' -ErrorAction SilentlyContinue | select -expand SkipCheckForUpdate
		if( $Verbose ) {
			Log-Message "LMS Client Info: lmsproductversion=$lmsproductversion / lmsproductcode=$lmsproductcode / lmssystemid=$lmssystemid / SkipCheckForUpdate=$SkipCheckForUpdate"
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
	} else {
		Log-Message "LMS Client Info: Cannot retrieve LMS client information, because 'get-lms' commandlet is not available."
	}
} elseif ( $PSScriptRoot.Contains("\Siemens\SSU\") ) { 
	# retrieve SSU client info ....
	$TEMPPRODUCTCODE = Get-InstalledSoftware  -Name 'Siemens Software Updater' 
	$ssuproductcode = $TEMPPRODUCTCODE.GUID-replace '\{(.*)\}','$1';
	$ssuproductversion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'Version' | select -expand Version
	$ssusystemid = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'SystemId' | select -expand SystemId
	$SkipCheckForUpdate  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'SkipCheckForUpdate' -ErrorAction SilentlyContinue | select -expand SkipCheckForUpdate
	if( $Verbose ) {
		Log-Message "SSU Client Info: ssuproductversion=$ssuproductversion / ssuproductcode=$ssuproductcode / ssusystemid=$ssusystemid / SkipCheckForUpdate=$SkipCheckForUpdate"
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

#determine systemid (if not already done)
if ( $systemid -eq $null ) {
	# SSU system id exists ...
	$systemid =  Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'SystemId' -ErrorAction SilentlyContinue | select -expand SystemId
}
if ( $systemid -eq $null ) {
	# LMS system id exists ...
	$systemid =  Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\LMS' -Name 'SystemId' -ErrorAction SilentlyContinue | select -expand SystemId
}
if ( $systemid -eq $null ) {
	# use machine id (as final default)
	$systemid = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -ErrorAction SilentlyContinue | select -expand MachineGuid
}
if ( $Verbose ) {
	Log-Message "System Id: $systemid"
}

#determine SkipCheckForUpdate (if not already done)
if ( $SkipCheckForUpdate -eq $null ) {
	# SkipCheckForUpdate for SSU exists ...
	$SkipCheckForUpdate =  Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\SSU' -Name 'SkipCheckForUpdate' -ErrorAction SilentlyContinue | select -expand SkipCheckForUpdate
}
if ( $SkipCheckForUpdate -eq $null ) {
	# SkipCheckForUpdate for LMS exists ...
	$SkipCheckForUpdate =  Get-ItemProperty -Path 'HKLM:\SOFTWARE\Siemens\LMS' -Name 'SkipCheckForUpdate' -ErrorAction SilentlyContinue | select -expand SkipCheckForUpdate
}
if ( $SkipCheckForUpdate -eq $null ) {
	# use 0 (as final default)
	$SkipCheckForUpdate = 0
}
if ( $Verbose ) {
	Log-Message "SkipCheckForUpdate: $SkipCheckForUpdate"
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
$OS_MAJ_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMajorVersionNumber' -ErrorAction SilentlyContinue | select -expand CurrentMajorVersionNumber
$OS_MIN_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMinorVersionNumber' -ErrorAction SilentlyContinue | select -expand CurrentMinorVersionNumber
$OS_BUILD_NUM = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber' | select -expand CurrentBuildNumber

$SSU_UPDATE_ENABLED = (Get-ScheduledTask -TaskName "SSUScheduledTask" -ErrorAction SilentlyContinue).Triggers.Enabled
if( $SSU_UPDATE_ENABLED -eq $null ) {
	Log-Message "Warning! Scheduled task 'SSUScheduledTask' is nto available or not readable."
		$SSU_UPDATE_INTERVAL = "n/a"
		$SSU_UPDATE_TIME = "n/a"
		$SSU_UPDATE_TYPE = "n/a"
} else {
	if( $SSU_UPDATE_ENABLED -eq "True" )
	{
		if( (Get-ScheduledTask -TaskName "SSUScheduledTask").Triggers.DaysInterval -eq 1 ) {
			# Daily
			$SSU_UPDATE_INTERVAL = "Daily"
		} elseif ( (Get-ScheduledTask -TaskName "SSUScheduledTask").Triggers.WeeksInterval -eq 1 ) {
			$SSU_UPDATE_INTERVAL = "Weekly"
		} else {
			$SSU_UPDATE_INTERVAL = "Monthly"
		}
	}
	$SSU_UPDATE_TYPE =  Get-ItemProperty -Path 'HKCU:\SOFTWARE\Siemens\SSU' -Name 'InstallUpdateType' -ErrorAction SilentlyContinue | select -expand InstallUpdateType
	if( $SSU_UPDATE_TYPE -eq $null ) {
		# Default: 'Automatic', see https://wiki.siemens.com/pages/viewpage.action?pageId=390630467
		$SSU_UPDATE_TYPE = "Automatic"
	}
	$SSU_UPDATE_TIME = (Get-ScheduledTask SSUScheduledTask | Get-ScheduledTaskInfo).NextRunTime.DateTime.split(' ')[4] 
}

# retrieve operating system information ...
if ( $operatingsystem -eq '' )
{
	#determine correct OS string, and map to https://wiki.siemens.com/display/en/OSD+Types

	# For Windows 11, the ProductName is not unique so instead of comparing the ProductName , we get the CurrentBuildNumber from registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuildNumber  and compare it.
	# For more information on Windows 11 refer the release notes:  https://docs.microsoft.com/en-us/windows/release-health/windows11-release-information
	if ( $OS_BUILD_NUM -gt 22621 ) {
		# > 22H2 (prepare for future releases)
		$operatingsystem = "Windows11"
	} elseif ( $OS_BUILD_NUM -eq 22621 ) {
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
$programDataPath = $env:ProgramData 
if ( Test-Path "$programDataPath\Siemens\LMS\Logs\SIEMBT.log" ) {
	#Log-Message "File 'SIEMBT.log' exists ..."
	$A = Get-ChildItem -Path $programDataPath\Siemens\LMS\Logs\SIEMBT.log | Select-String -Pattern 'Running on Hypervisor:(.+)'
	if( $A ) {
		if( $A[0] -match 'Running on Hypervisor:\s(?<Hypervisor>.+)' )
		{
			$LMS_SIEMBT_HYPERVISOR = $Matches.Hypervisor
			Log-Message "Hypervisior '$LMS_SIEMBT_HYPERVISOR' found in file 'SIEMBT.log' ..."
		}
	} else {
		if ( Test-Path "$programDataPath\Siemens\LMS\Logs\SIEMBT_HostInfo.txt" ) {
			#Log-Message "File 'SIEMBT_HostInfo.txt' exists ..."
			$A = Get-ChildItem -Path $programDataPath\Siemens\LMS\Logs\SIEMBT_HostInfo.txt | Select-String -Pattern 'Running on Hypervisor:(.+)'
			if( $A ) {
				if( $A[0] -match 'Running on Hypervisor:\s(?<Hypervisor>.+)' )
				{
					$LMS_SIEMBT_HYPERVISOR = $Matches.Hypervisor
					Log-Message "Hypervisior '$LMS_SIEMBT_HYPERVISOR' found in file 'SIEMBT_HostInfo.txt' ..."
				}
			} else {
				$LMS_SIEMBT_HYPERVISOR = "n/a"
			}
		} else {
			$LMS_SIEMBT_HYPERVISOR = "n/a"
		}
	}
} else {
	$LMS_SIEMBT_HYPERVISOR = "n/a"
}

if ( $SkipCheckForUpdate -ne '1' ) {
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
					$filepath = $Path + "\\" + $filename
					Log-Message "Start to download ... '$downloadurl' to '$filepath'"
					Start-BitsTransfer -Source "$downloadurl" -Destination $filepath
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
} else {
	Log-Message "*** SKIPPED *** Check for updates on client '$systemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."
}

Log-Message "Script Execution ended ..."
Log-Message "Exit with '$ExitCode'"
exit $ExitCode

