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
  Write-Host "System User           :"$env:USERDOMAIN\$env:USERNAME
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
            $(get-date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ")
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

Function parallelism($threads)
{
    $global:PARALLELISM = $threads
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

Function updateOskar
{
    Set-Location $WORKDIR
    If (-Not($Error)) 
    {
        git checkout -- .
    }
    If (-Not($Error)) 
    {
        git pull
    }

}

Function clearResults
{
    Set-Location $INNERWORKDIR
    ForEach($report in $(Get-ChildItem -Filter testreport*))
    {
        Remove-Item -Force $report
    }
    ForEach($log in $(Get-ChildItem -Filter "*.log"))
    {
    Remove-Item -Recurse -Force $log 
    }
    ForEach($archive in $(Get-ChildItem -Filter "*.zip"))
    {
        Remove-Item -Recurse -Force $archive 
    }
    ForEach($core in $(Get-ChildItem -Filter "core*"))
    {
        Remove-Item -Recurse -Force $core 
    }
    If(Test-Path -PathType Leaf -Path test.log)
    {
        Remove-Item -Force test.log
    }
    If(Test-Path -PathType Leaf -Path testProtocol.txt)
    {
        Remove-Item -Force testProtocol.txt
    }
}

Function showLog
{
    Get-Content "$INNERWORKDIR\test.log" | Out-GridView -Title "$INNERWORKDIR\test.log"
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
    Write-Host "Configure: cmake -G `"$GENERATOR`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES -DDebugInformationFormat?OldStyle`" `"$INNERWORKDIR\ArangoDB`""
    Start-Process -FilePath "cmake" -ArgumentList "-G `"$GENERATOR`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES -DDebugInformationFormat?OldStyle`" `"$INNERWORKDIR\ArangoDB`"" -RedirectStandardOutput "$INNERWORKDIR\cmake-configure.stdout.log" -RedirectStandardError "$INNERWORKDIR\cmake-configure.stderr.log" -Wait
}

Function buildWindows 
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build"))
    {
        Write-Host "Please Configure before this step."
        
    }
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    Write-Host "Build: cmake --build . --config `"$BUILDMODE`""
    Start-Process -FilePath "cmake" -ArgumentList "--build . --config `"$BUILDMODE`"" -RedirectStandardOutput "$INNERWORKDIR\cmake-build.stdout.log" -RedirectStandardError "$INNERWORKDIR\cmake-build.stderr.log" -Wait
    Copy-Item "$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\*" -Destination "$INNERWORKDIR\ArangoDB\build\bin\"
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

Function moveResultsToWorkspace
{
  Write-Host "Moving reports and logs to $env:WORKSPACE ..."
  ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter cmake-*))
  {
    Write-Host "Move $INNERWORKDIR\$file"
    Move-Item -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE
  }
  If(Test-Path -PathType Leaf $INNERWORKDIR\test.log)
  {
    If($(Get-Content $f -Head 1) -eq "BAD")
    {
        Write-Host "Move $INNERWORKDIR\test.log"
        Move-Item -Path "$INNERWORKDIR\test.log" -Destination $env:WORKSPACE
        ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter testreport*))
        {
            Write-Host "Move $INNERWORKDIR\$file"
            Move-Item -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE
        } 
    }
    Else
    {
        ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter testreport*))
        {
            Write-Host "Remove $INNERWORKDIR\$file"
            Remove-Item -Force "$INNERWORKDIR\$file" 
        } 
    }
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
    $(get-date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ") | Add-Content testProtocol.txt
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

Function unittest($test,$output)
{
    $PORT=Get-Random -Minimum 20000 -Maximum 65535
    Set-Location "$INNERWORKDIR\ArangoDB"
    [array]$global:UPIDS = [array]$global:UPIDS+$(Start-Process -FilePath "$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\arangosh.exe" -ArgumentList " -c $INNERWORKDIR\ArangoDB\etc\relative\arangosh.conf --log.level warning --server.endpoint tcp://127.0.0.1:$PORT --javascript.execute $INNERWORKDIR\ArangoDB\UnitTests\unittest.js -- $test" -RedirectStandardOutput "$output.stdout.log" -RedirectStandardError "$output.stderr.log" -PassThru).Id
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
        unittest "$($test[0]) --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort $($portBase + 99) $($test[2..$($test.Length)]) --skipNonDeterministic true --skipTimeCritical true" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }
    [array]$global:UPIDS = $null
    test1 "shell_server",""
    test1 "shell_client",""
    test1 "recovery","0","--testBuckets","4/0"
    test1 "recovery","1","--testBuckets","4/1"
    test1 "recovery","2","--testBuckets","4/2"
    test1 "recovery","3","--testBuckets","4/3"
    test1 "replication_sync",""
    test1 "replication_static",""
    test1 "replication_ongoing",""
    test1 "http_server",""
    test1 "ssl_server",""
    test1 "shell_server_aql","0","--testBuckets","5/0"
    test1 "shell_server_aql","1","--testBuckets","5/1"
    test1 "shell_server_aql","2","--testBuckets","5/2"
    test1 "shell_server_aql","3","--testBuckets","5/3"
    test1 "shell_server_aql","4","--testBuckets","5/4"
    test1 "dump",""
    test1 "server_http",""
    test1 "agency",""
    test1 "shell_replication",""
    test1 "http_replication",""
    test1 "catch",""
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
        unittest "$($test[0]) --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort $($portBase + 99) $($test[2..$($test.Length)]) --skipNonDeterministic true --skipTimeCritical true" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }

    Function test3([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        unittest "$($test[0]) --test $($test[2]) --storageEngine $STORAGEENGINE --cluster true --minPort $portBase --maxPort $($portBase + 99) --skipNonDeterministic true" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
        $portBase = $($portBase + 100)
        Start-Sleep 5
    }
    [array]$global:UPIDS = $null
    test3 "resilience","move","js/server/tests/resilience/moving-shards-cluster.js"
    test3 "resilience","failover","js/server/tests/resilience/resilience-synchronous-repl-cluster.js"
    test1 "shell_client",""
    test1 "shell_server",""
    test1 "http_server",""
    test1 "ssl_server",""
    test3 "resilience","sharddist","js/server/tests/resilience/shard-distribution-spec.js"
    test1 "shell_server_aql","0","--testBuckets","5/0"
    test1 "shell_server_aql","1","--testBuckets","5/1"
    test1 "shell_server_aql","2","--testBuckets","5/2"
    test1 "shell_server_aql","3","--testBuckets","5/3"
    test1 "shell_server_aql","4","--testBuckets","5/4"
    test1 "dump",""
    test1 "server_http",""
    test1 "agency",""
}

