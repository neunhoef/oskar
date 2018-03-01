Import-Module VSSetup

$WORKDIR = $pwd
If(-Not(Test-Path -PathType Container -Path "work"))
{
    New-Item -ItemType Directory -Path "work"
}
$INNERWORKDIR = "$WORKDIR\work"
$clcache = $(Get-ChildItem $(Get-VSSetupInstance).InstallationPath -Filter cl.exe -Recurse | Select-Object Fullname |Where {$_.FullName -match "Hostx86\\x64"}).FullName
$GENERATOR = "Visual Studio 15 2017 Win64"
$env:GYP_MSVS_OVERRIDE_PATH= Split-Path -Parent $clcache
$env:CLCACHE_DIR="$INNERWORKDIR\.clcache.windows"

Function showConfig
{
  Write-Host "Workdir               :"$WORKDIR
  Write-Host "Inner workdir         :"$INNERWORKDIR
  Write-Host "Cachedir              :"$env:CLCACHE_DIR
  Write-Host "Maintainer            :"$MAINTAINER
  Write-Host "Buildmode             :"$BUILDMODE
  Write-Host "Skip Packaging        :"$SKIPPACKAGING
  Write-Host "Static Executables    :"$STATICEXECUTABLES
  Write-Host "Generator             :"$GENERATOR
  Write-Host "CL                    :"$env:CLCACHE_CL
  Write-Host "Parallelism           :"$PARALLELISM
  Write-Host "Enterpriseedition     :"$ENTERPRISEEDITION
  Write-Host "Storage engine        :"$STORAGEENGINE
  Write-Host "Test suite            :"$TESTSUITE
  Write-Host "Verbose               :"$VERBOSEOSKAR
}

