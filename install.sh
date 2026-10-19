#!/usr/bin/env bash
# Interactive Linux installer. Read menu input from a terminal, never from a curl pipe.
# Upstream scripts are downloaded completely before execution; no keys are collected.

GUIDE_INSTALLER_VERSION='1.1.0'
GUIDE_CODEX_URL='https://chatgpt.com/codex/install.sh'
GUIDE_CC_URL='https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh'
GUIDE_NVM_URL='https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh'
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
  for guide_command in curl tar gzip xz git sha256sum; do
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
  for guide_command in curl tar gzip xz git sha256sum; do
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

guide_install_all() {
  guide_install_codex || return 1
  guide_install_cc || return 1
  guide_install_paseo || return 1
  guide_ok '三个工具均已安装并通过版本检查。登录、服务启动和配对请继续选择菜单。'
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
  for guide_tool in node npm codex cc-switch paseo; do
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

guide_menu() {
  local guide_result
  while true; do
    printf '\n%s\n' '========== Linux 工具安装菜单 =========='
    printf '%s\n' \
      '  1) 一键安装全部：Codex + CC-Switch + Paseo（自动补依赖）' \
      '  2) 只安装 Codex' \
      '  3) 只安装 CC-Switch' \
      '  4) 只安装 Paseo（自动补 Node.js / npm）' \
      '  5) 启动 Paseo 并查看状态' \
      '  6) 启用 Relay 并显示手机配对二维码' \
      '  7) 检查版本、命令路径和服务状态（只读）' \
      '  8) Codex 官方账号登录' \
      '  9) 打开 CC-Switch 服务商配置' \
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
