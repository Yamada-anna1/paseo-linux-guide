# 手机二维码与 Relay

[返回首页](../../README.md) · [本分类目录](README.md)

从 Linux 生成 Paseo 配对二维码，让手机连接。

执行位置：**Linux + 手机 Paseo** · 分类：项目与手机

Windows Desktop 已采用 SSH 时可以继续使用原连接。手机需要配对时，在运行 daemon 的同一个 Linux 用户下生成二维码。

## 1. 确认 daemon 在线

**Linux · 查看运行状态**

```bash
paseo daemon status
```

只有 daemon 未运行时才执行启动。

**Linux · 必要时启动 daemon**

```bash
paseo daemon start
```

## 2. 显示配对二维码

**Linux · 生成配对信息**

```bash
paseo daemon pair
```

按当前版本的提示完成配对。如果跨网络连接需要 Relay，按提示启用；终端会显示可扫描的二维码或配对链接。

**Linux · 查看当前版本的配对选项**

```bash
paseo daemon pair --help
```

若帮助中包含 --relay，可用下面的方式明确启用 Relay。它是 pair 的替代调用，不必与上一条重复执行。

**Linux · 支持该选项时启用 Relay 配对**

```bash
paseo daemon pair --relay
```

## 3. 在手机完成配对

- 手机 Paseo 打开添加主机或配对设备入口。
- 扫描终端中完整的二维码；显示不完整时可尝试粘贴配对链接。
- 检查手机选到的主机和 Linux 项目是否正确。
- Relay 方式不需要给手机开放服务器的 6767；手机也不依赖 Windows 的 SSH Agent。

> **配对信息保密**
>
> 二维码和配对链接包含连接所需的敏感信息，不要放进公开截图或共享文档。这里仅记录生成方式，不保存实际二维码。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：添加 Linux 项目](project-add.md) · [下一篇：CC-Switch 与服务商配置](../05-models/provider-switch.md)
