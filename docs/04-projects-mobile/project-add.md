# 添加 Linux 项目

[返回首页](../../README.md) · [本分类目录](README.md)

新建目录或克隆仓库，并处理 Choose a project 提示。

执行位置：**Linux + Paseo 界面** · 分类：项目与手机

> **Paseo 内置 GitHub 克隆入口**
>
> Clone from GitHub 提示缺少 gh 时，打开安装菜单，依次选 10 安装、11 登录、12 检查。旧 daemon 仍找不到命令，再等任务结束后选 13。详情见“GitHub CLI 安装与登录”。下方普通 git clone 是另一种方式，不需要重复执行。

## 方式 A：新建空项目目录

**Linux · 创建项目目录**

```bash
mkdir -p /root/my-project
```

## 方式 B：使用已有 Git 仓库

先把 YOUR_REPOSITORY_URL 替换成真实仓库地址。目标目录必须适合用于此次克隆；若已经创建并放入文件，先检查目录内容。

**Linux · 克隆仓库，先替换占位地址**

```bash
git clone YOUR_REPOSITORY_URL /root/my-project
```

## 在 Paseo 选择目录

- 确认主机选择的是目标远程 Linux，而不是 Windows 本地主机。
- 点击左侧“添加 project”或中间“Choose project”中的添加入口。
- 选择或填写 Linux 上实际存在的项目目录。
- 选中项目后新建工作区，再发送任务。

**Paseo · 示例项目路径**

```text
/root/my-project
```

**可用于首次测试的任务**

```text
请只查看项目结构，说明主要文件和运行方式，先不要修改文件。
```

> **Choose a project**
>
> 这条提示只表示当前尚未选择项目。远程主机已在线时，无需因此重新安装 SSH、Codex 或 Paseo。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：Linux 项目路径怎么看](project-paths.md) · [下一篇：手机二维码与 Relay](mobile-pair.md)
