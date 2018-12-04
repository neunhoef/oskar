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
  
If(Test-Path -PathType Leaf -Path "$HOME\.ssh\known_hosts")
{
    Remove-Item -Force "$HOME\.ssh\known_hosts"
    proc -process "ssh" -argument "-o StrictHostKeyChecking=no root@symbol.arangodb.biz exit"
}
proc -process "ssh" -argument "root@symbol.arangodb.biz cd /script/ && python program.py /mnt/symsrv_arangodb*"
proc -process "ssh" -argument "root@symbol.arangodb.biz gsutil rsync -r /mnt/ gs://download.arangodb.com"