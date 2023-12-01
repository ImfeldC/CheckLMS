#region Parameters
param (  
    [Parameter(Mandatory=$false, Position=0)]  
    [string]$sourcePath = "$env:ProgramFiles\Siemens\LMS\scripts\",  
  
    [Parameter(Mandatory=$false, Position=1)]  
    [string]$zipFilePath = "$env:ProgramData\Siemens\LMS\Logs\CheckLMS.zip",  
  
    [Parameter(Mandatory=$false, Position=2)]  
    [string]$modulePath = "$env:ProgramFiles\Siemens\LMS\scripts",  
  
    [switch]$Force,  
    [switch]$Upload  
)  
#endregion
# ---------------------------------------------------------------------------------------
# © Siemens 2022 - 2023
#
# Transmittal, reproduction, dissemination and/or editing of this document as well as utilization ofits contents and communication thereof to others without express authorization are prohibited.
# Offenders will be held liable for payment of damages. All rights created by patent grant orregistration of a utility model or design patent are reserved.
# ---------------------------------------------------------------------------------------
#
# This script creates a ZIP archive to distribute CheckLMS package.
#
# Purpose/Change: 
# '20231129': Initial script to create CheckLMS package  
# '20231201': First running version, to create CheckLMS packages  
#             Introduce 'modulePath' to specify path where to load common PS function module.
#
$scriptVersion = '20231201'

$scriptFilename="CheckLMS.bat"
$scriptName = $MyInvocation.MyCommand.Name

# Filters for the file extensions  
$extensions = @()  
$files = @("CheckLMS.bat")  

# Unload all loaded modules (only required for debug reason, e.g. when module has changed)
Get-Module | Remove-Module
#$modulePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent 
#$modulePath = "$env:ProgramFiles\Siemens\LMS\scripts" 
#$modulePath = "C:\UserData\imfeldc\OneDrive - Siemens AG\scripts"
Import-Module -Name "$modulePath\CommonPSFunctions.psm1"  -DisableNameChecking


if( $modulePath -eq "." ) {
	$modulePath = $PWD.Path
}
if( $sourcePath -eq "." ) {
	$sourcePath = $PWD.Path
}
Write-Message "Start CreateCheckLMSPackage script ... with option sourcePath=$sourcePath, zipFilePath=$zipFilePath, modulePath=$modulePath, Force=$Force, Upload=$Upload" $scriptName $scriptVersion 

