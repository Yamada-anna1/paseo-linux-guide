# 命令目录与 PATH

[返回首页](../../README.md) · [本分类目录](README.md)

解决安装成功后仍提示 command not found。

执行位置：**Linux** · 分类：安装部署

PATH 决定终端去哪些目录查找命令。CC-Switch 默认安装到 $HOME/.local/bin；只有当前用户为 root 时才对应 /root/.local/bin。npm 全局程序可能位于其他目录，以 command -v 输出为准。

## 让当前终端立即生效

**Linux · 加入用户命令目录**

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Linux · 刷新 Bash 命令缓存**

```bash
hash -r
```

## 保存到 Bash 配置

下条命令先检查是否已有完全相同的设置，避免重复追加。此处以 Bash 为例；其他 shell 需要对应的配置文件。

**Linux · 保存 PATH**

```bash
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

**Linux · 重新加载 Bash 配置**

```bash
source ~/.bashrc
```

## 确认三个命令的实际路径

**Linux · 查找 Codex**

```bash
command -v codex
```

**Linux · 查找 CC-Switch**

```bash
command -v cc-switch
```

**Linux · 查找 Paseo**

```bash
command -v paseo
```

> **终端可用，daemon 仍找不到**
>
> 正在运行的进程不会自动继承你后来修改的终端 PATH。修改后按“daemon 启停与环境刷新”重新启动，并用 Paseo 的 provider diagnostic 检查实际使用的路径。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：Linux 基础依赖](linux-prerequisites.md) · [下一篇：安装 Codex CLI](codex-install.md)
