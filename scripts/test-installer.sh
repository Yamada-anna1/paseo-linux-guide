#!/usr/bin/env bash
# Offline mock tests. Do not install packages, call the network, or change the real HOME.
TEST_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
. "$TEST_REPO_DIR/install.sh"
TEST_TEMP_DIR="$(mktemp -d /tmp/paseo-guide-tests.XXXXXXXX)" || exit 1
test_cleanup() {
  if [[ "$TEST_TEMP_DIR" == /tmp/paseo-guide-tests.* && -d "$TEST_TEMP_DIR" && ! -L "$TEST_TEMP_DIR" ]]; then
    rm -rf -- "$TEST_TEMP_DIR"
  fi
}
trap test_cleanup EXIT
TEST_COUNT=0
TEST_FAILED=0
test_fail() { printf 'ASSERTION FAILED: %s\n' "$*" >&2; exit 1; }
test_contains() { grep -qF -- "$2" "$1" || test_fail "expected $2 in $1"; }
test_absent() { if grep -qF -- "$2" "$1"; then test_fail "unexpected $2 in $1"; fi; }
test_event() { printf '%s\n' "$*" >> "$TEST_EVENTS"; }

test_mocks() {
  TEST_EVENTS="$TEST_TEMP_DIR/events-$TEST_COUNT"
  : > "$TEST_EVENTS"
  GUIDE_TMP_DIR="$TEST_TEMP_DIR/downloads-$TEST_COUNT"
  mkdir -p "$GUIDE_TMP_DIR" || test_fail 'mkdir'
  NVM_DIR="$TEST_TEMP_DIR/nvm-$TEST_COUNT"
  TEST_CODEX=0 TEST_CC=0 TEST_PASEO=0 TEST_NODE=0 TEST_NPM=0 TEST_GH=0
  TEST_GH_AUTH=1 TEST_GH_LOGIN_FAIL=0 TEST_HASH_FAIL=0 TEST_GH_BINARY_FAIL=0 TEST_STOP_FAIL=0 TEST_START_FAIL=0
  TEST_NPM_INSTALL_FAIL=0 TEST_DOWNLOAD_FAIL=0 TEST_BASE_FAIL=0 TEST_CONFIRM=0
  unset GH_TOKEN GITHUB_TOKEN PASEO_HOST PASEO_HOME
  guide_ensure_base() { test_event base; return "$TEST_BASE_FAIL"; }
  guide_save_environment() { test_event save-environment; return 0; }
  guide_prepend_path() { :; }
  guide_load_nvm() { test_event load-nvm; return 0; }
  guide_confirm() { test_event confirm; return "$TEST_CONFIRM"; }
  guide_download() {
    test_event "download $1"
    ((TEST_DOWNLOAD_FAIL == 0)) || return 9
    printf '#!/usr/bin/env bash\n:\n' > "$2"
  }
  guide_verify_sha256() { test_event checksum; return "$TEST_HASH_FAIL"; }
  tar() {
    test_event extract-gh
    [[ "$1" == -xzf && "$3" == -C && "$5" == */bin/gh ]] || test_fail 'unexpected tar arguments'
    mkdir -p "$4/$(dirname "$5")" || return 1
    printf '#!/bin/sh\nprintf "gh fixture\\n"\nexit %s\n' "$TEST_GH_BINARY_FAIL" > "$4/$5"
    chmod +x "$4/$5"
  }
  install() {
    test_event install-gh
    [[ "$1" == -m && "$2" == 0755 && -x "$3" && "$4" == "$HOME/.local/bin/gh" ]] || test_fail 'unexpected install arguments'
    TEST_GH=1
  }
  gh() {
    if [[ "$1" == --version ]]; then
      ((TEST_GH == 1)) || return 1
      printf 'gh mock-version\n'
    else
      test_event "gh $*"
      case "$*" in
        'auth status --hostname github.com') return "$TEST_GH_AUTH" ;;
        'auth login --hostname github.com --git-protocol https --web')
          ((TEST_GH_LOGIN_FAIL == 0)) || return 1
          TEST_GH_AUTH=0 ;;
        *) test_fail "unexpected gh invocation: $*" ;;
      esac
    fi
  }
  env() {
    test_event "upstream $*"
    case "$1" in
      CODEX_NON_INTERACTIVE=1) TEST_CODEX=1 ;;
      CC_SWITCH_FORCE=*) TEST_CC=1 ;;
      PROFILE=/dev/null) : ;;
      *) test_fail "unexpected env invocation: $*" ;;
    esac
  }
  codex() {
    if [[ "$1" == --version ]]; then
      ((TEST_CODEX == 1)) || return 1
      printf 'codex mock-version\n'
    else test_event "codex $*"; fi
  }
  cc-switch() {
    if [[ "${1:-}" == --version ]]; then
      ((TEST_CC == 1)) || return 1
      printf 'cc-switch mock-version\n'
    else test_event "cc-switch $*"; fi
  }
  node() {
    ((TEST_NODE == 1)) || return 1
    [[ "$1" == -e ]] || printf 'v24.mock\n'
  }
  npm() {
    if [[ "$1" == --version ]]; then
      ((TEST_NPM == 1)) || return 1
      printf '11.mock\n'
    else
      test_event "npm $*"
      ((TEST_NPM_INSTALL_FAIL == 0)) || return 42
      TEST_PASEO=1
    fi
  }
  nvm() {
    test_event "nvm $*"
    if [[ "$1" == install ]]; then TEST_NODE=1; TEST_NPM=1; fi
  }
  paseo() {
    if [[ "$1" == --version ]]; then
      ((TEST_PASEO == 1)) || return 1
      printf 'paseo mock-version\n'
    else
      test_event "paseo $*"
      [[ "$*" != 'daemon stop'* ]] || return "$TEST_STOP_FAIL"
      [[ "$*" != 'daemon start'* ]] || return "$TEST_START_FAIL"
    fi
    return 0
  }
  exec 9< /dev/null
}

