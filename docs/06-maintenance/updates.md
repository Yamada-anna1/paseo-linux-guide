# 版本更新

[返回首页](../../README.md) · [本分类目录](README.md)

沿用原安装方式更新，并核对真正生效的版本。

执行位置：**Linux + Windows** · 分类：维护与排障

## 先记录路径与版本

**Linux · Codex 安装位置**

```bash
type -a codex
```

**Linux · Paseo 安装位置**

```bash
type -a paseo
```

沿用实际使用的安装来源。npm 全局安装与独立安装脚本可能放在不同目录，更新其中一份不代表 daemon 自动改用它。

## Codex：选择与原安装一致的一种

**Linux · npm 安装用户的更新命令**

```bash
npm install -g @openai/codex@latest
```

如果原先使用官方安装脚本，则使用该安装器的当前流程；下面是替代路径，不需要与 npm 方式一起执行。

**Linux · 官方脚本安装用户的替代更新方式**

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

## Paseo CLI

**Linux · 更新 npm 安装的 Paseo**

```bash
npm install -g @getpaseo/cli@latest
```

## CC-Switch CLI

**Linux · 运行安装器并按提示选择 Update**

```bash
curl -fsSL https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh | bash
```

## 更新后确认

**Linux · Codex 版本**

```bash
codex --version
```

**Linux · Paseo 版本**

```bash
paseo --version
```

**Linux · CC-Switch 版本**

```bash
cc-switch --version
```

Windows Paseo Desktop 是另一端的软件，需通过桌面端自己的更新入口或官方发行包更新。服务器 CLI 更新后，按下一篇重新启动 daemon，并再次检查 provider diagnostic。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：models 与 additionalModels](../05-models/model-config.md) · [下一篇：daemon 启停与环境刷新](daemon-control.md)
