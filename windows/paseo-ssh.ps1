#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Server = '',
    [string]$ExpectedFingerprint = '',
    [string]$UserName = '',
    [int]$Port = 0,
    [string]$IdentityFile = '',
    [string]$StateDirectory = '',
    [switch]$Settings,
    [switch]$Help,
    [switch]$Library
)

$script:PaseoVersion = '1.0.0'
$script:RemoteBase64 = 'IyEvdXNyL2Jpbi9lbnYgYmFzaAojIENhbGxlZCBvbmx5IEFGVEVSIGhvc3QgZmluZ2VycHJpbnQgdmVyaWZpY2F0aW9uIGFuZCBzdWNjZXNzZnVsIFNTSCBhdXRoZW50aWNhdGlvbi4Kc2V0IC1ldW8gcGlwZWZhaWwKZmFpbCgpIHsgcHJpbnRmICdTVE9QOiAlc1xuJyAiJCoiID4mMjsgZXhpdCAxOyB9CltbICQjID09IDEgJiYgIiQxIiA9fiBeW0EtWmEtejAtOSsvXSs9ezAsMn0kIF1dIHx8IGZhaWwgJ2ludmFsaWQgcHVibGljIGtleSBhcmd1bWVudCcKa2V5X2Jsb2I9JDEKdGFyZ2V0X2hvbWU9JHtIT01FOi19CltbICIkdGFyZ2V0X2hvbWUiID09IC8qICYmICIkdGFyZ2V0X2hvbWUiICE9IC8gJiYgLWQgIiR0YXJnZXRfaG9tZSIgJiYgISAtTCAiJHRhcmdldF9ob21lIiBdXSB8fCBmYWlsICdpbnZhbGlkIHVzZXIgaG9tZScKdGFyZ2V0X2hvbWU9JChjZCAtUCAtLSAiJHRhcmdldF9ob21lIiAmJiBwd2QgLVApCltbICIkdGFyZ2V0X2hvbWUiICE9IC8gXV0gfHwgZmFpbCAncm9vdCBkaXJlY3RvcnkgaXMgbm90IGEgdXNlciBob21lJwpzc2hfZGlyPSIkdGFyZ2V0X2hvbWUvLnNzaCIKYXV0aF9maWxlPSIkc3NoX2Rpci9hdXRob3JpemVkX2tleXMiCltbICEgLUwgIiRzc2hfZGlyIiAmJiAoICEgLWUgIiRzc2hfZGlyIiB8fCAtZCAiJHNzaF9kaXIiICkgXV0gfHwgZmFpbCAndW5zYWZlIC5zc2ggZGlyZWN0b3J5JwpbWyAhIC1MICIkYXV0aF9maWxlIiAmJiAoICEgLWUgIiRhdXRoX2ZpbGUiIHx8IC1mICIkYXV0aF9maWxlIiApIF1dIHx8IGZhaWwgJ3Vuc2FmZSBhdXRob3JpemF0aW9uIGZpbGUnCmZvciB0YXJnZXQgaW4gIiR0YXJnZXRfaG9tZSIgIiRzc2hfZGlyIiAiJGF1dGhfZmlsZSI7IGRvCiAgaWYgW1sgLWUgIiR0YXJnZXQiIF1dOyB0aGVuCiAgICBbWyAtTyAiJHRhcmdldCIgXV0gfHwgZmFpbCAnb3duZXJzaGlwIGRvZXMgbm90IG1hdGNoIGxvZ2luIHVzZXInCiAgICBtb2RlPSQoc3RhdCAtYyAlYSAtLSAiJHRhcmdldCIpCiAgICAoKCAoOCMkbW9kZSAmIDAwMjIpID09IDAgKSkgfHwgZmFpbCAnZ3JvdXAvd29ybGQgd3JpdGFibGUgdGFyZ2V0OyBpbnNwZWN0IGJlZm9yZSByZXBhaXInCiAgZmkKZG9uZQp1bWFzayAwNzcKd29ya19kaXI9JChta3RlbXAgLWQgL3RtcC9wYXNlby1hdXRob3JpemUuWFhYWFhYWFgpCmNsZWFudXAoKSB7IFtbICIkd29ya19kaXIiID09IC90bXAvcGFzZW8tYXV0aG9yaXplLiogJiYgLWQgIiR3b3JrX2RpciIgJiYgISAtTCAiJHdvcmtfZGlyIiBdXSAmJiBybSAtcmYgLS0gIiR3b3JrX2RpciI7IH0KdHJhcCBjbGVhbnVwIEVYSVQKcHJpbnRmICdzc2gtZWQyNTUxOSAlcyBwYXNlby1zc2hcbicgIiRrZXlfYmxvYiIgPiAiJHdvcmtfZGlyL2tleS5wdWIiCnNzaC1rZXlnZW4gLUUgc2hhMjU2IC1sZiAiJHdvcmtfZGlyL2tleS5wdWIiIHx8IGZhaWwgJ2ludmFsaWQgRUQyNTUxOSBwdWJsaWMga2V5JwppZiBbWyAtZiAiJGF1dGhfZmlsZSIgXV07IHRoZW4KICBmb3VuZD0kKGF3ayAtdiBrZXk9IiRrZXlfYmxvYiIgJ2luZGV4KCQwLGtleSkgeyBmb3VuZD0xIH0gRU5EIHsgcHJpbnQgZm91bmQrMCB9JyAiJGF1dGhfZmlsZSIpCiAgaWYgW1sgIiRmb3VuZCIgPT0gMSBdXTsgdGhlbgogICAgcHJpbnRmICclc1xuJyAnS0VZX0FMUkVBRFlfUFJFU0VOVDogcmVzdHJpY3Rpb25zIHByZXNlcnZlZCcKICAgIGV4aXQgMAogIGZpCmZpCm1rZGlyIC1wIC1tIDcwMCAtLSAiJHNzaF9kaXIiCmlmIFtbIC1mICIkYXV0aF9maWxlIiBdXTsgdGhlbgogIGJhY2t1cD0kKG1rdGVtcCAiJGF1dGhfZmlsZS5wYXNlby1iYWNrdXAuWFhYWFhYWFgiKQogIGNwIC1wIC0tICIkYXV0aF9maWxlIiAiJGJhY2t1cCIgfHwgZmFpbCAnYmFja3VwIGZhaWxlZDsgbm8gYXBwZW5kJwogIHByaW50ZiAnQkFDS1VQX09LOiAlc1xuJyAiJGJhY2t1cCIKZmkKcHJpbnRmICdcbnNzaC1lZDI1NTE5ICVzIHBhc2VvLXNzaFxuJyAiJGtleV9ibG9iIiA+PiAiJGF1dGhfZmlsZSIKcHJpbnRmICclc1xuJyAnS0VZX0FEREVEJwpzc2gta2V5Z2VuIC1FIHNoYTI1NiAtbGYgIiRhdXRoX2ZpbGUiCg=='
$script:PaseoSource = if ($MyInvocation.MyCommand -is [Management.Automation.ExternalScriptInfo]) { [IO.File]::ReadAllText($MyInvocation.MyCommand.Path) } else { $MyInvocation.MyCommand.Definition }

