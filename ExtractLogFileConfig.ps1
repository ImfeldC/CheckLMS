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
    #Write-Output "Appender: $($appender.InnerXml)"    
}  
