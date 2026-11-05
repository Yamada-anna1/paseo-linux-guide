param([string]$FixtureDirectory)
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'paseo-ssh.ps1') -Library
if($env:CI -ne 'true' -or $env:GITHUB_ACTIONS -ne 'true') { throw 'Ephemeral GitHub runner only' }
$script:RealNative=(Get-Item Function:Invoke-Native).ScriptBlock
function Invoke-Native([string]$File,[string[]]$Arguments,[switch]$Interactive,[int]$TimeoutSeconds=30) {
    # Bootstrap with a separate test-only authorized key instead of saving a password.
    # Final BatchMode tests never receive this bootstrap identity.
    if([IO.Path]::GetFileName($File) -eq 'ssh' -and $Interactive) { $Arguments=@('-i',(Join-Path $FixtureDirectory 'bootstrap'))+$Arguments }
    & $script:RealNative $File $Arguments -Interactive:$Interactive -TimeoutSeconds $TimeoutSeconds
}
$hostInfo=Get-Ed25519Info ([IO.File]::ReadAllText((Join-Path $FixtureDirectory 'host.pub')).Trim())
$state=Join-Path $FixtureDirectory 'state space'
$null=[IO.Directory]::CreateDirectory($state)
$known=Join-Path $state 'known_hosts'
Write-Utf8File $known '# unrelated line preserved'
$options=[pscustomobject]@{Server='127.0.0.1';Port=22222;UserName='paseotest';IdentityFile=(Join-Path $FixtureDirectory 'client');ExpectedFingerprint=$hostInfo.Fingerprint;StateDirectory=$state}
Invoke-PaseoSetup $options $known -NoLocalEntry
$auth='/home/paseotest/.ssh/authorized_keys'
$before=(Get-FileHash $auth).Hash
Invoke-PaseoSetup $options $known -NoLocalEntry
if((Get-FileHash $auth).Hash -cne $before) { throw 'Repeated run changed authorized_keys' }
if(@(Get-ChildItem '/home/paseotest/.ssh/authorized_keys.paseo-backup.*').Count -ne 1) { throw 'Expected one backup' }
$options.ExpectedFingerprint='SHA256:incorrect'
$blocked=$false
try { Invoke-PaseoSetup $options $known -NoLocalEntry } catch { $blocked=$true }
if(!$blocked -or (Get-FileHash $auth).Hash -cne $before) { throw 'Wrong fingerprint was not blocked' }
Write-Host 'PASS real OpenSSH E2E: verified host, bootstrap login, actual Linux append, key-only login, repeat idempotence, wrong-pin rejection.'
