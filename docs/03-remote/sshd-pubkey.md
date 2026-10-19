# 开启 Linux 公钥认证

[返回首页](../../README.md) · [本分类目录](README.md)

排查有效配置为 PubkeyAuthentication no 的情况。

执行位置：**Linux** · 分类：远程连接

仅在检查确认 pubkeyauthentication no 时按此流程排查，不假定配置位于某个固定行号。修改期间保持现有 SSH 窗口打开，保留云控制台等备用访问方式。下方修改、语法检查和服务重载需要管理员权限；普通用户请按系统要求使用 sudo。

> **先排除 Match 块**
>
> 如果配置文件含 Match 块或多处 PubkeyAuthentication 设置，下面的整文件 sed 替换不适用。应编辑已经定位到的全局配置，并按实际连接条件检查有效值，不要批量改动其他用户的规则。

## 1. 检查有效配置

**Linux · 检查 SSH 认证设置**

```bash
sshd -T | grep -E 'pubkeyauthentication|permitrootlogin|authorizedkeysfile|authenticationmethods'
```

若提示 sshd: command not found，可将这条命令中的 sshd 改成 /usr/sbin/sshd。公钥认证应为 yes；root 是否允许登录还受 PermitRootLogin 和其他认证规则影响。

## 2. 定位配置文件

**Linux · 找到 PubkeyAuthentication 配置**

```bash
grep -RniE '^[[:space:]]*PubkeyAuthentication[[:space:]]' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null
```

## 3. 备份，再编辑已确认的文件

**Linux · 创建带时间的备份**

```bash
cp -a /etc/ssh/sshd_config "/etc/ssh/sshd_config.paseo-backup-$(date +%Y%m%d-%H%M%S)"
```

下面修改适用于已经确认在主配置里存在独立一行 PubkeyAuthentication no 的情况。若实际来源是其他文件或 Match 块，先按该文件和规则处理。

**Linux · 将已定位的 no 改为 yes**

```bash
sed -i -E 's/^[[:space:]]*PubkeyAuthentication[[:space:]]+no[[:space:]]*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
```

**Linux · 检查修改结果**

```bash
grep -nE '^[[:space:]]*PubkeyAuthentication[[:space:]]' /etc/ssh/sshd_config
```

## 4. 检查语法后重新加载

**Linux · 验证配置语法**

```bash
sshd -t
```

没有报错才继续。若出现错误，先修复或恢复备份，不要执行后面的重新加载。

**Linux · 重新加载 SSH 服务**

```bash
systemctl reload ssh
```

只有系统提示 ssh.service 不存在时，才改用下面的服务名；不要把两条当作都必须执行。

**Linux · 替代服务名**

```bash
systemctl reload sshd
```

**Linux · 再次确认有效值**

```bash
sshd -T | grep -E 'pubkeyauthentication|permitrootlogin|authorizedkeysfile'
```

## 5. 回到 Windows 验收

**Windows PowerShell · 再次测试**

```powershell
ssh -o BatchMode=yes root@YOUR_SERVER_IP "echo ok"
```

必须以这次实际连接结果为准。sshd -T 的全局输出不一定覆盖特定来源地址或用户的 Match 条件；若仍失败，还需要结合详细 SSH 日志检查。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：安装公钥与连接测试](ssh-test.md) · [下一篇：Paseo Desktop 连接](desktop-ssh.md)
