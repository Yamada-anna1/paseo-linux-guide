# 安装 CC-Switch CLI

[返回首页](../../README.md) · [本分类目录](README.md)

使用 SaladDay/cc-switch-cli 项目的安装地址，并处理 PATH。

执行位置：**Linux** · 分类：安装部署

这里的 CC-Switch CLI 来自 SaladDay/cc-switch-cli，是用于管理服务商配置的第三方工具。仅使用官方 Codex 登录时，它是可选项。

## 1. 检查是否已经安装

**Linux · 检查 CC-Switch**

```bash
cc-switch --version
```

## 2. 安装或更新

**Linux · CC-Switch 项目安装脚本**

```bash
curl -fsSL https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh | bash
```

安装器检测到已有版本时，按提示选择 Update 才会更新；首次使用时按安装提示操作。命令中不能包含 `[网址](网址)` 这种 Markdown 链接括号。

## 3. 让当前 shell 找到命令

**Linux · 加入 PATH**

```bash
export PATH="$HOME/.local/bin:$PATH"
```

永久保存的方法见“命令目录与 PATH”，无需在多处重复追加。

**Linux · 验证版本**

```bash
cc-switch --version
```

**Linux · 查看路径**

```bash
command -v cc-switch
```

## 4. 打开交互界面

**Linux · 打开 CC-Switch**

```bash
cc-switch
```

默认安装位置为 $HOME/.local/bin/cc-switch。能启动后，再到“CC-Switch 与服务商配置”区分持久切换和单次启动。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：Codex 登录与单独测试](codex-login.md) · [下一篇：安装 Paseo 与启动 daemon](paseo-install.md)
