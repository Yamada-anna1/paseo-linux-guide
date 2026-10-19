# 启动 Windows SSH Agent

[返回首页](../../README.md) · [本分类目录](README.md)

解决拒绝访问、无法连接 agent，并加载现有私钥。

执行位置：**Windows PowerShell** · 分类：远程连接

## 1. 管理员窗口配置服务

开始菜单搜索 PowerShell，右键选择“以管理员身份运行”。管理员权限用于修改和启动 Windows 服务。

**管理员 PowerShell · 设置自动启动**

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
```

**管理员 PowerShell · 启动服务**

```powershell
Start-Service -Name ssh-agent
```

**管理员 PowerShell · 查看状态**

```powershell
Get-Service -Name ssh-agent
```

Status 为 Running 表示服务已运行。“拒绝访问 / CouldNotSetService”通常说明当前窗口没有相应管理员权限。

## 2. 普通用户窗口加载密钥

回到运行 Paseo 的同一个 Windows 用户的普通 PowerShell。若管理员窗口使用了另一套账户，尤其要避免在那个账户下添加密钥。

**Windows PowerShell · 加载私钥**

```powershell
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
```

**Windows PowerShell · 查看已加载密钥**

```powershell
ssh-add -l
```

Identity added 表示私钥已加入 agent。它只验证本机这一步；服务器是否接受公钥，还要执行下一篇的连接测试。

> **Error connecting to agent**
>
> 先确认服务处于 Running，再检查 ssh 和 ssh-add 是否来自一致的 OpenSSH 环境。无需因此重新生成密钥。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：生成 Windows SSH 密钥](ssh-key.md) · [下一篇：安装公钥与连接测试](ssh-test.md)
