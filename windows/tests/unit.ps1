$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'paseo-ssh.ps1') -Library
$suite=Join-Path ([IO.Path]::GetTempPath()) ('paseo-tests-'+[Guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($suite)
$script:Pass=0
$script:RealNative=(Get-Item Function:Invoke-Native).ScriptBlock
function Check($Condition,[string]$Message) { if (!$Condition) { throw $Message } }
function Case([string]$Name,[scriptblock]$Body) { & $Body; $script:Pass++; Write-Host "PASS $script:Pass $Name" }
function Must-Fail([scriptblock]$Body,[string]$Pattern) { $failed=$false; try { & $Body } catch { $failed=$true; Check ($_.Exception.Message -match $Pattern) ('Wrong error: '+$_.Exception.Message) }; Check $failed 'Expected rejection' }
function Get-Service { return $null } # Never touch the real user's agent in these offline tests.
try {
    $keygen=Get-NativePath 'ssh-keygen'
    $fixture=Join-Path $suite 'fixture'
    $result=& $script:RealNative $keygen @('-q','-t','ed25519','-N','','-f',$fixture)
    Check ($result.Code -eq 0) ('Fixture key generation failed: '+$result.Err)
    $script:FixtureInfo=Get-Ed25519Info ([IO.File]::ReadAllText($fixture+'.pub').Trim())
    Case 'real ED25519 parser matches OpenSSH fingerprint' {
        $result=& $script:RealNative $keygen @('-E','sha256','-lf',($fixture+'.pub'))
        Check ($result.Out.Contains($script:FixtureInfo.Fingerprint)) 'fingerprint mismatch'
    }
    Case 'IPv4 / username / port reject shell injection and noncanonical input' {
        Assert-Connection '127.0.0.1' 22 'root'
        foreach($bad in @('127.0.0.1;whoami','-oProxyCommand=x','127.1','001.2.3.4','example.invalid','::1')) { Must-Fail { Assert-Connection $bad 22 'root' } 'IPv4' }
        Must-Fail { Assert-Connection '127.0.0.1' 0 'root' } '1'
        Must-Fail { Assert-Connection '127.0.0.1' 22 'root;id' } '.'
    }
    Case 'multiple native applications resolve to exactly one existing executable' {
        foreach($name in @('ssh','ssh-keygen','ssh-keyscan')) {
            $resolved=Get-NativePath $name
            Check ($resolved -is [string] -and (Test-Path -LiteralPath $resolved -PathType Leaf)) ('bad executable: '+$name)
            Check ($resolved -ceq @(Get-Command $name -CommandType Application)[0].Source) 'not first executable'
        }
    }
    Case 'download-style scriptblock entry parses and preserves reusable source' {
        $source=[IO.File]::ReadAllText((Join-Path $root 'paseo-ssh.ps1'))
        & ([scriptblock]::Create($source)) -Library
        Check ($script:PaseoSource.Trim([char]0xfeff) -ceq $source.Trim([char]0xfeff)) 'entry source not captured exactly'
    }
    Case 'public key validator rejects private files, multiline and spoofed binary type' {
        Must-Fail { Get-Ed25519Info ([IO.File]::ReadAllText($fixture)) } '.'
        Must-Fail { Get-Ed25519Info ($script:FixtureInfo.Line+"`n"+$script:FixtureInfo.Line) } '.'
        Must-Fail { Get-Ed25519Info 'ssh-ed25519 AA==' } '.'
        Must-Fail { Get-Ed25519Info ('ssh-rsa '+$script:FixtureInfo.Blob) } '.'
    }
    Case 'native argument transport handles spaces Unicode quotes and trailing slash' {
        $probe=Join-Path $suite 'argument probe.ps1'
        Write-Utf8File $probe 'param([string]$Value) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value))'
        $engine=(Get-Process -Id $PID).Path
        foreach($value in @('a b','quote"inside','C:\space path\',([char]0x4e2d).ToString()+' space')) {
            $result=& $script:RealNative $engine @('-NoProfile','-ExecutionPolicy','Bypass','-File',$probe,'-Value',$value)
            Check ($result.Code -eq 0) $result.Err
            Check ($result.Out.Trim() -ceq [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($value))) ('argument corrupted: '+$value)
        }
    }
    Case 'real Windows OpenSSH parses the pinned known_hosts path with spaces' {
        $emptyConfig=Join-Path $suite 'empty-config'
        Write-Utf8File $emptyConfig ''
        $pinPath=Join-Path $suite 'directory with spaces/verified-host'
        $settings=[pscustomobject]@{IdentityFile=$fixture;Port=2222;UserName='root';Server='127.0.0.1'}
        $arguments=@('-F',$emptyConfig,'-G')+@(Get-SshArguments $settings $pinPath $emptyConfig $false)
        $result=& $script:RealNative (Get-NativePath 'ssh') $arguments
        Check ($result.Code -eq 0) $result.Err
        Check ($result.Out.Contains($pinPath.Replace('\','/'))) 'OpenSSH parsed pinned path incorrectly'
        Check ($result.Out -match '(?m)^batchmode yes\r?$') 'batch mode not set'
        Check ($result.Out -match '(?m)^stricthostkeychecking (true|yes)\r?$') 'host checking not strict'
    }
    function Invoke-Native([string]$File,[string[]]$Arguments,[switch]$Interactive,[int]$TimeoutSeconds=30) {
        $name=[IO.Path]::GetFileNameWithoutExtension($File)
        if($name -eq 'ssh-keyscan') { return [pscustomobject]@{Code=0;Out=('127.0.0.1 ssh-ed25519 '+$script:FixtureInfo.Blob+"`n");Err=''} }
        if($name -eq 'ssh') {
            $script:SshCalls++
            Check ($Arguments -contains 'StrictHostKeyChecking=yes') 'host checking relaxed'
            Check ($Arguments -contains 'IdentitiesOnly=yes') 'identity selection absent'
            if($Interactive) { $script:InstallCalls++; $script:Installed=$true; return [pscustomobject]@{Code=$script:InstallCode;Out='';Err=''} }
            $success=$script:Installed -and !$script:FinalFail
            return [pscustomobject]@{Code=$(if($success){0}else{255});Out=$(if($success){"PASEO_SSH_OK`n"}else{''});Err=$(if($success){''}else{'test authentication failure'})}
        }
        & $script:RealNative $File $Arguments -Interactive:$Interactive -TimeoutSeconds $TimeoutSeconds
    }
    function Setup-Case {
        $script:SshCalls=0; $script:InstallCalls=0; $script:InstallCode=0; $script:Installed=$false; $script:FinalFail=$false
        $caseDir=Join-Path $suite ([Guid]::NewGuid().ToString('N')+' space')
        $null=[IO.Directory]::CreateDirectory($caseDir)
        $script:Options=[pscustomobject]@{Server='127.0.0.1';Port=22;UserName='root';IdentityFile=$fixture;ExpectedFingerprint=$script:FixtureInfo.Fingerprint;StateDirectory=$caseDir}
        $script:Known=Join-Path $caseDir 'known_hosts'
        Write-Utf8File $script:Known '# preserve unrelated records'
    }
    Case 'fingerprint mismatch fails before any SSH login or known_hosts change' {
        Setup-Case; $script:Options.ExpectedFingerprint='SHA256:wrong'
        Must-Fail { Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry } '.'
        Check ($script:SshCalls -eq 0) 'connected before verification'
        Check ([IO.File]::ReadAllText($script:Known) -ceq '# preserve unrelated records') 'modified trust'
    }
    Case 'verified repair backs up host records and saves only non-secret settings' {
        Setup-Case; Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry
        Check ($script:InstallCalls -eq 1) 'repair not invoked once'
        Check ((Get-ChildItem ($script:Known+'.paseo-backup.*')).Count -eq 1) 'backup missing'
        Check ([IO.File]::ReadAllText($script:Known).Contains('# preserve unrelated records')) 'lost unrelated record'
        $settings=Read-Settings $script:Options.StateDirectory
        Check ($settings.Fingerprint -ceq $script:FixtureInfo.Fingerprint) 'pin not saved'
        Check ($settings.PSObject.Properties.Name.Count -eq 5) 'unexpected settings fields'
    }
    Case 'repeat run skips repair and does not create repeated known-host backups' {
        $script:InstallCalls=0
        Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry
        Check ($script:InstallCalls -eq 0) 'duplicate install'
        Check ((Get-ChildItem ($script:Known+'.paseo-backup.*')).Count -eq 1) 'duplicate backup'
    }
    Case 'failed remote command prevents known_hosts commit and success settings' {
        Setup-Case; $script:InstallCode=1
        Must-Fail { Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry } '.'
        Check (!(Test-Path (Join-Path $script:Options.StateDirectory 'settings.json'))) 'saved false success'
        Check ([IO.File]::ReadAllText($script:Known) -ceq '# preserve unrelated records') 'changed known hosts'
    }
    Case 'failed final key-only test is not reported as success' {
        Setup-Case; $script:FinalFail=$true
        Must-Fail { Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry } '.'
        Check (!(Test-Path (Join-Path $script:Options.StateDirectory 'settings.json'))) 'saved false success'
    }
    Case 'revoked host entry stops before login and is preserved' {
        Setup-Case
        $revoked='@revoked 127.0.0.1 ssh-ed25519 '+$script:FixtureInfo.Blob
        Write-Utf8File $script:Known $revoked
        Must-Fail { Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry } '.'
        Check ($script:SshCalls -eq 0) 'revoked host contacted'
        Check ([IO.File]::ReadAllText($script:Known) -ceq $revoked) 'revocation removed'
    }
    Case 'missing half of key pair is preserved instead of overwritten' {
        Setup-Case
        $half=Join-Path $script:Options.StateDirectory 'half-key'
        Copy-Item -LiteralPath $fixture -Destination $half
        $script:Options.IdentityFile=$half
        Must-Fail { Invoke-PaseoSetup $script:Options $script:Known -NoLocalEntry } '.'
        Check (!(Test-Path ($half+'.pub'))) 'silently created missing key'
    }
    Case 'known-host replacement failure leaves original bytes intact' {
        Setup-Case
        $before=[IO.File]::ReadAllText($script:Known)
        $fileLock=[IO.File]::Open($script:Known,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
        try { Must-Fail { Save-HostRecord $script:Known '127.0.0.1' $script:FixtureInfo.Line $keygen $script:Options.StateDirectory } '.' }
        finally { $fileLock.Dispose() }
        Check ([IO.File]::ReadAllText($script:Known) -ceq $before) 'overwrote locked original'
    }
    Case 'nondefault port uses exact bracketed known_hosts target' {
        Check ((Get-TargetToken '127.0.0.1' 2222) -ceq '[127.0.0.1]:2222') 'port target wrong'
    }
    Case 'saved settings roundtrip and previous backup are deterministic' {
        Setup-Case
        $value=[pscustomobject]@{Server='127.0.0.1';UserName='root';Port=22;IdentityFile=$fixture;Fingerprint=$script:FixtureInfo.Fingerprint}
        Save-Settings $script:Options.StateDirectory $value
        $value.Port=2222
        Save-Settings $script:Options.StateDirectory $value
        Check ((Read-Settings $script:Options.StateDirectory).Port -eq 2222) 'settings not updated'
        Check (([IO.File]::ReadAllText((Join-Path $script:Options.StateDirectory 'settings.json.previous')) | ConvertFrom-Json).Port -eq 22) 'previous settings lost'
    }
    if($env:OS -eq 'Windows_NT') {
        Case 'local entry is BOM encoded and desktop shortcuts stay in isolated fixture' {
            Setup-Case
            $desktop=Join-Path $script:Options.StateDirectory 'fake-desktop'
            $null=[IO.Directory]::CreateDirectory($desktop)
            Install-LocalEntry $script:Options.StateDirectory $desktop
            $sourceBytes=[IO.File]::ReadAllBytes((Join-Path $script:Options.StateDirectory 'paseo-ssh.ps1'))
            Check ($sourceBytes[0] -eq 239 -and $sourceBytes[1] -eq 187 -and $sourceBytes[2] -eq 191) 'missing UTF8 BOM'
            Check (@(Get-ChildItem $desktop -Filter '*.lnk').Count -eq 2) 'missing local shortcuts'
            Install-LocalEntry $script:Options.StateDirectory $desktop
            Check (@(Get-ChildItem $desktop -Filter '*.lnk').Count -eq 2) 'duplicate shortcuts'
        }
    }
    Case 'all temporary work directories cleaned without deleting settings' {
        Check (@(Get-ChildItem $suite -Directory -Recurse | Where-Object Name -like 'work-*').Count -eq 0) 'work not cleaned'
    }
    Write-Host "$script:Pass tests passed on PowerShell $($PSVersionTable.PSVersion). Real user keys and servers untouched."
} finally {
    if([IO.Path]::GetFileName($suite) -match '^paseo-tests-[a-f0-9]{32}$' -and [IO.Path]::GetDirectoryName($suite).TrimEnd('\','/') -eq [IO.Path]::GetTempPath().TrimEnd('\','/')) { [IO.Directory]::Delete($suite,$true) }
}
