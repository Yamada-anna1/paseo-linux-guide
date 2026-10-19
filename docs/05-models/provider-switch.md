# CC-Switch 与服务商配置

[返回首页](../../README.md) · [本分类目录](README.md)

区分持久配置切换和只影响一个子进程的临时启动。

执行位置：**Linux** · 分类：模型与服务商

Paseo 启动的是 Linux 上的 Codex。要影响它，服务商配置必须在相同 Linux 用户下，并且能被 Paseo 创建的 Codex 进程读取。

## 查看已有服务商

**Linux · 查看 Codex 服务商列表**

```bash
cc-switch --app codex provider list
```

**Linux · 打开交互配置界面**

```bash
cc-switch
```

在交互界面中确认选中的应用是 Codex，再查看或切换实际要使用的配置。输入 API Key 的操作在本机终端完成，不把密钥写进本手册。

## 全局切换与单次启动的区别

| 方式 | 影响范围 | 对 Paseo 的含义 |
| --- | --- | --- |
| 持久 / 全局配置切换 | 更新该 Linux 用户后续 Codex 进程读取的配置 | 需要验证 Paseo 新建进程实际读到该配置 |
| cc-switch start codex … | 启动一个带指定配置的 Codex 子进程 | 不保证改变 Paseo 后续单独启动的 Codex |

以下两种方式按目的选择，不要连续照抄。YOUR_PROVIDER_ID 要替换为上方服务商列表中真实存在的 ID。

**Linux · 持久切换，先替换服务商 ID**

```bash
cc-switch --app codex provider switch YOUR_PROVIDER_ID
```

上面用于切换该 Linux 用户的 Codex 配置。下面只启动一次带指定配置的 Codex，不等于给 Paseo 全局切换。

**Linux · 单次启动，先替换服务商 ID**

```bash
cc-switch start codex YOUR_PROVIDER_ID
```

## 配置切换后的检查

**Linux · 检查 Paseo 的 Codex 环境**

```bash
paseo provider diagnostic codex
```

修改环境变量或路径后，按“daemon 启停与环境刷新”停止再启动。仅修改持久配置时，新建 Codex 会话后测试实际模型请求；不要凭界面名称判断接口已切换成功。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：手机二维码与 Relay](../04-projects-mobile/mobile-pair.md) · [下一篇：模型缺少，刷新不出来](models-missing.md)
