# ---------------------------------------------------------------------------------------
# © Siemens 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
# '20231019': Initial version (created by Andrej and attached to Defect 2368196)
# '20231020': Adjust to Siemens style guide. Add enhanced error handling. Execution is logged into SetOnlineCheckUser.log
# '20231112': Replace 'Write-Output' with 'Write-Host', to ensure that function return is not poluted with log output.
# '20231114': Align further to common powershell architecture. Add 'ms' to log output.
#
$scriptVersion = '20231114'

$programDataPath = $env:ProgramData 

# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
$logFile = "$programDataPath\Siemens\LMS\Logs\SetOnlineCheckUser.log"  
function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

	$logEntry = "[$scriptName/$scriptVersion] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.ffff') - $LogMessage"  
	#Write-Host $logEntry
	Add-Content -Path $logFile -Value $logEntry -Encoding UTF8  -ErrorAction SilentlyContinue
}

Log-Message "Start script ..."

# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird  
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")  
  
# Überprüfen, ob der Benutzer Admin-Rechte hat  
if ($isAdmin) {  
	Log-Message "User has administrator rights."

	Write-Host ""
	$pswd = Read-Host "Please enter your current user password" -AsSecureString
	Write-Host ""
	$plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pswd))
	$user = New-Object System.Security.Principal.NTAccount($env:USERNAME)
	$sid = $user.Translate([System.Security.Principal.SecurityIdentifier])
	$result = Set-ScheduledTask -TaskName "Siemens\Lms\OnlineCheckDaily" -User $sid -Password $plaintextPassword -ErrorAction SilentlyContinue

	if ($?)
	{
		Log-Message "The scheduled task 'OnlineCheckDaily' has been successfully configured with username '$env:USERNAME' (sid='$sid') and password."
		Write-Host "The scheduled task 'OnlineCheckDaily' has been successfully configured with your username and password."
		Write-Host ""
	}
	else
	{
		$errorMessage = $Error[0].Exception.Message
		#$errorMessage.Replace("`r","").Replace("`n","")
		$errorMessage = $errorMessage -replace [Environment]::NewLine, "" 
		Log-Message "Updating the scheduled task 'OnlineCheckDaily' has failed for user '$env:USERNAME' (sid='$sid'), with '$errorMessage'"
		Write-Host "Updating the scheduled task 'OnlineCheckDaily' has failed, with '$errorMessage'"
		Write-Host ""
	}

} else {  
	Log-Message "User has NO administrator rights."
    Write-Host "You need administrator rights to execute this script successfully."  
	Write-Host ""
}  

Log-Message "Finish script ..."