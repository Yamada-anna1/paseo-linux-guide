# 下载地址与参考资料

[返回首页](../../README.md) · [本分类目录](README.md)

集中保存安装来源与文档入口，便于日后核对版本。

执行位置：**资料索引** · 分类：维护与排障

安装入口在 2026-10-20 按 OpenAI 官方 CLI 文档、Paseo 官方文档及 CC-Switch 项目 README 核对。其他配置和界面可能随版本变化，使用时仍需确认当前 --help 与官方说明。

| 项目 / 主题 | 地址 |
| --- | --- |
| Codex CLI 官方文档 | https://learn.chatgpt.com/docs/codex/cli |
| Codex 认证文档 | https://developers.openai.com/codex/auth/ |
| Codex 安装脚本 | https://chatgpt.com/codex/install.sh |
| CC-Switch CLI 项目 | https://github.com/SaladDay/cc-switch-cli |
| CC-Switch CLI 发布版本 | https://github.com/SaladDay/cc-switch-cli/releases |
| CC-Switch CLI 安装脚本 | https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh |
| Paseo 安装说明 | https://paseo.sh/docs |
| Paseo CLI 命令 | https://paseo.sh/docs/cli |
| Paseo 连接说明 | https://paseo.sh/docs/connectivity |
| Paseo Codex 配置 | https://paseo.sh/docs/codex |
| Paseo 自定义提供方与模型 | https://paseo.sh/docs/custom-providers |
| Node.js 下载与安装 | https://nodejs.org/en/download |

## 以后如何维护这份手册

- 公开仓库始终使用占位符。个人服务器地址、账号和项目位置请保存在不上传的私人记录中。
- 更新软件后，记录 codex --version、paseo --version、cc-switch --version。
- 更换接口后，重新验证当前提供方和需要使用的 Model ID。
- 功能入口或命令变化时，先看该版本 --help，再更新对应文章。
- 修改 src/guide-content.json 后执行 npm run build，再执行 npm run check；不要只修改生成的 Markdown 或 HTML。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：常见错误与处理顺序](troubleshooting.md)
