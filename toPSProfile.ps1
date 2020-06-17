
[CmdletBinding()]
param (
     [string]$Modules   
)

If (!$Modules) 
{
    Get-ChildItem -Directory | `
    ForEach-Object {

        If ($_.Name -eq "Tests") { continue }

        If (Test-Path -Path "$Env:HOMEPATH\Documents\WindowsPowerShell\Modules\$($_.Name)") 
        {
            Write-Host "Removing Old Version." -ForegroundColor Cyan
            Remove-Item -Recurse "$Env:HOMEPATH\Documents\WindowsPowerShell\Modules\$($_.Name)" -force
        }

        Write-Host "Copying Module: " -ForegroundColor Cyan -NoNewline ; Write-Host "$($_.Name)" -ForegroundColor Green -NoNewline

        Copy-Item -Path $_ -Recurse -Destination "$Env:HOMEPATH\Documents\WindowsPowerShell\Modules\$($_.Name)" -Force
        If (Test-Path -Path "$Env:HOMEPATH\Documents\WindowsPowerShell\Modules\$($_.Name)") 
        {
            Write-Host "        Success." -ForegroundColor Yellow
        }
        Else { Write-Host "        Failed." -ForegroundColor Red}
    }
}