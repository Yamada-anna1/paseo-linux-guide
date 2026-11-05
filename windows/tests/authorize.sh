#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -s) == Linux ]] || { echo 'Linux-only permission tests'; exit 0; }
root=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d /tmp/paseo-auth-tests.XXXXXXXX)
cleanup() { [[ "$fixture" == /tmp/paseo-auth-tests.* && -d "$fixture" && ! -L "$fixture" ]] && rm -rf -- "$fixture"; }
trap cleanup EXIT
# Replace only the fixture-specific target assignment; never assign HOME.
sed 's/^target_home=${HOME:-}$/target_home=${PASEO_TEST_TARGET:?}/' "$root/src/authorize.sh" > "$fixture/helper.sh"
ssh-keygen -q -t ed25519 -N '' -f "$fixture/key"
blob=$(awk '{print $2}' "$fixture/key.pub")
count=0
prepare() {
  count=$((count+1)); export PASEO_TEST_TARGET="$fixture/home-$count"
  mkdir -m 700 "$PASEO_TEST_TARGET"
  mkdir -m 700 "$PASEO_TEST_TARGET/.ssh"
  printf '# original no trailing newline' > "$PASEO_TEST_TARGET/.ssh/authorized_keys"
  chmod 600 "$PASEO_TEST_TARGET/.ssh/authorized_keys"
}
reject() {
  before=$(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys")
  if bash "$fixture/helper.sh" "$1"; then echo 'Unexpected success'; exit 1; fi
  [[ $(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys") == "$before" ]]
}
prepare
bash "$fixture/helper.sh" "$blob"
grep -qF "$blob" "$PASEO_TEST_TARGET/.ssh/authorized_keys"
backup=("$PASEO_TEST_TARGET"/.ssh/authorized_keys.paseo-backup.*)
[[ $(cat "${backup[0]}") == '# original no trailing newline' ]]
[[ $(stat -c %a "$PASEO_TEST_TARGET/.ssh/authorized_keys") == 600 ]]
echo 'PASS append preserves exact backup and mode'
before=$(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys")
bash "$fixture/helper.sh" "$blob"
[[ $(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys") == "$before" ]]
echo 'PASS duplicate is idempotent'
prepare
printf 'from="example.invalid",command="echo limited" ssh-ed25519 %s restricted\n' "$blob" > "$PASEO_TEST_TARGET/.ssh/authorized_keys"
before=$(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys")
bash "$fixture/helper.sh" "$blob"
[[ $(sha256sum "$PASEO_TEST_TARGET/.ssh/authorized_keys") == "$before" ]]
echo 'PASS restricted existing key is not duplicated'
prepare; reject 'not-a-key'; echo 'PASS invalid argument rejected'
prepare; reject 'AAAA'; echo 'PASS invalid binary key rejected'
prepare; chmod 777 "$PASEO_TEST_TARGET"; reject "$blob"; echo 'PASS unsafe home rejected'
prepare
mv "$PASEO_TEST_TARGET/.ssh/authorized_keys" "$PASEO_TEST_TARGET/original"
ln -s "$PASEO_TEST_TARGET/original" "$PASEO_TEST_TARGET/.ssh/authorized_keys"
reject "$blob"; echo 'PASS symlink authorized file rejected'
prepare
mv "$PASEO_TEST_TARGET/.ssh" "$PASEO_TEST_TARGET/original-dir"
ln -s "$PASEO_TEST_TARGET/original-dir" "$PASEO_TEST_TARGET/.ssh"
reject "$blob"; echo 'PASS symlink directory rejected'
prepare
mkdir "$PASEO_TEST_TARGET/bin"
printf '#!/bin/sh\nexit 1\n' > "$PASEO_TEST_TARGET/bin/cp"
chmod +x "$PASEO_TEST_TARGET/bin/cp"
saved_path=$PATH; export PATH="$PASEO_TEST_TARGET/bin:$PATH"
reject "$blob"; export PATH=$saved_path; echo 'PASS backup failure prevents append'
export PASEO_TEST_TARGET=/
if bash "$fixture/helper.sh" "$blob" > "$fixture/root-output" 2>&1; then exit 1; fi
grep -qF 'invalid user home' "$fixture/root-output"
echo 'PASS root directory cannot be user home'
count=$((count+1)); export PASEO_TEST_TARGET="$fixture/new-$count"; mkdir -m 700 "$PASEO_TEST_TARGET"
bash "$fixture/helper.sh" "$blob"
[[ $(stat -c %a "$PASEO_TEST_TARGET/.ssh") == 700 && $(stat -c %a "$PASEO_TEST_TARGET/.ssh/authorized_keys") == 600 ]]
echo 'PASS new paths have restrictive modes'
echo '11 Linux authorization scenarios passed'
