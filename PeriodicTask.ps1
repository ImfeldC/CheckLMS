<#  
.SYNOPSIS  
  Script which get executed peridically by a scheduled task.  
.DESCRIPTION  
  This script executes commands (e.g. clean-up tasks) which will be executed periodically.  
.NOTES  
  Copyright (c) 2023 Siemens. All rights reserved.  
  
  THIS CODE IS SAMPLE CODE AND IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
  
  Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
  Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
  
  Author: Christian.Imfeld@Siemens.com   
  Creation Date: 06-Sep-2023  

  Purpose/Change: 
  '20230906': Initial Version   
  '20230925': Execute also 'ExtractHostInfo.ps1' periodically
  '20231108': Add output to logfile: "$env:ProgramData\Siemens\LMS\Logs\PeriodicTask.log"
              Do no longer redirect output within this script. (Fix: Defect 2386252)
			  Do no longer call 'push-fpstore -startup -ErrorAction SilentlyContinue'
#>
$scriptVersion = '20231108'

# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
$logFile = "$env:ProgramData\Siemens\LMS\Logs\PeriodicTask.log"  
function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

	$logEntry = "[$scriptName/$scriptVersion] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $LogMessage"  
	Write-Output $logEntry
	Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 
}

Log-Message "Start script ..."  

try
{
	add-pssnapin "PushFpStoreSnapin"
}
catch
{
	write-Host "already installed"
}

if (Test-Path "$env:ProgramFiles\Siemens\LMS\scripts\CleanUp.ps1") {  
    & "$env:ProgramFiles\Siemens\LMS\scripts\CleanUp.ps1"  
}

if (Test-Path "$env:ProgramFiles\Siemens\LMS\scripts\ExtractHostInfo.ps1") {  
    & "$env:ProgramFiles\Siemens\LMS\scripts\ExtractHostInfo.ps1"
}

Log-Message "Finish script ..."  
