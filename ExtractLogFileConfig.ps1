[xml]$config = Get-Content "C:\Program Files\Siemens\LMS\bin\lmslogcfg.xml"    
$appender = $config.configuration.appender | Where-Object {$_.name -eq "ALL-OUT"}    
$fileValue = $appender.param | Where-Object {$_.name -eq "File"} | Select-Object -ExpandProperty value    
$maxBackupIndex = $appender.param | Where-Object {$_.name -eq "MaxBackupIndex"} | Select-Object -ExpandProperty value    
$levelValue = $config.configuration.root.level.value    
if ($appender -eq $null) {    
    Write-Output "ERROR: Appender not found."    
} else {    
    $filePath = Split-Path $fileValue  
    Write-Output "File Value: $fileValue"    
    Write-Output "File Path: $filePath"  
    Write-Output "Max Backup Index: $maxBackupIndex"  
    Write-Output "Level Value: $levelValue"    
    Write-Output "Appender: $($appender.InnerXml)"    
}  