test_case() {
  TEST_COUNT=$((TEST_COUNT + 1))
  if ( "$2" ) > "$TEST_TEMP_DIR/output-$TEST_COUNT" 2>&1; then
    printf 'PASS %02d %s\n' "$TEST_COUNT" "$1"
  else
    TEST_FAILED=$((TEST_FAILED + 1))
    printf 'FAIL %02d %s\n' "$TEST_COUNT" "$1"
    cat "$TEST_TEMP_DIR/output-$TEST_COUNT"
  fi
}

test_fresh_all() {
  test_mocks
  guide_install_all || test_fail 'install all'
  [[ "$TEST_CODEX$TEST_CC$TEST_PASEO$TEST_NODE$TEST_NPM$TEST_GH" == 111111 ]] || test_fail 'not all installed'
  test_contains "$TEST_EVENTS" 'CODEX_NON_INTERACTIVE=1'
  test_contains "$TEST_EVENTS" 'nvm install 24'
  test_contains "$TEST_EVENTS" 'nvm alias default 24'
  test_contains "$TEST_EVENTS" "npm install --global --prefix $HOME/.local @getpaseo/cli@latest"
  test_absent "$TEST_EVENTS" 'paseo daemon'
  test_absent "$TEST_EVENTS" 'gh auth'
}
test_user_recovery() {
  test_mocks
  TEST_CODEX=1 TEST_CC=1
  guide_install_all || test_fail 'existing tools + missing npm recovery'
  test_absent "$TEST_EVENTS" "$GUIDE_CODEX_URL"
  test_absent "$TEST_EVENTS" "$GUIDE_CC_URL"
  test_contains "$TEST_EVENTS" "$GUIDE_NVM_URL"
  [[ "$TEST_PASEO$TEST_NODE$TEST_NPM" == 111 ]] || test_fail 'Paseo dependencies not installed'
}
test_existing_all() {
  test_mocks
  TEST_CODEX=1 TEST_CC=1 TEST_PASEO=1 TEST_GH=1
  guide_install_all || test_fail 'all-existing skip'
  [[ ! -s "$TEST_EVENTS" ]] || test_fail 'already installed tools should not mutate anything'
}
test_existing_node() {
  test_mocks
  TEST_NODE=1 TEST_NPM=1
  guide_install_paseo || test_fail 'existing node'
  test_absent "$TEST_EVENTS" 'nvm install'
  test_absent "$TEST_EVENTS" "$GUIDE_NVM_URL"
  [[ "$TEST_PASEO" == 1 ]] || test_fail 'missing Paseo'
}
test_download_failure() {
  test_mocks
  TEST_DOWNLOAD_FAIL=1
  if guide_install_all; then test_fail 'download failure reported success'; fi
  test_absent "$TEST_EVENTS" 'upstream'
  test_absent "$TEST_EVENTS" "$GUIDE_CC_URL"
  test_absent "$TEST_EVENTS" 'npm install'
}
test_npm_failure() {
  test_mocks
  TEST_NODE=1 TEST_NPM=1 TEST_NPM_INSTALL_FAIL=1
  if guide_start_paseo; then test_fail 'npm failure reported success'; fi
  test_absent "$TEST_EVENTS" 'paseo daemon'
}
test_nvm_download_failure() {
  test_mocks
  TEST_DOWNLOAD_FAIL=1
  if guide_install_paseo; then test_fail 'nvm failure reported success'; fi
  test_absent "$TEST_EVENTS" 'nvm install'
  test_absent "$TEST_EVENTS" 'npm install'
}
test_base_failure() {
  test_mocks
  TEST_BASE_FAIL=1
  if guide_install_all; then test_fail 'base failure reported success'; fi
  test_absent "$TEST_EVENTS" 'download'
}
test_pair_confirmed() {
  test_mocks
  TEST_PASEO=1
  guide_pair_paseo || test_fail 'pair'
  test_contains "$TEST_EVENTS" 'paseo daemon start'
  test_contains "$TEST_EVENTS" 'paseo daemon status'
  test_contains "$TEST_EVENTS" 'paseo daemon pair --relay'
}
test_pair_declined() {
  test_mocks
  TEST_CONFIRM=1
  guide_pair_paseo || test_fail 'declining should return cleanly'
  test_absent "$TEST_EVENTS" 'paseo daemon'
  test_absent "$TEST_EVENTS" 'npm install'
}
test_login_declined() {
  test_mocks
  TEST_CONFIRM=1
  guide_login_codex || test_fail 'declining login'
  test_absent "$TEST_EVENTS" 'codex login'
  test_absent "$TEST_EVENTS" 'download'
}
test_read_only() {
  test_mocks
  TEST_CODEX=1 TEST_CC=1 TEST_PASEO=1 TEST_NODE=1 TEST_NPM=1
  guide_status || test_fail 'status'
  test_absent "$TEST_EVENTS" 'download'
  test_absent "$TEST_EVENTS" 'save-environment'
  test_absent "$TEST_EVENTS" 'npm install'
  test_contains "$TEST_EVENTS" 'paseo daemon status'
}
test_menu_input() {
  test_mocks
  printf 'invalid\n4\n7\n0\n' > "$TEST_TEMP_DIR/menu-input-$TEST_COUNT"
  exec 9< "$TEST_TEMP_DIR/menu-input-$TEST_COUNT"
  guide_menu </dev/null > "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" || test_fail 'menu'
  [[ "$TEST_PASEO" == 1 ]] || test_fail 'menu did not install selected Paseo'
  test_absent "$TEST_EVENTS" "$GUIDE_CODEX_URL"
  test_absent "$TEST_EVENTS" "$GUIDE_CC_URL"
  test_contains "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" '选项无效'
  test_contains "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" '已退出'
}
test_menu_failure_retry() {
  test_mocks
  TEST_BASE_FAIL=1
  printf '4\n0\n' > "$TEST_TEMP_DIR/menu-input-$TEST_COUNT"
  exec 9< "$TEST_TEMP_DIR/menu-input-$TEST_COUNT"
  guide_menu </dev/null > "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" 2>&1 || test_fail 'menu error recovery'
  test_contains "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" '当前流程已停止'
  test_contains "$TEST_TEMP_DIR/menu-output-$TEST_COUNT" '已退出'
}
test_pipe_entrypoint() {
  # --help avoids platform, TTY, network, and installation while exercising bash stdin entry.
  bash -s -- --help < "$TEST_REPO_DIR/install.sh" > "$TEST_TEMP_DIR/pipe-help-$TEST_COUNT" || test_fail 'piped entry'
  test_contains "$TEST_TEMP_DIR/pipe-help-$TEST_COUNT" 'Linux 交互式安装器'
}
test_source_no_action() {
  bash -c '. "$1"; printf "source-ok\n"' bash "$TEST_REPO_DIR/install.sh" > "$TEST_TEMP_DIR/source-$TEST_COUNT" || test_fail 'source'
  [[ "$(cat "$TEST_TEMP_DIR/source-$TEST_COUNT")" == source-ok ]] || test_fail 'sourcing performed actions'
}
test_unknown_argument() {
  if bash "$TEST_REPO_DIR/install.sh" --unattended > "$TEST_TEMP_DIR/args-$TEST_COUNT" 2>&1; then
    test_fail 'unknown argument accepted'
  fi
  test_contains "$TEST_TEMP_DIR/args-$TEST_COUNT" '未知参数'
}
test_profile_idempotent() {
  local test_profile="$TEST_TEMP_DIR/profile-$TEST_COUNT"
  printf '# Existing user configuration\n' > "$test_profile"
  guide_append_environment "$test_profile" || test_fail 'append profile'
  guide_append_environment "$test_profile" || test_fail 'append profile again'
  [[ "$(grep -cF '# >>> paseo-linux-guide >>>' "$test_profile")" == 1 ]] || test_fail 'duplicate block'
  test_contains "$test_profile" '# Existing user configuration'
  test_contains "$test_profile" 'export PATH="$HOME/.local/bin:$PATH"'
  bash -n "$test_profile" || test_fail 'profile syntax'
}
test_verify_failure() {
  test_mocks
  env() { test_event "upstream-without-binary $*"; return 0; }
  if guide_install_all; then test_fail 'successful download without working binary accepted'; fi
  test_absent "$TEST_EVENTS" "$GUIDE_CC_URL"
}

