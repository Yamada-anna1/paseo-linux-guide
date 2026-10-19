# Paseo Desktop 连接

[返回首页](../../README.md) · [本分类目录](README.md)

填写 SSH 地址，分清 SSH 端口与 daemon 端口。

执行位置：**Paseo 界面** · 分类：远程连接

前提是 Linux daemon 正在运行，并且 Windows 的 BatchMode SSH 测试直接输出 ok。Paseo 使用本机 OpenSSH 环境，不会读取其他 SSH 软件里保存的服务器密码。

- 打开 Paseo 的添加主机入口，选择“远程 SSH / Remote SSH”。
- 在 SSH 主机字段填写下面的地址。
- 点击连接，确认出现正确的远程主机名。
- 连接后选择远程 Linux 项目，再新建工作区。

**Paseo · SSH 主机字段**

```text
ssh://root@YOUR_SERVER_IP
```

## 端口如何填写

| 情况 | 地址示例 |
| --- | --- |
| 默认 SSH 端口为 22 | ssh://root@YOUR_SERVER_IP |
| 显式写出默认 SSH 端口 | ssh://root@YOUR_SERVER_IP:22 |
| 假设 SSH 改为 2222 | ssh://root@YOUR_SERVER_IP:2222 |
| 假设 daemon 改为 7777 | ssh://root@YOUR_SERVER_IP?daemonPort=7777 |

冒号后的端口指 SSH 服务。Paseo 默认通过 SSH 访问远端的 127.0.0.1:6767，因此不要把地址误写成 ssh://root@YOUR_SERVER_IP:6767。

## 怎样判断下一步

- 远程主机旁的绿色圆点表示连接在线。
- Choose a project 表示还没选项目，进入“添加 Linux 项目”。
- SSH 测试成功但 Paseo 无法连接：先检查远端 paseo daemon status。
- 菜单名称会随版本和语言变化，以界面中的添加主机、远程 SSH 入口为准。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：开启 Linux 公钥认证](sshd-pubkey.md) · [下一篇：Linux 项目路径怎么看](../04-projects-mobile/project-paths.md)