Function waitForProcesses($seconds)
{
    While($true)
    {
        [array]$global:NUPIDS = $null
        ForEach($UPID in $UPIDS)
        {
            If(Get-WmiObject win32_process | Where {$_.ParentProcessId -eq $UPID})
            {
                [array]$global:NUPIDS = [array]$global:NUPIDS + $(Get-WmiObject win32_process | Where {$_.ParentProcessId -eq $UPID})
            }
        } 
        If($NUPIDS.Count -eq 0 ) 
        {
            Return $false
        }
        Write-Host "$($NUPIDS.Count) jobs still running, remaining $seconds seconds..."
        $seconds = $($seconds - 5)
        If($seconds -lt 0)
        {
            return $true
        }
        Start-Sleep 5
    }
}

Function waitOrKill($seconds)
{
    Write-Host "Waiting for processes to terminate..."
    If(waitForProcesses $seconds) 
    {
        ForEach($NUPID in $NUPIDS)
        {
            Stop-Process -Id $NUPID.Handle
        } 
        If(waitForProcesses 30) 
        {
            ForEach($NUPID in $NUPIDS)
            {
                Stop-Process -Force -Id $NUPID.Handle
            } 
            waitForProcesses 15  
        }
    }
}

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
    $d = $(get-date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ")
    $d | Add-Content testProtocol.txt
    $result = "GOOD"
    ForEach($f in $(Get-ChildItem -Filter *.stdout.log))
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
  Push-Location
    Set-Location $INNERWORKDIR
    Write-Host "Compress-Archive -Path `"$INNERWORKDIR\tmp\`" -DestinationPath `"$INNERWORKDIR\ArangoDB\innerlogs.zip`""
    Compress-Archive -Path "$INNERWORKDIR\tmp\" -DestinationPath "$INNERWORKDIR\ArangoDB\innerlogs.zip"
  Pop-Location

  ForEach($log in $(Get-ChildItem -Filter "*.log"))
  {
    Write-Host "Compress-Archive -Path $log -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
    Compress-Archive -Path $log -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  }
  ForEach($archive in $(Get-ChildItem -Filter "*.zip"))
  {
    Write-Host "Compress-Archive -Path $archive -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
    Compress-Archive -Path $archive -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  }
  ForEach($core in $(Get-ChildItem -Filter "core*"))
  {
    Write-Host "Compress-Archive -Path $core -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
    Compress-Archive -Path $core -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  }
  Write-Host "Compress-Archive -Path testProtocol.txt -Update -DestinationPath `"$INNERWORKDIR\testreport-$d.zip`""
  Compress-Archive -Path testProtocol.txt -Update -DestinationPath "$INNERWORKDIR\testreport-$d.zip"
  Write-Host "Remove-Item -Recurse -Force testProtocol.txt"
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
    $env:TMPDIR = "$INNERWORKDIR\tmp"
    Set-Location "$INNERWORKDIR\ArangoDB"
    ForEach($log in $(Get-ChildItem -Filter "*.log"))
    {
        Remove-Item -Recurse -Force $log 
    }

    Switch -Regex ($TESTSUITE)
    {
        "cluster"
        {
            launchClusterTests
            waitOrKill 600
            createReport  
            Break
        }
        "single"
        {
            launchSingleTests
            waitOrKill 600
            createReport
            Break
        }
        "resilience"
        {
            launchResilienceTests
            waitOrKill 600
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
        Return $true
    }
    Else
    {
        Return $false
    }   
}

Function oskar
{
    checkoutIfNeeded
    runTests
}

Function oskar1
{
    showConfig
    buildArangoDB
    oskar
}

Function oskar2
{
    showConfig
    buildArangoDB
    cluster
    oskar
    single
    oskar
    cluster
}

Function oskar4
{
    showConfig
    buildArangoDB
    rocksdb
    cluster
    oskar
    single
    oskar
    mmfiles
    cluster
    oskar
    single
    oskar
    cluster
    rocksdb
}

Function oskar8
{
    showConfig
    enterprise
    buildArangoDB
    rocksdb
    cluster
    oskar
    single
    oskar
    mmfiles
    cluster
    oskar
    single
    oskar
    community
    buildArangoDB
    rocksdb
    cluster
    oskar
    single
    oskar
    mmfiles
    cluster
    oskar
    single
    oskar
    cluster
    rocksdb
}

Clear
showConfig