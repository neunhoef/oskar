If(-Not($ENV:WORKSPACE))
{
    $ENV:WORKSPACE = $(Split-Path -Parent $global:WORKDIR)
}
$global:WORKDIR = $pwd
If(-Not(Test-Path -PathType Container -Path "work"))
{
    New-Item -ItemType Directory -Path "work"
}
$global:INNERWORKDIR = "$WORKDIR\work"
$env:TMP = "$INNERWORKDIR\tmp"
$env:CLCACHE_DIR="$INNERWORKDIR\.clcache.windows"

$global:GENERATOR = "Visual Studio 15 2017 Win64"
Import-Module VSSetup -ErrorAction Stop

While (Test-Path Alias:curl) 
{
    Remove-Item Alias:curl
}

Function proc($process,$argument,$logfile)
{
    If($logfile -eq $false)
    {
        $p = Start-Process $process -ArgumentList $argument -NoNewWindow -PassThru
        $h = $p.Handle
        $p.WaitForExit()
        If($p.ExitCode -eq 0)
        {
            Set-Variable -Name "ok" -Value $true -Scope global
        }
        Else
        {
            Set-Variable -Name "ok" -Value $false -Scope global
        }
    }
    Else
    {
        $p = Start-Process $process -ArgumentList $argument -RedirectStandardOutput "$logfile.stdout.log" -RedirectStandardError "$logfile.stderr.log" -PassThru
        $h = $p.Handle
        $p.WaitForExit()
        If($p.ExitCode -eq 0)
        {
            Set-Variable -Name "ok" -Value $true -Scope global
        }
        Else
        {
            Set-Variable -Name "ok" -Value $false -Scope global
        }
    }
}

Function comm
{
    Set-Variable -Name "ok" -Value $? -Scope global
}

Function 7zip($Path,$DestinationPath)
{
    7za.exe a -mx9 $DestinationPath $Path 
}

Function showConfig
{
	Write-Host "#################################"
	Write-Host "Global Configuration"
	Write-Host "- User           : "$env:USERDOMAIN\$env:USERNAME
	Write-Host "- Cache          : "$env:CLCACHE_CL
	Write-Host "- Cachedir       : "$env:CLCACHE_DIR
	Write-Host " "
	Write-Host "Build Configuration"
	Write-Host "- Enterprise     : "$ENTERPRISEEDITION
	Write-Host "- Buildmode      : "$BUILDMODE
	Write-Host "- Maintainer     : "$MAINTAINER
	Write-Host " "
	Write-Host "- Generator      : "$GENERATOR
	Write-Host "- Packaging      : "$PACKAGING
	Write-Host "- Static         : "$STATICEXECUTABLES
	Write-Host " "	
	Write-Host "Test Configuration:"
	Write-Host "- Storage engine : "$STORAGEENGINE
	Write-Host "- Test suite     : "$TESTSUITE
	Write-Host " "
	Write-Host "Internal Configuration:"
	Write-Host "- Workdir        : "$WORKDIR
	Write-Host "- Inner workdir  : "$INNERWORKDIR
	Write-Host "- Parallelism    : "$PARALLELISM
	Write-Host "- Verbose        : "$VERBOSEOSKAR
	Write-Host "#################################"
	Write-Host " "
    comm
}

Function lockDirectory
{
    Push-Location $pwd
    Set-Location $WORKDIR
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
            $(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ")
            Start-Sleep -Seconds 15
        }
    }
    comm 
    Pop-Location
}

Function unlockDirectory
{
    Push-Location $pwd
    Set-Location $WORKDIR
    If(Test-Path -PathType Leaf LOCK.$pid)
    {
        Remove-Item LOCK
        Remove-Item LOCK.$pid
        Write-Host "Removed lock"
    }
    comm
    Pop-Location   
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
	$global:PACKAGING = "Off"
    $global:USEFAILURETESTS = "On"
}
Function skipPackagingOff
{
    $global:SKIPPACKAGING = "Off"
	$global:PACKAGING = "On"
    $global:USEFAILURETESTS = "Off"
}
If(-Not($SKIPPACKAGING))
{
    skipPackagingOff
}

Function staticExecutablesOn
{
    $global:STATICEXECUTABLES = "On"
    $global:STATICLIBS = "true"
}
Function staticExecutablesOff
{
    $global:STATICEXECUTABLES = "Off"
    $global:STATICLIBS = "false"
}
If(-Not($STATICEXECUTABLES))
{
    staticExecutablesOff
}

