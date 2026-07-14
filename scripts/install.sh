#!/usr/bin/env bash
# Idempotent installer: symlinks agentrc files into place.
#
# - Creates target directories if missing.
# - Backs up any existing real file to *.bak before replacing it with a symlink.
# - Never touches *.local files — those belong to the private layer and are
#   only ever created by hand (or by the private repo's own installer).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

link() {
  local src="$1" dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip    $dst (source missing: $src)"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  # Already linked to the right place — nothing to do.
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    echo "ok      $dst"
    return
  fi

  # Stale symlink pointing elsewhere: safe to remove, nothing to back up.
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    # Real file/dir: back it up, never clobbering an earlier backup.
    local bak="$dst.bak"
    [[ -e "$bak" ]] && bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    echo "backup  $dst -> $bak"
  fi

  ln -s "$src" "$dst"
  echo "link    $dst -> $src"
}

# zsh + git
link "$REPO_DIR/zsh/.zshrc"      "$HOME/.zshrc"
link "$REPO_DIR/git/.gitconfig"  "$HOME/.gitconfig"
link "$REPO_DIR/git/.githooks"   "$HOME/.githooks"   # global hooks (core.hooksPath in .gitconfig)

# starship prompt
link "$REPO_DIR/starship/starship.toml"  "$HOME/.config/starship.toml"

# Claude Code
link "$REPO_DIR/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$REPO_DIR/claude/settings.json"  "$HOME/.claude/settings.json"
link "$REPO_DIR/claude/hooks"          "$HOME/.claude/hooks"
link "$REPO_DIR/agents/AGENTS.md"      "$HOME/.claude/AGENTS.md"

# Codex (reads AGENTS.md natively; real config.toml is gitignored and optional)
link "$REPO_DIR/agents/AGENTS.md"      "$HOME/.codex/AGENTS.md"
if [[ -f "$REPO_DIR/codex/config.toml" ]]; then
  link "$REPO_DIR/codex/config.toml"   "$HOME/.codex/config.toml"
else
  echo "note    codex/config.toml not present (copy codex/config.toml.example to create it)"
fi

# Enable the committed pre-commit hook (secret checks) for this repo.
git -C "$REPO_DIR" config core.hooksPath .githooks
echo "ok      core.hooksPath = .githooks"

echo
echo "Done. Run scripts/fetch-skills.sh to fetch external skills and link all skills."
