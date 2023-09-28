#region Parameters
param(
	[string]$logfilename = "SIEMBT.log",
	[string]$logpath = "",
	[bool]$Verbose = $true,
	[bool]$skipErrors = $true
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
# Example of VD port entry:
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) === Network Info ===
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) Listening port: 27000
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) 
#
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) === LMGRD ===
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) Start-Date: Thu Sep 06 2018 10:34:03 Central Europe Daylight Time
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) PID: 1592
# 10:34:03 (lmgrd) (@lmgrd-SLOG@) LMGRD Version: v11.16.0.0 build 234449 i86_n3 ( build 234449 (ipv6))
#
#
# Example of FNLS port entry:
# 2023-09-26T19:27:01+0200 (SIEMBT) (@SIEMBT-SLOG@) === Network Info ===
# 2023-09-26T19:27:01+0200 (SIEMBT) (@SIEMBT-SLOG@) Listening port: 27009
# 2023-09-26T19:27:01+0200 (SIEMBT) (@SIEMBT-SLOG@) Daemon select timeout (in seconds): 1
# 2023-09-26T19:27:01+0200 (SIEMBT) (@SIEMBT-SLOG@) 
#
# 2023-09-26T10:34:07+0200 (SIEMBT) (@SIEMBT-SLOG@) === Vendor Daemon ===
# 2023-09-26T10:34:07+0200 (SIEMBT) (@SIEMBT-SLOG@) Vendor daemon: SIEMBT
# 2023-09-26T10:34:07+0200 (SIEMBT) (@SIEMBT-SLOG@) Start-Date: Thu Sep 06 2018 10:34:07 Central Europe Daylight Time
# 2023-09-26T10:34:07+0200 (SIEMBT) (@SIEMBT-SLOG@) PID: 1856
# 2023-09-26T10:34:07+0200 (SIEMBT) (@SIEMBT-SLOG@) VD Version: v11.16.0.0 build 234449 i86_n3 ( build 234449 (ipv6))
#
# ---------------------------------------------------------------------------------------
#
# '20230913': Initial version (created with help of Azure OpneAI studio)
# '20230921': Read-out backup file (in case a rollover has been performed)
# '20230922': Further improve; open any backup file till a 'host info' blok is found.
# '20230925': Store the 'Host Info' block in file "C:\ProgramData\Siemens\LMS\Logs\SIEMBT_HostInfo.txt"
# '20230927': Add command line option $Verbose, to enable/disable trace messages. Per default the traces are enabled. To set use command line option: -Verbose:$false
#             Add command line option $logfilename and $logpath, to specifiy which file in which folder to analyze. Default is: "$env:ProgramData\Siemens\LMS\Logs\SIEMBT.log"
#             -> Example to set: powershell -Command "& 'ExtractHostInfo.ps1' -logpath:'C:\CheckScriptArchive\Logs'"
#             Enhance the script to extract also the FNLS and VD port.
# '20230928': Extend to retreive also errors (from SIEMBT.log and rollover files) and store them in 'SIEMBT_Errors.log' (per default disabled, enable them with command line option: -skipErrors:$false )
#             Extract start date & time and PID of vendor daemon (VD) and Flexnet Licensign Service (FLNS)
#
$scriptVersion = '20230928'

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

if($Verbose) { Log-Message "Start script (skipErrors=$skipErrors) ..." }

$programDataPath = $env:ProgramData 
if( [string]::IsNullOrEmpty($logpath) )
{
	$logpath = "$programDataPath\Siemens\LMS\Logs\"
	if($Verbose) { Log-Message "LogPath: $logpath" }
}