Function lockDirectory
{
    If(-Not(Test-Path -PathType Leaf LOCK.$pid))
    {
        $pid | Add-Content LOCK.$pid
        While($true)
        {
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

Function single
{
    $global:TESTSUITE = "single"
}
Function cluster
{
    $global:TESTSUITE = "cluster"
}
Function resilience
{
    $global:TESTSUITE = "resilience"
}
If(-Not($TESTSUITE))
{
    cluster
}

Function skipPackagingOn
{
    $global:SKIPPACKAGING = "On"
}
Function skipPackagingOff
{
    $global:SKIPPACKAGING = "Off"
}
If(-Not($SKIPPACKAGING))
{
    skipPackagingOn
}

Function staticExecutablesOn
{
    $global:STATICEXECUTABLES = "On"
}
Function staticExecutablesOff
{
    $global:STATICEXECUTABLES = "Off"
}
If(-Not($STATICEXECUTABLES))
{
    staticExecutablesOff
}

Function maintainerOn
{
    $global:MAINTAINER = "On"
}
Function maintainerOff
{
    $global:MAINTAINER = "Off"
}
If(-Not($MAINTAINER))
{
    maintainerOn
}

Function debugMode
{
    $global:BUILDMODE = "Debug"
}
Function releaseMode
{
    $global:BUILDMODE = "RelWithDebInfo"
}
If(-Not($BUILDMODE))
{
    releaseMode
}

Function community
{
    $global:ENTERPRISEEDITION = "Off"
}
Function enterprise
{
    $global:ENTERPRISEEDITION = "On"
}
If(-Not($ENTERPRISEEDITION))
{
    enterprise
}

Function mmfiles
{
    $global:STORAGEENGINE = "mmfiles"
}
Function rocksdb
{
    $global:STORAGEENGINE = "rocksdb"
}
If(-Not($STORAGEENGINE))
{
    rocksdb
}

Function verbose
{
    $global:VERBOSEOSKAR = "On"
}
Function silent
{
    $global:VERBOSEOSKAR = "Off"
}
If(-Not($VERBOSEOSKAR))
{
    verbose
}

Function parallelism($arg)
{
    $global:PARALLELISM = $arg
}
If(-Not($PARALLELISM))
{
    $global:PARALLELISM = 64
}

Function checkoutArangoDB
{
    Set-Location $INNERWORKDIR
    If(-Not(Test-Path -PathType Container -Path "ArangoDB"))
    {
        git clone https://github.com/arangodb/ArangoDB
    }
}

Function checkoutEnterprise
{
    checkoutArangoDB
    Set-Location "$INNERWORKDIR\ArangoDB"
    If(-Not(Test-Path -PathType Container -Path "enterprise"))
    {
        If(Test-Path -PathType Leaf -Path "$HOME\.ssh\known_hosts")
        {
            Remove-Item -Force "$HOME\.ssh\known_hosts"
        }
        ssh -o StrictHostKeyChecking=no git@github.com
        git clone ssh://git@github.com/arangodb/enterprise
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

Function switchBranches($branch_c,$branch_e)
{
    checkoutIfNeeded
    Set-Location "$INNERWORKDIR\ArangoDB"
    If (-Not($Error)) 
    {
        git checkout -- .
    }
    If (-Not($Error)) 
    {
        git pull
    }
    If (-Not($Error)) 
    {
        git checkout $branch_c
    }
    If (-Not($Error)) 
    {
        git pull
    }
    If($ENTERPRISEEDITION -eq "On")
    {
        Set-Location "$INNERWORKDIR\ArangoDB\enterprise"
        If (-Not($Error)) 
        {
            git checkout -- .
        }
        If (-Not($Error)) 
        {
            git pull
        }
        If (-Not($Error)) 
        {
            git checkout $branch_e
        }
        If (-Not($Error)) 
        {
            git pull
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

Function showLog
{
    Get-Content "$INNERWORKDIR\test.log" -Tail 100
}

Function  findArangoDBVersion
{
    If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_MAJOR") -match '.*"([0-9a-zA-Z]*)".*')
    {
        $ARANGODB_VERSION_MAJOR = $Matches[1]
        If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_MINOR") -match '.*"([0-9a-zA-Z]*)".*')
        {
            $ARANGODB_VERSION_MINOR = $Matches[1]
            If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_REVISION") -match '.*"([0-9a-zA-Z]*)".*')
            {
                $ARANGODB_VERSION_REVISION = $Matches[1]
                If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_PACKAGE_REVISION") -match '.*"([0-9a-zA-Z]*)".*')
                {
                    $ARANGODB_PACKAGE_REVISION = $Matches[1]
                    $ARANGODB_VERSION = "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_REVISION"
                    $ARANGODB_FULL_VERSION = "$ARANGODB_VERSION-$ARANGODB_PACKAGE_REVISION"
                    Write-Host $ARANGODB_FULL_VERSION
                }

            }
        }

    }
}

Function configureWindows
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build"))
    {
        New-Item -ItemType Directory -Path "$INNERWORKDIR\ArangoDB\build"
    }
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    cmake -G "$GENERATOR" -DUSE_MAINTAINER_MODE="$MAINTAINER" -DUSE_ENTERPRISE="$ENTERPRISEEDITION" -DCMAKE_BUILD_TYPE="$BUILDMODE" -DSKIP_PACKAGING="$SKIPPACKAGING" -DSTATIC_EXECUTABLES="$STATICEXECUTABLES" "$INNERWORKDIR\ArangoDB"
}

Function buildWindows 
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build"))
    {
        Write-Host "Please Configure before this step."
        
    }
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    cmake --build . --config "$BUILDMODE"
}

Function buildArangoDB
{
    checkoutIfNeeded
    If(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build")
    {
       Remove-Item -Recurse -Force -Path "$INNERWORKDIR\ArangoDB\build"
    }
    configureWindows
    buildWindows
}

Function buildStaticArangodb
{
    staticExecutablesOn
    buildArangoDB
}

Function moveResultsToWorkspace
{
  Write-Host "Moving reports and logs to $WORKSPACE ..."
  ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter testreport*))
  {
    Write-Host "Move $file"
    Move-Item -Path $file -Destination $WORKSPACE 
  }
  ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter *.deb))
  {
    Write-Host "Move $file"
    Move-Item -Path $file -Destination $WORKSPACE 
  }
  If(Test-Path -PathType Leaf $INNERWORKDIR\test.log)
  {
    Write-Host "Move $INNERWORKDIR\test.log"
    Move-Item -Path "$INNERWORKDIR\test.log" -Destination $WORKSPACE 
  }
}

Function getRepoState
{
    Set-Location "$INNERWORKDIR\Arangodb"
    $repoState = $(git status -b -s | Select-String -Pattern "^[?]" -NotMatch)
    If($ENTERPRISEEDITION -eq "On")
    {
        Set-Location "$INNERWORKDIR\ArangoDB\enterprise"
        $repoStateEnterprise = $(git status -b -s | Select-String -Pattern "^[?]" -NotMatch)
        Set-Location "$INNERWORKDIR\Arangodb"
    }
    Else
    {
        $repoStateEnterprise = ""
    }
}

Function noteStartAndRepoState
{
    getRepoState
    If(Test-Path -PathType Leaf -Path testProtocol.txt)
    {
        Remove-Item -Force testProtocol.txt
    }
    $(Get-Date -UFormat +%Y-%M-%D_%H.%M.%SZ) | Add-Content testProtocol.txt
    Write-Output "========== Status of main repository:" | Add-Content testProtocol.txt
    Write-Host "========== Status of main repository:"
    ForEach($line in $repoState)
    {
        Write-Output " $line" | Add-Content testProtocol.txt
        Write-Host " $line"
    }
    If($ENTERPRISEEDITION -eq "On")
    {
        Write-Output "Status of enterprise repository:" | Add-Content testProtocol.txt
        Write-Host "Status of enterprise repository:"
        ForEach($line in $repoStateEnterprise)
        {
            Write-Output " $line" | Add-Content testProtocol.txt
            Write-Host " $line"
        }
    }

}

Function unittest([array]$test)
{
    $PORT=Get-Random -Minimum 20000 -Maximum 65535
    Set-Location "$INNERWORKDIR\ArangoDB"
    $UPID = $UPID+$(Start-Process -FilePath "$INNERWORKDIR\ArangoDB\build\bin\RelWithDebInfo\arangosh.exe" -ArgumentList " -c $INNERWORKDIR\ArangoDB\etc\relative\arangosh.conf --log.level warning --server.endpoint tcp://127.0.0.1:$PORT --javascript.execute $INNERWORKDIR\ArangoDB\UnitTests\unittest.js $test" -NoNewWindow -PassThru)
}

Function launchSingleTests
{
    noteStartAndRepoState
    Write-Host "Launching tests..."
    $portBase = 10000

    Function test1([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        #unittest "$test[1] --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort $($portBase + 99) $test[3..#] --skipNonDeterministic true --skipTimeCritical true"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }
}

Function launchClusterTests
{
    noteStartAndRepoState
    Write-Host "Launching tests..."
    $portBase = 10000

    Function test1([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        unittest "$test[1] --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort $($portBase + 99) $test --skipNonDeterministic true --skipTimeCritical true"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }

    Function test3([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        unittest "$argv[1] --test $argv[3] --storageEngine $STORAGEENGINE --cluster true --minPort $portBase --maxPort $($portBase + 99) --skipNonDeterministic true"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }
}

#Function waitForProcesses([array]$var)
#{
#    $i=$var[1]
#    While($true)
#    {
#        
#    }
#}
#  set i $argv[1]
#  while true
#    # Check subprocesses:
#    set pids (jobs -p)
#    if test (count $pids) -eq 0
#      echo
#      return 1
#    end
#
#    echo -n (count $pids) jobs still running, remaining $i "seconds..."\r
#
#    set i (math $i - 5)
#    if test $i -lt 0
#      echo
#      return 0
#    end
#
#    sleep 5
#  end
#end

#Function waitOrKill
#{
#   Write-Host "Waiting for processes to terminate..." 
#}
#  echo Waiting for processes to terminate...
#  if waitForProcesses $argv[1]
#    kill (jobs -p)
#    if waitForProcesses 15
#      kill -9 (jobs -p)
#    end
#  end
#end

Function log([array]$log)
{
    ForEach($l in $log)
    {
        Write-Host $l
        $l | Add-Content "$INNERWORKDIR\test.log"
    }
}

Function createReport
{
    $d = $(Get-Date -UFormat +%Y-%M-%D_%H.%M.%SZ)
    $d | Add-Content testProtocol.txt
    $result = "GOOD"
    ForEach($f in $(Get-ChildItem -Filter *.log))
    {
        If(-Not($(Get-Content $f -Tail 1) -eq "Success"))
        {
            $result = "BAD"
            Write-Host "Bad result in $f"
            "Bad result in $f" | Add-Content testProtocol.txt
            $badtests = $badtests + "Bad result in $f"
        }
    }

  $result | Add-Content testProtocol.txt
  $olddir = $pwd
  Set-Location $INNERWORKDIR
  Compress-Archive -Path tmp -DestinationPath "$INNERWORKDIR\ArangoDB\innerlogs.zip"
  Set-Location $olddir
  
  $cores = Get-ChildItem -Filter "core*"
  $archives = Get-ChildItem -Filter "*.zip"
  $logs = Get-ChildItem -Filter "*.log"
  Write-Host "Compress-Archive -Path $logs -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
  Compress-Archive -Path $logs -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  Write-Host "Compress-Archive -Path $cores -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
  Compress-Archive -Path $cores -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  Write-Host "Compress-Archive -Path $archives -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
  Compress-Archive -Path $archives -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  Write-Host "Compress-Archive -Path testProtocol.txt -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
  Compress-Archive -Path testProtocol.txt -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  Write-Host "Remove-Item -Recurse -Force $cores"
  Remove-Item -Recurse -Force $cores
  Write-Host "Remove-Item -Recurse -Force $archives"
  Remove-Item -Recurse -Force $archives
  Write-Host "Remove-Item -Recurse -Force testProtocol.txt"
  Remove-Item -Recurse -Force testProtocol.txt
  log "$d $TESTSUITE $result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE" $repoState $repoStateEnterprise $badtests ""
}

Function runTests
{
    Set-Location $INNERWORKDIR
    If(Test-Path -PathType Container -Path tmp)
    {
        Remove-Item -Recurse -Force -Path tmp
        New-Item -ItemType Directory -Path tmp
    }
    Else
    {
        New-Item -ItemType Directory -Path tmp
    }
    $TMPDIR = "$INNERWORKDIR\tmp"
    Set-Location "$INNERWORKDIR\ArangoDB"

    Switch -Regex ($TESTSUITE)
    {
        "cluster"
        {
            launchClusterTests
            waitOrKill 1800
            createReport  
            Break
        }
        "single"
        {
            launchSingleTests
            waitOrKill 1800
            createReport
            Break
        }
        "resilience"
        {
            launchResilienceTests
            waitOrKill 1800
            createReport
            Break
        }
        "*"
        {
            Write-Host "Unknown test suite $TESTSUITE"
            $result = "BAD"
            Break
        }
    }

    If($result -eq "GOOD")
    {
    Exit 0
    }
    Else
    {
    Exit 1
    }   
}

Clear
showConfig