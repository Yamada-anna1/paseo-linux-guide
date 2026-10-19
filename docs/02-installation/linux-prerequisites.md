# Linux 基础依赖

[返回首页](../../README.md) · [本分类目录](README.md)

检查系统、Node.js、npm、curl 与 Git。

执行位置：**Linux** · 分类：安装部署

## 逐条检查

**Linux · 系统发行版**

```bash
cat /etc/os-release
```

**Linux · CPU 架构**

```bash
uname -m
```

**Linux · Node.js 版本**

```bash
node -v
```

**Linux · npm 版本**

```bash
npm -v
```

**Linux · curl 版本**

```bash
curl --version
```

**Linux · Git 版本**

```bash
git --version
```

Paseo 的 npm 安装方式依赖 Node.js 和 npm；curl 用于下载安装脚本；Git 用于克隆代码。Node.js 版本需满足当前 Paseo 发布版本的要求。

## 缺少命令时

- node 或 npm 不存在：先按 Node.js 官方说明安装当前受支持的 LTS，并确认符合 Paseo 要求。
- curl 或 git 不存在：按 /etc/os-release 中的发行版选择 apt、dnf 等对应的软件包管理器。
- 不要把 Ubuntu/Debian 的命令直接套到其他发行版。
- 完成依赖安装后，重新执行上面的检查，再继续安装 Codex 与 Paseo。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：GitHub CLI 安装与登录](github-cli.md) · [下一篇：命令目录与 PATH](path.md)
