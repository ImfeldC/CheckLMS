param(  
    [Parameter(Mandatory=$true)]  
    [string[]]$directories,  
    [Parameter(Mandatory=$true)]  
    [string]$outputFile,  
    [Parameter(Mandatory=$true)]  
    [datetime]$startDate,  
    [Parameter(Mandatory=$true)]  
    [datetime]$endDate  
)  


# Funktion zum Extrahieren des Datums aus einer Zeile  
function Get-DateFromLineInt($line, $pattern, $dateformat, $culture) {  
	#Write-Host "Check Match: Pattern: '$pattern', Format: '$dateformat', Culture: '$culture', Line: '$line'"  
    $matches = [regex]::Matches($line, $pattern)  
    if ($matches.Count -gt 0) {  
		#Write-Host "Match found: '$($matches[0].Value)', Pattern: '$pattern', Format: '$dateformat', Culture: '$culture', Line: '$line'"  
		$date = [datetime]::ParseExact($matches[0].Value, $dateformat, $culture)
        # Check if date is valid ...
        if($date) {  
			#Write-Host "Date found: $date "  
			return $date 
        }  
    }  
    return $null  
}  
  
# Funktion zum Extrahieren des Datums aus einer Zeile  
function Get-DateFromLine($line) {  
	# Example: 2023-09-18 19:36:25,015
	$date = Get-DateFromLineInt $line "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}" 'yyyy-MM-dd HH:mm:ss,fff' $null
	if($date) {  
		return $date 
	}  
	# Example: 20 Oct 2023 07:54:10,167
	$culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US") 
	return Get-DateFromLineInt $line "\d{2} [A-Za-z]{3} \d{4} \d{2}:\d{2}:\d{2},\d{3}" 'dd MMM yyyy HH:mm:ss,fff' $culture 
}

# Arrays to store values
$allFiles = @()  
$lines = @()  
$processedFolders = 0  
$processedFiles = 0  
$totFileCount=0

# Calculate total number of files  
foreach ($directory in $directories) {  
	$processedFolders++  
	$files  = Get-ChildItem -Path $directory -Filter "licenf.*.log" -File -Recurse
	$files += Get-ChildItem -Path $directory -Filter "LMU.log.*" -File -Recurse
	$files += Get-ChildItem -Path $directory -Filter "LmuTool.log.*" -File -Recurse
	$files += Get-ChildItem -Path $directory -Filter "LMUPowerShell.log.*" -File -Recurse
	$totFileCount += $files.Count

	$allFiles += [pscustomobject]@{  
		Files = $files
		Folder = $directory
		FolderIndex = $processedFolders
	}
}
Write-Host "Process $totFileCount files ..."  

# Serach through all folders and files ... 
$allFiles | ForEach-Object {
	foreach ($file in $_.Files) {  
		$processedFiles++  
		# Show progress bar, about processing files  
		Write-Progress -Activity "Processing Files" -Status "Processed $processedFiles of $totFileCount files" -PercentComplete (($processedFiles / $totFileCount) * 100)  

		# Skip file if the size is larger than 50MB  
		if ($file.Length -gt 50MB) {  
			Write-Host "[$processedFiles] Skipping file: $($file.Name), Size: $($file.Length) bytes, it is too big!"  
			continue  
		}  

		# Extract the date of the file  
		$fileDate = $file.LastWriteTime  
		# Skip file if the date is not within the specified range  
		if ($fileDate -lt $startDate -or $fileDate -gt $endDate.AddDays(1)) {  
			Write-Host "[$processedFiles] Skipping file: $($file.Name), Date: $($fileDate.ToString("dd.MM.yyyy HH:mm:ss")), it is not in speciffied date range from $($startDate.ToString("dd.MM.yyyy HH:mm:ss")) to $($endDate.ToString("dd.MM.yyyy HH:mm:ss"))!"  
			continue  
		}  

		# Zeilen aus der Datei lesen und nach Datum extrahieren  
		$content = Get-Content -Path $file.FullName  
		Write-Host "[$processedFiles] Processing file: $($file.Name), Size: $($file.Length) bytes, Last Modified: $($file.LastWriteTime), $($content.Count) lines loaded ... Up to now $($lines.Count) lines processed."  
		$linenum=0
		foreach ($line in $content) {  
			$linenum++
			# Show progress bar, about processing files  
			Write-Progress -Activity "Analyze file $($file.Name)" -Status "Processed $linenum of $($content.Count) lines. Processed $processedFiles of $totFileCount files" -PercentComplete (($linenum / $content.Count) * 100)  
			$date = Get-DateFromLine $line  
			if ($date) {  
				if ($date -ge $startDate -and $date -le $endDate.AddDays(1)) {  
					#Write-Host "Valid date found in $($file.Name) on line $linenum : $date"  
					$lines += [pscustomobject]@{  
						Date = $date  
						Line = $line 
						Linenum = $linenum
						File = $file
						FileIndex = $processedFiles
						Folder = $_.Folder
						FolderIndex = $_.FolderIndex
					}  
				}
			}  
		}  
		# Close progress bar  
		Write-Progress -Activity "Analyze file $($file.Name)" -Completed  
	}  
}
# Close progress bar  
Write-Progress -Activity "Processing Files" -Completed  

Write-Host "All $processedFiles files processed: $($lines.Count) lines sorted."  

# Zeilen nach Datum und Zeit sortieren  
$sortedLines = $lines | Sort-Object -Property Date, Linenum  
  
# Zeilen in die Ausgabedatei schreiben  
$linenum=0
$sortedLines | ForEach-Object {
	$linenum++
	# Show progress bar, about processing files  
	Write-Progress -Activity "Save File" -Status "Saved $linenum of $($lines.Count) lines" -PercentComplete (($linenum / $lines.Count) * 100)  
	$ComposedLine = "{5,6} [{0:d2}/{1:d5}] {2,17}/{4,6}: {3}" -f [int]$_.FolderIndex, [int]$_.FileIndex, $_.File.Name, $_.Line, $_.Linenum, $linenum
    $ComposedLine | Out-File -FilePath $outputFile -Append  
}  
# Close progress bar  
Write-Progress -Activity "Save File" -Completed  

Write-Host "Whole content written to '$outputFile'."  
  
