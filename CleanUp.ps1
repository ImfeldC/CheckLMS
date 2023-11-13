<#  
.SYNOPSIS  
  Deletes old log files from the Siemens LMS Logs directory.  
.DESCRIPTION  
  This script perofrms a rollover on SIEMBT.log
  It also deletes log files from the Siemens LMS Logs directory that are older than 30 days and match the pattern 'licenf.*.log' or 'licenf.*.log.*' or 'licenf.log.*' or 'SIEMBT.*.log'. 
  It also deletes log files that are larger than 500 MB and have the extension '.log'.  
.NOTES  
  Copyright (c) 2023 Siemens. All rights reserved.  
  
  Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
  Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
  
  Author: Christian.Imfeld@Siemens.com   
  Creation Date: 06-Sep-2023  
  Purpose/Change: 
  20230906: Implement rollover function for SIEMBT.log  
  20230925: Adjust to common format, include function Log-Message
  20230928: Check result of file deletion.
  20231108: Delete local available FNP SDK [ZIP and EXE] and its unzipped content. (Fix: Defect 2385072)
#>
$scriptVersion = '20231108'

# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
$logFile = "$env:ProgramData\Siemens\LMS\Logs\CleanUp.log"  
function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

	$logEntry = "[$scriptName/$scriptVersion] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $LogMessage"  
	Write-Output $logEntry
	Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 
}

Log-Message "Starting log cleanup script..."  

$encoding = [Console]::OutputEncoding  
Log-Message "Verwendetes Encoding: $encoding"

# Rollover SIEMBT.log
$programFilePath=${Env:ProgramFiles(x86)}
$switchExePath = "$programFilePath\Siemens\LMS\server\lmswitch.exe"  
$logFolderPath = "$env:ProgramData\Siemens\LMS\Logs"  
$licenseFilePath = "$env:ProgramData\Siemens\LMS\Server Certificates\LicenseFile-Dummy_valid_Product.lic"  
$maxSize = 100MB  
$logFiles = Get-ChildItem -Path $logFolderPath -Filter SIEMBT.log | Where-Object { $_.Length -gt $maxSize }  
if ($logFiles.Count -eq 0) {  
    Log-Message "SIEMBT.log file is not larger than $($maxSize/1MB) MB."  
} else {  
	if (Test-Path $switchExePath) {  
		$logFileName = "SIEMBT.$(Get-Date -Format 'yyyyMMdd_HHmmss').log"  
		$logFilePath = Join-Path $logFolderPath $logFileName  
		Log-Message "Perform rollover for SIEMBT.log: '$switchExePath -c ""$licenseFilePath"" SIEMBT ""$logFilePath"" -rollover'."  
		& $switchExePath -c ""$licenseFilePath"" SIEMBT ""$logFilePath"" -rollover
		Log-Message "Rollover for SIEMBT.log executed. Saved in '$logFilePath'."  
	} else {
		Log-Message "Exectuable '$switchExePath' doesn't exists."  
	}
}  

# Delete log files older than 30 days and matching the pattern 'licenf.*.log' or 'licenf.*.log.*' or 'licenf.log.*' or 'SIEMBT.*.log'  
$limit = (Get-Date).AddDays(-30)  
$deletedFiles = Get-ChildItem -Path $logFolderPath | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit -and ($_.Name -like "licenf.*.log" -or $_.Name -like "licenf.*.log.*" -or $_.Name -like "licenf.log.*" -or $_.Name -like "SIEMBT.*.log") }  
if ($deletedFiles.Count -eq 0) {  
    Log-Message "No log files found that match the criteria 'licenf.*.log' or 'licenf.*.log.*' or 'licenf.log.*' or 'SIEMBT.*.log' and are older then $limit."  
} else {  
    Log-Message "Found $($deletedFiles.Count) log files that match the criteria 'licenf.*.log' or 'licenf.*.log.*' or 'licenf.log.*' or 'SIEMBT.*.log' and are older then $limit. Deleting..."  
    $deletedFiles | ForEach-Object {  
        $_ | Remove-Item -ErrorAction SilentlyContinue 
		if ($?) {  
			Log-Message "Deleted file: $($_.FullName)"  
		} else {  
			Log-Message "FAILED: Deletion of file: $($_.FullName)"  
		}
    }  
    Log-Message "Deleted $($deletedFiles.Count) log files."  
}  
  
# Delete log files older than 3 days and matching the pattern 'flex*.log'  
$limit = (Get-Date).AddDays(-3)  
$deletedFiles = Get-ChildItem -Path $logFolderPath | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit -and ($_.Name -like "flex*.log") }  
if ($deletedFiles.Count -eq 0) {  
    Log-Message "No log files found that match the criteria 'flex*.log' and are older then $limit."  
} else {  
    Log-Message "Found $($deletedFiles.Count) log files that match the criteria 'flex*.log' and are older then $limit. Deleting..."  
    $deletedFiles | ForEach-Object {  
        $_ | Remove-Item -ErrorAction SilentlyContinue 
		if ($?) {  
			Log-Message "Deleted file: $($_.FullName)"  
		} else {  
			Log-Message "FAILED: Deletion of file: $($_.FullName)"  
		}
    }  
    Log-Message "Deleted $($deletedFiles.Count) log files."  
}  
  
