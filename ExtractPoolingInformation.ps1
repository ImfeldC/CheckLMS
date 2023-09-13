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
#
$scriptVersion = '20230913'

$logFile = "C:\ProgramData\Siemens\LMS\Logs\SIEMBT.log"  
$searchPattern = "\r\n(.*?) Pooling (.*?)  and (.*?) \r\n.*? Updating feature (.*?)\r\n"

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
    $matches | ForEach-Object { Log-Message "Feature found with 'Pooling' at $($_.Groups[1].Value): $($_.Groups[4].Value) ( $($_.Groups[2].Value) / $($_.Groups[3].Value) )" }  
}  
else {  
    Log-Message "No matches found."  
}  
Log-Message "Finish script ..."  
