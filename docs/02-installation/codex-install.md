# 安装 Codex CLI

[返回首页](../../README.md) · [本分类目录](README.md)

安装实际执行 AI 任务的命令行程序。

执行位置：**Linux** · 分类：安装部署

## 1. 先检查已有版本

**Linux · 检查 Codex**

```bash
codex --version
```

能输出版本号就说明已经安装，可继续登录和测试。只有命令不存在时才需要安装。

## 2. 选择一种安装方式

方式 A：使用官方安装脚本。

**Linux · 官方安装脚本**

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

方式 B：已有 Node.js / npm 时，也可以使用 npm。A、B 二选一，不要为了同一次安装反复交替执行。

**Linux · 替代安装方式：npm**

```bash
npm install -g @openai/codex
```

## 3. 验证安装

**Linux · 重新检查版本**

```bash
codex --version
```

**Linux · 查看正在使用的路径**

```bash
command -v codex
```

**Linux · 检查是否存在多个安装位置**

```bash
type -a codex
```

如果安装提示成功但命令找不到，先查看“命令目录与 PATH”。如果出现多个路径，Paseo 可能调用了另一份版本；先查清路径，再更新需要使用的那一份。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：命令目录与 PATH](path.md) · [下一篇：Codex 登录与单独测试](codex-login.md)
