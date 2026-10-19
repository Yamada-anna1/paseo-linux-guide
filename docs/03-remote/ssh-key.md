# 生成 Windows SSH 密钥

[返回首页](../../README.md) · [本分类目录](README.md)

先检查已有密钥，避免覆盖原来的登录凭据。

执行位置：**Windows PowerShell** · 分类：远程连接

## 1. 检查本机 OpenSSH

**Windows PowerShell · 检查 SSH**

```powershell
ssh -V
```

## 2. 检查已有密钥

**Windows PowerShell · 查看是否已有私钥**

```powershell
Test-Path "$env:USERPROFILE\.ssh\id_ed25519"
```

**Windows PowerShell · 查看是否已有公钥**

```powershell
Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

如果两条都返回 True，通常可以直接使用已有密钥，跳到 SSH Agent。不要重复生成或覆盖正在使用的密钥。

## 3. 仅在没有密钥时生成

**Windows PowerShell · 生成 ED25519 密钥**

```powershell
ssh-keygen -t ed25519
```

- 保存路径提示可按 Enter 使用默认路径。
- 如果提示文件已存在，不要覆盖已有密钥；取消并先检查它的用途。
- 可以设置密钥口令，之后通过 ssh-agent 解锁，让 Paseo 无需交互输入口令。
- id_ed25519 是私钥，留在 Windows；id_ed25519.pub 是公钥，安装到 Linux。

> **服务器密码与密钥口令不同**
>
> 服务器密码用于首次手动 SSH 登录；密钥口令用于解锁本机私钥。两者不要混淆，也不要输入到主机指纹确认提示中。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：安装 Paseo 与启动 daemon](../02-installation/paseo-install.md) · [下一篇：启动 Windows SSH Agent](ssh-agent.md)
