# Linux 项目路径怎么看

[返回首页](../../README.md) · [本分类目录](README.md)

明确代码在哪台电脑，避免把 Windows 路径填到 Linux。

执行位置：**Linux + Paseo 界面** · 分类：项目与手机

当前选择的是 Linux 远程主机，因此项目目录必须在那台服务器上。Windows 的 C: 盘不会因为建立 SSH 连接就自动映射过去。

| 路径 | 所属位置 | 远程 Linux 项目能否直接选 |
| --- | --- | --- |
| /root/my-project | Linux 的 root 用户目录 | 目录存在时可以 |
| /home/ubuntu/app | Linux 的 ubuntu 用户目录 | 有权限且目录存在时可以 |
| C:\Users\WINDOWS_USER\Desktop\my-project | Windows 本地磁盘 | 不能直接作为 Linux 路径 |

## 查看当前目录

**Linux · 当前完整路径**

```bash
pwd
```

**Linux · 当前目录内容**

```bash
ls -la
```

例如 pwd 输出 /root，ls 中有 my-project 文件夹，那么项目完整路径为 /root/my-project。进入项目后再执行 pwd，可以直接复制完整路径。

**Linux · 进入示例项目**

```bash
cd /root/my-project
```

**Linux · 获取可填写的完整路径**

```bash
pwd
```

如果项目只在 Windows，可以通过 SFTP 上传，或从 Git 仓库克隆到 Linux。若想操作本机文件，应在 Paseo 中选择本地主机。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：Paseo Desktop 连接](../03-remote/desktop-ssh.md) · [下一篇：添加 Linux 项目](project-add.md)
