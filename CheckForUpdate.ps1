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

Write-Host "Check for updates on client '$lmssystemid' for '$operatingsystem', for product '$productcode' with version '$productversion' ..."

$body = "{
`n    `"ProductCode`": `"$productcode`",
`n    `"ProductVersion`": `"$productversion`",
`n    `"OperationSystem`": `"$operatingsystem`",
`n    `"Language`": `"en-us`",
`n    `"clientType`":`"CheckForUpdate`",
`n    `"clientVersion`":`"20220311`",
`n    `"clientGUID`":`"$lmssystemid`"
`n}"

$response = Invoke-RestMethod 'https://www.automation.siemens.com/softwareupdater/public/api/updates' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json -depth 100
