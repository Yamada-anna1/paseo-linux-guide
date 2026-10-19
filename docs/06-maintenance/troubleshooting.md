# 常见错误与处理顺序

[返回首页](../../README.md) · [本分类目录](README.md)

按报错定位到具体环节，避免重复重装。

执行位置：**排障索引** · 分类：维护与排障

| 现象 / 报错 | 优先检查 | 对应文章 |
| --- | --- | --- |
| cc-switch / codex / paseo: command not found | 安装位置和当前用户 PATH | 命令目录与 PATH |
| GitHub CLI (gh) is not installed or not in PATH | 同一 Linux 用户下选 10 安装、11 登录、12 检查；旧 daemon 按需选 13 刷新 | GitHub CLI 安装与登录 |
| Set-Service 拒绝访问 | PowerShell 是否有管理员权限 | 启动 Windows SSH Agent |
| Error connecting to agent | ssh-agent 是否运行、ssh-add 所属环境 | 启动 Windows SSH Agent |
| Identity added 后仍 Permission denied | 远端是否开启公钥、密钥是否匹配、权限和 Match 规则 | 开启 Linux 公钥认证 |
| pubkeyauthentication no | 找到来源配置并正确开启 | 开启 Linux 公钥认证 |
| Windows SSH 输出 ok，Paseo 仍连接失败 | daemon 是否在线、地址和端口是否正确 | Paseo Desktop 连接 |
| Choose a project | 远程主机下是否已添加并选中目录 | 添加 Linux 项目 |
| 终端 Codex 正常，Paseo 找不到 | daemon 的 PATH 与实际二进制路径 | daemon 启停与环境刷新 |
| 模型缺少，点击刷新无效 | 四条诊断命令和 models 固定列表 | 模型缺少，刷新不出来 |
| 模型出现但 model_not_found | 准确模型 ID、实际服务商和权限 | 手动添加模型 |
| 二维码配对失败 | daemon、Relay 提示和手机所选主机 | 手机二维码与 Relay |

## 连接失败的详细证据

需要继续检查 SSH 时，可以在 Windows 获取详细日志。该命令仍使用无交互模式，不会要求输入服务器密码。

**Windows PowerShell · 详细 SSH 调试**

```powershell
ssh -vvv -o BatchMode=yes root@YOUR_SERVER_IP "echo ok"
```

重点看是否提供了预期密钥、服务器是否接受，以及拒绝后的认证方式。日志可能包含主机、用户名和路径，分享时只保留相关部分。

## 需要求助时带上哪些信息

- 执行位置：Linux 服务器、Windows 普通 PowerShell，还是管理员 PowerShell。
- 执行的完整命令与紧接着的报错文字。
- 相关软件版本、实际命令路径和当前选中的远程主机。
- 模型问题补充准确 Model ID、官方登录或第三方接口类型。
- 不附带密码、私钥、API Key、auth.json 内容或完整配对链接。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：日常命令速查](daily.md) · [下一篇：下载地址与参考资料](references.md)