$logpath = $logpath.TrimEnd("\")
$logFile = "$logpath\$logfilename"  
$hostinfoOutputFilePath = "$programDataPath\Siemens\LMS\Logs\SIEMBT_HostInfo.txt"  
$errorsOutputFilePath = "$programDataPath\Siemens\LMS\Logs\SIEMBT_Errors.log"  
$geninfoOutputFilePath = "$programDataPath\Siemens\LMS\Logs\SIEMBT_GenInfo.txt"  
$searchPatternHostInfo = "\r\n(.*? === Host Info ===\r\n.*?\r\n.*?\r\n.*?\r\n.*?\r\n.*?===============================================)\r\n"
$searchPatternBackupFile = "The debug log back-up is available in (C:.*)\r\n"
$searchPatternFNLSport = "\(@lmgrd-SLOG\@\) Listening port: (.*)\r\n" # search pattern for FNLS port
$searchPatternFNLSstartdatetime = "\(@lmgrd-SLOG\@\) Start-Date: (.*)\r\n" # search pattern for FNLS start date & time
$searchPatternFNLSpid = "\(@lmgrd-SLOG\@\) PID: (.*)\r\n" # search pattern for FNLS PID
$searchPatternVDport = "\(@SIEMBT-SLOG\@\) Listening port: (.*)\r\n" # search pattern for VD Port 
$searchPatternVDstartdatetime = "\(@SIEMBT-SLOG\@\) Start-Date: (.*)\r\n" # search pattern for VD start date & time
$searchPatternVDpid = "\(@SIEMBT-SLOG\@\) PID: (.*)\r\n" # search pattern for VD PID
$searchErrors = "((.*)ERROR:(.*))\r\n" # search pattern for errors

if( -not $skipErrors ) {
	# Delete (older) errors file
	Remove-Item -Path $errorsOutputFilePath -ErrorAction SilentlyContinue  
}

$hostInfoFound = $false
do {
	if (Test-Path $logFile) {  
		# Open the logfile and read them into one line
		if($Verbose) { Log-Message "Open file: $logFile" }
		$content = Get-Content $logFile | Out-String  
		if($Verbose) { Log-Message "File opened: $logFile" }
	  
		if( -not $fnlsPort ) {
			# Search for 'FNLS port' in open logfile  
			$matchesFNLSport = Select-String $searchPatternFNLSport -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesFNLSport) {  
				#$matchesFNLSport | ForEach-Object { Log-Message "FNLS port: $($_.Groups[1].Value)" }  
				
				$fnlsPort = $matchesFNLSport[-1].Groups[1].Value
				if($Verbose) { Log-Message "FNLS port: $fnlsPort (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "FNLS port: No matches found." }
			}  
		}
		if( -not $fnlsPID ) {
			# Search for 'FNLS port' in open logfile  
			$matchesFNLSpid = Select-String $searchPatternFNLSpid -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesFNLSpid) {  
				#$matchesFNLSpid | ForEach-Object { Log-Message "FNLS PID: $($_.Groups[1].Value)" }  
				
				$fnlsPID = $matchesFNLSpid[-1].Groups[1].Value
				if($Verbose) { Log-Message "FNLS PID: $fnlsPID (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "FNLS PID: No matches found." }
			}  
		}
		if( -not $fnlsStartDateTime ) {
			# Search for 'FNLS port' in open logfile  
			$matchesFNLSstartdatetime = Select-String $searchPatternFNLSstartdatetime -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesFNLSstartdatetime) {  
				#$matchesFNLSstartdatetime | ForEach-Object { Log-Message "FNLS start date & time: $($_.Groups[1].Value)" }  
				
				$fnlsStartDateTime = $matchesFNLSstartdatetime[-1].Groups[1].Value
				if($Verbose) { Log-Message "FNLS start date & time: $fnlsStartDateTime (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "FNLS start date & time: No matches found." }
			}  
		}

		if( -not $vdPort ) {
			# Search for 'VD port' in open logfile  
			$matchesVDport = Select-String $searchPatternVDport -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesVDport) {  
				#$matchesVDport | ForEach-Object { Log-Message "VD port: $($_.Groups[1].Value)" }  
				
				$vdPort = $matchesVDport[-1].Groups[1].Value
				if($Verbose) { Log-Message "VD port: $vdPort (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "VD port: No matches found." }
			}  
		}
		if( -not $vdPID ) {
			# Search for 'VD port' in open logfile  
			$matchesVDpid = Select-String $searchPatternVDpid -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesVDpid) {  
				#$matchesVDpid | ForEach-Object { Log-Message "VD PID: $($_.Groups[1].Value)" }  
				
				$vdPID = $matchesVDpid[-1].Groups[1].Value
				if($Verbose) { Log-Message "VD PID: $vdPID (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "VD PID: No matches found." }
			}  
		}
		if( -not $vdStartdatetime ) {
			# Search for 'VD port' in open logfile  
			$matchesVDstartdatetime = Select-String $searchPatternVDstartdatetime -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesVDstartdatetime) {  
				#$matchesVDstartdatetime | ForEach-Object { Log-Message "VD start date & time: $($_.Groups[1].Value)" }  
				
				$vdStartdatetime = $matchesVDstartdatetime[-1].Groups[1].Value
				if($Verbose) { Log-Message "VD start date & time: $vdStartdatetime (in $logFile)" }
			}  
			else {  
				if($Verbose) { Log-Message "VD start date & time: No matches found." }
			}  
		}
		
		if( -not $hostInfoFound ) {
			# Search for 'Host Info' in open logfile
			$matchesHostInfos = Select-String $searchPatternHostInfo -InputObject $content -AllMatches | % { $_.Matches }  
			# if 'Host Info' has been found ...
			if ($matchesHostInfos) {  
				if($Verbose) { Log-Message "Host Info: $($matchesHostInfos.Count) matches found." }
				
				# $matchesHostInfos | ForEach-Object { Log-Message "'Host Info' section found: `n$($_.Groups[1].Value)" }  
				
				$lastMatch = $matchesHostInfos[-1]  
				Log-Message "Most  recent 'Host Info' section: `n$lastMatch"
				
				Set-Content -Path $hostinfoOutputFilePath -Value $lastMatch
				if($Verbose) { Log-Message "Most  recent 'Host Info' section stored in '$hostinfoOutputFilePath'." }
				
				$hostInfoFound = $true
			} else {  
				if($Verbose) { Log-Message "'Host Info': No matches found." }
			}  
		}

		if( -not $skipErrors ) {
			# Search for errors in open logfile
			$matchesErrors = Select-String $searchErrors -InputObject $content -AllMatches | % { $_.Matches }  
			if ($matchesErrors) {  
				if($Verbose) { Log-Message "Errors: $($matchesErrors.Count) matches found." }
				#$matchesErrors | ForEach-Object { if($Verbose) { Log-Message "ERROR: $($_.Groups[1].Value)" } }  
				
				#Add-Content -Path $errorsOutputFilePath -Value $matchesErrors
				$matchesErrors | ForEach-Object { Add-Content -Path $errorsOutputFilePath -Value $($_.Groups[1].Value) } 

				if($Verbose) { Log-Message "Found errors stored in '$errorsOutputFilePath'." }
			} else {  
				if($Verbose) { Log-Message "Errors: No matches found." }
			}  
		}
		
		# Search for 'backup file' in open logfile  
		$matchesBackupFiles = Select-String $searchPatternBackupFile -InputObject $content -AllMatches | % { $_.Matches }  
		# If 'backup file' is found ....  
		if ($matchesBackupFiles) {  
			#$matchesBackupFiles | ForEach-Object { Log-Message "Backup File: $($_.Groups[1].Value)" }  
			
			$backupFile = $matchesBackupFiles[0].Groups[1].Value
			Log-Message "Backup File found: $backupFile (in $logFile)"
			$logFile = $backupFile
		} else {  
			$backupFile = ""
			Log-Message "Backup Files: No matches found."  
		}  
		#Log-Message "Backup Files: $($matchesBackupFiles.Count) matches found."
	}  else {
		$backupFile = ""
		if($Verbose) { Log-Message "File not found: $logFile" }
	}
	
} while ( (-not [string]::IsNullOrEmpty($backupFile)) -and ((-not $fnlsPort) -or (-not $vdPort) -or (-not $hostInfoFound) ) )

Log-Message "FNLS port: $fnlsPort / FNLS PID: $fnlsPID / FNLS start date & time: $fnlsStartDateTime"
Log-Message "VD port: $vdPort / VD PID: $vdPID / VD start date & time: $vdStartdatetime"

Set-Content -Path $geninfoOutputFilePath -Value "File $geninfoOutputFilePath created at $(Get-Date) .." -ErrorAction SilentlyContinue
Add-Content -Path $geninfoOutputFilePath -Value "FNLS port: $fnlsPort / FNLS PID: $fnlsPID / FNLS start date & time: $fnlsStartDateTime" -ErrorAction SilentlyContinue
Add-Content -Path $geninfoOutputFilePath -Value "VD port: $vdPort / VD PID: $vdPID / VD start date & time: $vdStartdatetime" -ErrorAction SilentlyContinue
if($Verbose) { Log-Message "General SIEMBT info stored in '$geninfoOutputFilePath'." }

if($Verbose) { Log-Message "Finish script ..." }