Function signPackageOn
{
    $global:SIGN = $true
}
Function signPackageOff
{
    $global:SIGN = $false
}
If(-Not($SIGN))
{
    signPackageOn
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
    $global:PARALLELISM = 16
}

Function checkoutArangoDB
{
    Push-Location $pwd
    Set-Location $INNERWORKDIR
    If(-Not(Test-Path -PathType Container -Path "ArangoDB"))
    {
        proc -process "git" -argument "clone https://github.com/arangodb/ArangoDB" -logfile $false
    }
    Pop-Location
}

Function checkoutEnterprise
{
    checkoutArangoDB
    if($global:ok)
    {
        Push-Location $pwd
        Set-Location "$INNERWORKDIR\ArangoDB"
        If(-Not(Test-Path -PathType Container -Path "enterprise"))
        {
            If(Test-Path -PathType Leaf -Path "$HOME\.ssh\known_hosts")
            {
                Remove-Item -Force "$HOME\.ssh\known_hosts"
                proc -process "ssh" -argument "-o StrictHostKeyChecking=no git@github.com" -logfile $false
            }
            proc -process "git" -argument "clone ssh://git@github.com/arangodb/enterprise" -logfile $false
        }
        Pop-Location
    }
}

Function checkoutIfNeeded
{
    If($ENTERPRISEEDITION -eq "On")
    {
        If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\enterprise"))
        {
            checkoutEnterprise
        }
    }
    Else
    {
        If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB"))
        {
            checkoutArangoDB
        }
    }
}


Function switchBranches($branch_c,$branch_e)
{
    checkoutIfNeeded
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB";comm
    If ($global:ok) 
    {
        proc -process "git" -argument "clean -dfx" -logfile $false
    }
    If ($global:ok) 
    {
        proc -process "git" -argument "checkout -- ." -logfile $false
    }
    If ($global:ok) 
    {
        proc -process "git" -argument "fetch" -logfile $false
    }
    If ($global:ok) 
    {
        proc -process "git" -argument "checkout $branch_c" -logfile $false
    }
    If ($global:ok) 
    {
        proc -process "git" -argument "reset --hard origin/$branch_c" -logfile $false
    }
    If($ENTERPRISEEDITION -eq "On")
    {
        Push-Location $pwd
        Set-Location "$INNERWORKDIR\ArangoDB\enterprise";comm
        If ($global:ok) 
        {
            proc -process "git" -argument "clean -dfx" -logfile $false
        }
        If ($global:ok) 
        {
            proc -process "git" -argument "checkout -- ." -logfile $false
        }
        If ($global:ok) 
        {
            proc -process "git" -argument "fetch" -logfile $false
        }
        If ($global:ok) 
        {
            proc -process "git" -argument "checkout $branch_e" -logfile $false
        }
        If ($global:ok) 
        {
            proc -process "git" -argument "reset --hard origin/$branch_e" -logfile $false
        }
        Pop-Location
    }
    Pop-Location
}

Function updateOskar
{
    Push-Location $pwd
    Set-Location $WORKDIR
    If ($global:ok) 
    {
        proc -process "git" -argument "checkout -- ." -logfile $false
    }
    If ($global:ok) 
    {
        proc -process "git" -argument "reset --hard origin/master" -logfile $false
    }
    Pop-Location
}

Function clearResults
{
    Push-Location $pwd
    Set-Location $INNERWORKDIR
    ForEach($report in $(Get-ChildItem -Filter testreport*))
    {
        Remove-Item -Force $report
    }
    ForEach($log in $(Get-ChildItem -Filter "*.log"))
    {
        Remove-Item -Force $log 
    }
    If(Test-Path -PathType Leaf -Path test.log)
    {
        Remove-Item -Force test.log
    }
    If(Test-Path -PathType Leaf -Path testProtocol.txt)
    {
        Remove-Item -Force testProtocol.txt
    }
    If(Test-Path -PathType Leaf -Path testfailures.txt)
    {
        Remove-Item -Force testfailures.txt
    }
    comm
    Pop-Location
}

Function showLog
{
    Get-Content "$INNERWORKDIR\test.log" | Out-GridView -Title "$INNERWORKDIR\test.log";comm
}

