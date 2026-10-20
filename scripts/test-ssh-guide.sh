#!/usr/bin/env bash
# Offline tests; generated fixture keys and all writes stay in one temporary directory.
# Never change HOME, contact an SSH host, or modify the user's SSH configuration.
SSH_TEST_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
. "$SSH_TEST_REPO/install.sh"
SSH_TEST_DIR="$(mktemp -d /tmp/paseo-ssh-tests.XXXXXXXX)" || exit 1
ssh_test_cleanup() {
  if [[ "$SSH_TEST_DIR" == /tmp/paseo-ssh-tests.* && -d "$SSH_TEST_DIR" && ! -L "$SSH_TEST_DIR" ]]; then
    rm -rf -- "$SSH_TEST_DIR"
  fi
}
trap ssh_test_cleanup EXIT
SSH_TEST_COUNT=0 SSH_TEST_FAILED=0
ssh_test_fail() { printf 'ASSERTION FAILED: %s\n' "$*" >&2; exit 1; }
ssh_test_has() { grep -qF -- "$2" "$1" || ssh_test_fail "missing: $2"; }
ssh_test_absent() { if grep -qF -- "$2" "$1"; then ssh_test_fail "unexpected: $2"; fi; }
ssh_test_case() {
  SSH_TEST_COUNT=$((SSH_TEST_COUNT + 1))
  if ( "$2" ) > "$SSH_TEST_DIR/output-$SSH_TEST_COUNT" 2>&1; then
    printf 'PASS SSH %02d %s\n' "$SSH_TEST_COUNT" "$1"
  else
    SSH_TEST_FAILED=$((SSH_TEST_FAILED + 1))
    printf 'FAIL SSH %02d %s\n' "$SSH_TEST_COUNT" "$1"
    cat "$SSH_TEST_DIR/output-$SSH_TEST_COUNT"
  fi
}

