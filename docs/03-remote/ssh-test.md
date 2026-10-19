# 安装公钥与连接测试

[返回首页](../../README.md) · [本分类目录](README.md)

将公钥加入 Linux，并验证无交互 SSH。

执行位置：**Windows + Linux** · 分类：远程连接

先将 YOUR_SERVER_IP 替换为自己的服务器地址，并根据实际情况替换 root。公钥已正确安装且测试通过时跳过追加步骤。所有 /root 路径也必须与 SSH 用户一致。

## 1. 从 Windows 安装公钥

**Windows PowerShell · 向 Linux 追加公钥**

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" | ssh root@YOUR_SERVER_IP "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

首次连接会要求确认主机指纹；核对后才输入 yes。出现服务器 password 提示时再输入服务器密码。整条管道命令作为一个步骤复制。

## 2. Linux 上确认权限

**Linux · 设置密钥目录权限**

```bash
chmod 700 /root/.ssh
```

**Linux · 设置公钥文件权限**

```bash
chmod 600 /root/.ssh/authorized_keys
```

**Linux · 确认目录和文件所有者**

```bash
chown root:root /root/.ssh /root/.ssh/authorized_keys
```

## 3. Windows 测试无交互登录

**Windows PowerShell · Paseo 连接前的关键测试**

```powershell
ssh -o BatchMode=yes root@YOUR_SERVER_IP "echo ok"
```

**预期输出**

```text
ok
```

BatchMode 禁止交互式密码提示，因此成功输出 ok 才能证明这条连接不依赖临时手输密码。若 Permission denied，继续检查 Linux 公钥认证设置。

> **不要只凭公钥注释判断匹配**
>
> authorized_keys 中出现 your-key-comment 只说明包含该注释，不足以证明它与当前私钥是一对。排障时应比较公钥指纹或完整公钥，而无需暴露私钥。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：启动 Windows SSH Agent](ssh-agent.md) · [下一篇：开启 Linux 公钥认证](sshd-pubkey.md)
