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
  
    # Aufrufen der Funktion zum Suchen von Dateien  
    Find-Files -Path $filePath -Name $fileName  
}  
