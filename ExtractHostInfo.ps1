# ---------------------------------------------------------------------------------------
# © Siemens 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
# Example to analyze:
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) === Host Info ===
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) Host used in license file: md63ktbc
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) HostID node-locked in license file: NA
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) HostID of the License Server: "0050b6910a35 00155d0824d3 0a1120524153 06a920524153 067320524153 167bcbb3dea0 067bcbb3dea0 047bcbb3dea0"
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) Running on Hypervisor: None (Physical)
# 2023-09-07T12:11:00+0200 (SIEMBT) (@SIEMBT-SLOG@) ===============================================
#
# Example of 'backup file' entry:
# 2023-09-21T08:07:24+0200 (SIEMBT) Successful roll-over of debug log file C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log. The debug log back-up is available in C:\ProgramData\Siemens\LMS\Logs\SIEMBT.20230921_080723.log
#
# ---------------------------------------------------------------------------------------
#
# '20230913': Initial version (created with help of Azure OpneAI studio)
# '20230921': Read-out backup file (in case a rollover has been performed)
# '20230922': Further improve; open any backup file till a 'host info' blok is found.
#
$scriptVersion = '20230922'

$logFile = "C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log"  
$searchPatternHostInfo = "\r\n(.*? === Host Info ===\r\n.*?\r\n.*?\r\n.*?\r\n.*?\r\n.*?===============================================)\r\n"
$searchPatternBackupFile = "The debug log back-up is available in (C:.*)\r\n"

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

Log-Message "Start script ..."  

do {
	# Open the logfile and read them into one line
	Log-Message "Open file: $logFile"
	$content = Get-Content $logFile | Out-String  
	Log-Message "File opened: $logFile"
  
	# Search for 'Host Info' in open logfile
	$matchesHostInfos = Select-String $searchPatternHostInfo -InputObject $content -AllMatches | % { $_.Matches }  

	# if 'Host Info' has been found ...
	if ($matchesHostInfos) {  
		Log-Message "Host Info: $($matchesHostInfos.Count) matches found."
		
		# $matchesHostInfos | ForEach-Object { Log-Message "'Host Info' section found: `n$($_.Groups[1].Value)" }  
		
		$lastMatch = $matchesHostInfos[-1]  
		Log-Message "Most  recent 'Host Info' section: `n$lastMatch"
	} else {
		# Search for 'backup file' in open logfile  
		$matchesBackupFiles = Select-String $searchPatternBackupFile -InputObject $content -AllMatches | % { $_.Matches }  
		# If 'backup file' is found ....  
		if ($matchesBackupFiles) {  
			#$matchesBackupFiles | ForEach-Object { Log-Message "Backup File: $($_.Groups[1].Value)" }  
			
			$backupFile = $matchesBackupFiles[0].Groups[1].Value
			Log-Message "Backup File found: $backupFile (in $logFile)"
			$logFile = $backupFile
		}  
		else {  
			$backupFile = ""
			Log-Message "Backup Files: No matches found."  
		}  
		#Log-Message "Backup Files: $($matchesBackupFiles.Count) matches found."
	}
} while ( ($matchesHostInfos.Count -eq 0) -and (-not [string]::IsNullOrEmpty($backupFile)) )

Log-Message "Finish script ..."  