Function  findArangoDBVersion
{
    If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_MAJOR")[0] -match '.*"([0-9a-zA-Z]*)".*')
    {
        $global:ARANGODB_VERSION_MAJOR = $Matches[1]
        If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_MINOR")[0] -match '.*"([0-9a-zA-Z]*)".*')
        {
            $global:ARANGODB_VERSION_MINOR = $Matches[1]
            If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_PATCH")[0] -match '.*"([0-9a-zA-Z]*)".*')
            {
                $global:ARANGODB_VERSION_PATCH = $Matches[1]
                If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_RELEASE_TYPE")[0] -match '.*"([0-9a-zA-Z]*)".*')
                {
                    $global:ARANGODB_VERSION_RELEASE_TYPE = $Matches[1]
                    If($(Select-String -Path $INNERWORKDIR\ArangoDB\CMakeLists.txt -SimpleMatch "set(ARANGODB_VERSION_RELEASE_NUMBER")[0] -match '.*"([0-9a-zA-Z]*)".*')
                    {
                        $global:ARANGODB_VERSION_RELEASE_NUMBER = $Matches[1]  
                    }
                }

            }
        }

    }
    $global:ARANGODB_VERSION = "$global:ARANGODB_VERSION_MAJOR.$global:ARANGODB_VERSION_MINOR.$global:ARANGODB_VERSION_PATCH"
    If($global:ARANGODB_VERSION_RELEASE_TYPE)
    {
        If($global:ARANGODB_VERSION_RELEASE_NUMBER)
        {
            $global:ARANGODB_FULL_VERSION = "$global:ARANGODB_VERSION-$global:ARANGODB_VERSION_RELEASE_TYPE.$global:ARANGODB_VERSION_RELEASE_NUMBER"
        }
        Else
        {
            $global:ARANGODB_FULL_VERSION = "$global:ARANGODB_VERSION-$global:ARANGODB_VERSION_RELEASE_TYPE"
        }
        
    }
    Else
    {
        $global:ARANGODB_FULL_VERSION = $global:ARANGODB_VERSION   
    }
    return $global:ARANGODB_FULL_VERSION
}

Function transformBundleSniplet
{   
}

Function downloadStarter
{
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (Select-String -Path "$INNERWORKDIR\ArangoDB\VERSIONS" -SimpleMatch "STARTER_REV")[0] -match '([0-9]+.[0-9]+.[0-9]+)|latest' | Out-Null
    $global:STARTER_REV = $Matches[0]
    If($global:STARTER_REV -eq "latest")
    {
        $JSON = Invoke-WebRequest -Uri 'https://api.github.com/repos/arangodb-helper/arangodb/releases/latest' -UseBasicParsing | ConvertFrom-Json
        $global:STARTER_REV = $JSON.name
    }
    Write-Host "Download: Starter"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/arangodb-helper/arangodb/releases/download/$STARTER_REV/arangodb-windows-amd64.exe","$INNERWORKDIR\ArangoDB\build\arangodb.exe")
}

Function downloadSyncer
{
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    If(-Not($env:DOWNLOAD_SYNC_USER))
    {
        Write-Host "Need  environment variable set!"
    }
    (Select-String -Path "$INNERWORKDIR\ArangoDB\VERSIONS" -SimpleMatch "SYNCER_REV")[0] -match '([0-9]+.[0-9]+.[0-9]+)|latest' | Out-Null
    $global:SYNCER_REV = $Matches[0]
    If($global:SYNCER_REV -eq "latest")
    {
        $JSON = curl -s -L "https://$env:DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/latest" | ConvertFrom-Json
        $global:SYNCER_REV = $JSON.name
    }
    $ASSET = curl -s -L "https://$env:DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/tags/$SYNCER_REV" | ConvertFrom-Json
    $ASSET_ID = $(($ASSET.assets) | Where-Object -Property name -eq arangosync-windows-amd64.exe).id
    Write-Host "Download: Syncer"
    curl -s -L -H "Accept: application/octet-stream" "https://$env:DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/assets/$ASSET_ID" -o "$INNERWORKDIR\ArangoDB\build\arangosync.exe"
}

