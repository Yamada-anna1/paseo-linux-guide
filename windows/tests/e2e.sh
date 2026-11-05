#!/usr/bin/env bash
set -euo pipefail
[[ ${CI:-} == true && ${GITHUB_ACTIONS:-} == true ]] || { echo 'Ephemeral GitHub runner only'; exit 1; }
test_root=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d /tmp/paseo-e2e.XXXXXXXX)
server_pid=''
cleanup() { if [[ -n "$server_pid" ]]; then sudo kill "$server_pid" 2>/dev/null || true; fi; [[ "$fixture" == /tmp/paseo-e2e.* && -d "$fixture" && ! -L "$fixture" ]] && sudo rm -rf -- "$fixture"; }
trap cleanup EXIT
[[ -x /usr/sbin/sshd ]] || { sudo apt-get update -qq; sudo apt-get install -y openssh-server; }
sudo useradd --create-home --shell /bin/bash paseotest
sudo passwd -d paseotest
sudo mkdir -p /run/sshd
for key in host bootstrap client; do ssh-keygen -q -t ed25519 -N '' -f "$fixture/$key"; done
sudo install -d -m 700 -o paseotest -g paseotest /home/paseotest/.ssh
sudo install -m 600 -o paseotest -g paseotest "$fixture/bootstrap.pub" /home/paseotest/.ssh/authorized_keys
# Test files only, not system sshd config.
printf '%s\n' 'ListenAddress 127.0.0.1' 'Port 22222' "HostKey $fixture/host" "PidFile $fixture/sshd.pid" 'PasswordAuthentication no' 'KbdInteractiveAuthentication no' 'PubkeyAuthentication yes' 'UsePAM no' 'StrictModes yes' 'AllowUsers paseotest' 'AuthorizedKeysFile .ssh/authorized_keys' 'LogLevel VERBOSE' > "$fixture/sshd_config"
sudo /usr/sbin/sshd -f "$fixture/sshd_config" -E "$fixture/sshd.log"
server_pid=$(sudo cat "$fixture/sshd.pid")
# Let the invoking CI runner read the dedicated test account's result, without changing its home permissions.
sudo --preserve-env=CI,GITHUB_ACTIONS pwsh -NoProfile -File "$test_root/tests/e2e.ps1" -FixtureDirectory "$fixture" || { sudo cat "$fixture/sshd.log"; exit 1; }
