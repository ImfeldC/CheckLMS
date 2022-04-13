#region Parameters
param(
	[string]$operatingsystem = 'Windows10'
)
#endregion

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$productcode = get-lms -ProductCode | select -expand Guid
$productversion = get-lms -LMSVersion
$lmssystemid = get-lms -SystemId

# retrieve client info ....
$LMS_IS_VM = (gcim Win32_ComputerSystem).HypervisorPresent
$OS_MACHINEGUID = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' | select -expand MachineGuid
$OS_PRODUCTNAME = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName' | select -expand ProductName
$OS_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentVersion' | select -expand CurrentVersion
$OS_MAJ_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMajorVersionNumber' | select -expand CurrentMajorVersionNumber
$OS_MIN_VERSION = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentMinorVersionNumber' | select -expand CurrentMinorVersionNumber
$LMS_PS_CSID = get-lms -Csid

Write-Host "Check for updates on client '$lmssystemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."

$body = "{
    `"ProductCode`": `"$productcode`",
    `"ProductVersion`": `"$productversion`",
    `"OperationSystem`": `"$operatingsystem`",
    `"Language`": `"en-us`",
    `"clientType`":`"CheckForUpdate`",
    `"clientVersion`":`"20220413`",
    `"clientGUID`":`"$lmssystemid`",
    `"clientInfo`":
    {
        `"CSID`":`"$LMS_PS_CSID`",
        `"LMS_IS_VM`":`"$LMS_IS_VM`",
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
