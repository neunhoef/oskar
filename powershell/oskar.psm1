Function Add-DirectoryLock
{
    If(-Not(Test-Path -PathType Leaf LOCK.$pid))
    {
        $pid | Out-File LOCK.$pid
        While($true)
        {
            # Remove a stale lock if it is found:
            If($pidfound = Get-Content LOCK -ErrorAction SilentlyContinue)
            {
                If(-Not(Get-Process -Id $pidfound -ErrorAction SilentlyContinue))
                {
                    Remove-Item LOCK
                    Remove-Item LOCk.$pidfound
                    Write-Host "Removed stale lock"
                }
            }
            If(New-Item -ItemType HardLink -Name LOCK -Value LOCK.$pid -ErrorAction SilentlyContinue)
            {
               Break
            }
            Write-Host "Directory is locked, waiting..."
            Get-Date
            Start-Sleep -Seconds 15
        }
    } 
}

Function Remove-DirectoryLock
{
    If(Test-Path -PathType Leaf LOCK.$pid)
    {
        Remove-Item LOCK
        Remove-Item LOCK.$pid
    }   
}

Function Show-Config
{
  Write-Host "Workdir           : $WORKDIR"
  Write-Host "Inner workdir     : $INNERWORKDIR"
  Write-Host "Maintainer        : $MAINTAINER"
  Write-Host "Buildmode         : $BUILDMODE"
  Write-Host "Parallelism       : $PARALLELISM"
  Write-Host "Enterpriseedition : $ENTERPRISEEDITION"
  Write-Host "Storage engine    : $STORAGEENGINE"
  Write-Host "Test suite        : $TESTSUITE"
  Write-Host "Verbose           : $VERBOSEOSKAR"
}

Function single
{
    $TESTSUITE = "single"
}
Function cluster
{
    $TESTSUITE = "cluster"
}
Function resilience
{
    $TESTSUITE = "resilience"
}
If(-Not($TESTSUITE))
{
    $TESTSUITE = "cluster"
}

Function maintainerOn
{
    $MAINTAINER = "On"
}
Function maintainerOff
{
    $MAINTAINER = "Off"
}
If(-Not($MAINTAINER))
{
    $MAINTAINER = "On"
}

Function debugMode
{
    $BUILDMODE = "Debug"
}
Function releaseMode
{
    $BUILDMODE = "RelWithDebInfo"
}
If(-Not($BUILDMODE))
{
    $BUILDMODE = "RelWithDebInfo"
}

Function community
{
    $ENTERPRISEEDITION = "Off"
}
Function enterprise
{
    $ENTERPRISEEDITION = "On"
}
If(-Not($ENTERPRISEEDITION))
{
    $ENTERPRISEEDITION = "On"
}

Function mmfiles
{
    $STORAGEENGINE = "mmfiles"
}
Function rocksdb
{
    $STORAGEENGINE = "rocksdb"
}
If(-Not($STORAGEENGINE))
{
    $STORAGEENGINE = "rocksdb"
}

Function parallelism($arg)
{
    $PARALLELISM = $arg
}
If(-Not($PARALLELISM))
{
    $PARALLELISM = 64
}

Function verbose
{
    $VERBOSEOSKAR = "On"
}
Function silent
{
    $VERBOSEOSKAR = "Off"
}

$WORKDIR = $pwd
$INNERWORKDIR = "$pwd\work"
If(-Not(Test-Path -PathType Container -Path "work"))
{
    New-Item -ItemType Directory -Path "work"
}
$VERBOSEOSKAR = "Off"

Function checkoutArangoDB
{
    Set-Location $INNERWORKDIR
    If(-Not(Test-Path -PathType Container -Path "ArangoDB"))
    {
        Start-Process "git "-ArgumentList "clone https://github.com/arangodb/ArangoDB" -Wait
    }
}

Function checkoutEnterprise
{
    checkoutArangoDB
    Set-Location "$INNERWORKDIR\ArangoDB"
    If(-Not(Test-Path -PathType Container -Path "enterprise"))
    {
        Start-Process "git "-ArgumentList "clone sven%40arangodb.com@https://github.com/arangodb/enterprise" -Wait
    }
}

Function checkoutIfNeeded
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB"))
    {
        If($ENTERPRISEEDITION -eq "On")
        {
            checkoutEnterprise
        }
        Else
        {
            checkoutArangoDB
        }
    }
    
}

Function clearResults
{
  Set-Location $INNERWORKDIR
  ForEach($file in $(Get-ChildItem -Filter testreport*))
  {
    Remove-Item -Force $file
  }
  Remove-Item -Force test.log
}

Show-Config