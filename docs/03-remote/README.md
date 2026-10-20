# 远程连接

[返回首页](../../README.md) · [全部分类](../README.md)

SSH 分步排障、主机指纹、Windows 密钥、SSH Agent、公钥认证、Paseo SSH

1. [SSH 排查与配置指引](ssh-troubleshooting.md) — 集中保存 Windows 与 Linux 的分段命令：主机指纹、登录公钥、授权文件、无交互测试。
2. [生成 Windows SSH 密钥](ssh-key.md) — 先检查已有密钥，避免覆盖原来的登录凭据。
3. [启动 Windows SSH Agent](ssh-agent.md) — 解决拒绝访问、无法连接 agent，并加载现有私钥。
4. [安装公钥与连接测试](ssh-test.md) — 将公钥加入 Linux，并验证无交互 SSH。
5. [开启 Linux 公钥认证](sshd-pubkey.md) — 排查有效配置为 PubkeyAuthentication no 的情况。
6. [Paseo Desktop 连接](desktop-ssh.md) — 填写 SSH 地址，分清 SSH 端口与 daemon 端口。
