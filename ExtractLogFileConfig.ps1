# ---------------------------------------------------------------------------------------
# © Siemens 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
# '20230918': Initial version (created with help of Azure OpneAI studio)
#
$scriptVersion = '20230918'
# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
function Log-Message {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    $message = "[$scriptName/$scriptVersion] {0} - {1}" -f (Get-Date), $LogMessage
	[System.Console]::WriteLine( $message )
}

Log-Message "Start script ..."  

# Funktion zum Suchen von Dateien mit einem bestimmten Namen  
function Find-Files {  
    param (  
        [string]$Path,  
        [string]$Name  
    )  
  
    # Suchen nach Dateien mit dem angegebenen Namen im angegebenen Pfad  
    $files = Get-ChildItem $Path -Filter "$Name.*" -File  
  
    # Ausgabe der gefundenen Dateien  
    if ($files.Count -eq 0) {  
        [System.Console]::WriteLine( "No files found." )
    } else {  
        #[System.Console]::WriteLine( "$($files.Count) Files found:"  )
        #foreach ($file in $files) {  
        #    [System.Console]::WriteLine( "- $($file.FullName)" )
        #}  
    }  
  
    # Suchen nach Dateien mit dem angegebenen Namen und einem Wildcard-Platzhalter im Pfad  
    $wildcardName = $Name -replace "{pid}", "*"  
    $wildcardFiles = Get-ChildItem $Path -Filter "$wildcardName.*" -File  
  
    # Ausgabe der gefundenen Dateien  
    if ($wildcardFiles.Count -eq 0) {  
        [System.Console]::WriteLine( "No wildcard files found."  )
    } else {  
        #[System.Console]::WriteLine( "$($wildcardFiles.Count) Wildcard files found:"  )
        #foreach ($file in $wildcardFiles) {  
        #    [System.Console]::WriteLine( "- $($file.FullName)"  )
        #}  
    }  
  
    # Ausgabe der Anzahl der gefundenen Dateien  
    #$totalFiles = $files.Count + $wildcardFiles.Count  
    #[System.Console]::WriteLine( "Total files found: $totalFiles"  )
  
    # Rückgabe der gefundenen Dateien  
    return ($files + $wildcardFiles)
}  

# Function to create ZIP archive
function Create-ZipArchive {
    param (  
        [System.IO.FileInfo[]]$Files,  
        [string]$ZipArchive  
    )  

	# Enter the path for the temporary folder and create it if it doesn't exist  
	$tempFolder = "$Env:TEMP\ArchiveFiles"  
	# Empty the temporary folder if it already exists  
	if (Test-Path $tempFolder) {  
		Remove-Item $tempFolder -Recurse -Force  
	}	  
	if (!(Test-Path $tempFolder)) { New-Item -ItemType Directory -Path $tempFolder | Out-Null }  
	# Copy the files to the temporary folder  
	foreach ($file in $Files) {  
		#[System.Console]::WriteLine( "Copy $($file.FullName)"  )
		Copy-Item $file.FullName -Destination $tempFolder  
	}  

	# Enter the path and name for the ZIP archive  
	if (Test-Path $ZipArchive) { Remove-Item $ZipArchive }  

	# Create the ZIP archive  
	Compress-Archive -Path $tempFolder -DestinationPath $ZipArchive #-ErrorAction SilentlyContinue  

	# Create the ZIP archive  
	#foreach ($file in $foundFiles) {  
	#	[System.Console]::WriteLine( "Add $($file.FullName)"  )
	#	Compress-Archive -Path $($file.FullName) -Update -DestinationPath $ZipArchive #-ErrorAction SilentlyContinue  
	#}  

	#[System.Console]::WriteLine( "Zip Archive '$ZipArchive' created ..."  )
	#return $ZipArchive
}

# XML-Konfigurationsdatei laden  
[xml]$config = Get-Content "$Env:ProgramFiles\Siemens\LMS\bin\lmslogcfg.xml"  
  
