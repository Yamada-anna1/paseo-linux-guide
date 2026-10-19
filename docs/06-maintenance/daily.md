# 日常命令速查

[返回首页](../../README.md) · [本分类目录](README.md)

已经配置好后，按目的找一条需要的命令。

执行位置：**Linux + Windows** · 分类：维护与排障

这里是命令索引，不是一组必须顺序执行的安装步骤。根据目的使用一条即可。

**Linux · 确认 Paseo 在线**

```bash
paseo daemon status
```

**Linux · daemon 未运行时启动**

```bash
paseo daemon start
```

**Linux · 检查 Codex 版本**

```bash
codex --version
```

**Linux · 检查 Codex 登录状态**

```bash
codex login status
```

**Linux · 检查 Paseo 的 Codex 环境**

```bash
paseo provider diagnostic codex
```

**Linux · 查看模型列表**

```bash
paseo provider models codex
```

**Linux · 打开 CC-Switch**

```bash
cc-switch
```

**Linux · 查看 Codex 服务商**

```bash
cc-switch --app codex provider list
```

**Linux · 显示手机配对二维码**

```bash
paseo daemon pair
```

**Windows PowerShell · 测试无交互 SSH**

```powershell
ssh -o BatchMode=yes root@YOUR_SERVER_IP "echo ok"
```

**Paseo · SSH 地址示例，先替换占位符**

```text
ssh://root@YOUR_SERVER_IP
```

**Paseo · 示例 Linux 项目路径**

```text
/root/my-project
```

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：daemon 启停与环境刷新](daemon-control.md) · [下一篇：常见错误与处理顺序](troubleshooting.md)