# Extract the exact displayed example; replace only its target variable, never HOME.
guide_ssh_append_example | sed 's/ssh_target_home="$HOME"/ssh_target_home="$SSH_TEST_TARGET"/' > "$SSH_TEST_DIR/append.sh"
ssh_test_syntax() { bash -n "$SSH_TEST_DIR/append.sh" || ssh_test_fail 'example syntax'; }
ssh_test_forbid_writes() {
  guide_as_admin() { ssh_test_fail 'unexpected elevation'; }
  guide_ensure_base() { ssh_test_fail 'unexpected dependency install'; }
  guide_save_environment() { ssh_test_fail 'unexpected profile edit'; }
  guide_download() { ssh_test_fail 'unexpected download'; }
  sudo() { ssh_test_fail 'unexpected sudo'; }
  chmod() { ssh_test_fail 'unexpected permission edit'; }
  systemctl() { ssh_test_fail 'unexpected service change'; }
}
ssh_test_print_only() {
  ssh_test_forbid_writes
  cp() { ssh_test_fail 'unexpected backup execution'; }
  mkdir() { ssh_test_fail 'unexpected directory creation'; }
  ssh-keygen() { ssh_test_fail 'unexpected key generation'; }
  local ssh_output="$SSH_TEST_DIR/instructions"
  { guide_ssh_host_steps; guide_ssh_windows_steps; guide_ssh_append_steps; guide_ssh_test_steps; } > "$ssh_output"
  ssh_test_has "$ssh_output" 'Windows PowerShell'
  ssh_test_has "$ssh_output" '管理员 PowerShell'
  ssh_test_has "$ssh_output" 'Get-Service ssh-agent'
  ssh_test_has "$ssh_output" 'ssh-add "$env:USERPROFILE\.ssh\id_ed25519"'
  ssh_test_has "$ssh_output" 'Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"'
  ssh_test_has "$ssh_output" 'BatchMode=yes'
  ssh_test_has "$ssh_output" 'YOUR_SERVER_IP'
  ssh_test_has "$ssh_output" '先比较相同算法'
  ssh_test_absent "$ssh_output" 'StrictHostKeyChecking=no'
  ssh_test_absent "$ssh_output" 'ssh-keyscan'
  ssh_test_absent "$ssh_output" 'ssh-keygen -R'
}
ssh_test_menu() {
  ssh_test_forbid_writes
  guide_ssh_diagnostics() { printf 'readonly-check-called\n'; }
  printf '14\nbad\n1\n2\n3\n4\n5\n0\n0\n' > "$SSH_TEST_DIR/menu-input"
  exec 9< "$SSH_TEST_DIR/menu-input"
  guide_menu </dev/null > "$SSH_TEST_DIR/menu-output" || ssh_test_fail 'menu return'
  ssh_test_has "$SSH_TEST_DIR/menu-output" 'readonly-check-called'
  ssh_test_has "$SSH_TEST_DIR/menu-output" 'SSH 子菜单中的编号'
  ssh_test_has "$SSH_TEST_DIR/menu-output" '已退出'
  ssh_test_has "$SSH_TEST_DIR/menu-output" 'Linux / FinalShell'
  ssh_test_has "$SSH_TEST_DIR/menu-output" 'Set-Clipboard'
}
ssh_test_diag_setup() {
  export SSH_TEST_TARGET="$SSH_TEST_DIR/diagnostic-$SSH_TEST_COUNT"
  mkdir -p "$SSH_TEST_TARGET/.ssh"
  printf '# test only\n' > "$SSH_TEST_TARGET/.ssh/authorized_keys"
  local ssh_body
  ssh_body="$(declare -f guide_ssh_diagnostics)"
  ssh_body="${ssh_body//\$HOME/\$SSH_TEST_TARGET}"
  ssh_body="${ssh_body//\/usr\/sbin\/sshd/\$SSH_TEST_DIR\/absent-sshd}"
  eval "$ssh_body"
  ssh_test_forbid_writes
  id() { [[ "$1" == -u ]] && printf '0\n' || printf 'guide-test-user\n'; }
  sshd() { printf 'pubkeyauthentication yes\npermitrootlogin prohibit-password\nstrictmodes yes\nauthorizedkeysfile .ssh/authorized_keys\nauthenticationmethods any\n'; }
  ssh-keygen() { printf 'fingerprint-check-called\n'; }
}
ssh_test_diag_root() {
  ssh_test_diag_setup
  guide_ssh_diagnostics > "$SSH_TEST_DIR/diagnostic-output" || ssh_test_fail 'root diagnostics'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" 'pubkeyauthentication yes'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" 'fingerprint-check-called'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" 'Match'
  [[ "$(cat "$SSH_TEST_TARGET/.ssh/authorized_keys")" == '# test only' ]] || ssh_test_fail 'changed authorized_keys'
}
ssh_test_diag_nonroot() {
  ssh_test_diag_setup
  id() { [[ "$1" == -u ]] && printf '1000\n' || printf 'guide-test-user\n'; }
  sshd() { ssh_test_fail 'nonroot called sshd'; }
  guide_ssh_diagnostics > "$SSH_TEST_DIR/diagnostic-output" || ssh_test_fail 'nonroot diagnostics'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '不自动提权'
}
ssh_test_diag_missing() {
  ssh_test_diag_setup
  guide_has() { [[ "$1" != sshd && "$1" != ssh-keygen ]] && command -v "$1" >/dev/null 2>&1; }
  guide_ssh_diagnostics > "$SSH_TEST_DIR/diagnostic-output" || ssh_test_fail 'missing tools diagnostics'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '找不到 sshd'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '缺少 ssh-keygen'
}
ssh_test_diag_invalid() {
  ssh_test_diag_setup
  sshd() { return 1; }
  ssh-keygen() { return 1; }
  guide_ssh_diagnostics > "$SSH_TEST_DIR/diagnostic-output" || ssh_test_fail 'invalid config diagnostics'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '检查失败'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '未识别出有效公钥'
}