function Write-Utf8File([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}
function Get-NativePath([string]$Name) {
    $commands = @(Get-Command $Name -CommandType Application -ErrorAction Stop)
    if (!$commands.Count -or !$commands[0].Source) { throw "找不到程序：$Name" }
    [string]$commands[0].Source
}
function Assert-PlainPath([string]$Path) {
    $part = [IO.Path]::GetFullPath($Path)
    while ($part) {
        if (Test-Path -LiteralPath $part) {
            if ((Get-Item -LiteralPath $part -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "拒绝符号链接或重解析路径：$part" }
        }
        $parent = [IO.Path]::GetDirectoryName($part)
        if ($parent -eq $part) { break }
        $part = $parent
    }
}
function Assert-Connection([string]$Address, [int]$SshPort, [string]$Login) {
    $parsed = $null
    if ($Address -notmatch '^\d{1,3}(\.\d{1,3}){3}$' -or ![Net.IPAddress]::TryParse($Address,[ref]$parsed) -or $parsed.ToString() -ne $Address) { throw '请输入标准 IPv4 地址，不要填写命令、网址或用户名。' }
    if ($SshPort -lt 1 -or $SshPort -gt 65535) { throw 'SSH 端口必须为 1–65535。' }
    if ($Login -notmatch '^[a-z_][a-z0-9_-]{0,31}$') { throw 'Linux 用户名不合法。' }
}
function Get-Ed25519Info([string]$Line) {
    $parts = $Line.Trim() -split '\s+'
    if ($parts.Count -lt 2 -or $parts[0] -cne 'ssh-ed25519' -or $Line -match '[\r\n]') { throw '只接受单行 ED25519 公钥；不能使用私钥或多行文件。' }
    if ($parts[1] -notmatch '^[A-Za-z0-9+/]+={0,2}$') { throw '公钥编码不正确。' }
    $raw = [Convert]::FromBase64String($parts[1])
    $prefix = [byte[]](0,0,0,11,115,115,104,45,101,100,50,53,53,49,57,0,0,0,32)
    if ($raw.Length -ne 51) { throw 'ED25519 公钥长度不正确。' }
    for ($i=0; $i -lt $prefix.Length; $i++) { if ($raw[$i] -ne $prefix[$i]) { throw '公钥类型与二进制内容不一致。' } }
    if ([Convert]::ToBase64String($raw) -cne $parts[1]) { throw '非规范公钥编码。' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $fingerprint = 'SHA256:' + [Convert]::ToBase64String($sha.ComputeHash($raw)).TrimEnd('=') } finally { $sha.Dispose() }
    [pscustomobject]@{ Blob=$parts[1]; Fingerprint=$fingerprint; Line=('ssh-ed25519 '+$parts[1]+' paseo-ssh') }
}
function ConvertTo-NativeArgument([string]$Value) {
    # Windows CRT quoting, including embedded quotes and trailing backslashes.
    '"' + [regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1') + '"'
}
function Invoke-Native([string]$File, [string[]]$Arguments, [switch]$Interactive, [int]$TimeoutSeconds=30) {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $File
    $info.UseShellExecute = $false
    if ($env:OS -eq 'Windows_NT') { $info.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ') }
    else { foreach ($arg in $Arguments) { $info.ArgumentList.Add($arg) } }
    $info.RedirectStandardOutput = !$Interactive
    $info.RedirectStandardError = !$Interactive
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        if (!$process.Start()) { throw "无法启动 $File" }
        if ($Interactive) { $process.WaitForExit(); return [pscustomobject]@{ Code=$process.ExitCode; Out=''; Err='' } }
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit($TimeoutSeconds*1000)) { $process.Kill(); $process.WaitForExit(); throw "命令超时：$File" }
        [pscustomobject]@{ Code=$process.ExitCode; Out=$outTask.Result; Err=$errTask.Result }
    } finally { $process.Dispose() }
}
function Get-SshArguments($Options, [string]$Known, [string]$EmptyConfig, [bool]$Interactive) {
    @('-o','StrictHostKeyChecking=yes','-o',('UserKnownHostsFile="'+$Known.Replace('\','/')+'"'),
      '-o','HostKeyAlgorithms=ssh-ed25519','-o','UpdateHostKeys=no','-o','IdentitiesOnly=yes',
      '-o',('BatchMode='+$(if($Interactive){'no'}else{'yes'})),'-o','ConnectTimeout=10',
      '-o','ConnectionAttempts=1','-o','NumberOfPasswordPrompts=2','-i',$Options.IdentityFile,
      '-p',[string]$Options.Port,($Options.UserName+'@'+$Options.Server))
}
function Get-TargetToken([string]$Address,[int]$SshPort) {
    if ($SshPort -eq 22) { return $Address }; return ('['+$Address+']:'+$SshPort)
}
function Get-HostMatches([string]$Known,[string]$Token,[string]$Keygen) {
    if (!(Test-Path -LiteralPath $Known)) { return '' }
    $result = Invoke-Native $Keygen @('-F',$Token,'-f',$Known)
    if ($result.Code -notin @(0,1)) { throw '无法读取已有主机信任记录。' }
    if ($result.Out -match '(?m)^@') { throw '目标存在撤销/CA 等特殊信任记录，停止自动修改，请管理员核查。' }
    return $result.Out
}
function Save-HostRecord([string]$Known,[string]$Token,[string]$HostLine,[string]$Keygen,[string]$Work) {
    Assert-PlainPath $Known
    $initial = if (Test-Path -LiteralPath $Known) { [IO.File]::ReadAllBytes($Known) } else { $null }
    $copy = Join-Path $Work 'known-hosts-copy'
    if ($null -ne $initial) {
        [IO.File]::WriteAllBytes($copy,$initial)
        $null = Get-HostMatches $copy $Token $Keygen
        $result = Invoke-Native $Keygen @('-R',$Token,'-f',$copy)
        if ($result.Code -ne 0) { throw '移除工作副本中的旧记录失败，原文件未修改。' }
    } else { Write-Utf8File $copy '' }
    [IO.File]::AppendAllText($copy,"`n$Token $HostLine`n",(New-Object Text.UTF8Encoding($false)))
    if ($null -ne $initial) {
        $current = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Known))
        if ($current -cne [Convert]::ToBase64String($initial)) { throw 'known_hosts 被其他程序修改，未覆盖，请重试。' }
        $backup = $Known+'.paseo-backup.'+[Guid]::NewGuid().ToString('N')
        [IO.File]::Replace($copy,$Known,$backup)
        Write-Host "Windows 主机记录备份：$backup"
    } else { [IO.File]::Move($copy,$Known) }
}
function Write-Event([string]$State,[string]$Message) {
    [IO.File]::AppendAllText((Join-Path $State 'last-run.log'),((Get-Date -Format s)+' '+$Message+"`n"),(New-Object Text.UTF8Encoding($false)))
}
function Show-GuideHelp([string]$State) {
    @"
Paseo SSH $script:PaseoVersion — 连接设置与重装指引
配置：$State\settings.json
日志：$State\last-run.log（无密码、无私钥、无终端录屏）
Windows 备份：用户 .ssh\known_hosts.paseo-backup.*
Linux 备份：目标用户 .ssh/authorized_keys.paseo-backup.*

找指纹：在服务器商控制台或已核实的 Linux 会话运行：
ssh-keygen -E sha256 -lf /etc/ssh/ssh_host_ed25519_key.pub
服务器重装：重新运行 Linux 菜单 14，使用含新指纹的 Windows 命令。
也可以启动本工具，按提示粘贴可信控制台的完整 SHA256 指纹。
扫描到的指纹不是信任依据；不匹配时不会输入密码或安装公钥。

提示符 PS C:\...> 是 Windows；root@...:~# 是 Linux。
密码只在 ssh 自身的提示中输入，输入时可能不显示字符。
私钥口令由 ssh-keygen / ssh-add 提示，不保存到本工具。
一条安装入口不等于绕过登录：没有密码或已有授权密钥时无法代替服务器授权。
不修改 sshd 配置、防火墙、root 登录策略；特殊 Match / AuthorizedKeysFile 需管理员处理。
默认使用 root 和 22；建议有条件时改用专用普通用户。
"@ | Write-Host
}
function Install-LocalEntry([string]$State,[string]$DesktopDirectory='') {
    if ($env:OS -ne 'Windows_NT') { return }
    $entry = Join-Path $State 'paseo-ssh.ps1'
    [IO.File]::WriteAllText($entry,$script:PaseoSource,(New-Object Text.UTF8Encoding($true)))
    $desktop = if($DesktopDirectory){$DesktopDirectory}else{[Environment]::GetFolderPath('Desktop')}
    if (!$desktop -or !(Test-Path -LiteralPath $desktop)) { return }
    try {
      $shell = New-Object -ComObject WScript.Shell
      foreach ($item in @(@('Paseo SSH Connect.lnk',''),@('Paseo SSH Settings.lnk',' -Settings'))) {
        $link = Join-Path $desktop $item[0]
        if (Test-Path -LiteralPath $link) { continue }
        $shortcut = $shell.CreateShortcut($link)
        $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $shortcut.Arguments = '-NoProfile -NoExit -ExecutionPolicy Bypass -File "'+$entry+'"'+$item[1]
        $shortcut.WorkingDirectory = $State
        $shortcut.Description = 'Paseo SSH connection, settings and troubleshooting'
        $shortcut.Save()
    }
      Write-Host '桌面入口：Paseo SSH Connect（连接）/ Paseo SSH Settings（设置与帮助）；已有同名入口不覆盖。'
    } catch {
      Write-Warning "无法创建桌面快捷方式，但本地入口已保存：$entry；可用 -Settings 打开设置。"
    }
}
function Read-Settings([string]$State) {
    $file = Join-Path $State 'settings.json'
    if (!(Test-Path -LiteralPath $file)) { return $null }
    $value = [IO.File]::ReadAllText($file) | ConvertFrom-Json
    foreach ($name in @('Server','UserName','Port','IdentityFile','Fingerprint')) {
        if (!$value.PSObject.Properties[$name]) { throw '配置字段不完整；保留文件，通过 -Settings 核查。' }
    }
    $value
}
function Save-Settings([string]$State,$Value) {
    $file = Join-Path $State 'settings.json'
    Assert-PlainPath $file
    $temp = Join-Path $State ('settings.'+[Guid]::NewGuid().ToString('N')+'.tmp')
    Write-Utf8File $temp ($Value | ConvertTo-Json)
    if (Test-Path -LiteralPath $file) { [IO.File]::Replace($temp,$file,($file+'.previous')) }
    else { [IO.File]::Move($temp,$file) }
}
function Invoke-PaseoSetup($Options,[string]$KnownHostsFile,[switch]$NoLocalEntry) {
    Assert-Connection $Options.Server $Options.Port $Options.UserName
    Assert-PlainPath $Options.IdentityFile
    Assert-PlainPath $KnownHostsFile
    Assert-PlainPath $Options.StateDirectory
    $state = $Options.StateDirectory
    $null = [IO.Directory]::CreateDirectory($state)
    $lock = $null; $work = $null
    try {
        $lock = [IO.File]::Open((Join-Path $state 'run.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $work = Join-Path $state ('work-'+[Guid]::NewGuid().ToString('N'))
        $null = [IO.Directory]::CreateDirectory($work)
        $tools = @{}
        foreach ($name in @('ssh','ssh-keyscan','ssh-keygen')) {
            $tools[$name] = Get-NativePath $name
        }
        Write-Event $state 'START'
        Write-Host "正在核对服务器：$($Options.Server):$($Options.Port) 用户 $($Options.UserName)"
        $token = Get-TargetToken $Options.Server $Options.Port
        $null = Get-HostMatches $KnownHostsFile $token $tools['ssh-keygen']
        $scan = Invoke-Native $tools['ssh-keyscan'] @('-T','5','-p',[string]$Options.Port,'-t','ed25519',$Options.Server) -TimeoutSeconds 15
        if ($scan.Code -ne 0) { throw '无法读取服务器主机公钥，请检查 IP、端口、网络和 ED25519 支持。' }
        $lines = @($scan.Out -split '\r?\n' | Where-Object { $_ -match '^\S+ ssh-ed25519 [A-Za-z0-9+/]+=*\s*$' } | Select-Object -Unique)
        if ($lines.Count -ne 1) { throw '扫描结果不唯一或格式异常，停止连接。' }
        $hostInfo = Get-Ed25519Info (($lines[0] -split '\s+',2)[1])
        $expected = $Options.ExpectedFingerprint
        if (!$expected) {
            Show-GuideHelp $state
            Write-Host ('网络提供的指纹（仅供比较，不是可信来源）：'+$hostInfo.Fingerprint)
            $expected = (Read-Host '请粘贴可信服务器控制台取得的 SHA256 指纹；不要输入 yes').Trim()
        }
        if ($expected -cne $hostInfo.Fingerprint) { throw '主机指纹不匹配。未登录、未发送公钥、未更新主机记录。重装后请从可信控制台重新取得指纹。' }
        Write-Event $state 'HOST_VERIFIED'
        Write-Host '主机指纹匹配。'
        if (!$NoLocalEntry) { Install-LocalEntry $state }
        $pin = Join-Path $work 'verified-host'
        $empty = Join-Path $work 'empty-config'
        Write-Utf8File $pin ($token+' '+$hostInfo.Line+"`n")
        Write-Utf8File $empty ''
        $pubPath = $Options.IdentityFile+'.pub'
        Assert-PlainPath $pubPath
        $privateExists = Test-Path -LiteralPath $Options.IdentityFile
        $publicExists = Test-Path -LiteralPath $pubPath
        if (!$privateExists -and !$publicExists) {
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Options.IdentityFile))
            Write-Host '没有默认密钥，将生成 ED25519 密钥。请在 ssh-keygen 提示时设置自己的口令。'
            $generated = Invoke-Native $tools['ssh-keygen'] @('-t','ed25519','-f',$Options.IdentityFile,'-C','paseo-ssh') -Interactive
            if ($generated.Code -ne 0) { throw '密钥生成未完成。' }
        } elseif (!$privateExists -or !$publicExists) { throw '私钥和 .pub 文件不完整，未覆盖或重新生成；请在设置中选择完整的现有密钥。' }
        if ((Get-Item -LiteralPath $pubPath).Length -gt 16384) { throw '公钥文件过大。' }
        $key = Get-Ed25519Info ([IO.File]::ReadAllText($pubPath).TrimEnd([char[]]"`r`n"))
        Write-Host ('用户登录公钥：'+$key.Fingerprint)
        $batchArgs = @(Get-SshArguments $Options $pin $empty $false)
        $test = Invoke-Native $tools['ssh'] ($batchArgs+@('echo PASEO_SSH_OK'))
        if ($test.Code -ne 0 -or $test.Out -notmatch '(?m)^PASEO_SSH_OK\r?$') {
            if ($env:OS -eq 'Windows_NT') {
                $agent = Get-Service ssh-agent -ErrorAction SilentlyContinue
                $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                if ($agent -and $agent.Status -ne 'Running' -and $admin) { Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent; $agent = Get-Service ssh-agent }
                if ($agent -and $agent.Status -eq 'Running') {
                    Write-Host '将现有密钥加载到本机 agent；若有私钥口令，请在 ssh-add 提示中输入。'
                    $addTool = Get-NativePath 'ssh-add'
                    $added = Invoke-Native $addTool @($Options.IdentityFile) -Interactive
                    if ($added.Code -ne 0) { throw 'ssh-add 未成功，未追加服务器授权。' }
                    $test = Invoke-Native $tools['ssh'] ($batchArgs+@('echo PASEO_SSH_OK'))
                } elseif ($agent) { Write-Host 'ssh-agent 未运行。加密私钥需要 agent；可在管理员窗口运行本工具自动启动它。' }
            }
        }
        if ($test.Code -ne 0 -or $test.Out -notmatch '(?m)^PASEO_SSH_OK\r?$') {
            Write-Host '将通过已验证的 SSH 连接安装当前公钥；SSH 可能要求服务器密码。密码不由本工具保存。'
            $remote = 'printf %s '+$script:RemoteBase64+' | base64 -d | bash -s -- '+$key.Blob
            $interactiveArgs = @(Get-SshArguments $Options $pin $empty $true)
            $install = Invoke-Native $tools['ssh'] ($interactiveArgs+@($remote)) -Interactive
            if ($install.Code -ne 0) { throw '服务器公钥安装失败或登录未完成；查看上方 STOP/认证错误。没有宣布连接成功。' }
            Write-Event $state 'AUTHORIZATION_COMMAND_COMPLETED'
        }
        $final = Invoke-Native $tools['ssh'] ($batchArgs+@('echo PASEO_SSH_OK'))
        if ($final.Code -ne 0 -or $final.Out -notmatch '(?m)^PASEO_SSH_OK\r?$') {
            Write-Host $final.Err
            throw '最终密钥测试失败。检查 ssh-agent、有效 sshd/Match 配置或自定义授权路径；不自动放宽认证。'
        }
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($KnownHostsFile))
        $existing = Get-HostMatches $KnownHostsFile $token $tools['ssh-keygen']
        if ($existing -notmatch [regex]::Escape('ssh-ed25519 '+$hostInfo.Blob)) { Save-HostRecord $KnownHostsFile $token $hostInfo.Line $tools['ssh-keygen'] $work }
        Save-Settings $state ([pscustomobject]@{ Server=$Options.Server; UserName=$Options.UserName; Port=$Options.Port; IdentityFile=$Options.IdentityFile; Fingerprint=$expected })
        Write-Event $state 'SSH_OK'
        Write-Host 'SSH_OK：密钥登录已通过，已保存连接设置。可以返回应用重连。' -ForegroundColor Green
        Write-Host "设置和排障入口：$state"
    } catch { Write-Event $state ('ERROR: '+$_.Exception.Message); throw }
    finally {
        if ($lock) { $lock.Dispose() }
        if ($work -and [IO.Directory]::Exists($work) -and [IO.Path]::GetDirectoryName($work) -eq $state -and [IO.Path]::GetFileName($work) -match '^work-[a-f0-9]{32}$') { [IO.Directory]::Delete($work,$true) }
    }
}

if (!$Library) {
    $ErrorActionPreference = 'Stop'
    try {
        if ($env:OS -ne 'Windows_NT') { throw '请在 Windows PowerShell 运行此脚本，不要在 Linux / FinalShell 终端执行。' }
        if (!$StateDirectory) { $StateDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PaseoSSH' }
        $StateDirectory = [IO.Path]::GetFullPath($StateDirectory)
        Assert-PlainPath $StateDirectory
        $null = [IO.Directory]::CreateDirectory($StateDirectory)
        if (!$Help) { Install-LocalEntry $StateDirectory }
        $saved = Read-Settings $StateDirectory
        if ($Help) { Show-GuideHelp $StateDirectory; return }
        if (!$UserName) { $UserName = if($saved){[string]$saved.UserName}else{'root'} }
        if (!$Port) { $Port = if($saved){[int]$saved.Port}else{22} }
        if (!$IdentityFile) { $IdentityFile = if($saved){[string]$saved.IdentityFile}else{Join-Path $env:USERPROFILE '.ssh\id_ed25519'} }
        if ($Settings) {
            Show-GuideHelp $StateDirectory
            $answer = Read-Host "Linux 用户 [$UserName]（回车保留）"; if($answer){$UserName=$answer}
            $answer = Read-Host "SSH 端口 [$Port]"; if($answer){$Port=[int]$answer}
            $answer = Read-Host "Windows 私钥路径 [$IdentityFile]"; if($answer){$IdentityFile=$answer}
            if (!$Server -and $saved) { $Server=[string]$saved.Server }
        }
        if (!$Server) {
            $last = if($saved){[string]$saved.Server}else{''}
            $Server = (Read-Host "服务器 IP [$last]").Trim(); if(!$Server){$Server=$last}
        }
        Assert-Connection $Server $Port $UserName
        if (!$ExpectedFingerprint -and $saved -and $saved.Server -eq $Server -and $saved.Port -eq $Port) { $ExpectedFingerprint=[string]$saved.Fingerprint }
        $IdentityFile=[IO.Path]::GetFullPath($IdentityFile)
        if ($Settings) {
            $answer = Read-Host "可信控制台的新主机 SHA256 指纹（仅重装/换机需要；回车保留）"
            if($answer) {
                if($answer -cnotmatch '^SHA256:[A-Za-z0-9+/]{43}$') { throw '指纹格式错误；请输入完整 SHA256 指纹，不是 yes。' }
                $ExpectedFingerprint=$answer
            }
            Save-Settings $StateDirectory ([pscustomobject]@{Server=$Server;UserName=$UserName;Port=$Port;IdentityFile=$IdentityFile;Fingerprint=$ExpectedFingerprint})
            Write-Host '设置已保存。连接请打开桌面「Paseo SSH Connect」。'; return
        }
        $options=[pscustomobject]@{Server=$Server;Port=$Port;UserName=$UserName;IdentityFile=$IdentityFile;ExpectedFingerprint=$ExpectedFingerprint;StateDirectory=$StateDirectory}
        Invoke-PaseoSetup $options (Join-Path $env:USERPROFILE '.ssh\known_hosts')
    } catch { Write-Host ('[失败] '+$_.Exception.Message) -ForegroundColor Red; throw }
}
