# 首次搭建路线

[返回首页](../../README.md) · [本分类目录](README.md)

按依赖顺序完成首次配置，已经成功的环节可以跳过。

执行位置：**Linux + Windows** · 分类：简介

从左侧目录按下面的顺序操作。每完成一个环节先检查结果，出现报错就进入对应的排障文章。

- 1. 安装部署 → Linux 基础依赖：确认 node、npm、curl、git 可用。
- 2. 安装部署 → 命令目录与 PATH：让当前用户能找到安装后的命令。
- 3. 安装部署 → 安装 Codex CLI → Codex 登录与单独测试。
- 4. 可选：安装部署 → 安装 CC-Switch；再到模型与服务商中配置需要使用的接口。
- 5. 安装部署 → 安装 Paseo：启动 daemon 并检查能否找到 Codex。
- 6. 远程连接 → 生成 Windows SSH 密钥 → 启动 SSH Agent → 安装公钥与连接测试。
- 7. 如果服务器禁止公钥登录，按开启 Linux 公钥认证处理。
- 8. 远程连接 → Paseo Desktop 连接。
- 9. 项目与手机 → 添加 Linux 项目；手机使用另看二维码配对。

## 四个验收结果

| 检查位置 | 应该看到 |
| --- | --- |
| Linux：codex --version | Codex 版本号 |
| Linux：paseo daemon status | daemon 正常运行 |
| Windows：SSH BatchMode 测试 | 直接输出 ok |
| Paseo Desktop | 远程主机在线，并能选择 Linux 项目 |

> **已经配置好的电脑**
>
> 无需每天重新安装软件、生成密钥或追加公钥。日常使用可直接看“日常命令速查”。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：三个工具与整体关系](overview.md) · [下一篇：复制命令与使用约定](copy-rules.md)