Function configureWindows
{
    If(-Not(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build"))
    {
        New-Item -ItemType Directory -Path "$INNERWORKDIR\ArangoDB\build"
    }
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    If($ENTERPRISEEDITION -eq "On")
    {
        downloadStarter
        downloadSyncer
        Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"   
        Write-Host "Configure: cmake -G `"$GENERATOR`" -T `"v141,host=x64`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DPACKAGING=NSIS -DCMAKE_INSTALL_PREFIX=/ -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DUSE_FAILURE_TESTS=`"$USEFAILURETESTS`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES`" -DOPENSSL_USE_STATIC_LIBS=`"$STATICLIBS`" -DTHIRDPARTY_BIN=`"$INNERWORKDIR\ArangoDB\build\arangodb.exe`" -DTHIRDPARTY_SBIN=`"$INNERWORKDIR\ArangoDB\build\arangosync.exe`" `"$INNERWORKDIR\ArangoDB`""
	    proc -process "cmake" -argument "-G `"$GENERATOR`" -T `"v141,host=x64`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DPACKAGING=NSIS -DCMAKE_INSTALL_PREFIX=/ -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DUSE_FAILURE_TESTS=`"$USEFAILURETESTS`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES`" -DOPENSSL_USE_STATIC_LIBS=`"$STATICLIBS`" -DTHIRDPARTY_BIN=`"$INNERWORKDIR\ArangoDB\build\arangodb.exe`" -DTHIRDPARTY_SBIN=`"$INNERWORKDIR\ArangoDB\build\arangosync.exe`" `"$INNERWORKDIR\ArangoDB`"" -logfile "$INNERWORKDIR\cmake"
    }
    Else
    {
        downloadStarter
        Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
        Write-Host "Configure: cmake -G `"$GENERATOR`" -T `"v141,host=x64`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DPACKAGING=NSIS -DCMAKE_INSTALL_PREFIX=/ -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DUSE_FAILURE_TESTS=`"$USEFAILURETESTS`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES`" -DOPENSSL_USE_STATIC_LIBS=`"$STATICLIBS`" -DTHIRDPARTY_BIN=`"$INNERWORKDIR\ArangoDB\build\arangodb.exe`" `"$INNERWORKDIR\ArangoDB`""
	    proc -process "cmake" -argument "-G `"$GENERATOR`" -T `"v141,host=x64`" -DUSE_MAINTAINER_MODE=`"$MAINTAINER`" -DUSE_ENTERPRISE=`"$ENTERPRISEEDITION`" -DCMAKE_BUILD_TYPE=`"$BUILDMODE`" -DPACKAGING=NSIS -DCMAKE_INSTALL_PREFIX=/ -DSKIP_PACKAGING=`"$SKIPPACKAGING`" -DUSE_FAILURE_TESTS=`"$USEFAILURETESTS`" -DSTATIC_EXECUTABLES=`"$STATICEXECUTABLES`" -DOPENSSL_USE_STATIC_LIBS=`"$STATICLIBS`" -DTHIRDPARTY_BIN=`"$INNERWORKDIR\ArangoDB\build\arangodb.exe`" `"$INNERWORKDIR\ArangoDB`"" -logfile "$INNERWORKDIR\cmake"
    }
    Pop-Location
}

Function buildWindows 
{
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    Write-Host "Build: cmake --build . --config `"$BUILDMODE`""
    proc -process "cmake" -argument "--build . --config `"$BUILDMODE`"" -logfile "$INNERWORKDIR\build"
    If($global:ok)
    {
        Copy-Item "$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\*" -Destination "$INNERWORKDIR\ArangoDB\build\bin\"; comm
    }
    Pop-Location
}

Function packageWindows
{
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB\build"
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    ForEach($TARGET in @("package-arangodb-server-nsis","package-arangodb-server-zip","package-arangodb-client-nsis"))
    {
        Write-Host "Build: cmake --build . --config `"$BUILDMODE`" --target `"$TARGET`""
        proc -process "cmake" -argument "--build . --config `"$BUILDMODE`" --target `"$TARGET`"" -logfile "$INNERWORKDIR\$TARGET-package"
    }
    Pop-Location
}

Function signWindows
{
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB\build\"
    Write-Host "Time: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH.mm.ssZ'))"
    $SIGNTOOL = $(Get-ChildItem C:\ -Recurse "signtool.exe" -ErrorAction SilentlyContinue).FullName[0]
    ForEach($PACKAGE in $(Get-ChildItem -Filter ArangoDB3*.exe).FullName)
    {
        Write-Host "Sign: $SIGNTOOL sign /tr `"http://sha256timestamp.ws.symantec.com/sha256/timestamp`" `"$PACKAGE`""
        proc -process "$SIGNTOOL" -argument "sign /tr `"http://sha256timestamp.ws.symantec.com/sha256/timestamp`" `"$PACKAGE`"" -logfile "$INNERWORKDIR\$PACKAGE-sign"
    }
    Pop-Location
}

Function buildArangoDB
{
    checkoutIfNeeded
    If(Test-Path -PathType Container -Path "$INNERWORKDIR\ArangoDB\build")
    {
       Remove-Item -Recurse -Force -Path "$INNERWORKDIR\ArangoDB\build"
    }
    configureWindows
    If($global:ok)
    {
        Write-Host "Configure OK."
        buildWindows
        if($global:ok)
        {
            Write-Host "Build OK."
            if($SKIPPACKAGING -eq "Off")
            {
                packageWindows
                if($global:ok)
                {
                    Write-Host "Package OK."
                    if($SIGN)
                    {
                        signWindows
                        if($global:ok)
                        {
                            Write-Host "Sign OK."
                        }
                        Else
                        {
                            Write-Host "Sign error, see $INNERWORKDIR\sign.* for details."
                        }
                    }
                }
                Else
                {
                    Write-Host "Package error, see $INNERWORKDIR\package.* for details."
                }
            }
        }
        Else
        {
            Write-Host "Build error, see $INNERWORKDIR\build.* for details."
        }
    }
    Else
    {
        Write-Host "cmake error, see $INNERWORKDIR\cmake.* for details."
    }
}

Function buildStaticArangoDB
{
    staticExecutablesOn
    buildArangoDB
}

Function moveResultsToWorkspace
{
    Write-Host "Moving reports and logs to $env:WORKSPACE ..."
    If(Test-Path -PathType Leaf "$INNERWORKDIR\test.log")
    {
        If(Get-Content -Path "$INNERWORKDIR\test.log" -Head 1 | Select-String -Pattern "BAD" -CaseSensitive)
        {
            ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter testreport*))
            {
                Write-Host "Move $INNERWORKDIR\$file"
                Move-Item -Force -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE; comm
            } 
        }
        Else
        {
            ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter "testreport*" -Exclude "*.zip"))
            {
                Write-Host "Remove $INNERWORKDIR\$file"
                Remove-Item -Force "$INNERWORKDIR\$file"; comm 
            } 
        }
    }
    If(Test-Path -PathType Leaf "$INNERWORKDIR\test.log")
    {
        Write-Host "Move $INNERWORKDIR\test.log"
        Move-Item -Force -Path "$INNERWORKDIR\test.log" -Destination $env:WORKSPACE; comm
    }
    ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter "*.zip"))
    {
        Write-Host "Move $INNERWORKDIR\$file"
        Move-Item -Force -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE; comm
    }
    ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter "build*"))
    {
        Write-Host "Move $INNERWORKDIR\$file"
        Move-Item -Force -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE; comm
    }
    ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter "cmake*"))
    {
        Write-Host "Move $INNERWORKDIR\$file"
        Move-Item -Force -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE; comm
    }
    ForEach ($file in $(Get-ChildItem $INNERWORKDIR -Filter "package*"))
    {
        Write-Host "Move $INNERWORKDIR\$file"
        Move-Item -Force -Path "$INNERWORKDIR\$file" -Destination $env:WORKSPACE; comm
    }
    if($SKIPPACKAGING -eq "Off")
    {
        ForEach ($file in $(Get-ChildItem "$INNERWORKDIR\ArangoDB\build" -Filter "ArangoDB3*.exe"))
        {
            Write-Host "Move $INNERWORKDIR\ArangoDB\build\$file"
            Move-Item -Force -Path "$INNERWORKDIR\ArangoDB\build\$file" -Destination $env:WORKSPACE; comm 
        }
        ForEach ($file in $(Get-ChildItem "$INNERWORKDIR\ArangoDB\build" -Filter "ArangoDB3*.zip"))
        {
            Write-Host "Move $INNERWORKDIR\ArangoDB\build\$file"
            Move-Item -Force -Path "$INNERWORKDIR\ArangoDB\build\$file" -Destination $env:WORKSPACE; comm 
        }
    }
    If(Test-Path -PathType Leaf "$INNERWORKDIR\testfailures.log")
    {
        Write-Host "Move $INNERWORKDIR\testfailures.log"
        Move-Item -Force -Path "$INNERWORKDIR\testfailures.log" -Destination $env:WORKSPACE; comm 
    }
}

