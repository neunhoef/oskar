Stop-Process -Name arango*
. prepareOskar.ps1

. $env:EDITION
. $env:STORAGE_ENGINE
. $env:TEST_SUITE

skipPackagingOn
switchBranches $env:ARANGODB_BRANCH $env:ENTERPRISE_BRANCH
If ($global:ok) 
{
    oskar1
}
$s = $global:ok
moveResultsToWorkspace
unlockDirectory

If($s)
{
    Exit 0
}
Else
{
    Exit 1
} 
