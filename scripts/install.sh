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

  # Already linked to the right place — nothing to do. Compare the raw link
  # target (we always create links with this exact absolute path); avoids
  # readlink -f, which older macOS lacks.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
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

# Git identity is per-machine: the shared .gitconfig sets user.useConfigOnly,
# so commits fail with a clear error until ~/.gitconfig.local provides
# user.name/user.email. Offer to create it here so a fresh machine works
# right after install. Prompt only when interactive; otherwise just warn.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  if [[ -t 0 ]]; then
    echo
    echo "No ~/.gitconfig.local found. Git identity is set per-machine there."
    read -r -p "Create it now? [Y/n] " reply
    if [[ -z "$reply" || "$reply" == [Yy]* ]]; then
      read -r -p "  git user.name:  " git_name
      read -r -p "  git user.email: " git_email
      if [[ -n "$git_name" && -n "$git_email" ]]; then
        printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$HOME/.gitconfig.local"
        echo "wrote   $HOME/.gitconfig.local"
      else
        echo "note    empty name or email - skipped; git commits will fail until ~/.gitconfig.local sets user.name/user.email"
      fi
    else
      echo "note    skipped - git commits will fail until ~/.gitconfig.local sets user.name/user.email"
    fi
  else
    echo "note    ~/.gitconfig.local missing - git commits will fail until it sets user.name/user.email"
  fi
fi

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
# Non-fatal: symlinks above are already valid, and re-running install.sh
# after fixing the cause converges (the whole script is idempotent).
if git -C "$REPO_DIR" config core.hooksPath .githooks 2>/dev/null; then
  echo "ok      core.hooksPath = .githooks"
else
  echo "warn    could not set repo hooks — run: git -C $REPO_DIR config core.hooksPath .githooks" >&2
fi

echo
echo "Done. Run scripts/fetch-skills.sh to fetch external skills and link all skills."