# Appender mit dem Namen "ALL-OUT" auswählen  
$appender = $config.configuration.appender | Where-Object {$_.name -eq "ALL-OUT"}  
  
# Wert der Datei-Parameter des Appenders auswählen  
$fileValue = $appender.param | Where-Object {$_.name -eq "File"} | Select-Object -ExpandProperty value  
  
# Wert des Level-Parameters der Root-Kategorie auswählen  
$levelValue = $config.configuration.root.level.value  
  
# Prüfen, ob der Appender gefunden wurde  
if ($appender -eq $null) {    
    Log-Message "ERROR: Appender not found."    
} else {    
    # Dateipfad und Dateiname aus dem Datei-Parameter extrahieren  
    $filePath = Split-Path $fileValue  
    $fileName = Split-Path $fileValue -Leaf  
      
    # Wert von MaxBackupIndex auswählen  
    $maxBackupIndex = $appender.param | Where-Object {$_.name -eq "MaxBackupIndex"} | Select-Object -ExpandProperty value  
      
    # Ausgabe der Ergebnisse  
    Log-Message "File Value: $fileValue"    
    Log-Message "File Path: $filePath"  
    Log-Message "File Name: $fileName"  
    Log-Message "Max Backup Index: $maxBackupIndex"  
    Log-Message "Level Value: $levelValue"    
  
    # Aufrufen der Funktion zum Suchen von Dateien und Speichern der gefundenen Dateien in einer Variablen  
    Log-Message "Search files: $filePath / $fileName"    
    $foundFiles = Find-Files -Path $filePath -Name $fileName  
    Log-Message "Files found: $($foundFiles.Count)"    

	# Read a value from the registry key  
	$keyPath = "HKLM:\SOFTWARE\FLEXlm License Manager\Siemens BT Licensing Server"  
	$valueName = "LMGRD_LOG_FILE"  
	$logFilePath = (Get-ItemProperty -Path $keyPath).$valueName  
	# Remove the first character if it is a "+"  
	if ($logFilePath.StartsWith("+")) {  
		$logFilePath = $logFilePath.Substring(1)  
	}
	# Add the value to the list of files  
	$foundFiles += [System.IO.FileInfo]::new($logFilePath)
    Log-Message "Add file: $logFilePath"    

	# Remove duplicate file names  
	$uniqueFiles = $foundFiles | Select-Object -Unique  
    Log-Message "Unique Files found: $($uniqueFiles.Count)"    

	# Remove files from the list if they are in a known path  
	$knownPath = "$Env:ProgramData\Siemens\LMS\Logs"  
	$additionalFiles = $uniqueFiles | Where-Object { $_.FullName -notlike "$knownPath\*" }  
    Log-Message "Additional Files - outside of common LMS log folder - found: $($additionalFiles.Count)"    

	# Remove files larger than 200 MB  
	$largeFiles = $additionalFiles | Where-Object { $_.Length -gt 1GB }  
	foreach ($file in $largeFiles) {  
		Log-Message( "Skip large file $($file.FullName) with size of $($file.Length/1000/1000/1000) GB"  )
	}  
	$finalFiles = $additionalFiles | Where-Object { $_.Length -lt 1GB }  
    Log-Message "Files to be added to the ZIP archive: $($finalFiles.Count)"    

	if( ($finalFiles.Count) -gt 0 ) {
		$zipPath = "$Env:ProgramData\Siemens\LMS\Logs\Additional_LogFiles.zip"  
		Create-ZipArchive -Files $finalFiles -ZipArchive $zipPath 
		Log-Message "ZIP archive '$zipPath' created ..."    
		foreach ($file in $finalFiles) {  
			Log-Message( "File $($file.FullName) added ..."  )
		}  
	} else {
		Log-Message "No files to copy into ZIP archive ..."    
	}
	
	Log-Message "Script finished ..."    
}  
