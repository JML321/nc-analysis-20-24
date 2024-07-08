# Save this script as KeepAwake.ps1 and run it with PowerShell
Add-Type -AssemblyName System.Windows.Forms

$duration = 2 * 60 * 60 # 2 hours in seconds
$endTime = (Get-Date).AddSeconds($duration)

while ((Get-Date) -lt $endTime) {
    [System.Windows.Forms.SendKeys]::SendWait("+")  # Send a Shift key press
    Start-Sleep -Seconds 175
}

Write-Output "The script has completed. The computer can now sleep."
