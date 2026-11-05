param([string]$Url='https://raw.githubusercontent.com/Yamada-anna1/paseo-ssh-windows/main/paseo-ssh.ps1')
$ErrorActionPreference='Stop'
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('paseo-download-test-'+[Guid]::NewGuid().ToString('N'))
try {
    $download=Invoke-RestMethod -Uri $Url
    # Web text can retain U+FEFF, unlike StreamReader/ReadAllText. Remove only leading BOM.
    & ([scriptblock]::Create($download.TrimStart([char]0xfeff))) -Help -StateDirectory $fixture
    if (Test-Path (Join-Path $fixture 'settings.json')) { throw 'Help unexpectedly saved connection settings' }
    Write-Host "PASS: actual published HTTPS loader on PowerShell $($PSVersionTable.PSVersion); help only, no SSH connection."
} finally {
    if ([IO.Directory]::Exists($fixture) -and [IO.Path]::GetFileName($fixture) -match '^paseo-download-test-[a-f0-9]{32}$' -and [IO.Path]::GetDirectoryName($fixture).TrimEnd('\','/') -eq [IO.Path]::GetTempPath().TrimEnd('\','/')) { [IO.Directory]::Delete($fixture,$true) }
}
