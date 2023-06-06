#
# This script captures a screen-shot of all attached monitiors and stores them in logs folder.
#
# Solution from https://stackoverflow.com/questions/2969321/how-can-i-do-a-screen-capture-in-windows-powershell
#
# '20230606': Initial script added.
$scriptVersion = '20230606'
$global:ExitCode=0

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Function to print-out messages, including <date> and <time> information.
$scriptName = $MyInvocation.MyCommand.Name
function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("[$scriptName/$scriptVersion] {0} - {1}" -f (Get-Date), $LogMessage)
}

$screens = [Windows.Forms.Screen]::AllScreens

$top    = ($screens.Bounds.Top    | Measure-Object -Minimum).Minimum
$left   = ($screens.Bounds.Left   | Measure-Object -Minimum).Minimum
$width  = ($screens.Bounds.Right  | Measure-Object -Maximum).Maximum
$height = ($screens.Bounds.Bottom | Measure-Object -Maximum).Maximum

$bounds   = [Drawing.Rectangle]::FromLTRB($left, $top, $width, $height)
$bmp      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
$graphics = [Drawing.Graphics]::FromImage($bmp)

$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

# Create log folders, in case they do not exist yet.
if (!(test-path -path "$env:PROGRAMDATA\SIEMENS\LMS\Logs\"))                            { [System.IO.Directory]::CreateDirectory("$env:PROGRAMDATA\SIEMENS\LMS\Logs\") }
if (!(test-path -path "$env:PROGRAMDATA\SIEMENS\LMS\Logs\CheckLMSLogs\"))               { [System.IO.Directory]::CreateDirectory("$env:PROGRAMDATA\SIEMENS\LMS\Logs\CheckLMSLogs\") }
if (!(test-path -path "$env:PROGRAMDATA\SIEMENS\LMS\Logs\CheckLMSLogs\ScreenCapture\")) { [System.IO.Directory]::CreateDirectory("$env:PROGRAMDATA\SIEMENS\LMS\Logs\CheckLMSLogs\ScreenCapture\") }

[string]$directory = "$env:PROGRAMDATA\SIEMENS\LMS\Logs\CheckLMSLogs\ScreenCapture\";
[string]$newFileName = "screen-capture_" + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + ".png";
[string]$newFilePath = [System.IO.Path]::Combine($directory, $newFileName);

$bmp.Save($newFilePath)
Log-Message "Screen captured ... '$newFilePath'"

$graphics.Dispose()
$bmp.Dispose()

#Log-Message "Exit with '$ExitCode'"
exit $ExitCode