test_gh_only() {
  test_mocks
  guide_install_gh || test_fail 'install gh'
  [[ "$TEST_GH" == 1 ]] || test_fail 'gh not installed'
  test_contains "$TEST_EVENTS" "releases/download/v$GUIDE_GH_VERSION/gh_${GUIDE_GH_VERSION}_linux_"
  test_contains "$TEST_EVENTS" 'checksum'
  test_contains "$TEST_EVENTS" 'install-gh'
  test_absent "$TEST_EVENTS" 'gh auth'
  test_absent "$TEST_EVENTS" 'npm install'
  test_absent "$TEST_EVENTS" 'paseo daemon'
}
test_gh_checksum_failure() {
  test_mocks
  TEST_HASH_FAIL=1
  if guide_install_gh; then test_fail 'invalid checksum accepted'; fi
  test_absent "$TEST_EVENTS" 'extract-gh'
  test_absent "$TEST_EVENTS" 'install-gh'
  test_absent "$TEST_EVENTS" 'save-environment'
}
test_gh_download_failure() {
  test_mocks
  TEST_DOWNLOAD_FAIL=1
  if guide_install_gh; then test_fail 'failed gh download accepted'; fi
  test_absent "$TEST_EVENTS" 'checksum'
  test_absent "$TEST_EVENTS" 'install-gh'
}
test_gh_incompatible_binary() {
  test_mocks
  TEST_GH_BINARY_FAIL=1
  if guide_install_gh; then test_fail 'incompatible gh binary accepted'; fi
  test_absent "$TEST_EVENTS" 'install-gh'
  test_absent "$TEST_EVENTS" 'save-environment'
}
test_gh_repair_declined() {
  test_mocks
  # Mock only file existence via a test-local wrapper; never change the real HOME.
  guide_working() { return 1; }
  guide_confirm() { test_event confirm; return 1; }
  local test_body
  test_body="$(declare -f guide_install_gh)"
  test_body="${test_body//\$HOME\/\.local\/bin\/gh/\$GUIDE_TMP_DIR\/broken-gh}"
  eval "$test_body"
  printf 'broken' > "$GUIDE_TMP_DIR/broken-gh"
  if guide_install_gh; then test_fail 'declined repair accepted'; fi
  test_contains "$TEST_EVENTS" confirm
  test_absent "$TEST_EVENTS" download
}
test_gh_login_declined() {
  test_mocks
  TEST_CONFIRM=1
  guide_login_github || test_fail 'declining GitHub login'
  test_absent "$TEST_EVENTS" 'gh auth'
  test_absent "$TEST_EVENTS" 'download'
}
test_gh_login() {
  test_mocks
  TEST_GH=1
  guide_login_github || test_fail 'GitHub login'
  test_contains "$TEST_EVENTS" 'gh auth login --hostname github.com --git-protocol https --web'
  [[ "$TEST_GH_AUTH" == 0 ]] || test_fail 'not logged in'
  test_absent "$TEST_EVENTS" 'paseo daemon'
}
test_gh_existing_login() {
  test_mocks
  TEST_GH=1 TEST_GH_AUTH=0
  guide_login_github || test_fail 'existing GitHub login'
  test_absent "$TEST_EVENTS" 'gh auth login'
  test_absent "$TEST_EVENTS" 'download'
}
test_gh_login_failure() {
  test_mocks
  TEST_GH=1 TEST_GH_LOGIN_FAIL=1
  if guide_login_github; then test_fail 'failed GitHub login reported success'; fi
}
test_gh_env_token() {
  test_mocks
  GH_TOKEN='test-placeholder-not-a-credential'
  if guide_login_github > "$GUIDE_TMP_DIR/login-output" 2>&1; then test_fail 'env token ignored'; fi
  test_absent "$GUIDE_TMP_DIR/login-output" "$GH_TOKEN"
  test_absent "$TEST_EVENTS" 'gh auth login'
  test_absent "$TEST_EVENTS" 'download'
  unset GH_TOKEN
  GITHUB_TOKEN='second-placeholder-not-a-credential'
  if guide_login_github > "$GUIDE_TMP_DIR/login-output" 2>&1; then test_fail 'GITHUB_TOKEN ignored'; fi
  test_absent "$GUIDE_TMP_DIR/login-output" "$GITHUB_TOKEN"
}
test_gh_status_read_only() {
  test_mocks
  TEST_GH=1 TEST_GH_AUTH=0
  guide_github_status || test_fail 'GitHub status'
  test_contains "$TEST_EVENTS" 'gh auth status --hostname github.com'
  test_absent "$TEST_EVENTS" 'download'
  test_absent "$TEST_EVENTS" 'gh auth login'
  test_absent "$TEST_EVENTS" '--show-token'
}
test_gh_status_failure() {
  test_mocks
  if guide_github_status; then test_fail 'missing gh status reported success'; fi
  test_absent "$TEST_EVENTS" 'gh auth'
  TEST_GH=1
  if guide_github_status; then test_fail 'logged-out status reported success'; fi
  test_absent "$TEST_EVENTS" download
}
test_paseo_refresh_declined() {
  test_mocks
  TEST_CONFIRM=1
  guide_refresh_paseo_environment || test_fail 'declining refresh'
  test_absent "$TEST_EVENTS" 'paseo daemon'
}
test_paseo_refresh() {
  test_mocks
  TEST_PASEO=1
  PASEO_HOME="$GUIDE_TMP_DIR/custom paseo"
  guide_refresh_paseo_environment || test_fail 'Paseo refresh'
  local test_calls
  test_calls="$(grep '^paseo daemon' "$TEST_EVENTS")"
  [[ "$test_calls" == "$(printf 'paseo daemon %s --home %s\n' stop "$PASEO_HOME" start "$PASEO_HOME" status "$PASEO_HOME")" ]] || test_fail 'refresh order or target'
}
test_paseo_stop_failure() {
  test_mocks
  TEST_PASEO=1 TEST_STOP_FAIL=1
  if guide_refresh_paseo_environment; then test_fail 'stop failure accepted'; fi
  test_absent "$TEST_EVENTS" 'paseo daemon start'
}
test_paseo_start_failure() {
  test_mocks
  TEST_PASEO=1 TEST_START_FAIL=1
  if guide_refresh_paseo_environment; then test_fail 'start failure accepted'; fi
  test_absent "$TEST_EVENTS" 'paseo daemon status'
}
test_paseo_remote_guard() {
  test_mocks
  PASEO_HOST='example.invalid:6767'
  if guide_refresh_paseo_environment; then test_fail 'remote selector accepted'; fi
  test_absent "$TEST_EVENTS" 'paseo daemon'
  unset PASEO_HOST
  PASEO_HOME='relative-path'
  if guide_refresh_paseo_environment; then test_fail 'relative home accepted'; fi
  test_absent "$TEST_EVENTS" 'paseo daemon'
}
test_gh_menu() {
  test_mocks
  printf '10\n11\n12\n13\n0\n' > "$GUIDE_TMP_DIR/menu-input"
  exec 9< "$GUIDE_TMP_DIR/menu-input"
  TEST_PASEO=1
  guide_menu </dev/null || test_fail 'GitHub menu actions'
  test_contains "$TEST_EVENTS" 'install-gh'
  test_contains "$TEST_EVENTS" 'gh auth login'
  test_contains "$TEST_EVENTS" 'paseo daemon stop'
}
test_real_checksum() {
  local test_file="$TEST_TEMP_DIR/checksum with spaces-$TEST_COUNT"
  printf abc > "$test_file"
  guide_verify_sha256 "$test_file" 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' || test_fail 'valid checksum rejected'
  printf tampered >> "$test_file"
  if guide_verify_sha256 "$test_file" 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'; then test_fail 'tampered checksum accepted'; fi
  if guide_verify_sha256 "$test_file" invalid; then test_fail 'malformed checksum accepted'; fi
}
test_gh_architectures() {
  uname() { printf 'aarch64\n'; }
  guide_gh_asset || test_fail 'ARM64 asset'
  [[ "$GUIDE_GH_ARCH" == arm64 && "$GUIDE_GH_SHA256" =~ ^[a-f0-9]{64}$ ]] || test_fail 'ARM64 checksum'
  uname() { printf 'x86_64\n'; }
  guide_gh_asset || test_fail 'amd64 asset'
  [[ "$GUIDE_GH_ARCH" == amd64 && "$GUIDE_GH_SHA256" =~ ^[a-f0-9]{64}$ ]] || test_fail 'amd64 checksum'
  uname() { printf 'unsupported\n'; }
  if guide_gh_asset; then test_fail 'unsupported architecture accepted'; fi
}

