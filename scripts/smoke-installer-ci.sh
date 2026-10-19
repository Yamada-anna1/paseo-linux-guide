#!/usr/bin/env bash
# REAL installation smoke test: only run on a disposable GitHub-hosted runner.
if [[ "${GITHUB_ACTIONS:-}" != true || "${RUNNER_ENVIRONMENT:-}" != github-hosted ]]; then
  printf 'Refusing real install outside a disposable GitHub-hosted runner.\n' >&2
  exit 1
fi
SMOKE_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
. "$SMOKE_REPO_DIR/install.sh"
GUIDE_TMP_DIR="$(mktemp -d /tmp/paseo-linux-guide.XXXXXXXX)" || exit 1
trap guide_cleanup EXIT
exec 9< /dev/null

# Simulate npm not being runnable without removing the runner's Node installation.
# nvm use must put its new, working npm ahead of this temporary command.
mkdir "$GUIDE_TMP_DIR/missing-npm" || exit 1
printf '#!/bin/sh\nprintf "npm is unavailable in this test environment\\n" >&2\nexit 127\n' > "$GUIDE_TMP_DIR/missing-npm/npm"
chmod +x "$GUIDE_TMP_DIR/missing-npm/npm" || exit 1
export PATH="$GUIDE_TMP_DIR/missing-npm:$PATH"
if guide_node_ready; then printf 'Test precondition failed: npm should be unavailable.\n' >&2; exit 1; fi

guide_install_all || exit 1
guide_node_ready || exit 1
[[ "$(node --version)" == v24.* ]] || exit 1
codex --version || exit 1
cc-switch --version || exit 1
paseo --version || exit 1
guide_install_all || exit 1
paseo daemon start --help > "$GUIDE_TMP_DIR/daemon-help.txt" || exit 1
paseo daemon status --help > "$GUIDE_TMP_DIR/status-help.txt" || exit 1
paseo daemon pair --help > "$GUIDE_TMP_DIR/pair-help.txt" || exit 1
grep -q -- '--relay' "$GUIDE_TMP_DIR/pair-help.txt" || {
  printf 'Published Paseo CLI lacks the required --relay option.\n' >&2
  exit 1
}

# No provider login, model calls, pairing QR codes or persistent daemon are created.
printf '\nReal Linux install + missing-npm recovery + repeat-install + daemon/pair command checks passed.\n'
