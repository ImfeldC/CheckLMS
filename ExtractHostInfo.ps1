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
# ---------------------------------------------------------------------------------------
#
# '20230913': Initial version (created with help of Azure OpneAI studio)
#
$scriptVersion = '20230913'

$logFile = "C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log"  
$searchPattern = "\r\n(.*? === Host Info ===\r\n.*?\r\n.*?\r\n.*?\r\n.*?\r\n.*?===============================================)\r\n"

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

# Öffnen Sie die Log-Datei und lesen Sie den Inhalt in eine einzige Zeichenfolge  
$content = Get-Content $logFile | Out-String  
  
# Suchen Sie nach dem Muster in der Zeichenfolge  
$matches = Select-String $searchPattern -InputObject $content -AllMatches | % { $_.Matches }  
  
# Wenn Übereinstimmungen gefunden wurden, geben Sie sie aus  
if ($matches) {  
	Log-Message "$($matches.Count) matches found."
	
    # $matches | ForEach-Object { Log-Message "'Host Info' section found: `n$($_.Groups[1].Value)" }  
	
	$lastMatch = $matches[-1]  
	Log-Message "Latest 'Host Info' section found: `n$lastMatch"
}  
else {  
    Log-Message "No matches found."  
}  
Log-Message "Finish script ..."  
