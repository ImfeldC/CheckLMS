$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$body = "{
`n    `"ProductCode`": `"6cf968fa-ffad-4593-9ecb-7a6f3ea07501`",
`n    `"ProductVersion`": `"?LMS_SCRIPT_BUILD?`",
`n    `"OperationSystem`": `"Windows10`",
`n    `"Language`": `"en-us`",
`n    `"clientType`":`"CheckLMS`",
`n    `"clientVersion`":`"?LMS_SCRIPT_BUILD?`",
`n    `"clientGUID`":`"?LMS_SYSTEMID?`",
`n    `"clientInfo`":
`n    {
`n        `"OS_MAJ_VERSION`":`"?OS_MAJ_VERSION?`",
`n        `"OS_MIN_VERSION`":`"?OS_MIN_VERSION?`",
`n        `"LMS_IS_VM`":`"?LMS_IS_VM?`",
`n        `"OS_MACHINEGUID`":`"?OS_MACHINEGUID?`"
`n    }
`n}"

$response = Invoke-RestMethod 'https://www.automation.siemens.com/softwareupdater/public/api/updates' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json -depth 100