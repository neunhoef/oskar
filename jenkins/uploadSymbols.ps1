  Function proc($process,$argument)
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

proc -process "ssh" -argument "root@symbol.arangodb.biz cd /script/ && python program.py /mnt/symsrv_arangodb*"
proc -process "ssh" -argument "root@symbol.arangodb.biz gsutil rsync -r /mnt/ gs://download.arangodb.com"