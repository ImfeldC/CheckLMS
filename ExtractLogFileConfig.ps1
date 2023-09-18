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
        [System.Console]::WriteLine( "$($files.Count) Files found:"  )
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
        [System.Console]::WriteLine( "$($wildcardFiles.Count) Wildcard files found:"  )
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
        [string[]]$Files,  
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
	foreach ($file in $uniqueFiles) {  
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

	[System.Console]::WriteLine( "Zip Archive '$ZipArchive' created ..."  )
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
    Write-Output "ERROR: Appender not found."    
} else {    
    # Dateipfad und Dateiname aus dem Datei-Parameter extrahieren  
    $filePath = Split-Path $fileValue  
    $fileName = Split-Path $fileValue -Leaf  
      
    # Wert von MaxBackupIndex auswählen  
    $maxBackupIndex = $appender.param | Where-Object {$_.name -eq "MaxBackupIndex"} | Select-Object -ExpandProperty value  
      
    # Ausgabe der Ergebnisse  
    Write-Output "File Value: $fileValue"    
    Write-Output "File Path: $filePath"  
    Write-Output "File Name: $fileName"  
    Write-Output "Max Backup Index: $maxBackupIndex"  
    Write-Output "Level Value: $levelValue"    
  
    # Aufrufen der Funktion zum Suchen von Dateien und Speichern der gefundenen Dateien in einer Variablen  
    Write-Output "Search files: $filePath / $fileName"    
    $foundFiles = Find-Files -Path $filePath -Name $fileName  
    Write-Output "Files found: $($foundFiles.Count)"    

	# Remove duplicate file names  
	$uniqueFiles = $foundFiles | Select-Object -Unique  
    Write-Output "Unique Files found: $($uniqueFiles.Count)"    

	# Remove files from the list if they are in a known path  
	$knownPath = "$Env:ProgramData\Siemens\LMS\Logs"  
	$finalFiles = $uniqueFiles | Where-Object { $_.FullName -notlike "$knownPath\*" }  
    Write-Output "Final Files found: $($finalFiles.Count)"    

	if( ($finalFiles.Count) -gt 0 ) {
		$zipPath = "$Env:ProgramData\Siemens\LMS\Logs\CheckLMSLogs\archive_licenf.zip"  
		Create-ZipArchive -Files $finalFiles -ZipArchive $zipPath 
	} else {
		Write-Output "No files to copy into ZIP archive ..."    
	}
	
	Write-Output "Script finished ..."    
}  