test_case 'fresh install all including Node/npm' test_fresh_all
test_case 'user case: keep Codex/CC; install missing npm and Paseo' test_user_recovery
test_case 'skip all working installations without writes' test_existing_all
test_case 'reuse working Node/npm' test_existing_node
test_case 'download failure stops entire dependent sequence' test_download_failure
test_case 'npm failure never starts daemon' test_npm_failure
test_case 'nvm download failure never invokes npm install' test_nvm_download_failure
test_case 'system dependency failure stops downloads' test_base_failure
test_case 'confirmed Relay: start, status, pair in sequence' test_pair_confirmed
test_case 'declining Relay makes no changes' test_pair_declined
test_case 'declining login preserves credentials' test_login_declined
test_case 'status action is read-only' test_read_only
test_case 'menu reads dedicated terminal FD with empty stdin' test_menu_input
test_case 'failed menu action returns to menu' test_menu_failure_retry
test_case 'curl-pipe style entrypoint executes' test_pipe_entrypoint
test_case 'sourcing installer does not run main' test_source_no_action
test_case 'unknown unattended argument is rejected' test_unknown_argument
test_case 'profile writes preserve user content and do not duplicate' test_profile_idempotent
test_case 'upstream success without a working binary is rejected' test_verify_failure
test_case 'install gh alone without Node, authentication or daemon changes' test_gh_only
test_case 'gh checksum failure blocks extraction and installation' test_gh_checksum_failure
test_case 'gh download failure blocks installation' test_gh_download_failure
test_case 'incompatible gh binary does not replace existing files' test_gh_incompatible_binary
test_case 'declining repair preserves broken local gh' test_gh_repair_declined
test_case 'declining GitHub login makes no changes' test_gh_login_declined
test_case 'GitHub login uses explicit github.com HTTPS browser flow' test_gh_login
test_case 'existing GitHub account and protocol are preserved' test_gh_existing_login
test_case 'GitHub login failure propagates' test_gh_login_failure
test_case 'environment tokens block browser login without exposing values' test_gh_env_token
test_case 'GitHub status is read-only and does not reveal tokens' test_gh_status_read_only
test_case 'missing gh and failed auth status are not reported as success' test_gh_status_failure
test_case 'declining environment refresh never stops Paseo' test_paseo_refresh_declined
test_case 'refresh uses same explicit local home in stop-start-status order' test_paseo_refresh
test_case 'failed stop prevents start' test_paseo_stop_failure
test_case 'failed start prevents success status' test_paseo_start_failure
test_case 'remote selectors and invalid home block local refresh' test_paseo_remote_guard
test_case 'new menu choices 10 through 13 dispatch correctly' test_gh_menu
test_case 'real SHA-256 validates content and rejects tampering' test_real_checksum
test_case 'GitHub release architecture and checksum mapping' test_gh_architectures
printf '\n%s tests, %s failures. No real packages were installed.\n' "$TEST_COUNT" "$TEST_FAILED"
((TEST_FAILED == 0))
