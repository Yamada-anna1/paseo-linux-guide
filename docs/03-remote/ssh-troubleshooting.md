# SSH 排查与配置指引

[返回首页](../../README.md) · [本分类目录](README.md)

集中保存 Windows 与 Linux 的分段命令：主机指纹、登录公钥、授权文件、无交互测试。

执行位置：**Windows PowerShell + Linux Bash · 每段均标明位置** · 分类：远程连接

## 先看这里：菜单 14 不会自动修改 SSH

在 Linux 安装菜单选 14：子选项 1 是当前用户的只读检查；2 是 Windows 主机指纹确认；3 是 Windows 密钥、ssh-agent 与公钥导出；4 是 Linux 公钥安全追加指引；5 是 Windows 无交互测试与应用重连指引。Windows 主机信任记录保存在 Windows 端，不能靠 Linux 安装菜单替你接受。手动改动前，保留当前 FinalShell / SSH 会话，并准备服务商控制台等备用入口。

| 出现什么 | 优先检查 | 不要做什么 |
| --- | --- | --- |
| Host key verification failed | 服务器主机指纹是否可信；Windows OpenSSH 是否已有正确记录 | 不要关闭 StrictHostKeyChecking，也不要盲目清除 known_hosts |
| Permission denied (publickey,password,keyboard-interactive) | 是否提供预期用户密钥、Linux 是否授权、权限与认证规则 | 不代表密码一定错，不必先重装工具或重新生成密钥 |
| authorized_keys is not a public key file | 文件是否为空、格式错误或没有可识别的公钥 | 不要据此清空文件；先备份并核对自己的公钥 |
| Windows 输出 SSH_OK，但应用仍失败 | 应用所用 Windows 用户、SSH 目标、身份文件及应用具体日志 | 不要把 SSH 成功等同于 Paseo daemon 或模型服务已正常 |

> **两类指纹、两套路径，不要混淆**
>
> 服务器主机公钥指纹用于确认“连接的服务器是谁”，来自 /etc/ssh/ssh_host_*_key.pub；用户登录公钥指纹用于确认“哪把登录密钥被授权”，来自 Windows 的 id_ed25519.pub 与 Linux 的 authorized_keys。Windows 的 $env:USERPROFILE 与 Linux 的 $HOME 不是同一个目录。身份文件字段若在 Windows 客户端上配置，应填 Windows 私钥路径；远程项目字段才填 Linux 项目路径。

## A. Windows：确认当前用户、SSH 和已有密钥（只读）

以下在运行目标应用的同一个 Windows 用户的普通 PowerShell 中逐段执行，不是在 FinalShell 的 Linux 终端。不要为了检查而换用另一个管理员账号。YOUR_LINUX_USER / YOUR_SERVER_IP 均须换成实际目标；端口不是 22 时同步替换。

**Windows 普通 PowerShell · 查看当前账号（只读）**

```powershell
# 用途：确认与桌面应用属于同一个 Windows 用户。
whoami
```

**Windows 普通 PowerShell · 查看 SSH 程序路径（只读）**

```powershell
# 用途：检查实际调用哪套 OpenSSH；只列程序路径，不读取凭据。
Get-Command ssh, ssh-add, ssh-keygen | Select-Object Name, Source
```

**Windows 普通 PowerShell · 查看 agent 服务（只读）**

```powershell
# 预期：需要 agent 时 Status 为 Running。
Get-Service -Name ssh-agent
```

**Windows 普通 PowerShell · 查看已加载密钥指纹（只读）**

```powershell
# 用途：只列指纹，不输出私钥。The agent has no identities 表示尚未加载。
ssh-add -l
```

**Windows 普通 PowerShell · 私钥是否存在（只读）**

```powershell
# True：已有文件，保留它；不要 Get-Content 这个不带 .pub 的文件。
Test-Path "$env:USERPROFILE\.ssh\id_ed25519"
```

**Windows 普通 PowerShell · 公钥是否存在（只读）**

