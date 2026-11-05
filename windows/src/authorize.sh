#!/usr/bin/env bash
# Called only AFTER host fingerprint verification and successful SSH authentication.
set -euo pipefail
fail() { printf 'STOP: %s\n' "$*" >&2; exit 1; }
[[ $# == 1 && "$1" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || fail 'invalid public key argument'
key_blob=$1
target_home=${HOME:-}
[[ "$target_home" == /* && "$target_home" != / && -d "$target_home" && ! -L "$target_home" ]] || fail 'invalid user home'
target_home=$(cd -P -- "$target_home" && pwd -P)
[[ "$target_home" != / ]] || fail 'root directory is not a user home'
ssh_dir="$target_home/.ssh"
auth_file="$ssh_dir/authorized_keys"
[[ ! -L "$ssh_dir" && ( ! -e "$ssh_dir" || -d "$ssh_dir" ) ]] || fail 'unsafe .ssh directory'
[[ ! -L "$auth_file" && ( ! -e "$auth_file" || -f "$auth_file" ) ]] || fail 'unsafe authorization file'
for target in "$target_home" "$ssh_dir" "$auth_file"; do
  if [[ -e "$target" ]]; then
    [[ -O "$target" ]] || fail 'ownership does not match login user'
    mode=$(stat -c %a -- "$target")
    (( (8#$mode & 0022) == 0 )) || fail 'group/world writable target; inspect before repair'
  fi
done
umask 077
work_dir=$(mktemp -d /tmp/paseo-authorize.XXXXXXXX)
cleanup() { [[ "$work_dir" == /tmp/paseo-authorize.* && -d "$work_dir" && ! -L "$work_dir" ]] && rm -rf -- "$work_dir"; }
trap cleanup EXIT
printf 'ssh-ed25519 %s paseo-ssh\n' "$key_blob" > "$work_dir/key.pub"
ssh-keygen -E sha256 -lf "$work_dir/key.pub" || fail 'invalid ED25519 public key'
if [[ -f "$auth_file" ]]; then
  found=$(awk -v key="$key_blob" 'index($0,key) { found=1 } END { print found+0 }' "$auth_file")
  if [[ "$found" == 1 ]]; then
    printf '%s\n' 'KEY_ALREADY_PRESENT: restrictions preserved'
    exit 0
  fi
fi
mkdir -p -m 700 -- "$ssh_dir"
if [[ -f "$auth_file" ]]; then
  backup=$(mktemp "$auth_file.paseo-backup.XXXXXXXX")
  cp -p -- "$auth_file" "$backup" || fail 'backup failed; no append'
  printf 'BACKUP_OK: %s\n' "$backup"
fi
printf '\nssh-ed25519 %s paseo-ssh\n' "$key_blob" >> "$auth_file"
printf '%s\n' 'KEY_ADDED'
ssh-keygen -E sha256 -lf "$auth_file"