Function getRepoState
{
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\Arangodb"; comm
    $global:repoState = "$(git rev-parse HEAD)`r`n"+$(git status -b -s | Select-String -Pattern "^[?]" -NotMatch)
    If($ENTERPRISEEDITION -eq "On")
    {
        Push-Location $pwd
        Set-Location "$INNERWORKDIR\ArangoDB\enterprise"; comm
        $global:repoStateEnterprise = "$(git rev-parse HEAD)`r`n$(git status -b -s | Select-String -Pattern "^[?]" -NotMatch)"
        Pop-Location
    }
    Else
    {
        $global:repoStateEnterprise = ""
    }
    Pop-Location
}

Function noteStartAndRepoState
{
    getRepoState
    If(Test-Path -PathType Leaf -Path testProtocol.txt)
    {
        Remove-Item -Force testProtocol.txt
    }
    $(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ") | Add-Content testProtocol.txt
    Write-Output "========== Status of main repository:" | Add-Content testProtocol.txt
    Write-Host "========== Status of main repository:"
    ForEach($line in $global:repoState)
    {
        Write-Output " $line" | Add-Content testProtocol.txt
        Write-Host " $line"
    }
    If($ENTERPRISEEDITION -eq "On")
    {
        Write-Output "Status of enterprise repository:" | Add-Content testProtocol.txt
        Write-Host "Status of enterprise repository:"
        ForEach($line in $global:repoStateEnterprise)
        {
            Write-Output " $line" | Add-Content testProtocol.txt
            Write-Host " $line"
        }
    }
}

Function unittest($test,$output)
{
    $PORT=Get-Random -Minimum 20000 -Maximum 65535
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB"; comm
    Write-Host "Test: $INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\arangosh.exe -c $INNERWORKDIR\ArangoDB\etc\relative\arangosh.conf --log.level warning --server.endpoint tcp://127.0.0.1:$PORT --javascript.execute $INNERWORKDIR\ArangoDB\UnitTests\unittest.js -- $test"
    [array]$global:UPIDS = [array]$global:UPIDS+$(Start-Process -FilePath "$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\arangosh.exe" -ArgumentList " -c $INNERWORKDIR\ArangoDB\etc\relative\arangosh.conf --log.level warning --server.endpoint tcp://127.0.0.1:$PORT --javascript.execute $INNERWORKDIR\ArangoDB\UnitTests\unittest.js -- $test" -RedirectStandardOutput "$output.stdout.log" -RedirectStandardError "$output.stderr.log" -PassThru).Id; comm
    Pop-Location
}

Function launchSingleTests
{
    noteStartAndRepoState
    Write-Host "Launching tests..."
    $global:portBase = 10000

    Function test1([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        If(-Not(Select-String -Path $INNERWORKDIR\ArangoDB\UnitTests\OskarTestSuitesBlackList -pattern $test[0]))
        {
            unittest "$($test[0]) --cluster false --storageEngine $STORAGEENGINE --minPort $global:portBase --maxPort $($global:portBase + 99) $($test[2..$($test.Length)]) --skipNondeterministic true --skipTimeCritical true --testOutput $env:TMP\$($test[0])$($test[1]).out --writeXmlReport false" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
            $global:portBase = $($global:portBase + 100)
            Start-Sleep 5
        }
        Else
        {
            Write-Host "Test suite" $test[0] "skipped by UnitTests/OskarTestSuitesBlackList"
        }
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
    test1 "shell_client_aql",""
    test1 "dump",""
    test1 "server_http",""
    test1 "agency",""
    test1 "shell_replication",""
    test1 "http_replication",""
    test1 "catch",""
    test1 "version",""
    test1 "endpoints","","--skipEndpointsIpv6","true"
    comm
}

Function launchClusterTests
{
    noteStartAndRepoState
    Write-Host "Launching tests..."
    $global:portBase = 10000

    Function test1([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        If(-Not(Select-String -Path $INNERWORKDIR\ArangoDB\UnitTests\OskarTestSuitesBlackList -pattern $test[0]))
        {
            $ruby = $(Get-Command ruby.exe -ErrorAction SilentlyContinue).Source
            if (-not $ruby -eq "") {
              $ruby = "--ruby $ruby"
            }
            $rspec = $((Get-Command rspec.bat).Source).Substring(0,((Get-Command rspec.bat).Source).Length-4)
            if (-not $rspec -eq "") {
              $rspec = "--rspec $rspec"
            }
            unittest "$($test[0]) --cluster false --storageEngine $STORAGEENGINE --minPort $global:portBase --maxPort $($global:portBase + 99) $($test[2..$($test.Length)]) --skipNondeterministic true --skipTimeCritical true --testOutput $env:TMP\$($test[0])$($test[1]).out --writeXmlReport false $ruby $rspec" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
            $global:portBase = $($global:portBase + 100)
            Start-Sleep 5
        }
        Else
        {
            Write-Host "Test suite" $test[0] "skipped by UnitTests/OskarTestSuitesBlackList"
        }
    }
    Function test3([array]$test)
    {
        If($VERBOSEOSKAR -eq "On")
        {
            Write-Host "Launching $test"
        }
        If(-Not(Select-String -Path $INNERWORKDIR\ArangoDB\UnitTests\OskarTestSuitesBlackList -pattern $test[0]))
        {
            $ruby = $(Get-Command ruby.exe -ErrorAction SilentlyContinue).Source
            if (-not $ruby -eq "") {
              $ruby = "--ruby $ruby"
            }
            $rspec = $((Get-Command rspec.bat).Source).Substring(0,((Get-Command rspec.bat).Source).Length-4)
            if (-not $rspec -eq "") {
              $rspec = "--rspec $rspec"
            }
            unittest "$($test[0]) --test $($test[2]) --storageEngine $STORAGEENGINE --cluster true --minPort $global:portBase --maxPort $($global:portBase + 99) --skipNondeterministic true --testOutput $env:TMP\$($test[0])_$($test[1]).out --writeXmlReport false $ruby $rspec" -output "$INNERWORKDIR\ArangoDB\$($test[0])_$($test[1])"
            $global:portBase = $($global:portBase + 100)
            Start-Sleep 5
        }
        Else
        {
            Write-Host "Test suite" $test[0] "skipped by UnitTests/OskarTestSuitesBlackList"
        }
    }
    [array]$global:UPIDS = $null
    test3 "resilience","move","moving-shards-cluster.js"
    test3 "resilience","failover","resilience-synchronous-repl-cluster.js"
    test1 "shell_client",""
    test1 "shell_server",""
    test1 "http_server",""
    test1 "ssl_server",""
    test3 "resilience","sharddist","shard-distribution-spec.js"
    test1 "shell_server_aql","0","--testBuckets","5/0"
    test1 "shell_server_aql","1","--testBuckets","5/1"
    test1 "shell_server_aql","2","--testBuckets","5/2"
    test1 "shell_server_aql","3","--testBuckets","5/3"
    test1 "shell_server_aql","4","--testBuckets","5/4"
    test1 "shell_client_aql",""
    test1 "dump",""
    test1 "server_http",""
    test1 "agency",""
    comm
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
    comm
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
    comm
}

Function log([array]$log)
{
    ForEach($l in $log)
    {
        Write-Host $l
        $l | Add-Content "$INNERWORKDIR\test.log"
    }
    comm
}

Function createReport
{
    $date = $(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH.mm.ssZ")
    $date | Add-Content testProtocol.txt
    $global:result = "GOOD"
    $global:badtests = $null
    Push-Location "$INNERWORKDIR\tmp"
        ForEach($dir in (Get-ChildItem -Directory -Filter "*.out"))
        {
            Write-Host "Looking at directory $($dir.BaseName)"
            If(Test-Path -PathType Leaf -Path "$($dir.FullName)\UNITTEST_RESULT_EXECUTIVE_SUMMARY.json")
                {
                            If(-Not($(Get-Content "$($dir.FullName)\UNITTEST_RESULT_EXECUTIVE_SUMMARY.json") -eq "true"))
                            {
                                $global:result = "BAD"
                                $file = $($dir.BaseName).Substring(0,$($dir.BaseName).Length-4)+".stdout.log"
                                Write-Host "Bad result in $file"
                                "Bad result in $file" | Add-Content testProtocol.txt
                                $global:badtests = $global:badtests + "Bad result in $file`r`n"
                            }   
                }
            Else
                {
                    Write-Host "No Testresult found at directory $($dir.BaseName)"
                    $global:result = "BAD"
                    "No Testresult found at directory $($dir.BaseName)" | Add-Content testProtocol.txt
                    $global:badtests = $global:badtests + "No Testresult found at directory $($dir.BaseName)`r`n"   
                }
        }
    Pop-Location
    $global:result | Add-Content testProtocol.txt
    If(Get-ChildItem -Path "$env:TMP" -Filter "core.dmp" -Recurse -ErrorAction SilentlyContinue -Force)
    {
        Write-Host "7zip -Path `"$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\`" -DestinationPath `"$INNERWORKDIR\crashreport-$date.zip`""
        7zip -Path "$INNERWORKDIR\ArangoDB\build\bin\$BUILDMODE\" -DestinationPath "$INNERWORKDIR\crashreport-$date.zip"
        New-Item -ItemType Directory -Path "$INNERWORKDIR\core"
        ForEach($core in (Get-ChildItem -Path "$env:TMP" -Filter "core.dmp" -Recurse -ErrorAction SilentlyContinue))
        {
            $newcore = "$($core.BaseName).$(Get-Random)"
            Add-Content -Value "$($core.FullName) = $newcore" -Path "$INNERWORKDIR\core\corelocation.log"
            Move-Item -Force $core.FullName  "$INNERWORKDIR\core\$newcore"
            Write-Host "7zip -Path `"$INNERWORKDIR\core\$newcore`" -DestinationPath `"$INNERWORKDIR\crashreport-$date.zip`""
            7zip -Path "$INNERWORKDIR\core\$newcore" -DestinationPath "$INNERWORKDIR\crashreport-$date.zip"
        }
        Write-Host "7zip -Path `"$INNERWORKDIR\core\corelocation.log`" -DestinationPath `"$INNERWORKDIR\crashreport-$date.zip`""
        7zip -Path "$INNERWORKDIR\core\corelocation.log" -DestinationPath "$INNERWORKDIR\crashreport-$date.zip"
        Remove-Item -Force -Recurse -Path "$INNERWORKDIR\core"
    }
    Push-Location "$env:TMP"
        If(Test-Path -PathType Leaf -Path "$INNERWORKDIR\ArangoDB\innerlogs.zip")
        {
            Remove-Item -Force "$INNERWORKDIR\ArangoDB\innerlogs.zip"
        }
        Write-Host "7zip -Path `"$env:TMP\`" -DestinationPath `"$INNERWORKDIR\ArangoDB\innerlogs.zip`""
        7zip -Path "$env:TMP\" -DestinationPath "$INNERWORKDIR\ArangoDB\innerlogs.zip"
    Pop-Location
    ForEach($log in $(Get-ChildItem -Filter "*.log"))
    {
        Write-Host "7zip -Path $log  -DestinationPath `"$INNERWORKDIR\testreport-$date.zip`""
        7zip -Path $log  -DestinationPath "$INNERWORKDIR\testreport-$date.zip"
    }
    ForEach($archive in $(Get-ChildItem -Filter "*.zip" | Where {$_.Name -ne "crashreport-$date.zip"}))
    {
        Write-Host "7zip -Path $archive -DestinationPath `"$INNERWORKDIR\testreport-$date.zip`""
        7zip -Path $archive -DestinationPath "$INNERWORKDIR\testreport-$date.zip"
    }
    Write-Host "7zip -Path testProtocol.txt -DestinationPath `"$INNERWORKDIR\testreport-$date.zip`""
    7zip -Path testProtocol.txt -DestinationPath "$INNERWORKDIR\testreport-$date.zip"

    log "$date $TESTSUITE $global:result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE",$global:repoState,$global:repoStateEnterprise,$badtests
    If(Test-Path -PathType Leaf -Path "$INNERWORKDIR\testfailures.log")
    {
        Remove-Item -Force "$INNERWORKDIR\testfailures.log"
    }
    ForEach($file in (Get-ChildItem -Path "$INNERWORKDIR\tmp" -Filter "testfailures.txt" -Recurse).FullName)
    {
        Get-Content $file | Add-Content "$INNERWORKDIR\testfailures.log"; comm
    }
}

Function runTests
{
    If(Test-Path -PathType Container -Path $env:TMP)
    {
        Remove-Item -Recurse -Force -Path $env:TMP
        New-Item -ItemType Directory -Path $env:TMP
    }
    Else
    {
        New-Item -ItemType Directory -Path $env:TMP
    }
    Push-Location $pwd
    Set-Location "$INNERWORKDIR\ArangoDB"
    ForEach($log in $(Get-ChildItem -Filter "*.log"))
    {
        Remove-Item -Recurse -Force $log 
    }
    Pop-Location

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
            $global:result = "BAD"
            Break
        }
    }

    If($global:result -eq "GOOD")
    {
        Set-Variable -Name "ok" -Value $true -Scope global
    }
    Else
    {
        Set-Variable -Name "ok" -Value $false -Scope global
    }   
}

Function oskar
{
    checkoutIfNeeded
    if($global:ok)
    {
        runTests
    }
}

Function oskar1
{
    showConfig
    buildArangoDB
    if($global:ok)
    {
        oskar
    }
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
    comm
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
    comm
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
    comm
}

Function makeRelease
{
    maintainerOff
    skipPackagingOff
    signPackageOn
    community
    buildArangoDB
    moveResultsToWorkspace
    enterprise
    buildArangoDB
    moveResultsToWorkspace
}
