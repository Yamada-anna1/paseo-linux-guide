#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/install.sh"
fixture=$(mktemp -d /tmp/paseo-wizard-tests.XXXXXXXX)
cleanup() { [[ "$fixture" == /tmp/paseo-wizard-tests.* && -d "$fixture" && ! -L "$fixture" ]] && rm -rf -- "$fixture"; }
trap cleanup EXIT
for address in 127.0.0.1 0.0.0.0 255.255.255.255; do guide_ipv4_valid "$address"; done
for address in '127.0.0.1;id' '01.2.3.4' '1.2.3' '1.2.3.256' '-oProxyCommand=x'; do if guide_ipv4_valid "$address"; then exit 1; fi; done
echo 'PASS IPv4 accepts literal addresses and rejects injection'
id() { [[ "$1" == -u ]] && printf '0\n' || printf 'root\n'; }
sshd() { printf 'pubkeyauthentication yes\n'; }
ssh-keygen() { printf '256 SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA fixture (ED25519)\n'; }
body=$(declare -f guide_ssh_wizard)
body=${body//\/etc\/ssh\/ssh_host_ed25519_key.pub/\$fixture\/host.pub}
eval "$body"
printf '# fixture' > "$fixture/host.pub"
guide_download() { echo 'unexpected download' >&2; exit 1; }
guide_as_admin() { echo 'unexpected elevation' >&2; exit 1; }
chmod() { echo 'unexpected chmod' >&2; exit 1; }
export SSH_CONNECTION='127.0.0.1 11111 127.0.0.1 2222'
printf '127.0.0.1\n' > "$fixture/input"
exec 9< "$fixture/input"
guide_ssh_wizard > "$fixture/output"
grep -qF -- "-Port 2222 -ExpectedFingerprint 'SHA256:" "$fixture/output"
grep -qF 'paseo-ssh-windows/main/paseo-ssh.ps1' "$fixture/output"
echo 'PASS wizard carries verified fingerprint user and port into one PowerShell command'
sshd() { printf 'pubkeyauthentication no\n'; }
exec 9< "$fixture/input"
if guide_ssh_wizard > "$fixture/output" 2>&1; then exit 1; fi
! grep -qF 'scriptblock' "$fixture/output"
echo 'PASS disabled public key auth stops without automatic relaxation'
sshd() { printf 'pubkeyauthentication yes\n'; }
ssh-keygen() { return 1; }
exec 9< "$fixture/input"
if guide_ssh_wizard > "$fixture/output" 2>&1; then exit 1; fi
! grep -qF 'scriptblock' "$fixture/output"
echo 'PASS missing fingerprint never produces auto-trust launcher'
printf '127.0.0.1;id\n' > "$fixture/input"
exec 9< "$fixture/input"
if guide_ssh_wizard > "$fixture/output" 2>&1; then exit 1; fi
echo 'PASS rejected input does not reach generated command'
