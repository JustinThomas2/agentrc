#!/usr/bin/env bash
# Fetch pinned external skills and symlink all skills into the agents' dirs.
#
# 1. Reads skills.txt: <git-url>@<tag-or-sha> [<path-in-repo>] [<tree-sha>]
#    (# comments allowed; see skills.txt header for field meanings).
# 2. Clones/updates each entry into skills/external/.repos/<name>/ (sparse
#    when a path is given) and exposes the skill dir as
#    skills/external/<name> (all gitignored). A pinned tree-sha is verified
#    with git itself before the skill is exposed.
# 3. Symlinks every skill folder — own skills in skills/ and fetched ones in
#    skills/external/ — into ~/.claude/skills/ and ~/.codex/skills/.
#
# Idempotent: re-running updates pins and refreshes links.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_DIR/skills.txt"
EXTERNAL_DIR="$REPO_DIR/skills/external"
REPOS_DIR="$EXTERNAL_DIR/.repos"

mkdir -p "$REPOS_DIR" "$HOME/.claude/skills" "$HOME/.codex/skills"

# --- 1+2: fetch pinned external skills -------------------------------------
seen_names=" "
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r raw; do
    # Strip comments and surrounding whitespace; skip blanks.
    line="${raw%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue

    read -r pin path tree <<<"$line"
    ref="${pin##*@}"
    url="${pin%@*}"
    if [[ "$url" == "$pin" || -z "$ref" ]]; then
      echo "error   bad manifest line (expected <url>@<version> [path] [tree-sha]): $line" >&2
      exit 1
    fi

    if [[ -n "$path" ]]; then
      name="$(basename "$path")"
    else
      name="$(basename "$url" .git)"
    fi
    if [[ "$seen_names" == *" $name "* ]]; then
      echo "error   duplicate skill name '$name' derived from manifest — rename one entry's repo/path" >&2
      exit 1
    fi
    seen_names+="$name "
    repo="$REPOS_DIR/$name"

    # Supply-chain guard: a cached clone must still point at the manifest's
    # URL. On mismatch, drop the cache (it's disposable) and re-clone.
    if [[ -d "$repo/.git" ]]; then
      origin="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
      if [[ "$origin" != "$url" ]]; then
        echo "warn    $name: cached clone origin '$origin' != manifest '$url' — re-cloning" >&2
        rm -rf "$repo"
      fi
    fi

    if [[ -d "$repo/.git" ]]; then
      echo "update  $name @ $ref"
      if git -C "$repo" fetch --quiet --depth 1 origin "$ref" 2>/dev/null; then
        git -C "$repo" checkout --quiet --detach FETCH_HEAD
      else
        git -C "$repo" fetch --quiet origin
        git -C "$repo" checkout --quiet --detach "$ref"
      fi
    else
      echo "fetch   $name @ $ref"
      # Sparse, blob-filtered clone keeps subdirectory skills cheap.
      # --branch works for tags and branches; fall back for raw SHAs.
      if ! git clone --quiet --depth 1 --branch "$ref" --filter=blob:none --sparse "$url" "$repo" 2>/dev/null; then
        git clone --quiet --filter=blob:none --sparse "$url" "$repo"
        git -C "$repo" checkout --quiet --detach "$ref"
      fi
    fi
    if [[ -n "$path" ]]; then
      git -C "$repo" sparse-checkout set "$path"
    else
      git -C "$repo" sparse-checkout disable
    fi

    # Integrity pin: refuse content that doesn't match the recorded tree.
    if [[ -n "$tree" ]]; then
      if [[ -n "$path" ]]; then
        actual="$(git -C "$repo" rev-parse "HEAD:$path")"
      else
        actual="$(git -C "$repo" rev-parse 'HEAD^{tree}')"
      fi
      if [[ "$actual" != "$tree" ]]; then
        echo "error   $name: tree sha mismatch (pinned $tree, fetched $actual) — refusing to install" >&2
        exit 1
      fi
    fi

    # Expose the skill dir as skills/external/<name>.
    src="$repo"
    [[ -n "$path" ]] && src="$repo/$path"
    if [[ ! -f "$src/SKILL.md" ]]; then
      echo "error   $name: no SKILL.md at ${path:-repo root}" >&2
      exit 1
    fi
    dst="$EXTERNAL_DIR/$name"
    if [[ ! -L "$dst" || "$(readlink "$dst")" != "$src" ]]; then
      if [[ -L "$dst" ]]; then
        rm "$dst"
      elif [[ -e "$dst" ]]; then
        echo "error   $dst exists and is not a symlink — move it aside first" >&2
        exit 1
      fi
      ln -s "$src" "$dst"
    fi
  done < "$MANIFEST"
fi

# --- 3: symlink all skills into ~/.claude/skills and ~/.codex/skills -------
link_skill() {
  local src="$1" name dst
  name="$(basename "$src")"
  for target in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
    dst="$target/$name"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      echo "ok      $dst"
      continue
    fi
    if [[ -L "$dst" ]]; then
      rm "$dst"
    elif [[ -e "$dst" ]]; then
      # Pre-existing real copy (e.g. hand-installed before agentrc): back it
      # up and replace with the managed symlink, same policy as install.sh.
      bak="$dst.bak"
      [[ -e "$bak" ]] && bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$bak"
      echo "backup  $dst -> $bak"
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
