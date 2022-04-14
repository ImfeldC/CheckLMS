#region Parameters
param(
	[string]$operatingsystem = 'Windows10',
	[string]$language = 'en-us'
)
#endregion

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# set client type ..
$clientType = 'CheckForUpdate'
$clientVersion = '20220414'

# retrieve product information ...
$productcode = get-lms -ProductCode | select -expand Guid
$productversion = get-lms -LMSVersion
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

Write-Host "Check for updates on client '$lmssystemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."

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

Write-Host "Message Body ... `n'$body'"

$response = Invoke-RestMethod 'https://www.automation.siemens.com/softwareupdater/public/api/updates' -Method 'POST' -Headers $headers -Body $body

Write-Host "Message Response ..."
$response | ConvertTo-Json -depth 100
