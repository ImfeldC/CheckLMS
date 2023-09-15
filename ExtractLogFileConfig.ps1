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
        Write-Output "No files found."  
    } else {  
        Write-Output "Files found:"  
        foreach ($file in $files) {  
            Write-Output "- $($file.FullName)"  
        }  
    }  
  
    # Suchen nach Dateien mit dem angegebenen Namen und einem Wildcard-Platzhalter im Pfad  
    $wildcardName = $Name -replace "{pid}", "*"  
    $wildcardFiles = Get-ChildItem $Path -Filter "$wildcardName.*" -File  
  
    # Ausgabe der gefundenen Dateien  
    if ($wildcardFiles.Count -eq 0) {  
        Write-Output "No wildcard files found."  
    } else {  
        Write-Output "Wildcard files found:"  
        foreach ($file in $wildcardFiles) {  
            Write-Output "- $($file.FullName)"  
        }  
    }  
  
    # Ausgabe der Anzahl der gefundenen Dateien  
    $totalFiles = $files.Count + $wildcardFiles.Count  
    Write-Output "Total files found: $totalFiles"  
  
    # Rückgabe der gefundenen Dateien  
    return ,$files + $wildcardFiles  
}  
  
# XML-Konfigurationsdatei laden  
[xml]$config = Get-Content "C:\Program Files\Siemens\LMS\bin\lmslogcfg.xml"  
  
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
    $foundFiles = Find-Files -Path $filePath -Name $fileName  
  
    # Erstellen eines ZIP-Archivs mit den gefundenen Dateien  
    if ($foundFiles.Count -eq 0) {  
        Write-Output "No files found to archive."  
    } else {  
        # Erstellen eines Dateinamens für das ZIP-Archiv  
        $zipFileName = "$fileName.zip"  
  
        # Erstellen des Pfads für das ZIP-Archiv  
        $zipFilePath = Join-Path $filePath $zipFileName  
  
        # Prüfen, ob das ZIP-Archiv bereits existiert  
        if (Test-Path $zipFilePath) {  
            Write-Output "Deleting existing archive: $zipFilePath"  
            Remove-Item $zipFilePath  
        }  
  
        # Erstellen des ZIP-Archivs  
        Write-Output "Creating archive: $zipFilePath"  
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"  
        [System.IO.Compression.ZipFile]::CreateFromDirectory($filePath, $zipFilePath)  
  
        Write-Output "Archive created at $zipFilePath."  
    }  
}  
