$HDD = $(Split-Path -Qualifier $ENV:WORKSPACE)
If(-Not(Test-Path -PathType Container -Path "$HDD\$env:NODE_NAME"))
{
    New-Item -ItemType Directory -Path "$HDD\$env:NODE_NAME"
}
$OSKARDIR = "$HDD\$env:NODE_NAME"
Set-Location $OSKARDIR
If(-Not(Test-Path -PathType Container -Path "$OSKARDIR\oskar"))
{
    git clone https://github.com/neunhoef/oskar
    Set-Location "$OSKARDIR\oskar"
}
Set-Location "$OSKARDIR\oskar"
Import-Module "$OSKARDIR\oskar\powershell\oskar.psm1"
If(-Not($?))
{
    Write-Host "Did not find oskar modul"
    Exit 1
}

lockDirectory
updateOskar
If($(Get-Module).Name -ccontains "oskar")
{
    Remove-Module oskar
}
Import-Module "$OSKARDIR\oskar\powershell\oskar.psm1"
clearResults

switchBranches $env:ARANGODB_BRANCH $env:ENTERPRISE_BRANCH
#disableDebugSymbols
If ($?) 
{
    oskar1
}
moveResultsToWorkspace
unlockDirectory