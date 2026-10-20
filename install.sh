#!/usr/bin/env bash
# Interactive Linux installer. Read menu input from a terminal, never from a curl pipe.
# Upstream scripts are downloaded completely before execution; no keys are collected.

GUIDE_INSTALLER_VERSION='1.3.0'
GUIDE_CODEX_URL='https://chatgpt.com/codex/install.sh'
GUIDE_CC_URL='https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh'
GUIDE_NVM_URL='https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh'
# Pinned official release; hashes checked against cli/cli release assets on 2026-10-20.
GUIDE_GH_VERSION='2.102.0'
GUIDE_TMP_DIR=''

guide_info() { printf '\n[信息] %s\n' "$*"; }
guide_ok() { printf '[完成] %s\n' "$*"; }
guide_error() { printf '[失败] %s\n' "$*" >&2; }
guide_has() { command -v "$1" >/dev/null 2>&1; }

guide_read() {
  printf '%s' "$1" >&2
  IFS= read -r GUIDE_REPLY <&9
}

guide_confirm() {
  guide_read "$1 [y/N] " || return 1
  case "$GUIDE_REPLY" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

guide_open_terminal() {
  # The surrounding group keeps the expected no-TTY diagnostic concise.
  if { exec 9<> /dev/tty; } 2>/dev/null; then return 0; fi
  guide_error '没有可交互的终端。请在 SSH 登录后的终端执行；自动化 SSH 请使用 ssh -t。'
  return 1
}

guide_platform() {
  if [[ "$(uname -s)" != Linux ]]; then
    guide_error '此安装器仅用于 Linux。不要在 Windows PowerShell / Git Bash 中直接安装。'
    return 1
  fi
  case "$(uname -m)" in
    x86_64|aarch64|arm64) ;;
    *) guide_error '仅支持 Linux x86_64 或 ARM64；未修改系统。'; return 1 ;;
  esac
  if [[ -z "${HOME:-}" || "$HOME" != /* || "$HOME" == / || ! -d "$HOME" ]]; then
    guide_error '当前用户主目录无效；未修改系统。'
    return 1
  fi
}

guide_prepend_path() {
  export PATH="$HOME/.local/bin:$PATH"
  hash -r
}

guide_load_nvm() {
  local guide_nvm_home="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$guide_nvm_home/nvm.sh" ]]; then
    export NVM_DIR="$guide_nvm_home"
    # Only load nvm's entry point, not arbitrary commands from the user's shell rc.
    . "$guide_nvm_home/nvm.sh" || return 1
  fi
  guide_prepend_path
}

guide_append_environment() {
  local guide_profile="$1"
  if [[ -f "$guide_profile" ]] && grep -qF '# >>> paseo-linux-guide >>>' "$guide_profile"; then return 0; fi
  # Append a small managed block; never replace the user's existing configuration.
  {
    printf '\n%s\n' '# >>> paseo-linux-guide >>>'
    printf '%s\n' 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"'
    printf '%s\n' '[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"'
    printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"'
    printf '%s\n' '# <<< paseo-linux-guide <<<'
  } >> "$guide_profile"
}

guide_save_environment() {
  local guide_profile
  local -a guide_profiles=("$HOME/.bashrc" "$HOME/.profile")
  [[ ! -f "$HOME/.bash_profile" ]] || guide_profiles+=("$HOME/.bash_profile")
  mkdir -p "$HOME/.local/bin" || return 1
  for guide_profile in "${guide_profiles[@]}"; do
    guide_append_environment "$guide_profile" || return 1
  done
  guide_prepend_path
}

guide_as_admin() {
  if [[ "$(id -u)" == 0 ]]; then
    "$@"
  elif guide_has sudo; then
    sudo "$@" <&9
  else
    guide_error '需要补装系统依赖，但当前用户没有 sudo。请让管理员安装所提示的依赖。'
    return 1
  fi
}

guide_ensure_base() {
  local guide_command
  local -a guide_missing=()
  for guide_command in curl tar gzip xz git sha256sum install; do
    guide_has "$guide_command" || guide_missing+=("$guide_command")
  done
  if ((${#guide_missing[@]} == 0)); then return 0; fi
  guide_info "缺少基础命令：${guide_missing[*]}。将补装下载、解压和 Git 依赖。"
  if guide_has apt-get; then
    guide_as_admin apt-get update || return 1
    guide_as_admin env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl tar gzip xz-utils git coreutils || return 1
  elif guide_has dnf; then
    guide_as_admin dnf install -y ca-certificates curl tar gzip xz git coreutils || return 1
  elif guide_has yum; then
    guide_as_admin yum install -y ca-certificates curl tar gzip xz git coreutils || return 1
  else
    guide_error '无法自动补齐依赖：当前只处理 apt-get / dnf / yum。请先由管理员安装缺失命令。'
    return 1
  fi
  for guide_command in curl tar gzip xz git sha256sum install; do
    if ! guide_has "$guide_command"; then
      guide_error "依赖安装后仍找不到 $guide_command，停止当前流程。"
      return 1
    fi
  done
}

guide_download() {
  local guide_url="$1" guide_destination="$2"
  if [[ -z "$GUIDE_TMP_DIR" || ! -d "$GUIDE_TMP_DIR" || "$guide_destination" != "$GUIDE_TMP_DIR/"* ]]; then
    guide_error '临时下载目录无效。'; return 1
  fi
  curl --proto '=https' --tlsv1.2 -fSL --retry 2 --connect-timeout 20 --max-time 180 \
    "$guide_url" -o "$guide_destination" || {
      guide_error "下载失败：$guide_url。没有执行下载内容。"; return 1;
    }
  if [[ ! -s "$guide_destination" ]]; then
    guide_error '下载内容为空，没有执行。'; return 1
  fi
}

guide_working() {
  guide_has "$1" && "$1" --version >/dev/null 2>&1
}

guide_node_ready() {
  guide_has node && guide_has npm || return 1
  node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)' >/dev/null 2>&1 || return 1
  npm --version >/dev/null 2>&1
}

guide_ensure_node() {
  if guide_node_ready; then
    guide_ok "已有可用 Node.js $(node --version) / npm $(npm --version)，保留原环境。"
    return 0
  fi
  if [[ -f /etc/alpine-release ]]; then
    guide_error 'Alpine / musl 的 Node.js 安装不在此自动流程内；请使用发行版适配方案。'
    return 1
  fi
  guide_info 'Node.js/npm 缺少、不可运行或 Node.js 低于 22；安装用户级 Node.js 24 LTS。'
  guide_ensure_base || return 1
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    guide_download "$GUIDE_NVM_URL" "$GUIDE_TMP_DIR/nvm-install.sh" || return 1
    bash -n "$GUIDE_TMP_DIR/nvm-install.sh" || return 1
    # Suppress nvm's own profile edits. One managed block below handles Bash consistently.
    env PROFILE=/dev/null METHOD=script NVM_DIR="$NVM_DIR" \
      bash "$GUIDE_TMP_DIR/nvm-install.sh" </dev/null || return 1
  fi
  guide_load_nvm || return 1
  if ! guide_has nvm; then guide_error 'nvm 安装后未能加载。'; return 1; fi
  nvm install 24 || return 1
  nvm alias default 24 || return 1
  nvm use 24 || return 1
  guide_save_environment || return 1
  if ! guide_node_ready; then
    guide_error 'Node.js/npm 验证失败，未继续安装 Paseo。'
    return 1
  fi
  guide_ok "Node.js $(node --version) / npm $(npm --version) 已就绪。"
}

guide_install_codex() {
  if guide_working codex; then guide_ok "$(codex --version) 已可用，跳过安装。"; return 0; fi
  guide_info '安装 Codex CLI（OpenAI 官方独立安装器）。'
  guide_ensure_base || return 1
  guide_save_environment || return 1
  guide_download "$GUIDE_CODEX_URL" "$GUIDE_TMP_DIR/codex-install.sh" || return 1
  sh -n "$GUIDE_TMP_DIR/codex-install.sh" || return 1
  # Avoid launching an interactive Codex session from inside the installer.
  env CODEX_NON_INTERACTIVE=1 sh "$GUIDE_TMP_DIR/codex-install.sh" </dev/null || return 1
  guide_prepend_path
  if ! guide_working codex; then guide_error 'Codex 安装后验证失败。'; return 1; fi
  guide_ok "$(codex --version)"
}

guide_install_cc() {
  if guide_working cc-switch; then guide_ok "$(cc-switch --version) 已可用，跳过安装。"; return 0; fi
  local guide_cc_force=0
  if [[ -e "$HOME/.local/bin/cc-switch" || -L "$HOME/.local/bin/cc-switch" ]]; then
    guide_confirm '发现无法正常运行的 CC-Switch 文件，是否重新安装修复？' || return 1
    guide_cc_force=1
  fi
  guide_info '安装 CC-Switch CLI（SaladDay 项目）。'
  guide_ensure_base || return 1
  guide_save_environment || return 1
  guide_download "$GUIDE_CC_URL" "$GUIDE_TMP_DIR/cc-switch-install.sh" || return 1
  bash -n "$GUIDE_TMP_DIR/cc-switch-install.sh" || return 1
  env CC_SWITCH_FORCE="$guide_cc_force" CC_SWITCH_INSTALL_DIR="$HOME/.local/bin" \
    bash "$GUIDE_TMP_DIR/cc-switch-install.sh" <&9 || return 1
  guide_prepend_path
  if ! guide_working cc-switch; then guide_error 'CC-Switch 安装后验证失败。'; return 1; fi
  guide_ok "$(cc-switch --version)"
}

guide_install_paseo() {
  if guide_working paseo; then guide_ok "$(paseo --version) 已可用，跳过安装。"; return 0; fi
  guide_info '安装 Paseo；先自动检查 Node.js 和 npm。'
  guide_ensure_base || return 1
  guide_ensure_node || return 1
  guide_save_environment || return 1
  # Per-invocation prefix, not a permanent npm configuration change; never sudo npm.
  npm install --global --prefix "$HOME/.local" @getpaseo/cli@latest || return 1
  guide_prepend_path
  if ! guide_working paseo; then guide_error 'Paseo 安装后验证失败。'; return 1; fi
  guide_ok "$(paseo --version)"
}

guide_gh_asset() {
  case "$(uname -m)" in
    x86_64)
      GUIDE_GH_ARCH='amd64'
      GUIDE_GH_SHA256='bb766f710eef8ede859c18578c72c327597cd4c8a85b06001b1f3843c6019386' ;;
    aarch64|arm64)
      GUIDE_GH_ARCH='arm64'
      GUIDE_GH_SHA256='7862c86c72f43df3a2d93ddde6f473285b4e2af61b494849846827e513ef6484' ;;
    *) guide_error 'GitHub CLI 自动安装仅支持 x86_64 / ARM64。'; return 1 ;;
  esac
}

guide_verify_sha256() {
  local guide_file="$1" guide_expected="$2"
  [[ "$guide_expected" =~ ^[a-f0-9]{64}$ ]] || return 1
  # Basename + controlled working directory also handles spaces in temporary paths.
  (cd "$(dirname "$guide_file")" && printf '%s  %s\n' "$guide_expected" "$(basename "$guide_file")" | sha256sum --check --status)
}

guide_install_gh() {
  if guide_working gh; then guide_ok "$(gh --version) 已可用，跳过安装。"; return 0; fi
  if [[ -e "$HOME/.local/bin/gh" || -L "$HOME/.local/bin/gh" ]]; then
    guide_confirm '发现无法正常运行的 GitHub CLI 文件，是否重新安装修复？' || return 1
  fi
  guide_gh_asset || return 1
  guide_info "安装 GitHub CLI $GUIDE_GH_VERSION（官方二进制 + 固定 SHA-256 校验）。"
  guide_ensure_base || return 1
  local guide_package="gh_${GUIDE_GH_VERSION}_linux_${GUIDE_GH_ARCH}"
  local guide_archive="$GUIDE_TMP_DIR/$guide_package.tar.gz" guide_extract
  guide_download "https://github.com/cli/cli/releases/download/v$GUIDE_GH_VERSION/$guide_package.tar.gz" "$guide_archive" || return 1
  if ! guide_verify_sha256 "$guide_archive" "$GUIDE_GH_SHA256"; then
    guide_error 'GitHub CLI 校验失败；没有解压、运行或安装该下载文件。'; return 1
  fi
  guide_extract="$(mktemp -d "$GUIDE_TMP_DIR/gh-extract.XXXXXXXX")" || return 1
  tar -xzf "$guide_archive" -C "$guide_extract" "$guide_package/bin/gh" || return 1
  if ! "$guide_extract/$guide_package/bin/gh" --version; then
    guide_error '下载的 GitHub CLI 无法运行，未替换已有文件。'; return 1
  fi
  guide_save_environment || return 1
  install -m 0755 "$guide_extract/$guide_package/bin/gh" "$HOME/.local/bin/gh" || return 1
  guide_prepend_path
  if ! guide_working gh; then guide_error 'GitHub CLI 安装后验证失败。'; return 1; fi
  guide_ok "$(gh --version)"
  guide_info '下一步选 11 登录、12 检查；Paseo 仍提示找不到 gh 时，任务结束后再选 13。'
}

guide_install_all() {
  guide_install_codex || return 1
  guide_install_cc || return 1
  guide_install_paseo || return 1
  guide_install_gh || return 1
  guide_ok 'Codex、CC-Switch、Paseo、GitHub CLI 均已安装并通过版本检查。登录、启动和配对请继续选择菜单。'
}

guide_start_paseo() {
  guide_install_paseo || return 1
  paseo daemon start <&9 || return 1
  paseo daemon status <&9
}

guide_pair_paseo() {
  guide_info '此操作会启动 Paseo，并启用跨网络 Relay 配对。二维码/配对链接不要公开分享。'
  guide_confirm '是否继续启用 Relay 并显示配对二维码？' || return 0
  guide_start_paseo || return 1
  paseo daemon pair --relay <&9
}

guide_status() {
  local guide_tool
  guide_info '仅检查当前用户的命令版本和路径，不安装软件。'
  for guide_tool in node npm git codex cc-switch paseo gh; do
    if guide_working "$guide_tool"; then
      printf '\n%s：%s\n' "$guide_tool" "$(command -v "$guide_tool")"
      "$guide_tool" --version
    else
      printf '\n%s：未安装、当前 PATH 找不到，或运行失败。\n' "$guide_tool"
    fi
  done
  if guide_working paseo; then
    printf '\nPaseo 服务状态：\n'
    paseo daemon status <&9 || printf '服务未运行或状态检查失败；可选择菜单 5。\n'
  fi
}

guide_login_codex() {
  guide_info '适用于使用官方账号；若已配置第三方 API，请取消并保留原配置。'
  guide_confirm '是否开始 Codex 官方账号设备码登录？' || return 0
  guide_install_codex || return 1
  codex login --device-auth <&9
}

guide_configure_cc() {
  guide_install_cc || return 1
  guide_info '退出 CC-Switch 交互界面后，会返回本安装菜单。'
  cc-switch <&9
}

guide_github_status() {
  guide_info '检查当前 Linux 用户的 GitHub CLI 和 github.com 登录状态；不会安装或登录。'
  if ! guide_working gh; then guide_error 'gh 不可用，请先选择菜单 10。'; return 1; fi
  printf 'gh 路径：%s\n' "$(command -v gh)"
  gh --version || return 1
  if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    guide_info '检测到 GH_TOKEN / GITHUB_TOKEN；gh 会优先使用环境凭据，不代表 daemon 也继承了它。不会显示变量内容。'
  fi
  if ! gh auth status --hostname github.com <&9; then
    guide_error 'GitHub 登录未通过检查：可能未登录、凭据失效或网络失败。核对上方错误；需要登录时选 11。'
    return 1
  fi
}

guide_login_github() {
  if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    guide_error '检测到 GH_TOKEN / GITHUB_TOKEN，未开始持久化登录。可选 12 检查；若改用浏览器登录，请自行在原终端移除临时凭据后重开菜单。'
    return 1
  fi
  guide_info '请使用运行 Paseo 的同一个 Linux 用户登录 GitHub；Windows 上的登录不会自动传到服务器。'
  guide_info '将使用 github.com 浏览器设备码授权及 HTTPS Git 协议；按提示在自己的电脑/手机完成授权，不要分享设备码。'
  guide_info '没有可用的系统凭据库时，gh 可能把凭据保存为本用户配置目录中的明文文件。不要上传该目录。'
  guide_confirm '是否继续安装（如缺少）并登录 GitHub？' || return 0
  guide_install_gh || return 1
  if gh auth status --hostname github.com >/dev/null 2>&1; then
    guide_ok '当前用户已有可用 GitHub 登录，保留现有账号与 Git 协议配置。'
    guide_github_status
    return $?
  fi
  gh auth login --hostname github.com --git-protocol https --web <&9 || return 1
  guide_github_status
}

guide_refresh_paseo_environment() {
  if [[ -n "${PASEO_HOST:-}" ]]; then
    guide_error '检测到 PASEO_HOST；为避免误操作其他主机，未停止服务。请在目标 Linux 取消远程选择后重开菜单。'
    return 1
  fi
  local guide_paseo_home="${PASEO_HOME:-$HOME/.paseo}"
  if [[ "$guide_paseo_home" != /* || "$guide_paseo_home" == / ]]; then
    guide_error 'PASEO_HOME 必须是有效的 Linux 绝对目录，未停止服务。'; return 1
  fi
  guide_info "将停止并从当前 PATH 重新启动本机 Paseo：$guide_paseo_home。可能中断任务和客户端连接。"
  guide_info '请先等任务结束。如果由 systemd / 容器管理，请取消并检查其启动环境；本操作不修改服务定义。'
  guide_confirm '确认当前目标无运行中任务，并执行停止后启动？' || return 0
  guide_load_nvm || return 1
  if ! guide_working paseo; then guide_error 'Paseo 不可用，请先选 4 安装。'; return 1; fi
  paseo daemon stop --home "$guide_paseo_home" <&9 || return 1
  paseo daemon start --home "$guide_paseo_home" <&9 || return 1
  paseo daemon status --home "$guide_paseo_home" <&9 || return 1
  guide_info '请回到 Paseo 重新打开 Clone from GitHub。若仍报错，确认连接主机、Linux 用户和服务管理器环境。'
}

guide_ssh_diagnostics() {
  local guide_sshd='' guide_ssh_config='' guide_ssh_file
  guide_info 'Linux SSH 只读检查：不安装、不 sudo、不读取私钥、不修改配置或权限。'
  printf '当前用户：%s\n主目录：%s\n' "$(id -un)" "$HOME"
  printf '%s\n' '必须与 Windows 想登录的 Linux 用户一致；本检查不是远程登录成功证明。'
  if guide_has sshd; then guide_sshd="$(command -v sshd)"
  elif [[ -x /usr/sbin/sshd ]]; then guide_sshd=/usr/sbin/sshd; fi
  printf '\n[sshd 基础配置]\n'
  if [[ "$(id -u)" != 0 ]]; then
    printf '%s\n' '当前不是 root，不自动提权；请管理员检查 sshd -T 输出。'
  elif [[ -z "$guide_sshd" ]]; then
    printf '%s\n' '找不到 sshd；未自动安装。请核对 SSH 服务及实际运行环境。'
  elif guide_ssh_config="$("$guide_sshd" -T 2>&1)"; then
    printf '%s\n' "$guide_ssh_config" | grep -E '^(pubkeyauthentication|permitrootlogin|authorizedkeysfile|authenticationmethods|strictmodes) ' || true
  else
    printf '%s\n' 'sshd -T 检查失败；请管理员在终端查看具体错误，未修改配置。'
  fi
  printf '%s\n' '注意：Match 规则要结合 sshd -T -C 检查；运行服务的自定义 -f/-o 参数也可能改变结果。'
  printf '%s\n' '下方仅检查当前用户的常用 authorized_keys 路径；自定义路径应按上方配置另查。'
  printf '\n[目录权限与属主]\n'
  if guide_has stat; then
    for guide_ssh_file in "$HOME" "$HOME/.ssh" "$HOME/.ssh/authorized_keys"; do
      if [[ -e "$guide_ssh_file" || -L "$guide_ssh_file" ]]; then
        stat -c '%a %U:%G %n' -- "$guide_ssh_file" || true
      else printf '不存在：%s\n' "$guide_ssh_file"; fi
    done
  else printf '%s\n' '缺少 stat，跳过权限检查。'; fi
  printf '\n[已授权登录公钥指纹]\n'
  if ! guide_has ssh-keygen; then
    printf '%s\n' '缺少 ssh-keygen，跳过公钥指纹检查。'
  elif [[ -L "$HOME" || -L "$HOME/.ssh" || -L "$HOME/.ssh/authorized_keys" ]]; then
    printf '%s\n' '主目录、.ssh 或 authorized_keys 是符号链接；请管理员核对目标，本检查不继续跟随。'
  elif [[ -f "$HOME/.ssh/authorized_keys" ]]; then
    ssh-keygen -lf "$HOME/.ssh/authorized_keys" </dev/null || printf '%s\n' '未识别出有效公钥：可能为空、格式不符或无法读取；不要直接清空文件。'
  else printf '%s\n' '常用 authorized_keys 文件不存在；请结合实际 AuthorizedKeysFile 配置判断。'; fi
  printf '\n[服务器主机公钥指纹，与登录公钥不同]\n'
  for guide_ssh_file in /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_rsa_key.pub; do
    if guide_has ssh-keygen && [[ -f "$guide_ssh_file" && ! -L "$guide_ssh_file" ]]; then
      ssh-keygen -lf "$guide_ssh_file" </dev/null || true
    fi
  done
  printf '%s\n' '主机指纹必须从你已信任的会话或服务商控制台取得；不能把本输出当作自动信任授权。'
  guide_ok '只读检查结束。需要修复时先看子菜单 2–5；当前没有进行修改。'
}

guide_ssh_host_steps() {
  cat <<'GUIDE_SSH_HOST'

【步骤 1 · Linux / 已信任的 FinalShell 会话或服务商控制台】
用途：查看服务器 ED25519 主机公钥指纹。只读；无权读取时请管理员协助。
# Linux Bash：不是 Windows，也不是私钥文件
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

【步骤 2 · Windows PowerShell / 普通窗口】
先替换 YOUR_LINUX_USER 与 YOUR_SERVER_IP；非 22 端口也要修改。
# Windows：首次连接；可能询问主机信任或服务器密码
ssh -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"

看到 yes/no/[fingerprint] 时，先比较相同算法的 SHA256 指纹。
只有与步骤 1 一致才输入 yes。信任记录写入 Windows 用户的 known_hosts。
指纹不一致或提示 REMOTE HOST IDENTIFICATION HAS CHANGED：停止核实，
不要关闭主机校验，不要盲目删除旧记录，不要自动接受扫描到的密钥。

FinalShell 能连接，不代表 Windows OpenSSH 已信任同一主机。
Linux 菜单不能替 Windows 确认信任。不要在 Linux 里运行上述 Windows 测试。
SSH_OK 若依赖密码得到，尚不证明无交互密钥登录可用；继续看子菜单 5。
GUIDE_SSH_HOST
}

guide_ssh_windows_steps() {
  cat <<'GUIDE_SSH_WINDOWS'

【Windows PowerShell 命令速查：每段分别复制，不在 Linux 执行】
以下仅展示，不会由 Linux 安装器执行。先确认使用运行 Codex 的同一 Windows 用户。

【1 · 普通窗口 / 只读：当前用户、SSH 命令】
whoami
Get-Command ssh

【2 · 普通窗口 / 只读：检查已有密钥，只检查文件是否存在】
Test-Path "$env:USERPROFILE\.ssh\id_ed25519"
Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub"
任意一个存在：不要覆盖或盲目重新生成。

【3 · 仅两个文件都不存在时 / 普通窗口 / 会创建新密钥】
# 整段复制；已有任意一个文件则只提示，不覆盖
if ((Test-Path "$env:USERPROFILE\.ssh\id_ed25519") -or (Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub")) {
    Write-Host '已有密钥文件，停止生成，请使用或检查现有密钥。'
} else {
    New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
    ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519"
}
如设置私钥口令，请妥善保存；后续用 ssh-agent 解锁。不要把私钥上传到服务器。

【4 · 普通窗口 / 只读：查看服务与已加载密钥】
Get-Service ssh-agent
ssh-add -l
没有身份、服务未启动和公钥被服务器拒绝是不同问题。

【5 · 仅服务未启用时 / 管理员 PowerShell / 会修改服务设置】
# 两条分别执行；已经 Running 时不必重复
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

【6 · 普通窗口 / 会将已有私钥加载到本机 agent】
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
成功通常显示 Identity added；需要口令时在自己终端输入，不要分享。

【7 · 普通窗口 / 只读：核对本机登录公钥指纹】
ssh-keygen -lf "$env:USERPROFILE\.ssh\id_ed25519.pub"
该指纹应与 Linux authorized_keys 中某把钥匙一致；不是服务器主机指纹。

【8 · 普通窗口 / 只读：显示可上传的公钥；必须保留 .pub 后缀】
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"

【9 · 可选 / 会替换 Windows 剪贴板内容，仅复制公钥】
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" -Raw | Set-Clipboard
不要读取、复制或发送没有 .pub 后缀的 id_ed25519 内容。

【10 · 公钥文件传送 / 会在服务器主目录写入 incoming-key.pub】
推荐在已信任的 FinalShell 文件面板上传 id_ed25519.pub，改名 incoming-key.pub。
上传到目标 Linux 用户的主目录，先确认该目标文件不存在或可替换。
如果普通 SSH 已能认证，也可在 Windows PowerShell 使用下面命令；先替换占位符：
scp -P 22 "$env:USERPROFILE\.ssh\id_ed25519.pub" YOUR_LINUX_USER@YOUR_SERVER_IP:incoming-key.pub
若 scp 也因认证失败，不要循环重试；使用已有 FinalShell 会话上传 .pub。
上传仅是准备候选文件，尚未添加授权；继续看子菜单 4。
GUIDE_SSH_WINDOWS
}

guide_ssh_append_example() {
  # Printed Bash example only. Nothing here executes unless the user separately copies it.
  cat <<'GUIDE_SSH_APPEND_EXAMPLE'
(
  set -eu
  # Linux Bash：当前用户必须就是准备通过 SSH 登录的目标用户。
  ssh_target_home="$HOME"
  ssh_fail() { printf '[停止] %s\n' "$*" >&2; exit 1; }
  [[ "$ssh_target_home" == /* && -d "$ssh_target_home" && ! -L "$ssh_target_home" ]] || ssh_fail '主目录必须是实际的绝对目录。'
  ssh_target_home="$(cd -P -- "$ssh_target_home" && pwd -P)"
  [[ "$ssh_target_home" != / ]] || ssh_fail '拒绝把根目录作为用户主目录。'
  ssh_candidate="$ssh_target_home/incoming-key.pub"
  ssh_dir="$ssh_target_home/.ssh"
  ssh_authorized="$ssh_dir/authorized_keys"
  [[ -f "$ssh_candidate" && ! -L "$ssh_candidate" ]] || ssh_fail '候选 .pub 文件不存在或是符号链接。'
  [[ "$(wc -c < "$ssh_candidate")" -le 16384 ]] || ssh_fail '候选文件过大，不应是密钥集合或私钥。'
  # 接受 Windows CRLF；整个文件只允许一行、无控制字符的 OpenSSH 公钥。
  ssh_pubkey="$(LC_ALL=C awk '{ sub(/\r$/, ""); if (NR != 1 || $0 ~ /[[:cntrl:]]/) bad=1; line=$0 } END { if (NR != 1 || bad) exit 1; print line }' "$ssh_candidate")" || ssh_fail '只接受单行公钥文件。'
  IFS=' ' read -r ssh_type ssh_blob ssh_comment <<< "$ssh_pubkey"
  case "$ssh_type" in ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com) ;; *) ssh_fail '不是支持的 OpenSSH 公钥；不要上传私钥或占位文本。' ;; esac
  [[ "$ssh_blob" =~ ^[A-Za-z0-9+/]+={0,3}$ ]] || ssh_fail '公钥内容格式不正确。'
  ssh-keygen -lf "$ssh_candidate" || ssh_fail '公钥验证失败。'
  # 拒绝异常目标，保留已有文件与权限；不自动更改 sshd 配置。
  [[ -d "$ssh_target_home" && -O "$ssh_target_home" ]] || ssh_fail '主目录属主不匹配。'
  [[ ! -L "$ssh_dir" && ( ! -e "$ssh_dir" || -d "$ssh_dir" ) ]] || ssh_fail '.ssh 目标异常。'
  [[ ! -L "$ssh_authorized" && ( ! -e "$ssh_authorized" || -f "$ssh_authorized" ) ]] || ssh_fail 'authorized_keys 目标异常。'
  for ssh_path in "$ssh_target_home" "$ssh_dir" "$ssh_authorized"; do
    if [[ -e "$ssh_path" ]]; then
      [[ -O "$ssh_path" ]] || ssh_fail "属主不匹配：$ssh_path"
      ssh_mode="$(stat -c %a -- "$ssh_path")"
      (( (8#$ssh_mode & 0022) == 0 )) || ssh_fail "组或其他用户可写，请先核查权限：$ssh_path"
    fi
  done
  # 相同密钥即使有不同注释或 from=/command= 限制，也不再添加无限制副本。
  if [[ -f "$ssh_authorized" ]]; then
    if grep -Fq -- "$ssh_blob" "$ssh_authorized"; then
      printf '%s\n' '文件已包含该密钥本体；没有重复追加，请检查原条目的限制选项。'
      exit 0
    else
      ssh_search_status=$?
      [[ "$ssh_search_status" == 1 ]] || ssh_fail '无法检查原授权文件，未追加。'
    fi
  fi
  umask 077
  mkdir -p -m 700 -- "$ssh_dir"
  if [[ -f "$ssh_authorized" ]]; then
    ssh_backup="$(mktemp "$ssh_authorized.bak.XXXXXXXX")"
    cp -p -- "$ssh_authorized" "$ssh_backup" || ssh_fail '备份失败，未追加。'
    printf '原文件已备份：%s\n' "$ssh_backup"
  fi
  # 前置换行避免与旧文件最后一行粘连；>> 仅追加，不覆盖。
  printf '\n%s\n' "$ssh_pubkey" >> "$ssh_authorized"
  printf '%s\n' '已追加公钥；仅添加授权公钥无需重启 sshd。请保留当前会话并在 Windows 测试。'
  ssh-keygen -lf "$ssh_authorized"
)
GUIDE_SSH_APPEND_EXAMPLE
}

guide_ssh_append_steps() {
  cat <<'GUIDE_SSH_APPEND'

【Linux / FinalShell：公钥认证排查与安全追加指引】
这里仅显示步骤，不执行追加。不是让你重装工具、放开 root 密码登录或重启 Paseo。
请先保留当前能用的 FinalShell 会话，确认当前 Linux 用户就是目标登录用户。

【1 · Linux / 只读：账号、授权文件与权限】
id -un
ssh-keygen -lf "$HOME/.ssh/authorized_keys"
stat -c '%a %U:%G %n' "$HOME" "$HOME/.ssh" "$HOME/.ssh/authorized_keys"
出现 is not a public key file 只说明没有识别出有效公钥，可能为空或格式不符。
公钥指纹应与 Windows 的 id_ed25519.pub 一致；不要比较两边文件注释。
管理员可检查（普通用户不要为照抄示例切换成 root）：
sshd -T | grep -E '^(pubkeyauthentication|permitrootlogin|authorizedkeysfile|authenticationmethods|strictmodes) '
如有 Match、自定义 -f/-o 或非默认 AuthorizedKeysFile，请先核对实际配置。
下方追加例子仅用于当前用户的默认 ~/.ssh/authorized_keys。

【2 · 准备候选公钥】
按子菜单 3，仅将 Windows 的 .pub 文件上传到目标 Linux 用户主目录，命名 incoming-key.pub。
先确认这把公钥属于你打算授权的电脑；文件必须只有一行，不要上传私钥。
上传后先运行这条只读命令，与 Windows .pub 的 SHA256 指纹核对一致再继续：
ssh-keygen -lf "$HOME/incoming-key.pub"

【3 · Linux Bash / 会修改授权文件：需要时才复制下面完整括号块】
整块不能拆开执行：验证通过后先备份再追加；检测到同一密钥则保留原条目。
整块执行过程中不会暂停等待你核对指纹，必须先完成上一步核对。
如果检查不通过就停止，请先处理报错，不要删掉保护检查或清空原文件。
GUIDE_SSH_APPEND
  guide_ssh_append_example
  printf '\n%s\n' '完成后转到 Windows 子菜单 5 测试。备份和候选文件留在服务器，不自动删除。'
}

guide_ssh_test_steps() {
  cat <<'GUIDE_SSH_TEST'

【Windows PowerShell / 普通窗口：无交互连接测试】
先替换 YOUR_LINUX_USER / YOUR_SERVER_IP；使用正确 SSH 端口。
# 只执行远程 echo；不询问密码，用来验证密钥/agent 认证
ssh -o BatchMode=yes -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"

【可选：明确指定已存在的 Windows 私钥文件，不是 .pub】
ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$env:USERPROFILE\.ssh\id_ed25519" -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"
若私钥有口令，先用子菜单 3 的 ssh-add 在本机 agent 中解锁。
IdentityFile 是 Windows 上的私钥路径，不是 Linux 项目目录，也不是公钥文件。

【仍失败时 / 只读诊断：输出分享前遮盖主机、账号和路径】
ssh -vv -o BatchMode=yes -p 22 YOUR_LINUX_USER@YOUR_SERVER_IP "echo SSH_OK"

结果判断：
  SSH_OK：回到 Codex 设置 → 连接，点击目标主机的“重新连接”。
  Host key verification failed：回子菜单 2，先核对服务器主机指纹。
  Permission denied：看是否 Offering public key、agent 是否有钥匙，再查 Linux 授权公钥与规则。
  Connection refused / timeout：核对地址、SSH 端口及网络；不要用重装 gh 代替检查。

SSH 连接、GitHub gh 登录、Paseo daemon 的 PATH 是三个不同环节。
Paseo 手机端找不到 gh：用主菜单 10/11/12；旧 daemon 按需确认后选 13。
终端 SSH_OK 后 Codex 仍失败：查看应用具体错误与远端登录 shell 的 PATH，不盲目重装。
GUIDE_SSH_TEST
}

guide_ssh_menu() {
  local guide_ssh_result
  while true; do
    printf '\n%s\n' '========== SSH 排查与配置指引 ==========' \
      '所有选项只读检查或展示步骤；不会自动修改 SSH、信任记录、密钥或防火墙。' \
      '  1) Linux SSH 只读检查（配置、权限、公钥指纹）' \
      '  2) Windows 首次连接与主机指纹确认指引' \
      '  3) Windows PowerShell 密钥 / ssh-agent / 公钥传送速查' \
      '  4) Linux 公钥排查与备份追加指引（仅展示）' \
      '  5) Windows 无交互测试与应用重连指引' \
      '  0) 返回安装主菜单'
    guide_read '输入 SSH 子菜单编号并回车：' || return 0
    guide_ssh_result=0
    case "$GUIDE_REPLY" in
      1) guide_ssh_diagnostics || guide_ssh_result=$? ;;
      2) guide_ssh_host_steps || guide_ssh_result=$? ;;
      3) guide_ssh_windows_steps || guide_ssh_result=$? ;;
      4) guide_ssh_append_steps || guide_ssh_result=$? ;;
      5) guide_ssh_test_steps || guide_ssh_result=$? ;;
      0|q|Q) return 0 ;;
      *) printf '选项无效，请输入 SSH 子菜单中的编号。\n'; continue ;;
    esac
    if ((guide_ssh_result != 0)); then guide_error '当前检查或输出失败；未自动进行修复。'; fi
  done
}

guide_menu() {
  local guide_result
  while true; do
    printf '\n%s\n' '========== Linux 工具安装菜单 =========='
    printf '%s\n' \
      '  1) 一键安装全部：Codex + CC-Switch + Paseo + GitHub CLI（自动补依赖）' \
      '  2) 只安装 Codex' \
      '  3) 只安装 CC-Switch' \
      '  4) 只安装 Paseo（自动补 Node.js / npm）' \
      '  5) 启动 Paseo 并查看状态' \
      '  6) 启用 Relay 并显示手机配对二维码' \
      '  7) 检查版本、命令路径和服务状态（只读）' \
      '  8) Codex 官方账号登录' \
      '  9) 打开 CC-Switch 服务商配置' \
      ' 10) 安装 GitHub CLI（gh，供 GitHub 克隆使用）' \
      ' 11) 登录 GitHub（浏览器设备码授权）' \
      ' 12) 检查 GitHub CLI 和登录状态（只读）' \
      ' 13) 刷新 Paseo 环境（停止后启动，需确认）' \
      ' 14) SSH 排查与配置指引（只读检查 / 分步操作）' \
      '  0) 退出'
    guide_read '输入选项编号并回车：' || break
    guide_result=0
    case "$GUIDE_REPLY" in
      1) guide_install_all || guide_result=$? ;;
      2) guide_install_codex || guide_result=$? ;;
      3) guide_install_cc || guide_result=$? ;;
      4) guide_install_paseo || guide_result=$? ;;
      5) guide_start_paseo || guide_result=$? ;;
      6) guide_pair_paseo || guide_result=$? ;;
      7) guide_status || guide_result=$? ;;
      8) guide_login_codex || guide_result=$? ;;
      9) guide_configure_cc || guide_result=$? ;;
      10) guide_install_gh || guide_result=$? ;;
      11) guide_login_github || guide_result=$? ;;
      12) guide_github_status || guide_result=$? ;;
      13) guide_refresh_paseo_environment || guide_result=$? ;;
      14) guide_ssh_menu || guide_result=$? ;;
      0|q|Q) break ;;
      *) printf '选项无效，请输入菜单中的编号。\n'; continue ;;
    esac
    if ((guide_result != 0)); then
      guide_error "当前流程已停止（退出码 $guide_result）；已成功的安装会保留。请查看上方报错后重试。"
    fi
  done
  guide_info '已退出。若刚安装了 Node.js 或修改 PATH，请重新连接 SSH，使父终端加载新环境。'
}

guide_cleanup() {
  # Only the single mktemp directory created by this process may be removed.
  if [[ -n "$GUIDE_TMP_DIR" && "$GUIDE_TMP_DIR" == /tmp/paseo-linux-guide.* && -d "$GUIDE_TMP_DIR" && ! -L "$GUIDE_TMP_DIR" ]]; then
    rm -rf -- "$GUIDE_TMP_DIR"
  fi
}

guide_main() {
  case "${1:-}" in
    --help|-h)
      printf '%s\n' 'Linux 交互式安装器：在 SSH 终端运行 install.sh，然后按数字选择。' \
        '不提供无人值守的自动安装参数；安装过程中不修改 SSH、防火墙或账号密钥。'
      return 0 ;;
    --version) printf '%s\n' "$GUIDE_INSTALLER_VERSION"; return 0 ;;
    '') ;;
    *) guide_error '未知参数。请用 --help 查看说明。'; return 2 ;;
  esac
  guide_platform || return 1
  guide_open_terminal || return 1
  GUIDE_TMP_DIR="$(mktemp -d /tmp/paseo-linux-guide.XXXXXXXX)" || return 1
  trap guide_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  guide_load_nvm || return 1
  printf '\nPaseo Linux 安装器 v%s\n当前用户：%s  主目录：%s\n' "$GUIDE_INSTALLER_VERSION" "$(id -un)" "$HOME"
  printf '%s\n' \
    '选择安装即允许下载对应上游软件，并在需要时补齐系统依赖。' \
    '可用的已有工具会跳过，不自动升级、不卸载，也不替你登录账号。' \
    '安装位置使用当前用户；不要交替用 root 与其他用户安装。' \
    '不会修改 SSH / 防火墙 / API Key，不自动停止已有 daemon。'
  guide_menu
}

if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "$0" ]]; then
  guide_main "$@"
fi