# Check if the source directory exists  
if (Test-Path $sourcePath) {  
    # Check if the ZIP file already exists  
    if (Test-Path $zipFilePath) {  
        if (!$Force) {  
            Write-Message "The ZIP file already exists: $zipFilePath" $scriptName $scriptVersionv  
            return  
        }  
        else {  
            Remove-Item -Path $zipFilePath -Force  
        }  
    }  
 
 	# Read-out version of LMS CheckLMS Package
	$result = Get-CheckLMSVersionValues -filePath "$sourcePath"  
	Write-Message "CheckLMS Version: '$($result.strVersion)'  ($($result.strBuild)) installed at '$($result.fileName)'" $scriptName $scriptVersion 

    # Create ZIP archive  
    Add-Type -A 'System.IO.Compression.FileSystem'  
    $zipFile = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')  
  
    # Create report file  
    $reportFilePath = Join-Path (Split-Path $zipFilePath) "LMSBgInfoPackage.txt"  
    $reportContent = @()  
  
    $reportContent += "LMS CheckLMS package from '{0}'." -f $sourcePath
    $reportContent += "CheckLMS Version: '$($result.strVersion)'  ($($result.strBuild))"
    try {  
        # Filter files in the source directory based on specified extensions  
        $actFiles = Get-ChildItem -Path $sourcePath -File -Recurse   
		#Write-Message "$($actFiles.Count) files found in path '$sourcePath'" $scriptName $scriptVersion
		$actFiles = Get-ChildItem -Path $sourcePath -File -Recurse | Where-Object {$extensions -contains $_.Extension.ToLowerInvariant()}  
		#Write-Message "$($actFiles.Count) found to be added to the ZIP archive, which match the filter '$extensions'" $scriptName $scriptVersion
		
		# Search the directory and its subdirectories for the specified files  
		$foundFiles = Get-ChildItem -Path $sourcePath -Include $files -Recurse -File  
		#Write-Message "$($foundFiles.Count) files found in path '$sourcePath'" $scriptName $scriptVersion

		# Search the directory and its subdirectories for the script file  
		$scriptFiles = Get-ChildItem -Path $sourcePath -Include $scriptFilename -Recurse -File  
		Write-Message "$($scriptFiles.Count) files found in path '$sourcePath' with the name '$scriptFilename'" $scriptName $scriptVersion

		$combinedFiles = $actFiles + $foundFiles  
		Write-Message "Totaly $($combinedFiles.Count) files found to be added to the ZIP archive." $scriptName $scriptVersion

        #foreach ($file in $combinedFiles) {  
		#	Write-Message "Check file: $file with Extension $($file.Extension)" $scriptName $scriptVersion
		#	if( $extensions -contains $file.Extension.ToLowerInvariant() ) {
		#		Write-Message "File found ... $file" $scriptName $scriptVersion
		#	}
		#}
  
        # Add files to the ZIP archive and collect file names for the report  
		$i=0
        foreach ($file in $combinedFiles) {  
            $zipFileEntry = $zipFile.CreateEntry($file.Name)  
            $zipStream = $zipFileEntry.Open()  
            $fileStream = $file.OpenRead()  
			$i++
  
            try {  
                $fileStream.CopyTo($zipStream)  
  
                # Add file name to the report content 
				$version = Get-ScriptVersion -FilePath $file.Fullname
				$fileHash = Get-FileHash -Path $file.Fullname -Algorithm MD5 -ErrorAction SilentlyContinue 
                #$reportContent += "[{0,3}] {1,-50} [{2,3} KB] {3} / Hash={4}" -f $i, $file.Name, [Math]::Ceiling($file.Length / 1024), $file.LastWriteTime, $fileHash
                $reportContent += "[{0,3}] {1,-50} [{2,3} KB] {3} / Version={4,10}, Hash={5}" -f $i, $file.Name, [Math]::Ceiling($file.Length / 1024), $file.LastWriteTime, $version, $fileHash
            }  
            finally {  
                $zipStream.Close()  
                $fileStream.Close()  
            }  
        }  
    }  
    finally {  
        $zipFile.Dispose()  
    }  

    if (Test-Path $zipFilePath) {  
		# Calculate hash from LMS CheckLMS ZIP package
		$zipFileHash = Get-FileHash -Path $zipFilePath
		Write-Message "zipFileHash=$zipFileHash" $scriptName $scriptVersion

		# Finalize the LMS CheckLMS package report
		$reportContent += "LMS CheckLMS package created at '{0}' on machine '{1}' by user '{2}'." -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.ffff'), $env:COMPUTERNAME, $env:USERNAME
		$reportContent += "LMS CheckLMS ZIP package available at '{0}', with Hash={1}" -f $zipFilePath, $zipFileHash
	  
		# Write the report content to the report file  
		$reportContent | Out-File -FilePath $reportFilePath  
	  
		Write-Message "The ZIP archive has been created successfully: $zipFilePath" $scriptName $scriptVersion  
		Write-Message "The report file has been created: $reportFilePath" $scriptName $scriptVersion  
		
		if( $Upload ) {
			if( $scriptFiles.Count -eq 1) {
				Write-Message "$($scriptFiles.Count) script file found, will upload content to AWS." $scriptName $scriptVersion  
				$scriptFile = $scriptFiles | Select-Object -First 1
				
				# CheckLMS.bat -> lms/CheckLMS/CheckLMS.bat
				Upload-AWS $scriptFile.Name "lms/CheckLMS/"
				# $zipFilePath -> lms/CheckLMS/
				Upload-AWS $zipFilePath "lms/CheckLMS/"
				# $reportFilePath -> lms/CheckLMS/
				Upload-AWS $reportFilePath "lms/CheckLMS/"

			} else {
				Write-Message "$($scriptFiles.Count) script files found, only ONE script file is allowed. Cannot upload content." $scriptName $scriptVersion  
			}
		}
	} else {
		Write-Message "The ZIP file DOESN'T exists: $zipFilePath" $scriptName $scriptVersionv  
	}
}  
else {  
    Write-Message "The source directory does not exist: '$sourcePath'" $scriptName $scriptVersion  
}

Write-Message "End CreateCheckLMSPackage script"  $scriptName $scriptVersion 
