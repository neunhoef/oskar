$HDD = $(Split-Path -Parent $(Split-Path -Parent $ENV:WORKSPACE))
If(-Not(Test-Path -PathType Container -Path "$HDD\$env:NODE_NAME"))
{
    New-Item -ItemType Directory -Path "$HDD\$env:NODE_NAME"
}
$WORKSPACE = "$HDD\$env:NODE_NAME"
Set-Location $WORKSPACE
If(-Not(Test-Path -PathType Container -Path "$WORKSPACE\oskar"))
{
    git clone https://github.com/neunhoef/oskar
    Set-Location "$WORKSPACE\oskar"
}
Set-Location "$WORKSPACE\oskar"
Import-Module "$WORKSPACE\oskar\powershell\oskar.psm1"
If($Error -ne 0)
{
    Write-Host "Did not find oskar and helpers"
    Exit 1
}

lockDirectory
updateOskar
clearResults

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
If (-Not($Error)) 
{
    oskar1
}

Set-Location "$WORKSPACE\oskar"
moveResultsToWorkspace
unlockDirectory

exit $Error