ssh_test_prepare() {
  export SSH_TEST_TARGET="$SSH_TEST_DIR/home-$SSH_TEST_COUNT"
  mkdir -m 700 "$SSH_TEST_TARGET"
  cp "$SSH_TEST_DIR/fixture.pub" "$SSH_TEST_TARGET/incoming-key.pub"
}
ssh_test_existing() {
  ssh_test_prepare
  mkdir -m 700 "$SSH_TEST_TARGET/.ssh"
  printf '# preserve exact bytes without a trailing newline' > "$SSH_TEST_TARGET/.ssh/authorized_keys"
  chmod 600 "$SSH_TEST_TARGET/.ssh/authorized_keys"
}
ssh_test_run_example() { bash "$SSH_TEST_DIR/append.sh"; }
ssh_test_append_existing() {
  ssh_test_existing
  ssh_test_run_example || ssh_test_fail 'append existing'
  ssh_test_has "$SSH_TEST_TARGET/.ssh/authorized_keys" '# preserve exact bytes without a trailing newline'
  ssh_test_has "$SSH_TEST_TARGET/.ssh/authorized_keys" "$(cat "$SSH_TEST_DIR/fixture.pub")"
  local ssh_backups=("$SSH_TEST_TARGET"/.ssh/authorized_keys.bak.*)
  [[ ${#ssh_backups[@]} == 1 && -f "${ssh_backups[0]}" ]] || ssh_test_fail 'missing unique backup'
  [[ "$(cat "${ssh_backups[0]}")" == '# preserve exact bytes without a trailing newline' ]] || ssh_test_fail 'backup changed original content'
  ssh-keygen -lf "$SSH_TEST_TARGET/.ssh/authorized_keys" >/dev/null || ssh_test_fail 'new key not parseable'
  [[ "$(stat -c %a "$SSH_TEST_TARGET/.ssh/authorized_keys")" == 600 ]] || ssh_test_fail 'changed file permissions'
}
ssh_test_append_new() {
  ssh_test_prepare
  ssh_test_run_example || ssh_test_fail 'new authorization'
  [[ "$(stat -c %a "$SSH_TEST_TARGET/.ssh")" == 700 ]] || ssh_test_fail 'new directory mode'
  [[ "$(stat -c %a "$SSH_TEST_TARGET/.ssh/authorized_keys")" == 600 ]] || ssh_test_fail 'new file mode'
}
ssh_test_append_duplicate() {
  ssh_test_existing
  printf 'from="example.invalid",command="echo restricted" %s different-comment\n' "$(cut -d ' ' -f 1-2 "$SSH_TEST_DIR/fixture.pub")" > "$SSH_TEST_TARGET/.ssh/authorized_keys"
  local ssh_original
  ssh_original="$(sha256sum "$SSH_TEST_TARGET/.ssh/authorized_keys")"
  ssh_test_run_example || ssh_test_fail 'existing restricted key should cleanly skip'
  [[ "$(sha256sum "$SSH_TEST_TARGET/.ssh/authorized_keys")" == "$ssh_original" ]] || ssh_test_fail 'existing restrictions changed'
  [[ "$(find "$SSH_TEST_TARGET/.ssh" -type f | wc -l)" == 1 ]] || ssh_test_fail 'duplicate should not create backup'
}
ssh_test_rejected_unchanged() {
  local ssh_before
  ssh_before="$(sha256sum "$SSH_TEST_TARGET/.ssh/authorized_keys")"
  if ssh_test_run_example; then ssh_test_fail 'invalid candidate accepted'; fi
  [[ "$(sha256sum "$SSH_TEST_TARGET/.ssh/authorized_keys")" == "$ssh_before" ]] || ssh_test_fail 'invalid input altered authorization'
}
ssh_test_private_rejected() {
  ssh_test_existing
  cp "$SSH_TEST_DIR/fixture" "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_multiline_rejected() {
  ssh_test_existing
  cat "$SSH_TEST_DIR/fixture.pub" "$SSH_TEST_DIR/fixture.pub" > "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_empty_rejected() {
  ssh_test_existing
  : > "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_placeholder_rejected() {
  ssh_test_existing
  printf 'YOUR_PUBLIC_KEY\n' > "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_invalid_blob_rejected() {
  ssh_test_existing
  printf 'ssh-ed25519 invalidbase64 test\n' > "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_crlf() {
  ssh_test_prepare
  printf '%s\r\n' "$(cat "$SSH_TEST_DIR/fixture.pub")" > "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_run_example || ssh_test_fail 'Windows CRLF key rejected'
  if LC_ALL=C grep -q $'\r' "$SSH_TEST_TARGET/.ssh/authorized_keys"; then ssh_test_fail 'CR persisted in authorization'; fi
}
ssh_test_candidate_symlink() {
  ssh_test_existing
  mv "$SSH_TEST_TARGET/incoming-key.pub" "$SSH_TEST_TARGET/real-key.pub"
  ln -s "$SSH_TEST_TARGET/real-key.pub" "$SSH_TEST_TARGET/incoming-key.pub"
  ssh_test_rejected_unchanged
}
ssh_test_directory_symlink() {
  ssh_test_prepare
  mkdir "$SSH_TEST_TARGET/elsewhere"
  ln -s "$SSH_TEST_TARGET/elsewhere" "$SSH_TEST_TARGET/.ssh"
  if ssh_test_run_example; then ssh_test_fail 'symlink directory accepted'; fi
  [[ ! -e "$SSH_TEST_TARGET/elsewhere/authorized_keys" ]] || ssh_test_fail 'wrote outside target'
}
ssh_test_authorized_symlink() {
  ssh_test_prepare
  mkdir -m 700 "$SSH_TEST_TARGET/.ssh"
  printf 'untouched' > "$SSH_TEST_TARGET/outside"
  ln -s "$SSH_TEST_TARGET/outside" "$SSH_TEST_TARGET/.ssh/authorized_keys"
  if ssh_test_run_example; then ssh_test_fail 'symlink authorization accepted'; fi
  [[ "$(cat "$SSH_TEST_TARGET/outside")" == untouched ]] || ssh_test_fail 'overwrote linked file'
}
ssh_test_writable_home() {
  ssh_test_existing
  chmod 777 "$SSH_TEST_TARGET"
  ssh_test_rejected_unchanged
}
ssh_test_backup_failure() {
  ssh_test_existing
  mkdir "$SSH_TEST_TARGET/bin"
  printf '#!/bin/sh\nexit 1\n' > "$SSH_TEST_TARGET/bin/cp"
  chmod +x "$SSH_TEST_TARGET/bin/cp"
  export PATH="$SSH_TEST_TARGET/bin:$PATH"
  ssh_test_rejected_unchanged
}
ssh_test_root_home() {
  export SSH_TEST_TARGET=/
  if ssh_test_run_example > "$SSH_TEST_DIR/root-home-output" 2>&1; then ssh_test_fail 'root directory accepted'; fi
  ssh_test_has "$SSH_TEST_DIR/root-home-output" '拒绝把根目录作为用户主目录'
}
ssh_test_diag_symlink_parent() {
  ssh_test_diag_setup
  # Move only the test-owned directory, then replace it with a symlink.
  mv "$SSH_TEST_TARGET/.ssh" "$SSH_TEST_TARGET/linked-ssh"
  ln -s "$SSH_TEST_TARGET/linked-ssh" "$SSH_TEST_TARGET/.ssh"
  ssh-keygen() { [[ "$2" != "$SSH_TEST_TARGET/.ssh/authorized_keys" ]] || ssh_test_fail 'followed parent symlink'; }
  guide_ssh_diagnostics > "$SSH_TEST_DIR/diagnostic-output" || ssh_test_fail 'symlink diagnostics'
  ssh_test_has "$SSH_TEST_DIR/diagnostic-output" '不继续跟随'
}

ssh_test_case 'displayed manual Bash snippet parses' ssh_test_syntax
ssh_test_case 'all instructional pages print only with Windows labels and safe defaults' ssh_test_print_only
ssh_test_case 'main menu 14 enters and returns through all SSH choices on FD 9' ssh_test_menu
ssh_test_case 'root diagnostics read selected values without writes' ssh_test_diag_root
ssh_test_case 'ordinary-user diagnostics never elevate' ssh_test_diag_nonroot
ssh_test_case 'missing SSH tools do not trigger installation' ssh_test_diag_missing
ssh_test_case 'invalid config and key file remain diagnostic, not auto-repaired' ssh_test_diag_invalid
if [[ "$(uname -s)" == Linux ]]; then
  ssh-keygen -q -t ed25519 -N '' -C guide-test-fixture -f "$SSH_TEST_DIR/fixture" || exit 1
  ssh_test_case 'manual append preserves old bytes, creates backup and adds valid key' ssh_test_append_existing
  ssh_test_case 'new authorized_keys and directory have restrictive permissions' ssh_test_append_new
  ssh_test_case 'same key with restrictions and another comment is not duplicated' ssh_test_append_duplicate
  ssh_test_case 'private key candidate rejected without touching authorization' ssh_test_private_rejected
  ssh_test_case 'multiple candidate lines rejected without writes' ssh_test_multiline_rejected
  ssh_test_case 'empty candidate rejected without writes' ssh_test_empty_rejected
  ssh_test_case 'placeholder candidate rejected without writes' ssh_test_placeholder_rejected
  ssh_test_case 'malformed public key body rejected without writes' ssh_test_invalid_blob_rejected
  ssh_test_case 'single Windows CRLF public key is accepted and normalized' ssh_test_crlf
  ssh_test_case 'symlink candidate rejected' ssh_test_candidate_symlink
  ssh_test_case 'symlink .ssh directory rejected' ssh_test_directory_symlink
  ssh_test_case 'symlink authorized_keys target rejected' ssh_test_authorized_symlink
  ssh_test_case 'group/world-writable HOME is not silently changed' ssh_test_writable_home
  ssh_test_case 'backup failure prevents append' ssh_test_backup_failure
  ssh_test_case 'root directory cannot be an authorization target' ssh_test_root_home
  ssh_test_case 'diagnostics do not follow symlink .ssh parent' ssh_test_diag_symlink_parent
else
  printf 'SKIP: filesystem permission / real fixture-key tests require Linux; they run in CI.\n'
fi
printf '\n%s SSH tests, %s failures. No user keys or server configuration were changed.\n' "$SSH_TEST_COUNT" "$SSH_TEST_FAILED"
((SSH_TEST_FAILED == 0))
