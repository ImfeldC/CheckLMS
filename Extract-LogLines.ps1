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

$culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US") 

# Funktion zum Extrahieren des Datums aus einer Zeile  
function Get-DateFromLine($line) {  
    $pattern = "\d{2} [A-Za-z]{3} \d{4} \d{2}:\d{2}:\d{2},\d{3}"  
    $matches = [regex]::Matches($line, $pattern)  
    if ($matches.Count -gt 0) {  
		#Write-Host "Match found: '$($matches[0].Value)'"  
        # Überprüfen, ob das extrahierte Datum gültig ist  
        if ([datetime]::ParseExact($matches[0].Value, 'dd MMM yyyy HH:mm:ss,fff', $culture)) {  
			#Write-Host "Date found: $($matches[0].Value) "  
			return $matches[0].Value  
        }  
    }  
    return $null  
}  
  
# Array für die extrahierten Zeilen erstellen  
$lines = @()  
  
# Fortschrittsvariablen initialisieren  
$processedFiles = 0  
$processedFolders = 0  

# Calculate total number of files  
foreach ($directory in $directories) {  
    $files = Get-ChildItem -Path $directory -Filter "licenf.*.log" -File -Recurse
	$allFiles += $files
}

# Serach through all folders and files ... 
foreach ($directory in $directories) {  
	$processedFolders++  
    $files = Get-ChildItem -Path $directory -Filter "licenf.*.log" -File -Recurse
	foreach ($file in $files) {  
		$processedFiles++  
		# Fortschritt aktualisieren  
		Write-Progress -Activity "Processing Files" -Status "Processed $processedFiles of $($allFiles.Count) files" -PercentComplete (($processedFiles / $allFiles.Count) * 100)  

		# Skip file if the size is larger than 10MB  
		if ($file.Length -gt 10MB) {  
			#Write-Host "Skipping file: $($file.Name), Size: $($file.Length) bytes, it is too big!"  
			continue  
		}  

		# Extract the date of the file  
		$fileDate = $file.LastWriteTime  
		# Skip file if the date is not within the specified range  
		if ($fileDate -lt $startDate -or $fileDate -gt $endDate.AddDays(1)) {  
			#Write-Host "Skipping file: $($file.Name), Date: $($fileDate.ToString("dd.MM.yyyy HH:mm:ss")), it is not in speciffied date range from $($startDate.ToString("dd.MM.yyyy HH:mm:ss")) to $($endDate.ToString("dd.MM.yyyy HH:mm:ss"))!"  
			continue  
		}  

		# Dateiname und Größe auf der Konsole ausgeben  
		#Write-Host "Processing file: $($file.Name), Size: $($file.Length) bytes, Last Modified: $($file.LastWriteTime) ... $($lines.Count)"  

		# Zeilen aus der Datei lesen und nach Datum extrahieren  
		$content = Get-Content -Path $file.FullName  
		$linenum=0
		foreach ($line in $content) {  
			$linenum++
			$date = Get-DateFromLine $line  
			if ($date) {  
				#Write-Host "Valid date found in line: $date"  
				# Zeile mit Datum zum Array hinzufügen  
				$lines += [pscustomobject]@{  
					Date = $date  
					Line = $line 
					Linenum = $linenum
					File = $file
					FileIndex = $processedFiles
					FolderIndex = $processedFolders
				}  
			}  
		}  
	}  
}
Write-Host "All files processed: $($lines.Count) lines sorted."  

# Zeilen nach Datum und Zeit sortieren  
$sortedLines = $lines | Sort-Object -Property Date, Linenum  
  
# Zeilen in die Ausgabedatei schreiben  
$linenum=0
$sortedLines | ForEach-Object {
	$linenum++
	$ComposedLine = "{5,6} [{0:d2}/{1:d5}] {2,17}/{4,-5}: {3}" -f [int]$_.FolderIndex, [int]$_.FileIndex, $_.File.Name, $_.Line, $_.Linenum, $linenum
    $ComposedLine | Out-File -FilePath $outputFile -Append  
}  
Write-Host "Whole content written to '$outputFile'."  
  
# Fortschrittsanzeige abschließen  
Write-Progress -Activity "Processing Files" -Completed  
