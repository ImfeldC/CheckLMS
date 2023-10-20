
Write-Host ""
$pswd = Read-Host "Please enter your current user password" -AsSecureString
Write-Host ""
$plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pswd))
$user = New-Object System.Security.Principal.NTAccount($env:USERNAME)
$sid = $user.Translate([System.Security.Principal.SecurityIdentifier])
$result = Set-ScheduledTask -TaskName "Siemens\Lms\OnlineCheckDaily" -User $sid -Password $plaintextPassword

if ($?)
{
	Write-Host "The scheduled task 'OnlineCheckDaily' has been successfully configured with your username and password."
	Write-Host ""
}
else
{
	Write-Host "Updating the scheduled task 'OnlineCheckDaily' has failed!"
	Write-Host ""
}
