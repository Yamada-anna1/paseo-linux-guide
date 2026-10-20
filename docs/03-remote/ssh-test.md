# 安装公钥与连接测试

[返回首页](../../README.md) · [本分类目录](README.md)

将公钥加入 Linux，并验证无交互 SSH。

执行位置：**Windows + Linux** · 分类：远程连接

先将 YOUR_LINUX_USER 与 YOUR_SERVER_IP 替换为目标用户和服务器地址，端口按实际配置。公钥已正确安装且测试通过时跳过追加。本页为简要顺序；Windows / Linux 全部分段命令与注释集中在 [SSH 排查与配置指引](ssh-troubleshooting.md)。

## 1. 核对主机指纹，再准备自己的公钥

**Windows 普通 PowerShell · 读取自己的公钥，不读取私钥**

```powershell
# 仅读取 .pub 文件；不要去掉 .pub，也不要直接管道覆盖远端授权文件。
Get-Content -LiteralPath "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

首次连接前按排障指南 C 核对服务器主机指纹；确认一致后才能接受 Windows 的信任提示。需要添加公钥时，使用该指南 E 的单独公钥文件上传、指纹确认、备份后追加步骤，不覆盖原 authorized_keys。不要把公钥内容当 shell 命令执行。

## 2. Linux 目标用户确认权限与指纹（只读）

**Linux 目标用户 · 检查目录与授权文件权限**

```bash
stat -c '%a %U:%G %n' "$HOME" "$HOME/.ssh" "$HOME/.ssh/authorized_keys"
```

**Linux 目标用户 · 查看已授权公钥指纹**

```bash
ssh-keygen -lf "$HOME/.ssh/authorized_keys"
```

.ssh 常用 700、authorized_keys 常用 600，且属于目标用户；不对不明路径执行递归 chown。文件不存在、格式无法识别或权限不符时，先保留错误并按排障指南 D / E 核对。

## 3. Windows 测试无交互登录

**Windows 普通 PowerShell · 应用连接前的关键测试**

```powershell
# 先替换用户、地址和实际端口；不会询问服务器密码。
ssh -o BatchMode=yes -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
```

**预期输出**

```text
SSH_OK
```

BatchMode 禁止交互式密码提示，因此成功输出 SSH_OK 才能证明这条连接不依赖临时手输密码。若 Permission denied，继续核对用户公钥指纹、实际身份文件与 Linux 认证规则；成功后回到应用重新连接同一目标。

> **不要只凭公钥注释判断匹配**
>
> authorized_keys 中出现 your-key-comment 只说明包含该注释，不足以证明它与当前私钥是一对。排障时应比较公钥指纹或完整公钥，而无需暴露私钥。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：启动 Windows SSH Agent](ssh-agent.md) · [下一篇：开启 Linux 公钥认证](sshd-pubkey.md)