```powershell
# True：可以继续读取这一份 .pub 公钥；False：先核对实际密钥路径。
Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

已有密钥时不重新生成。若只缺 .pub，也不要因此覆盖私钥，应先确认原文件用途。仅当两个默认文件都不存在且确实需要新密钥时，才执行下方带存在性保护的可选命令；已有任意一个文件会停止生成。使用其他密钥文件名时，应同步替换后续路径。

**Windows 普通 PowerShell · 仅在没有密钥时生成（会创建文件）**

```powershell
# 只在默认私钥和公钥均不存在时生成，避免覆盖已有登录凭据。
if ((Test-Path "$env:USERPROFILE\.ssh\id_ed25519") -or (Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub")) {
    Write-Warning '已有私钥或公钥；未生成新密钥，请先核对现有文件。'
} else {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force | Out-Null
    ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519"
}
```

生成时可设置私钥口令，妥善保存并在 B 中用 ssh-agent 解锁；不要公开口令。若意外出现已存在文件的覆盖提示，取消并检查，不接受覆盖。

**Windows 普通 PowerShell · 查看登录公钥指纹（只读）**

```powershell
# 记下 SHA256 指纹，稍后与 Linux authorized_keys 的指纹比较。
ssh-keygen -lf "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

**Windows 普通 PowerShell · 显示完整公钥（只读，仅 .pub）**

```powershell
# 只复制输出的一整行公钥。绝不能去掉文件名末尾的 .pub。
Get-Content -LiteralPath "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

**Windows 普通 PowerShell · 可选：把公钥复制到剪贴板**

```powershell
# 只复制 .pub 公钥；此步骤会替换当前剪贴板，不读取私钥。
Get-Content -Raw -LiteralPath "$env:USERPROFILE\.ssh\id_ed25519.pub" | Set-Clipboard
```

## B. Windows：仅在需要时启动 agent、加载已有密钥

本节不是只读：前两条会修改 Windows 服务状态。仅当服务未运行或被禁用时，右键以管理员身份运行 PowerShell；不要反复执行已完成的设置。服务本来已 Running 时，跳过服务设置，直接回普通用户窗口检查或加载密钥。

**Windows 管理员 PowerShell · 按需设置服务自动启动**

```powershell
# 仅用于 ssh-agent 被禁用或需要开机启动；会修改系统服务配置。
Set-Service -Name ssh-agent -StartupType Automatic
```

**Windows 管理员 PowerShell · 按需启动服务**

```powershell
# 仅用于 ssh-agent 尚未运行；成功通常不输出文字。
Start-Service -Name ssh-agent
```

**Windows 普通 PowerShell · 加载自己的已有私钥**

```powershell
# 回到运行应用的同一个 Windows 用户。出现口令提示时在本机输入。
# 这里是私钥文件路径，不是 .pub；命令不会显示私钥内容。
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
```

出现 Identity added 后，再运行 A 中的 ssh-add -l 核对指纹。agent 已加载密钥不代表服务器必然接受；Error connecting to agent 需先核对服务状态和 ssh / ssh-add 是否来自一致环境。不要公开密钥口令。

## C. 先核对服务器主机指纹，再让 Windows 保存信任

先从可信的服务商控制台或已验证服务器身份的 Linux 会话取得主机公钥指纹。FinalShell 已连接只证明其自身会话可用；它与 Windows OpenSSH 的信任记录和认证配置不应假定自动共享。

**Linux 可信控制台 / 会话 · 读取服务器 ED25519 主机公钥指纹**

```bash
# 用途：核对服务器身份；只读取 .pub 公钥，不读取主机私钥。
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

**Windows 普通 PowerShell · 手动验证一次目标服务器**

```powershell
# 先替换用户和地址；22 也需与实际 SSH 端口一致。
ssh -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
```

若出现 Are you sure you want to continue connecting，先将显示的 ED25519 / SHA256 指纹与可信 Linux 会话的同类指纹逐字比较。一致才输入 yes。若协商到其他算法，应从可信入口读取该算法的 .pub 指纹再比较；不要拿用户登录公钥指纹来比较。若指纹不一致或提示 REMOTE HOST IDENTIFICATION HAS CHANGED，停止并向服务器管理者确认，不关闭检查、不盲目删除记录。

Permanently added 表示本次主机信任记录已保存，不表示登录密钥已获授权。随后如要求服务器密码，只在本机终端输入；Connection reset 不足以单独判定是密码错误。下一步以 BatchMode 的结果和服务器端诊断为准。

## D. Linux：公钥认证、授权文件与权限（只读）

以下在目标 Linux 用户的现有可信会话中执行。$HOME 必须属于将要 SSH 登录的用户；不要在 root 会话里误把公钥加给另一个用户。若授权路径不是默认 .ssh/authorized_keys，应按有效配置核对真实路径，不直接照搬追加步骤。

**Linux · 核对当前用户与主目录（只读）**

```bash
# 必须与 Windows ssh 命令中的 YOUR_LINUX_USER 一致。
id -un
printf '%s\n' "$HOME"
```

**Linux 管理员 · 查看 SSH 认证配置（只读）**

```bash
# 需要管理员读取完整配置；普通用户请由管理员执行或按授权使用 sudo。
sshd -T | grep -E '^(pubkeyauthentication|permitrootlogin|authorizedkeysfile|authenticationmethods|strictmodes) '
```

sshd 不在 PATH 时可使用 /usr/sbin/sshd；普通用户经授权可使用 sudo /usr/sbin/sshd -T，再连接同样的 grep 过滤。PubkeyAuthentication yes 表示全局允许公钥认证，但 Match 条件、用户规则和额外认证方式仍可能改变本次连接的结果；必要时由管理员使用 sshd -T -C 按实际连接条件检查。不要为排障开启 root 密码登录或改成更宽松的认证规则。

**Linux 目标用户 · 查看已授权登录公钥指纹（只读）**

```bash
# 与 A 中 Windows .pub 的 SHA256 指纹比较，不要只比较行尾注释。
ssh-keygen -lf "$HOME/.ssh/authorized_keys"
```

**Linux 目标用户 · 查看目录 / 文件权限与所有者（只读）**

```bash
# 默认授权路径的检查；文件缺失时保留报错，不要先清空或覆盖。
stat -c '%a %U:%G %n' "$HOME" "$HOME/.ssh" "$HOME/.ssh/authorized_keys"
```

常见安全设置为 .ssh 700、authorized_keys 600，属于目标用户；主目录不得允许不受信任的其他用户写入。不要只因主目录不是 700 就断定失败，仍要看所有者、ACL 和有效规则。若文件报 is not a public key file，只能说明此工具没识别出有效公钥，可能为空、格式不正确或内容无法识别；不是要求删除它。

## E. Linux：保留原文件，验证后只追加自己的公钥

> **手动步骤；安装菜单不会执行写入**
>
> 只在已确认目标账号和有效授权路径后操作。公钥必须来自 A 中你自己的完整 .pub 文件；不要粘贴网页占位符、聊天中的他人公钥或任何私钥。先验证待添加公钥并由你核对指纹，再备份已有 authorized_keys，最后用追加而不是覆盖。原有可用密钥和受限授权行必须保留。

安全追加步骤也可在菜单 14 → 4 查看。先用 FinalShell 的文件上传功能，仅将 Windows 的 id_ed25519.pub 上传到目标 Linux 用户主目录，文件名改为 incoming-key.pub；不要上传 id_ed25519 私钥。目标目录以 D 中 $HOME 的实际输出为准，不是在文件管理器中输入字面量 $HOME。若 SSH 身份尚未验证成功，不要强求使用 scp 上传。

**Linux 目标用户 · 上传前先检查临时文件名（只读）**

```bash
# 只有显示“可上传”才向该路径上传 .pub。已有文件或符号链接时先人工核对，不覆盖。
if [ -e "$HOME/incoming-key.pub" ] || [ -L "$HOME/incoming-key.pub" ]; then
    printf '%s\n' '停止：incoming-key.pub 已存在，先核对，不要覆盖。'
else
    printf '%s\n' '可上传：只上传自己的 .pub 公钥到主目录，命名为 incoming-key.pub。'
fi
```

**Windows 普通 PowerShell · 可选替代上传（会写入 Linux 候选文件）**

```powershell
# 仅在已核对主机指纹、普通 SSH 能认证且远端目标文件不存在时使用。
# 与 FinalShell 上传二选一；仅传 .pub 公钥，不传私钥。
scp -P 22 "$env:USERPROFILE\.ssh\id_ed25519.pub" YOUR_LINUX_USER@YOUR_SERVER_IP:incoming-key.pub
```

上传后先执行下一段只读指纹命令，由你与 Windows 结果核对一致后，再执行后面的完整授权块。授权块会验证单行公钥、显示指纹、备份并追加，但不会暂停等待你核对指纹。文件内容只作为数据读取，绝不作为 shell 命令执行；空值、多行、占位符、私钥或不合法格式均会拒绝。不要使用 eval，也不要把自己的密钥直接嵌入公开脚本。

**Linux 目标用户 · 上传后先核对候选公钥指纹（只读）**

```bash
# 必须与 Windows A 中 id_ed25519.pub 的 SHA256 指纹一致，再继续追加。
ssh-keygen -lf "$HOME/incoming-key.pub"
```

指纹一致且确认要授权后，才整段复制下面括号块；不要拆开执行。它只修改当前用户默认 $HOME/.ssh/authorized_keys，不调整 SSH 认证配置。已有相同密钥（包括带 from= / command= 等限制的条目）会直接保留，不再添加无限制副本。

**Linux 目标用户 Bash · 手动授权：整块验证、备份、追加（会写入）**

```bash
(
  set -eu
  # Linux Bash：当前用户必须就是准备通过 SSH 登录的目标用户。
  ssh_target_home="$HOME"
  ssh_fail() { printf '[停止] %s\n' "$*" >&2; exit 1; }
  [[ "$ssh_target_home" == /* && -d "$ssh_target_home" && ! -L "$ssh_target_home" ]] || ssh_fail '主目录必须是实际的绝对目录。'
  ssh_target_home="$(cd -P -- "$ssh_target_home" && pwd -P)"
  [[ "$ssh_target_home" != / ]] || ssh_fail '拒绝把根目录作为用户主目录。'
  ssh_candidate="$ssh_target_home/incoming-key.pub"
  ssh_dir="$ssh_target_home/.ssh"
  ssh_authorized="$ssh_dir/authorized_keys"
  [[ -f "$ssh_candidate" && ! -L "$ssh_candidate" ]] || ssh_fail '候选 .pub 文件不存在或是符号链接。'
  [[ "$(wc -c < "$ssh_candidate")" -le 16384 ]] || ssh_fail '候选文件过大，不应是密钥集合或私钥。'
  # 接受 Windows CRLF；整个文件只允许一行、无控制字符的 OpenSSH 公钥。
  ssh_pubkey="$(LC_ALL=C awk '{ sub(/\r$/, ""); if (NR != 1 || $0 ~ /[[:cntrl:]]/) bad=1; line=$0 } END { if (NR != 1 || bad) exit 1; print line }' "$ssh_candidate")" || ssh_fail '只接受单行公钥文件。'
  IFS=' ' read -r ssh_type ssh_blob ssh_comment <<< "$ssh_pubkey"
  case "$ssh_type" in ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com) ;; *) ssh_fail '不是支持的 OpenSSH 公钥；不要上传私钥或占位文本。' ;; esac
  [[ "$ssh_blob" =~ ^[A-Za-z0-9+/]+={0,3}$ ]] || ssh_fail '公钥内容格式不正确。'
  ssh-keygen -lf "$ssh_candidate" || ssh_fail '公钥验证失败。'
  # 拒绝异常目标，保留已有文件与权限；不自动更改 sshd 配置。
  [[ -d "$ssh_target_home" && -O "$ssh_target_home" ]] || ssh_fail '主目录属主不匹配。'
  [[ ! -L "$ssh_dir" && ( ! -e "$ssh_dir" || -d "$ssh_dir" ) ]] || ssh_fail '.ssh 目标异常。'
  [[ ! -L "$ssh_authorized" && ( ! -e "$ssh_authorized" || -f "$ssh_authorized" ) ]] || ssh_fail 'authorized_keys 目标异常。'
  for ssh_path in "$ssh_target_home" "$ssh_dir" "$ssh_authorized"; do
    if [[ -e "$ssh_path" ]]; then
      [[ -O "$ssh_path" ]] || ssh_fail "属主不匹配：$ssh_path"
      ssh_mode="$(stat -c %a -- "$ssh_path")"
      (( (8#$ssh_mode & 0022) == 0 )) || ssh_fail "组或其他用户可写，请先核查权限：$ssh_path"
    fi
  done
  # 相同密钥即使有不同注释或 from=/command= 限制，也不再添加无限制副本。
  if [[ -f "$ssh_authorized" ]]; then
    if grep -Fq -- "$ssh_blob" "$ssh_authorized"; then
      printf '%s\n' '文件已包含该密钥本体；没有重复追加，请检查原条目的限制选项。'
      exit 0
    else
      ssh_search_status=$?
      [[ "$ssh_search_status" == 1 ]] || ssh_fail '无法检查原授权文件，未追加。'
    fi
  fi
  umask 077
  mkdir -p -m 700 -- "$ssh_dir"
  if [[ -f "$ssh_authorized" ]]; then
    ssh_backup="$(mktemp "$ssh_authorized.bak.XXXXXXXX")"
    cp -p -- "$ssh_authorized" "$ssh_backup" || ssh_fail '备份失败，未追加。'
    printf '原文件已备份：%s\n' "$ssh_backup"
  fi
  # 前置换行避免与旧文件最后一行粘连；>> 仅追加，不覆盖。
  printf '\n%s\n' "$ssh_pubkey" >> "$ssh_authorized"
  printf '%s\n' '已追加公钥；仅添加授权公钥无需重启 sshd。请保留当前会话并在 Windows 测试。'
  ssh-keygen -lf "$ssh_authorized"
)
```

**Linux 目标用户 · 追加后复核用户公钥指纹（只读）**

```bash
# 应出现与 Windows A 步骤一致的登录公钥 SHA256 指纹。
ssh-keygen -lf "$HOME/.ssh/authorized_keys"
```

修改 authorized_keys 通常不需要重启 SSH 服务。若仍然无法识别文件或没有对应指纹，停止并保留备份，先检查文件内容格式和实际授权路径，不清空文件、不重新生成客户端密钥。只有修改了 sshd 配置时，才按 [开启 Linux 公钥认证](sshd-pubkey.md) 的备份、语法检查与重载流程处理。

## F. Windows：无交互验收与应用重连

**Windows 普通 PowerShell · 最终验收（不询问服务器密码）**

```powershell
# BatchMode=yes 禁止交互式密码提示；成功应只出现 SSH_OK 等正常输出。
ssh -o BatchMode=yes -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
```

**Windows 普通 PowerShell · 按需明确指定现有私钥再测试**

```powershell
# 仅在默认身份选错时使用；-i 是 Windows 私钥路径，不是 Linux 路径或 .pub。
# 加密私钥应已通过 ssh-add 加载；不输出私钥内容。
ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$env:USERPROFILE\.ssh\id_ed25519" -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
```

| 结果 | 含义 / 下一步 |
| --- | --- |
| SSH_OK | 该 Windows 用户到该 Linux 用户的 SSH 无交互测试通过；回应用点击重新连接，核对同一主机、端口与账号 |
| Permission denied | 核对 A 的实际密钥指纹与 D 的授权列表，以及 Match / 账号规则；不要继续盲目重装 |
| Host key verification failed | 回 C 核对主机指纹与当前 Windows 用户的信任记录 |
| timeout / Connection refused / Connection reset | 保留具体报错；检查服务器可用性、网络、SSH 端口和服务端日志，不直接归因于密钥 |

如果应用需要填写“身份文件”，应使用已验证的 Windows 私钥文件路径，不能填 .pub 或 Linux 路径；字段留空本身不一定是错误，默认密钥或 ssh-agent 可能已提供身份。SSH_OK 只证明 SSH 这一层成功，不证明 Paseo daemon、GitHub CLI 或模型已正常；Paseo 后续错误再按对应服务排查。

## G. Windows：仍失败时保留最小调试证据（只读）

**Windows 普通 PowerShell · 详细 SSH 日志，不输出私钥内容**

```powershell
# 看 Offering public key、Server accepts key 和认证失败原因。
# 日志会包含地址、用户名与路径；发给别人前先脱敏。
ssh -vvv -o BatchMode=yes -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
```

> **只分享必要诊断结果**
>
> 可以分享脱敏报错和公钥指纹；不要发送密码、私钥文件内容、密钥口令、GitHub 令牌、完整环境变量、hosts.yml 或配对链接。不得为“方便”开启 root 密码登录、关闭主机检查或公开 daemon 端口。

参考：OpenSSH ssh / sshd / ssh-keygen / sshd_config 手册（https://man.openbsd.org/ssh.1 · https://man.openbsd.org/sshd.8 · https://man.openbsd.org/ssh-keygen.1 · https://man.openbsd.org/sshd_config.5）；Windows OpenSSH 密钥管理（https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement）。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：安装 Paseo 与启动 daemon](../02-installation/paseo-install.md) · [下一篇：生成 Windows SSH 密钥](ssh-key.md)
