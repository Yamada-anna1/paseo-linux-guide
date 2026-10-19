# 模型缺少，刷新不出来

[返回首页](../../README.md) · [本分类目录](README.md)

四条命令先定位是界面、daemon、Codex 还是接口问题。

执行位置：**Linux + Paseo 界面** · 分类：模型与服务商

不同客户端可能连接不同主机、Codex 版本、账号或第三方接口，因此模型菜单不一定相同。先检查 Paseo 当前连接的那台 Linux，再决定是否更新或手动添加。

## 先执行这四条

**Linux · 1 / 4：Codex 版本**

```bash
codex --version
```

**Linux · 2 / 4：Paseo 版本**

```bash
paseo --version
```

**Linux · 3 / 4：Paseo 实际使用的 Codex**

```bash
paseo provider diagnostic codex
```

**Linux · 4 / 4：Paseo 发现的模型**

```bash
paseo provider models codex
```

## 按结果选择下一步

| 观察到的结果 | 下一步 |
| --- | --- |
| 命令列出了模型，界面没有 | 确认界面是同一远程主机和 Codex 配置，清空搜索条件，再刷新并重新打开菜单 |
| 命令也没列出该模型 | 检查 Codex 版本、实际服务商、模型目录发现和固定 models 配置 |
| diagnostic 中路径或版本与终端不同 | 查找多份安装，统一 Paseo 实际调用的 Codex 路径 |
| 命令提示未知子命令 | 查看当前版本帮助，按安装来源更新相应软件 |
| 能选模型，实际请求失败 | 依据 model_not_found、权限或网络报错排查接口，不要只重复刷新 |

## 保留最少的排障证据

- 记录四条命令的结果和缺少的准确 Model ID。
- 记录 Paseo 当前选择的主机，以及使用官方账号还是第三方接口。
- 只分享与版本、路径、模型和错误有关的输出；先遮盖其中可能出现的凭据。
- 没有完成实际模型请求前，不把“菜单出现了”写成“模型已经可用”。

> **诊断与验证**
>
> 本文提供排查流程，不代表任何服务器的问题已经修复。以目标服务器的诊断结果和一次实际模型回复为准。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：CC-Switch 与服务商配置](provider-switch.md) · [下一篇：手动添加模型](model-add.md)
