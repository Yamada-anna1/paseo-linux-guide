# Paseo SSH Windows — PowerShell 一键连接助手

适用于 Windows PowerShell 5.1 和 PowerShell 7。它处理 Windows → Linux 的 SSH 密钥连接，不安装 Paseo，也不代表模型服务已经正常。公开代码没有个人服务器地址、密钥、指纹或密码。

## 推荐入口：Linux 菜单 14

在已信任的 Linux 会话或服务器商控制台中打开手册安装菜单，选 **14**，输入服务器公网 IPv4。它会读取当前用户、当前 SSH 端口和 ED25519 主机指纹，输出一条 Windows 命令。

把生成的整行复制到 **Windows PowerShell** 执行。正常路径无需继续选择 1–5 个排障步骤，也不用手动复制公钥或粘贴 Bash。服务器密码、私钥口令仍可能需要由你本人输入；这些不能由脚本猜测或绕过。

Linux 菜单入口：

```bash
curl -fsSL https://raw.githubusercontent.com/Yamada-anna1/paseo-linux-guide/main/install.sh | bash
```

## Windows 独立入口

在 **Windows PowerShell** 执行，不是在 FinalShell 的服务器终端：

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Yamada-anna1/paseo-ssh-windows/main/paseo-ssh.ps1')))
```

这是下载并运行远程脚本，运行前应信任并审阅本仓库。也可以下载 `paseo-ssh.ps1` 后在本地运行。首次没有可信指纹时会显示获取方法并要求输入完整 SHA256 指纹，**不会把网络扫描到的指纹自动当成可信指纹**。已有成功设置时可直接使用保存的指纹，重装后指纹变化会停止。

默认账号 `root`、端口 `22`、私钥为当前 Windows 用户的 `.ssh/id_ed25519`。这只是兼容当前使用方式；有普通专用 Linux 用户时建议在设置中改用该用户。已有密钥不会被覆盖；只缺私钥或只缺 `.pub` 时会停止。新密钥由 OpenSSH 提示设置口令，本工具不替你选择空口令。

## 防止以后找不到：桌面入口与设置

首次运行会保存本地入口，并创建两个桌面快捷方式（已有同名文件不覆盖）：

- **Paseo SSH Connect**：运行连接向导。
- **Paseo SSH Settings**：查看指纹命令、日志、备份，并修改账号、端口、私钥路径或重装后的可信指纹。

使用英文快捷方式名是为了兼容英文版 Windows；工具内部仍为中文。桌面被组织策略限制时，会保留本地脚本并提示路径，不因快捷方式失败中断后续连接检查。

找不到桌面图标时，在 Windows PowerShell 运行本地设置入口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\PaseoSSH\paseo-ssh.ps1" -Settings
```

`ExecutionPolicy Bypass` 仅作用于本次进程；不修改系统或用户的持久执行策略。如果组织策略禁止脚本，应请管理员处理，不能绕过组织限制。

| 内容 | 位置 / 说明 |
| --- | --- |
| 工具与设置 | `%LOCALAPPDATA%\PaseoSSH` |
| 连接设置 | `settings.json`，仅保存 IP、用户、端口、私钥路径、已核对主机指纹 |
| 前一次设置 | `settings.json.previous` |
| 阶段与错误日志 | `last-run.log`，不录制终端、不保存密码或私钥 |
| Windows 主机记录备份 | `%USERPROFILE%\.ssh\known_hosts.paseo-backup.*` |
| Linux 授权文件备份 | 目标用户的 `.ssh/authorized_keys.paseo-backup.*` |

多台服务器可以使用不同 `-StateDirectory` 分开保存；默认配置只记住最后一次成功的目标。不要公开上传整个本地配置、日志或备份。

## 自动执行的内容与安全边界