# Delete log files larger than 500 MB and with the extension '.log'  
$maxSize = 500MB  
$logFiles = Get-ChildItem -Path $logFolderPath -Filter *.log | Where-Object { $_.Length -gt $maxSize }  
if ($logFiles.Count -eq 0) {  
    Log-Message "No log files found that are larger than $($maxSize/1MB) MB and have the extension '.log'."  
} else {  
    Log-Message "Found $($logFiles.Count) log files that are larger than $($maxSize/1MB) MB and have the extension '.log'. Deleting..."  
    $logFiles | ForEach-Object {  
        $_ | Remove-Item -ErrorAction SilentlyContinue 
		if ($?) {  
			Log-Message "Deleted file: $($_.FullName)"  
		} else {  
			Log-Message "FAILED: Deletion of file: $($_.FullName)"  
		}
    }  
    Log-Message "Deleted $($logFiles.Count) log files."  
}  

# Delete local available FNP SDK [ZIP and EXE] and its unzipped content.
$downloadPath = "$env:ProgramData\Siemens\LMS\Download\"  
$expirationDate = Get-Date -Year 2023 -Month 11 -Day 11  

# Check if the directory exists  
if (Test-Path -Path $downloadPath) {  
    # Adjust the file and directory patterns accordingly  
    $zipPattern = "SiemensFNP-*-Binaries.zip"  
    $exePattern = "SiemensFNP-*-Binaries.exe" 
	$dirPattern = "SiemensFNP-*-Binaries"
  
    # Find all files and directories that match the specified patterns and are older than the expiration date  
    $zipFiles = Get-ChildItem -Path $downloadPath -File -Filter $zipPattern | Where-Object { $_.LastWriteTime -lt $expirationDate }  
    $exeFiles = Get-ChildItem -Path $downloadPath -File -Filter $exePattern | Where-Object { $_.LastWriteTime -lt $expirationDate }  
	$directories = Get-ChildItem -Path $downloadPath -Directory -Filter $dirPattern | Where-Object { $_.LastWriteTime -lt $expirationDate } 
  
    # Delete each found .zip file  
	if ($zipFiles.Count -eq 0) {  
		Log-Message "No ZIP files found that match the criteria '$zipPattern' and are older then $expirationDate."  
	} else {  
		Log-Message "Found $($zipFiles.Count) ZIP files that match the criteria '$zipPattern' and are older then $expirationDate. Deleting..."  
		foreach ($zipfile in $zipFiles) {  
			$deleteResult = $null
			Remove-Item -Path $zipfile.FullName -Force -ErrorVariable deleteResult -ErrorAction SilentlyContinue  
			if (!$deleteResult) {  
				Log-Message "Deleted file: $($zipfile.FullName)"  
			} else {  
				Log-Message "FAILED: Deletion of file: $($zipfile.FullName)"  
			}
		}  
	}
	
    # Delete each found .exe file  
	if ($exeFiles.Count -eq 0) {  
		Log-Message "No EXE files found that match the criteria '$exePattern' and are older then $expirationDate."  
	} else {  
		Log-Message "Found $($exeFiles.Count) EXE files that match the criteria '$exePattern' and are older then $expirationDate. Deleting..."  
		foreach ($exeFile in $exeFiles) {  
			$deleteResult = $null
			Remove-Item -Path $exeFile.FullName -Force -ErrorVariable deleteResult -ErrorAction SilentlyContinue  
			if (!$deleteResult) {  
				Log-Message "Deleted file: $($exeFile.FullName)"  
			} else {  
				Log-Message "FAILED: Deletion of file: $($exeFile.FullName)"  
			}
		}  
	}
	
    # Delete each found directory and its contents  
	if ($directories.Count -eq 0) {  
		Log-Message "No directory found that match the criteria '$dirPattern' and are older then $expirationDate."  
	} else {  
		Log-Message "Found $($directories.Count) directories that match the criteria '$dirPattern' and are older then $expirationDate. Deleting..."  
		foreach ($directory in $directories) {  
			$deleteResult = $null
			Remove-Item -Path $directory.FullName -Recurse -Force -ErrorVariable deleteResult -ErrorAction SilentlyContinue  
			if (!$deleteResult) {  
				Log-Message "Deleted directory: $($directory.FullName)"  
			} else {  
				Log-Message "FAILED: Deletion of directory: $($directory.FullName)"  
			}
		}  
	}
	
    # Delete the $LMS_DOWNLOAD_PATH directory if it is empty  
    if ((Get-ChildItem -Path $downloadPath).Count -eq 0) {  
        $deleteResult = Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue  
		if ($deleteResult) {  
			Log-Message "Deleted directory: $downloadPath"  
		} else {  
			Log-Message "FAILED: Deletion of directory: $downloadPath"  
		}
    }  
}  

Log-Message "Log cleanup script finished."
