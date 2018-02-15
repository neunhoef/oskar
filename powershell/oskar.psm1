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