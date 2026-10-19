# daemon 启停与环境刷新

[返回首页](../../README.md) · [本分类目录](README.md)

区分普通重启和为新 PATH、配置环境启动新进程。

执行位置：**Linux** · 分类：维护与排障

> **菜单方式刷新环境**
>
> 安装 gh 或改变 PATH 后，旧 daemon 可能仍使用旧环境。可在同一 Linux 用户的安装菜单选 13，核对目标目录、等待任务结束，再确认停止后启动。它会打断连接；不自动执行，也不修改 systemd / 容器服务配置。

## 查看、启动、停止

**Linux · 查看状态**

```bash
paseo daemon status
```

**Linux · 未运行时启动**

```bash
paseo daemon start
```

**Linux · 需要停止时执行**

```bash
paseo daemon stop
```

## 普通重启

**Linux · 重启 daemon**

```bash
paseo daemon restart
```

restart 用于常规重启。不要假定它一定会继承刚刚在另一个 shell 中设置的所有环境变量。重启也会让客户端暂时断开，先等正在进行的任务结束。

## PATH 或安装位置改变时

在准备启动 daemon 的同一个终端中确认命令路径，再停止旧进程并重新启动。

**Linux · 准备当前 shell 的 PATH**

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Linux · 确认 Codex 路径**

```bash
command -v codex
```

**Linux · 停止旧 daemon**

```bash
paseo daemon stop
```

**Linux · 从当前环境启动**

```bash
paseo daemon start
```

**Linux · 检查真正使用的环境**

```bash
paseo provider diagnostic codex
```

> **如果使用系统服务管理**
>
> 如果 daemon 是由 systemd 等服务管理器拉起，进程环境可能来自服务定义，而不是当前终端。此时应检查实际服务配置和启动方式，以 diagnostic 结果为准。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：版本更新](updates.md) · [下一篇：日常命令速查](daily.md)
