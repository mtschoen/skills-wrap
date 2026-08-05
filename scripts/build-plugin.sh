#!/usr/bin/env bash
# Assemble this repo into a Claude Code plugin tree.
#
# The repo uses the skills-dev root layout (SKILL.md at the repo root), but a
# plugin discovers skills under `skills/<name>/`. Rather than duplicate SKILL.md
# and references/ in git - two copies that would drift - this script generates
# the plugin layout on demand.
#
# Usage: ./scripts/build-plugin.sh [OUTDIR]      (default: build/plugin)
# Then:  claude plugin install <OUTDIR>

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$repo_root/build/plugin}"

rm -rf "$out"
mkdir -p "$out/skills/wrap"

# Plugin-root files: the manifest and the hook manifest Claude Code auto-loads.
cp -R "$repo_root/.claude-plugin" "$out/"
cp -R "$repo_root/hooks" "$out/"

# The skill itself, under the path a plugin looks for.
cp "$repo_root/SKILL.md" "$out/skills/wrap/"
cp -R "$repo_root/references" "$out/skills/wrap/"
cp -R "$repo_root/scripts" "$out/skills/wrap/"
rm -f "$out/skills/wrap/scripts/build-plugin.sh"

# Nice-to-haves at the plugin root; tests/ and docs/ are dev-only and excluded.
cp "$repo_root/README.md" "$out/"
cp "$repo_root/LICENSE" "$out/"

echo "built plugin tree: $out"
echo
echo "install it with:  claude plugin install \"$out\""
echo "verify with:      /wrap should appear in a fresh session"
