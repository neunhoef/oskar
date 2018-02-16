#Import-Module VSSetup

Function lockDirectory
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

Function unlockDirectory
{
    If(Test-Path -PathType Leaf LOCK.$pid)
    {
        Remove-Item LOCK
        Remove-Item LOCK.$pid
    }   
}

$WORKDIR = $pwd
$INNERWORKDIR = "$pwd\work"
If(-Not(Test-Path -PathType Container -Path "work"))
{
    New-Item -ItemType Directory -Path "work"
}
$VERBOSEOSKAR = "Off"
$GENERATOR = "Visual Studio 15 2017 Win64"
#$CL = $(Get-ChildItem $(Get-VSSetupInstance).InstallationPath -Filter cl.exe -Recurse | Select-Object Fullname |Where {$_.FullName -match "Hostx64\\x64"}).FullName
#$CLPATH = Split-Path -Parent $CL
#$env:GYP_MSVS_OVERRIDE_PATH=$CLPATH
$env:CC="clcache"
$env:CXX="clcache"

Function showConfig
{
  Write-Host "Workdir               :"$WORKDIR
  Write-Host "Inner workdir         :"$INNERWORKDIR
  Write-Host "Maintainer            :"$MAINTAINER
  Write-Host "Buildmode             :"$BUILDMODE
  Write-Host "Skip Packaging        :"$SKIPPACKAGING
  Write-Host "Generator             :"$GENERATOR
  Write-Host "CC                    :"$env:CC
  Write-Host "CXX                   :"$env:CXX
  #Write-Host "GYP_MSVS_OVERRIDE_PATH:"$env:GYP_MSVS_OVERRIDE_PATH
  Write-Host "Parallelism           :"$PARALLELISM
  Write-Host "Enterpriseedition     :"$ENTERPRISEEDITION
  Write-Host "Storage engine        :"$STORAGEENGINE
  Write-Host "Test suite            :"$TESTSUITE
  Write-Host "Verbose               :"$VERBOSEOSKAR
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

Function skipPackagingOn
{
    $SKIPPACKAGING = "On"
}
Function skipPackagingOff
{
    $SKIPPACKAGING = "Off"
}
If(-Not($SKIPPACKAGING))
{
    $SKIPPACKAGING = "On"
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
        Start-Process "git " -ArgumentList "clone sven%40arangodb.com@https://github.com/arangodb/enterprise" -Wait
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

Function configureWinRelease
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build"))
    {
        New-Item -ItemType Directory -Path "$INNERWORKDIR\ArangoDB\build"
    }
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    Start-Process "cmake" -ArgumentList "-G `"$GENERATOR`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DSKIP_PACKAGING=`"$SKIPPACKAGING`" `"$INNERWORKDIR\ArangoDB`"" -Wait
}

Function buildWinRelease 
{
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    Start-Process "cmake"  -ArgumentList "--build . --config `"$BUILDMODE`"" -Wait
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

Function showLog
{
    Get-Content "$INNERWORKDIR\test.log" -Tail 100
}

showConfig