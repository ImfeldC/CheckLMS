#region Parameters
param(
	[string]$logfilename = "SIEMBT.log",
	[string]$logpath = "",
	[bool]$Verbose = $true
)
#endregion
# ---------------------------------------------------------------------------------------
# © Siemens 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
# Example to analyze:
# 2023-09-11T15:33:19+0200 (SIEMBT) Updating feature si_sipass_base
# 2023-09-11T15:33:19+0200 (SIEMBT) Pooling 00C8 B4AF 1648 7024  and 00D8 FA08 3246 61E3 
# 2023-09-11T15:33:19+0200 (SIEMBT) Updating feature sbt_lms_connection_test
#
# ---------------------------------------------------------------------------------------
#
# '20230913': Initial version (created with help of Azure OpneAI studio)
# '20230927': Consider 'rollover' and load older backup files for further analysis.
#             Add command line option $Verbose, to enable/disable trace messages. Per default the traces are enabled. To set use command line option: -Verbose:$false
#             Add command line option $logfilename and $logpath, to specifiy which file in which folder to analyze. Default is: "$env:ProgramData\Siemens\LMS\Logs\SIEMBT.log"
#             -> Example to set: powershell -Command "& 'ExtractPoolingInformation.ps1' -logpath:'C:\CheckScriptArchive\Logs'"
# '20231112': Replace 'Write-Output' with 'Write-Host', to ensure that function return is not poluted with log output.
#
$scriptVersion = '20231112'

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

    Write-Host ("[$scriptName/$scriptVersion] {0} - {1}" -f (Get-Date), $LogMessage)
}

if($Verbose) { Log-Message "Start script ..." }

if( [string]::IsNullOrEmpty($logpath) )
{
	$programDataPath = $env:ProgramData 
	$logpath = "$programDataPath\Siemens\LMS\Logs\"
	if($Verbose) { Log-Message "LogPath: $logpath" }
}

$logpath = $logpath.TrimEnd("\")
$logFile = "$logpath\$logfilename"  
$searchPattern = "\r\n(.*?) Pooling (.*?)  and (.*?) \r\n.*? Updating feature (.*?)\r\n"
$searchPatternBackupFile = "The debug log back-up is available in (C:.*)\r\n"

do {
	if (Test-Path $logFile) {  
		# Open the logfile and read them into one line
		Log-Message "Open file: $logFile" 
		$content = Get-Content $logFile | Out-String  
		  
		# Suchen Sie nach dem Muster in der Zeichenfolge  
		$matches = Select-String $searchPattern -InputObject $content -AllMatches | % { $_.Matches }  
		  
		# Wenn Übereinstimmungen gefunden wurden, geben Sie sie aus  
		if ($matches) {  
			$matches | ForEach-Object { Log-Message "Feature found with 'Pooling' at $($_.Groups[1].Value): $($_.Groups[4].Value) ( $($_.Groups[2].Value) / $($_.Groups[3].Value) )" }  
		}  
		else {  
			if($Verbose) { Log-Message "No matches found." } 
		}  

		# Search for 'backup file' in open logfile  
		$matchesBackupFiles = Select-String $searchPatternBackupFile -InputObject $content -AllMatches | % { $_.Matches }  
		# If 'backup file' is found ....  
		if ($matchesBackupFiles) {  
			#$matchesBackupFiles | ForEach-Object { Log-Message "Backup File: $($_.Groups[1].Value)" }  
			
			$backupFile = $matchesBackupFiles[0].Groups[1].Value
			if($Verbose) { Log-Message "Backup File found: $backupFile (in $logFile)" }
			$logFile = $backupFile
		} else {  
			$backupFile = ""
			if($Verbose) { Log-Message "Backup Files: No matches found." }
		}  
	}  else {
		$backupFile = ""
		if($Verbose) { Log-Message "File not found: $logFile" }
	}
} while ( -not [string]::IsNullOrEmpty($backupFile) )

if($Verbose) { Log-Message "Finish script ..." }