1. 严格校验 IPv4、端口和用户名，拒绝命令注入式输入。
2. 读取网络主机公钥，但必须与可信控制台取得的指纹完全匹配才能登录。
3. 只支持 ED25519 主机密钥及 ED25519 用户密钥；不支持时停止，不降低算法或主机验证要求。
4. 使用独立的已验证主机记录进行连接，避免旧记录阻止重装后的安全核对。
5. 先尝试已有密钥。必要时加载 agent；Windows 管理员窗口可启动现有 ssh-agent 服务。普通窗口没有权限时不会暗中提权。
6. 若服务器尚未授权，使用已有登录能力（通常是本人输入服务器密码）执行验证、备份和追加。仅传公钥，不传私钥。
7. 已有同一把公钥时跳过，保留 `from=` / `command=` 等原有限制；拒绝符号链接、不安全权限和无效公钥。
8. 最终必须通过 `BatchMode=yes` 的无交互测试，才更新正常 Windows 主机记录、保存成功设置并显示 `SSH_OK`。

主机记录更新先备份，只替换对应 IP/端口的匹配记录。撤销标记或 CA 等特殊记录不会自动移除。现有 SSH 配置仍会被读取；代理、跳板机、FIDO/RSA/自定义密钥不在自动诊断范围内。有额外认证策略时可能无法自动通过，工具不会删除这些配置。

本工具不放开 root 登录、不关闭主机检查、不修改 `sshd_config`、防火墙或云端安全组。公钥认证关闭、自定义 `AuthorizedKeysFile`、`Match`、服务以不同 `-f/-o` 启动等问题需要管理员核实。缺少 OpenSSH 时会报缺少命令，不会暗中安装系统组件。

## 这次实际遇到的问题

| 报错 / 现象 | 原因与新流程 |
| --- | --- |
| Linux 中 `Get-Content: command not found` | Windows 命令粘到了 Linux。新入口明确分平台，只需复制一个 Windows 启动命令。 |
| Windows 中 `/root/...` 不存在、`stat` 不识别 | Linux 命令粘到了 Windows。授权处理由工具通过 SSH 执行，不再要求来回复制。 |
| 重装后 `REMOTE HOST IDENTIFICATION HAS CHANGED` | 旧主机记录与新系统不同。必须取得可信新指纹，再备份并定向更新记录。 |
| 删除旧记录后仍 `Host key verification failed` | 没有完成首次 `yes` 确认。新流程在核对指纹后生成严格绑定的记录，无需手动接受未知主机。 |
| 密码能登录，但 BatchMode 失败 | 不能据此宣布密钥成功。工具补齐授权后再次做无交互测试。 |
| `authorized_keys is not a public key file` | 可能为空或格式错误。保留原内容，验证公钥后备份追加，不清空。 |
| FinalShell `syntax error near unexpected token for` | 多行脚本被单行输入框压平。工具传输固定脚本，不依赖粘贴多行 Bash。 |
| 备份命令顺序颠倒 | 变量没先赋值，备份落错目录。新流程内部管理唯一备份名和执行顺序。 |

## 测试

本地 / Windows CI（临时生成测试密钥，不读取或修改真实用户密钥）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/unit.ps1
```

```powershell
pwsh -NoProfile -File tests/unit.ps1
```

Linux 授权保护测试：

```bash
bash tests/authorize.sh
```

`tests/e2e.sh` 只允许在 GitHub 临时 runner 执行：创建临时测试账号、本地专用端口的真实 sshd、临时主机密钥与用户密钥，验证真实授权追加和无交互登录。不会连接个人服务器。测试通过不代表所有发行版、企业策略、网络和服务自定义配置均兼容。

生成单文件入口（Node.js，无第三方包）：

```bash
node scripts/build.cjs
```

入口带 UTF-8 BOM，保证 Windows PowerShell 5.1 正确读取中文；生成文件内嵌固定 Linux 授权脚本，不在运行时下载第二份远程脚本。

参考：OpenSSH `ssh`、`sshd`、`ssh-keygen`、`ssh-keyscan` 官方手册，以及 Microsoft Windows OpenSSH / PowerShell 字符编码文档。
