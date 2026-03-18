#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

step() {
  printf '\n==> %s\n' "$1"
}

has_npm_script() {
  local script_name="$1"
  if [[ ! -f package.json ]] || ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    return 1
  fi

  node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
    process.exit(pkg.scripts && pkg.scripts[process.argv[1]] ? 0 : 1);
  ' "$script_name" >/dev/null 2>&1
}

step "cargo fmt --all -- --check"
cargo fmt --all -- --check

step "cargo clippy --all-targets --all-features -- -D warnings"
cargo clippy --all-targets --all-features -- -D warnings

step "cargo test --all-features"
cargo test --all-features

if has_npm_script "build-sdk"; then
  step "npm run build-sdk"
  npm run build-sdk
else
  step "skip npm run build-sdk"
  echo "npm, package.json, or build-sdk script not available"
fi

if has_npm_script "test-sdk"; then
  step "npm run test-sdk"
  npm run test-sdk
else
  step "skip npm run test-sdk"
  echo "npm, package.json, or test-sdk script not available"
fi
