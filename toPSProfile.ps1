
[CmdletBinding()]
param (
     [string]$Modules   
)

$Env:PSModulePath -split ";|:" | ForEach-Object { If ($_ -match "Documents") { $ModulePath = $_ } }

Write-Verbose "PSModulePath: $ModulePath"

If (!$Modules) 
{
    Get-ChildItem -Directory | `
    ForEach-Object {

        If ($_.Name -eq "Tests")  { return }
        If ($_.Name -eq "assets") { return }

        If (Test-Path -Path "$ModulePath\$($_.Name)") 
        {
            Write-Host "Removing Old Version." -ForegroundColor Cyan
            Remove-Item -Recurse "$ModulePath\$($_.Name)" -force
        }

        Write-Host "Copying Module: " -ForegroundColor Cyan -NoNewline ; Write-Host "$($_.Name)" -ForegroundColor Green 

        Copy-Item -Path $_ -Recurse -Destination "$ModulePath\$($_.Name)" -Force
        If (Test-Path -Path "$ModulePath\$($_.Name)") 
        {
               Write-Host "                Success." -ForegroundColor Yellow
        }
        Else { Write-Host "                Failed." -ForegroundColor Red}
    }
}