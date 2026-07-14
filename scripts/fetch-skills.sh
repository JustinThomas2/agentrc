#!/usr/bin/env bash
# Fetch pinned external skills and symlink all skills into the agents' dirs.
#
# 1. Reads skills.txt (lines of <git-url>@<tag-or-sha>; # comments allowed).
# 2. Clones/updates each entry into skills/external/<name>/ (gitignored).
# 3. Symlinks every skill folder — own skills in skills/ and fetched ones in
#    skills/external/ — into ~/.claude/skills/ and ~/.codex/skills/.
#
# Idempotent: re-running updates pins and refreshes links.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_DIR/skills.txt"
EXTERNAL_DIR="$REPO_DIR/skills/external"

mkdir -p "$EXTERNAL_DIR" "$HOME/.claude/skills" "$HOME/.codex/skills"

# --- 1+2: fetch pinned external skills -------------------------------------
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r line; do
    # Strip comments and surrounding whitespace; skip blanks.
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue

    ref="${line##*@}"
    url="${line%@*}"
    if [[ "$url" == "$line" || -z "$ref" ]]; then
      echo "error   bad manifest line (expected <url>@<version>): $line" >&2
      exit 1
    fi

    name="$(basename "$url" .git)"
    dest="$EXTERNAL_DIR/$name"

    if [[ -d "$dest/.git" ]]; then
      echo "update  $name @ $ref"
      git -C "$dest" fetch --quiet origin "$ref" 2>/dev/null || git -C "$dest" fetch --quiet origin
      git -C "$dest" checkout --quiet "$ref"
    else
      echo "fetch   $name @ $ref"
      # --branch works for tags and branches; fall back to full clone for SHAs.
      if ! git clone --quiet --depth 1 --branch "$ref" "$url" "$dest" 2>/dev/null; then
        git clone --quiet "$url" "$dest"
        git -C "$dest" checkout --quiet "$ref"
      fi
    fi
  done < "$MANIFEST"
fi

# --- 3: symlink all skills into ~/.claude/skills and ~/.codex/skills -------
link_skill() {
  local src="$1" name dst
  name="$(basename "$src")"
  for target in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
    dst="$target/$name"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
      echo "ok      $dst"
      continue
    fi
    if [[ -L "$dst" ]]; then
      rm "$dst"
    elif [[ -e "$dst" ]]; then
      echo "skip    $dst exists and is not a symlink (move it aside first)" >&2
      continue
    fi
    ln -s "$src" "$dst"
    echo "link    $dst -> $src"
  done
}

shopt -s nullglob
for dir in "$REPO_DIR/skills"/*/ "$EXTERNAL_DIR"/*/; do
  dir="${dir%/}"
  [[ "$dir" == "$EXTERNAL_DIR" ]] && continue   # container dir, not a skill
  [[ -f "$dir/SKILL.md" ]] || continue          # only link real skill folders
  link_skill "$dir"
done

echo
echo "Done."
